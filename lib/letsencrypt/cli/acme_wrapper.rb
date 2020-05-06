require 'json'
require 'acme-client'
require 'logger'
require 'colorize'
require_relative 'support/certificate'

class AcmeWrapper
  def initialize(options)
    @options = options
    if !@options[:color]
      String.disable_colorization = true
    end
  end

  def log(message, severity=:info)
    @logger ||= Logger.new(STDOUT).tap {|logger|
      logger.level = Logger::SEV_LABEL.index(@options[:log_level].upcase)
      logger.formatter = proc do |sev, datetime, progname, msg|
        "#{datetime.to_s.light_black}: #{msg}\n"
      end
    }
    @logger.send(severity, message)
  end

  def client
    @client ||= Acme::Client.new(private_key: account_key, directory: directory)
  end

  def create_order(domains)
    log "Creating order for domains #{domains.to_s.blue}"
    return client.new_order(identifiers: domains)
  end

  def authorize(authorization)
    domain = authorization.domain
    FileUtils.mkdir_p(@options[:webroot_path])
    log "Authorizing #{domain.blue}.."
    challenge = authorization.http

    challenge_file = File.join(@options[:webroot_path], challenge.filename.split('/').last)
    log "Writing challenge to #{challenge_file}", :debug
    File.write(challenge_file, challenge.file_content)

    challenge.request_validation

    10.times do
      log "Checking verification...", :debug
      sleep 1
      challenge.reload
      break if challenge.status != 'pending'
    end

    if challenge.status == 'valid'
      log "Authorization successful for #{domain.green}"
      File.unlink(challenge_file)
      true
    else
      log "Authorization error for #{domain.red}", :error
      log challenge.error['detail']
      false
    end
  end

  def cert(domains)
    return if certificate_exists_and_valid_and_all_domains_included?(domains)
    csr = OpenSSL::X509::Request.new
    certificate_private_key = find_or_create_pkey(@options[:private_key_path], "private key", @options[:key_length] || 2048)

    csr.subject = OpenSSL::X509::Name.new([
      # ['C',             options[:country], OpenSSL::ASN1::PRINTABLESTRING],
      # ['ST',            options[:state],        OpenSSL::ASN1::PRINTABLESTRING],
      # ['L',             options[:city],         OpenSSL::ASN1::PRINTABLESTRING],
      # ['O',             options[:organization], OpenSSL::ASN1::UTF8STRING],
      # ['OU',            options[:department],   OpenSSL::ASN1::UTF8STRING],
      # ['CN',            options[:common_name],  OpenSSL::ASN1::UTF8STRING],
      # ['emailAddress',  options[:email],        OpenSSL::ASN1::UTF8STRING]
      ['CN', domains.first, OpenSSL::ASN1::UTF8STRING]
    ])
    if domains.count > 1
      ef = OpenSSL::X509::ExtensionFactory.new
      exts = [ ef.create_extension( "subjectAltName", domains.map{|domain| "DNS:#{domain}"}.join(','), false  ) ]
      attrval = OpenSSL::ASN1::Set([OpenSSL::ASN1::Sequence(exts)])
      attrs = [
        OpenSSL::X509::Attribute.new('extReq', attrval),
        OpenSSL::X509::Attribute.new('msExtReq', attrval),
      ]
      attrs.each do |attr|
        csr.add_attribute(attr)
      end
    end
    csr.version = 2
    csr.public_key = certificate_private_key.public_key
    csr.sign(certificate_private_key, OpenSSL::Digest::SHA256.new)
    order = create_order(domains)
    order.finalize(csr: csr)
    while order.status == 'processing'
      sleep(1)
      order.reload
    end
    certificate = Certificate.new(order.certificate)
    File.write(@options[:fullchain_path], certificate.fullchain_to_pem)
    File.write(@options[:chain_path], certificate.chain_to_pem)
    File.write(@options[:certificate_path], certificate.to_pem)
    log "Certificate successfully created to #{@options[:fullchain_path]} #{@options[:chain_path]} and #{@options[:certificate_path]}!".green
    log "Certificate valid until: #{certificate.x509.not_after}"
  end

  def check_certificate(path)
    unless File.exists?(path)
      log "Certificate #{path} does not exists", :warn
      return false
    end
    cert = OpenSSL::X509::Certificate.new(File.read(path))
    renew_on = cert.not_after.to_date - @options[:days_valid]
    log "Certificate '#{path}' valid until #{cert.not_after.to_date}.", :info
    if Date.today >= renew_on
      log "Certificate '#{path}' should be renewed!", :warn
      return false
    else
      true
    end
  end

  def revoke_certificate(path)
    unless File.exists?(path)
      log "Certificate #{path} does not exists", :warn
      return false
    end
    cert = OpenSSL::X509::Certificate.new(File.read(path))
    if client.revoke(certificate: cert)
      log "Certificate '#{path}' was revoked", :info
    end
    true
  rescue Acme::Client::Error::Malformed => e
    log e.message, :error
    return false
  end

  private

  def certificate_exists_and_valid_and_all_domains_included?(domains)
    return false if !File.exists?(@options[:certificate_path])
    cert = OpenSSL::X509::Certificate.new(File.read(@options[:certificate_path]))
    domains_in_cert = cert.extensions.map(&:to_h).select{|i| i['oid'] == 'subjectAltName' }.map{|i| i['value']}.join(', ').split(/, */).map{|i| i.sub(/^DNS:/, '') }  +
      [ cert.subject.to_s.sub(%r{/CN=}, '') ].uniq.sort
    missing_domains = domains.sort.uniq - domains_in_cert
    if missing_domains != []
      log "Certificate '#{@options[:certificate_path]}' missing domains #{missing_domains.join(' ')}. Existing: #{domains_in_cert.join(' ')}", :warn
      return false
    end
    expires_on = cert.not_after.to_date
    if expires_on <= Date.today
      log "Certificate '#{@options[:certificate_path]}' has expired on #{expires_on}.", :warn
      return false
    end
    renew_on = expires_on - @options[:days_valid]
    if renew_on > Date.today
      log "Certificate '#{@options[:certificate_path]}' still valid till #{cert.not_after.to_date}.", :warn
      log "Won't renew until #{renew_on} (#{@options[:days_valid]} days before)", :warn
      exit 2
    end

    false
  end

  def directory
    if @options[:test]
      "https://acme-staging-v02.api.letsencrypt.org/directory"
    else
      "https://acme-v02.api.letsencrypt.org/directory"
    end
  end

  def account_key
    @account_key ||= find_or_create_pkey(@options[:account_key], "account key", @options[:key_length] || 4096)
  end

  def find_or_create_pkey(file_path, name, length)
    if File.exists?(file_path)
      log "existing account key found"
      OpenSSL::PKey::RSA.new File.read file_path
    else
      log "creating new private key to #{file_path}..."
      private_key = OpenSSL::PKey::RSA.new(length)
      File.write(file_path, private_key.to_s)
      File.chmod(0400, file_path)
      private_key
    end
  end
end
