class Certificate
  extend Forwardable

  attr_reader :x509, :x509_chain

  def_delegators :x509, :to_pem, :to_der

  def initialize(fullchain_certificate)
    fullchain_array = fullchain_certificate.strip.split("\n\n")
    @x509 = OpenSSL::X509::Certificate.new(fullchain_array.first)
    @x509_chain = fullchain_array[1..-1].map { |cert| OpenSSL::X509::Certificate.new(cert) }
  end

  def chain_to_pem
    x509_chain.map(&:to_pem).join("\n")
  end

  def x509_fullchain
    [x509, *x509_chain]
  end

  def fullchain_to_pem
    x509_fullchain.map(&:to_pem).join("\n")
  end

  def common_name
    x509.subject.to_a.find { |name, _, _| name == 'CN' }[1]
  end
end
