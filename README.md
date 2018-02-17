# ACME-Cli

[![Build Status](https://travis-ci.org/zealot128/ruby-acme-cli.svg?branch=travis)](https://travis-ci.org/zealot128/ruby-acme-cli)
[![Gem Version](https://badge.fury.io/rb/acme-cli.svg)](https://badge.fury.io/rb/acme-cli)

Yet another ACME client (e.g. to use together with Letsencrypt CA to issue TLS certs) for command lines using Ruby.

## Installation

* This tool needs Ruby >= 2.1 (as the dependency ``acme-client`` needs that because of use of keyword arguments).
* OpenSSL bindings
* no sudo! (needs access to webserver-root ``/.well-known/acme-challenges`` alias for all domains - See later section for Nginx example)

```
# check your ruby version:
$ ruby --version
ruby 2.2.3p173 (2015-08-18 revision 51636) [x86_64-linux]

$ gem install acme-cli

$ acme-cli --version
0.2.0
```

### Troubleshooting Ruby version

Unfortunately, most Linux distributions does not ship a current Ruby version (Version 1.9.3 or 2.0). Check, if your ruby version is at least 2.2. Otherwise you need to update the Ruby.

If you are installing this as a non-root user, you might want to try RVM. Installation itself needs no root, but needs some packages:

```
sudo apt-get install curl bison build-essential zlib1g-dev libssl-dev libreadline6-dev libxml2-dev libgmp-dev git-core
```

To install RVM:

```
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable  --autolibs=disable --auto-dotfiles

rvm install 2.2
source ~/.bashrc # or ~/.profile RVM tells you to reload your shell

ruby --version
```

Notice: If you are using RVM, all your cronjobs must be run as a login shell, otherwise RVM does not work:

```cron
* * * * * /bin/bash -l -c "acme-cli manage ..."
```

Another way, e.g. on Ubuntu 14.04 might be to use the [Brightbox ppa](https://www.brightbox.com/blog/2015/01/05/ruby-2-2-0-packages-for-ubuntu/).

## Usage

Specify ``-t`` to use Letsencrypt test server. Without it, all requests are called against the production server, that might have some more strict rate limiting. If you are just toying around, add the -t flag.

```bash
# show all commands

acme-cli help

# show options for an individual command
acme-cli help cert

# creates account_key.json in current_dir
acme-cli register -t myemail@example.com

# authorize one or more domains/subdomains
acme-cli authorize -t --webroot-path /var/www/default example.com www.example.com somedir.example.com

# experimental: authorize all server_names in /etc/nginx/sites-enabled/*
acme-cli authorize_all -t --webroot-path /var/www/default

# create a certificate for domains that are already authorized within the last minutes (1h-2h I think)
# the first domain will be the cn subject. All other are subjectAlternateName
# if cert.pem already exists, will only create a new one if the old is expired
# (30 days before expiration) -> see full help
acme-cli help cert

acme-cli cert -t example.com www.example.com somdir.example.com
# will create key.pem fullchain.pem chain.pem and cert.pem in current directory

# checks validation date of given certificate.
# Exists non-zero if:
# * not exists (exit 1)
# * will expire in more than 30 days (exit code 2)
acme-cli check --days-valid 30 cert.pem
```


And last but not least, the meta command ``manage`` that integrated check + authorize + cert (intended to be run as cronjob):

```bash
$ acme-cli manage --days-valid 30 \
                       --account-key /home/acme/account_key.pem \
                       --webroot-path /home/acme/webroot/.well-known/acme-challenge \
                       --key-directory /home/acme/certs \
                       example.com www.example.com

2015-12-05 23:40:04 +0100: Certificate /home/acme/certs/example.com/cert.pem does not exists
2015-12-05 23:40:04 +0100: Authorizing example.com...
2015-12-05 23:40:04 +0100: existing account key found
2015-12-05 23:40:06 +0100: Authorization successful for example.com
2015-12-05 23:40:06 +0100: Authorizing www.example.com
2015-12-05 23:40:08 +0100: Authorization successful for www.example.com
2015-12-05 23:40:08 +0100: creating new private key to /home/acme/certs/example.com/key.pem...
2015-12-05 23:40:09 +0100: Certificate successfully created to /home/acme/certs/example.com/fullchain.pem /home/acme/certs/example.com/chain.pem and /home/acme/certs/example.com/cert.pem!
2015-12-05 23:40:09 +0100: Certificate valid until: 2016-03-04 21:40:00 UTC

# Run command again exits immediately:
$ acme-cli manage --days-valid 30 --account-key /home/acme/account_key.pem --webroot-path /home/acme/webroot/.wel
l-known/acme-challenge --key-directory /home/acme/certs \
      example.com www.example.com
2015-12-05 23:40:17 +0100: Certificate '/home/acme/certs/example.com/cert.pem' valid until 2016-03-04.
$ echo $?
1
```

This had:

1. check if /home/acme/certs/example.com/cert.pem exists and expires in less than 30 days (or exit 1 at this point)
2. authorize all domains + subdomains
3. issue one certificate with those domains and place it under /home/acme/certs/example.com/[key.pem,fullchain.pem,chain.pem,cert.pem]
4. exit 0 -> so can be && with ``service nginx reload`` or mail deliver

For running as cron, reducing log level to fatal might be desirable: ``acme-cli manage --log-level fatal``.

## Example integration Nginx:

```nginx
server {
  listen 80;
  server_name example.com www.example.com somedir.example.com
  location /.well-known/acme-challenge {
	  alias /home/acme/webroot/.well-known/acme-challenge;
	  default_type "text/plain";
	  try_files $uri =404;
  }
```

notice the location - alias. Use this dir with ``--webroot-path`` for authorization.

Afterwards, use the fullchain.pem and key.pem:

```nginx
server {
  listen 443 ssl;
  server_name example.com www.example.com;
  ssl on;
  ssl_certificate_key /home/acme/certs/example.com/key.pem;
  ssl_certificate /home/acme/certs/example.com/fullchain.pem;

  # use the settings from: https://gist.github.com/konklone/6532544
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/zealot128/ruby-acme-cli/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
