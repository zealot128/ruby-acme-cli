require "spec_helper"
require "letsencrypt-cli"
require "tmpdir"

module Letsencrypt::Cli
  describe "App" do
    specify "cert " do
      Timecop.freeze Time.parse("2015-12-05 12:00") do
        cert = <<-DOC.strip_heredoc
          -----BEGIN CERTIFICATE-----
          MIIE+DCCA+CgAwIBAgITAPpwmurwFGWv2JshsvTKRSP8eTANBgkqhkiG9w0BAQsF
          ADAfMR0wGwYDVQQDDBRoYXBweSBoYWNrZXIgZmFrZSBDQTAeFw0xNTEyMDQyMjAx
          MDBaFw0xNjAzMDMyMjAxMDBaMBsxGTAXBgNVBAMTEHN0ZWZhbndpZW5lcnQuZGUw
          ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCkEUYABDn9oL/Z1EDBDhBK
          9StLC9gwfUI75YoPRUNtinALwS/GAmZyGQmwXzGrtQeW1zTmJShmWjyEUE6faGQU
          Hn1BXloysbbYboa34nMlAyff1cuXvvgnF2ez1CbZB98pDoAyGPnhXuc1Cq18Mohb
          Ri9P9EqP58LYAOeHHa6xFA0C+s/uK0d17jzJa4vMhubLyniPR6hcgDxbBcatRSWW
          D1UbIOr2l065jabEMjCMlYIEg9DVsjS0E5BX0MMVx2vcsHVN6V1KF7O+Fj9eSjxv
          r9VSW2X+frR1NW7xfoF+kzqXFIl9QG8I7RkeG46KHJ7q+6QWaEhDNHRzQ8LukN1B
          AgMBAAGjggIvMIICKzAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUH
          AwEGCCsGAQUFBwMCMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFIat6cLW+YKwrJ4w
          kaOMeOTJpoKsMB8GA1UdIwQYMBaAFPt4TxL5YBWDLJ8XfzQZsy426kGJMHgGCCsG
          AQUFBwEBBGwwajAzBggrBgEFBQcwAYYnaHR0cDovL29jc3Auc3RhZ2luZy14MS5s
          ZXRzZW5jcnlwdC5vcmcvMDMGCCsGAQUFBzAChidodHRwOi8vY2VydC5zdGFnaW5n
          LXgxLmxldHNlbmNyeXB0Lm9yZy8wMQYDVR0RBCowKIIQc3RlZmFud2llbmVydC5k
          ZYIUd3d3LnN0ZWZhbndpZW5lcnQuZGUwgf4GA1UdIASB9jCB8zAIBgZngQwBAgEw
          geYGCysGAQQBgt8TAQEBMIHWMCYGCCsGAQUFBwIBFhpodHRwOi8vY3BzLmxldHNl
          bmNyeXB0Lm9yZzCBqwYIKwYBBQUHAgIwgZ4MgZtUaGlzIENlcnRpZmljYXRlIG1h
          eSBvbmx5IGJlIHJlbGllZCB1cG9uIGJ5IFJlbHlpbmcgUGFydGllcyBhbmQgb25s
          eSBpbiBhY2NvcmRhbmNlIHdpdGggdGhlIENlcnRpZmljYXRlIFBvbGljeSBmb3Vu
          ZCBhdCBodHRwczovL2xldHNlbmNyeXB0Lm9yZy9yZXBvc2l0b3J5LzANBgkqhkiG
          9w0BAQsFAAOCAQEALBQ6vloxMOF0PDqQQxcl7a9Uct/3CzSnQkd840bYA9KffaCt
          ybGycWcKL5o+E1Hh8K6soYiMEI+nrB7jSVN2nckqSx7yQen/OGYFsZiysBpewbyA
          +ife65CPa7MyAOSMLv9lNMH5bkGbR72yBKVyj4LAx6DxsYKSJS1P+w5CbkxKMHAX
          9zvuPa5IW6gLYd+AY6Xg6iSqtFPfGc1C+tWrd4w/wcQtKPmQV/b8P8tg7PAdItND
          JYGOaudcRmmXiuLPHUQcqhNikRNHzZhsSXAIRJntVG4ifk5bbVPPngHVDlXnZM9T
          0yA+Ssmk6klj0Q1MZMVhivMGvZxQxFsXzHXsTg==
          -----END CERTIFICATE-----
        DOC
        cert_path = File.join(@current_dir, "cert.pem")
        File.write(cert_path, cert)
        app = App.new
        out = capture(:stdout) do
          expect {
            app.invoke("cert", ['example.com'], certificate_path: cert_path, color: false)
          }.to raise_error(SystemExit)
        end
        expect(out).to include 'still valid till 2016-03-03'
      end
    end
  end

end
