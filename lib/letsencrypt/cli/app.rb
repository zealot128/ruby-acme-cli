require 'thor'
require 'colorize'
require 'fileutils'
module Letsencrypt
  module Cli
    class App < Thor
      class_option :account_key, desc: "Path to private key file (will be created if not exists)", aliases: "-a", default: 'account_key.pem'
      class_option :test, desc: "Use staging url of Letsencrypt instead of production server", aliases: "-t", type: :boolean
      class_option :log_level, desc: "Log Level (debug, info, warn, error, fatal)", default: "info"
      class_option :color, desc: "Disable colorize", default: true, type: :boolean

      desc 'register EMAIL', 'Register account'
      method_option :key_length, desc: "Length of generated private key", type: :numeric, default: 4096
      def register(email)
        if email.nil? || email == ""
          wrapper.log "no E-Mail specified!", :fatal
          exit 1
        end
        if !email[/.*@.*/]
          wrapper.log "not an email", :fatal
          exit 1
        end
        registration = wrapper.client.register(contact: "mailto:" + email)
        registration.agree_terms
        wrapper.log "Account created, Terms accepted"
      end

      desc 'authorize_all', "Verify all server_names in /etc/nginx/sites-enabled/* (needs read access)"
      method_option :webroot_path, desc: "Path to mapped .acme-challenge folder (no subdir)", aliases: '-w', required: true
      method_option :webserver_dir, desc: "Path to webserver configs", default: "/etc/nginx/sites-enabled"
      def authorize_all
        lines = Dir[ File.join(@options[:webserver_dir], "*")].map{|file| File.read(file).lines.grep(/^\s*server_name/) }.flatten
        domains = lines.flatten.map{|i| i.strip.split(/[; ]/).drop(1) }.flatten.reject{|i| i.length < 3 }.uniq
        authorize(*domains)
      end

      desc 'authorize [DOMAINS]', 'Authorize all domains'
      method_option :webroot_path, desc: "Path to mapped .well-known/acme-challenge folder (no subdirs will be created)", aliases: '-w', required: true
      def authorize(*domains)
        rc = 0
        domains.each do |domain|
          if !wrapper.authorize(domain)
            rc = 1
          end
        end
        if rc != 0
          exit rc
        end
      end

      desc "cert [DOMAINS]", "create certificate and private key pair for domains. The first domain is the main CN domain, the reset will be added as SAN. If the given certificate-path already exists, script will exit non-zero if the certificate is still valid until the given number of days before."
      method_option :private_key_path, desc: "Path to private key. Will be created if non existant", aliases: '-k', default: 'key.pem'
      method_option :key_length, desc: "Length of private key", default: 2048, type: :numeric
      method_option :fullchain_path, desc: "Path to fullchain certificate (Nginx) (will be overwritten if exists!)", aliases: '-f', default: 'fullchain.pem'
      method_option :certificate_path, desc: "Path to certificate (Apache)", aliases: '-c', default: 'cert.pem'
      method_option :chain_path, desc: "Path to chain (Apache)", aliases: '-n', default: 'chain.pem'
      method_option :days_valid, desc: "If the --certificate-path already exists, only create new stuff, if that certificate isn't valid for less than the given number of days", default: 30, type: :numeric
      def cert(*domains)
        if domains.length == 0
          wrapper.log "no domains given", :fatal
          exit 1
        end
        wrapper.cert(domains)
      end

      desc "check PATH_TO_CERTIFICATE", "checks, if a given certificate exists and is valid until DAYS_VALID"
      method_option :days_valid, desc: "If the --certificate-path already exists, only create new stuff, if that certificate isn't valid for less than the given number of days", default: 30, type: :numeric
      def check(path)
        if !wrapper.check_certificate(path)
          exit 1
        end
      end

      desc "revoke PATH_TO_CERTIFICATE", "revokes a given certificate"
      def revoke(path)
        wrapper.revoke_certificate(path)
      end

      desc "manage DOMAINS", "meta command that will: check if cert already exists / still valid (exits zero if nothing todo, exits 2 if certificate is still valid) + authorize given domains + issue certificate for given domains"
      method_option :key_length, desc: "Length of private key", default: 2048, type: :numeric
      method_option :days_valid, desc: "If the --certificate-path already exists, only create new stuff, if that certificate isn't valid for less than the given number of days", default: 30, type: :numeric
      method_option :webroot_path, desc: "Path to mapped .well-known/acme-challenge folder (no subdirs will be created)", aliases: '-w', required: true
      method_option :key_directory, desc: "Base directory of key creation. A subfolder with the first domain will be created where all certs + key are stored", default: "~/certs/"
      def manage(*domains)
        key_dir = File.join(@options[:key_directory], domains.first)
        FileUtils.mkdir_p(key_dir)
        @options = @options.merge(
          :private_key_path  => File.join(key_dir, 'key.pem'),
          :fullchain_path    => File.join(key_dir, 'fullchain.pem'),
          :certificate_path  => File.join(key_dir, 'cert.pem'),
          :chain_path        => File.join(key_dir, 'chain.pem'),
        )
        if wrapper.check_certificate(@options[:certificate_path])
          exit 2
        end
        authorize(*domains)
        cert(*domains)
      end

      map %w[--version -v] => :__print_version
      desc "--version, -v", "print the version"
      def __print_version
        puts Letsencrypt::Cli::VERSION
      end

      private

      def wrapper
        @wrapper ||= AcmeWrapper.new(options)
      end
    end
  end
end
