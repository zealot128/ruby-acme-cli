# Change Log

## [v0.3.0](https://github.com/zealot128/ruby-letsencrypt-cli/tree/v0.3.0)

* Certificate creation checks if existing certificate includes all requested domains. If at least one is missing, a new cert will be requested
* Added Ruby 2.3.0 and Ruby head to the build matrix

[Full Changelog](https://github.com/zealot128/ruby-letsencrypt-cli/compare/v0.2.0...v0.3.0)

## [v0.2.0](https://github.com/zealot128/ruby-letsencrypt-cli/tree/v0.2.0)

[Full Changelog](https://github.com/zealot128/ruby-letsencrypt-cli/compare/v0.1.4...v0.2.0)

**Closed issues:**

- cf1e0d9 Exit code 2, if certificate is still valid

**Merged pull requests:**

- Apply strict permissions on private key [\#4](https://github.com/zealot128/ruby-letsencrypt-cli/pull/4) ([zygiss](https://github.com/zygiss))
- Fix typo in README [\#2](https://github.com/zealot128/ruby-letsencrypt-cli/pull/2) ([kenrick](https://github.com/kenrick))

## [v0.1.4](https://github.com/zealot128/ruby-letsencrypt-cli/tree/v0.1.4) (2015-12-08)

* require higher acme-client version, that generated correct fullchain certs.
  fullchain.pem is chain.pem + cert.pem, should be cert.pem + chain.pem [\#1](https://github.com/zealot128/ruby-letsencrypt-cli/issues/1)

[Full Changelog](https://github.com/zealot128/ruby-letsencrypt-cli/compare/v0.1.3...v0.1.4)

## [v0.1.3](https://github.com/zealot128/ruby-letsencrypt-cli/tree/v0.1.3) (2015-12-06)

* Fixed registration
* Added various specs

[Full Changelog](https://github.com/zealot128/ruby-letsencrypt-cli/compare/v0.1.2...v0.1.3)

## [v0.1.2](https://github.com/zealot128/ruby-letsencrypt-cli/tree/v0.1.2) (2015-12-05)

* Added manage command
* Improved nginx doc + Ruby installation

[Full Changelog](https://github.com/zealot128/ruby-letsencrypt-cli/compare/v0.1.1...v0.1.2)

## [v0.1.1](https://github.com/zealot128/ruby-letsencrypt-cli/tree/v0.1.1) (2015-12-05)

[Full Changelog](https://github.com/zealot128/ruby-letsencrypt-cli/compare/v0.1.0...v0.1.1)

* b654469 new command: check PATH_TO_CERT

## [v0.1.0](https://github.com/zealot128/ruby-letsencrypt-cli/tree/v0.1.0) (2015-12-05)

* released first public version
* added --version flag
* added explicit production server

[Full Changelog](https://github.com/zealot128/ruby-letsencrypt-cli/compare/v0.1.0.beta1...v0.1.0)

## [v0.1.0.beta1](https://github.com/zealot128/ruby-letsencrypt-cli/tree/v0.1.0.beta1) (2015-12-05)
[Full Changelog](https://github.com/zealot128/ruby-letsencrypt-cli/compare/v0.1.0.pre...v0.1.0.beta1)

## [v0.1.0.pre](https://github.com/zealot128/ruby-letsencrypt-cli/tree/v0.1.0.pre) (2015-12-05)


\* *This Change Log was (partially) automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*