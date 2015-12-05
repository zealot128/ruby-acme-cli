# Letsencrypt::Cli

[![Build Status](https://travis-ci.org/zealot128/ruby-letsencrypt-cli.svg?branch=travis)](https://travis-ci.org/zealot128/ruby-letsencrypt-cli)
[![Gem Version](https://badge.fury.io/rb/letsencrypt-cli.svg)](https://badge.fury.io/rb/letsencrypt-cli)

Yet another Letsencrypt client using Ruby.

## Installation

* This tool needs Ruby > 2.0 (as the dependency acme needs that).
* openssl bindings
* no sudo! (Just access to webserver root .well-known alias)

    $ gem install letsencrypt-cli

## Usage

Specify ``-p`` to use letsencrypt production server. Without it, all requests are called against the staging server. (live server has some hard rate limiting, so use the staging server for playing first).

```bash
# show all commands

letsencrypt-cli help

# show options for an individual command
letsencrypt-cli help cert

# creates account_key.json in current_dir
letsencrypt-cli register -p myemail@example.com


# authorize one or more domains/subdomains
letsencrypt-cli authorize -p --webroot-path /var/www/default example.com www.example.com somedir.example.com

# experimental: authorize all server_names in /etc/nginx/sites-enabled/*
letsencrypt-cli authorize_all -p --webroot-path /var/www/default


# create a certificate for before authorized domains.
# the first domain will be the cn subject. All other are subjectAlternateName
letsencrypt-cli cert example.com www.exaple.com somdir.example.com
# will create key.pem fullchain.pem chain.pem and cert.pem
```


## Example integration nginx:


```nginx
server {
  listen 80;
  server_name example.com www.example.com somedir.example.com
  location /.well-known/acme-challenge {
	  alias /home/letsencrypt/webroot/.well-known/acme-challenge;
	  default_type "text/plain";
	  try_files $uri =404;
  }
```

notice the location - alias. Use this dir with ``--webroot-path`` for authorization.

Afterwards, use the fullchain.pem and key.pem:

```nginx
server {
  listen 443 ssl;
  server_name stefanwienert.de www.stefanwienert.de;
  ssl on;
  ssl_certificate_key /path/to/key.pem;
  ssl_certificate /path/to/fullchain.pem;

  # use the settings from: https://gist.github.com/konklone/6532544
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/zealot128/letsencrypt-cli/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
