require 'thor'
require 'colorize'
require 'fileutils'
module Letsencrypt
  module Cli
    class App < Thor
      class_option :account_key, desc: "Path to private key file (will be created if not exists)", aliases: "-a", default: 'account_key.pem'
      class_option :production, desc: "Use production url of letsencrypt instead of staging server", aliases: "-p", type: :boolean
      class_option :log_level, desc: "Log Level (debug, info, warn, error, fatal)", default: "info"
      class_option :color, desc: "Disable colorize", default: true, type: :boolean

      desc 'register EMAIL', 'Register account'
      method_option :key_length, desc: "Length of generated private key", type: :numeric, default: 4096
      def register(email)
        if email.nil? || email == ""
          log "no E-Mail specified!", :fatal
          exit 1
        end
        if !email[/.*@.*/]
          log "not an email", :fatal
          exit 1
        end
        registration = wrapper.client.register(contact: "mailto:" + email)
        registration.agree_terms
        wrapper.log "Account created, Terms accepted"
      end

      desc 'authorize_all', "Verify all server_names in /etc/nginx/sites-enabled/* (needs read access)"
      method_option :webroot_path, desc: "Path to mapped .acme-challenge folder (no subdir)", aliases: '-w', required: true
      def authorize_all
        lines = Dir['/etc/nginx/sites-enabled/*'].map{|file| File.read(file).lines.grep(/^\s*server_name/) }.flatten
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
        exit rc
      end

      desc "cert [DOMAINS]", "create certificate and private key pair for domains. The first domain is the main CN domain, the reset will be added as SAN. If the given certificate-path already exists, script will exit non-zero if the certificate is still valid until the given number of days before."
      method_option :private_key_file, desc: "Path to private key. Will be created if non existant", aliases: '-k', default: 'key.pem'
      method_option :key_length, desc: "Length of private key", default: 2048, type: :numeric
      method_option :fullchain_path, desc: "Path to fullchain certificate (Nginx) (will be overwritten if exists!)", aliases: '-f', default: 'fullchain.pem'
      method_option :certificate_path, desc: "Path to certificate (Apache)", aliases: '-c', default: 'cert.pem'
      method_option :chain_path, desc: "Path to chain (Apache)", aliases: '-n', default: 'chain.pem'
      method_option :days_valid, desc: "If the --certificate-path already exists, only create new stuff, if that certificate isn't valid for less than the given number of days", default: 30, type: :numeric
      def cert(*domains)
        if domains.length == 0
          $stderr.puts "no domains given"
          exit 1
        end
        wrapper.cert(domains)
      end

      private

      def wrapper
        @wrapper ||= AcmeWrapper.new(options)
      end
    end
  end
end
