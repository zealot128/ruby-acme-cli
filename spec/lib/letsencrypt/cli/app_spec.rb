require "spec_helper"
require "letsencrypt-cli"
require "tmpdir"

module Letsencrypt::Cli
  describe "App" do
    let(:app) { App.new }
    specify "register" do
      Timecop.freeze Time.parse("2015-12-05 12:00") do
        VCR.use_cassette("register") do
          key_path = File.join(@current_dir, "account_key.pem")
          out = capture(:stdout) {
            app.invoke "register", ["info@stefanwienert.de"],
              color: false,
              test: true,
              account_key: key_path
          }
          expect(out).to include "Account created"
          expect(File.exists?(key_path)).to be == true
        end
      end
    end

    # this test needs manual intervention -> I will binding.pry inside the
    # authorization and copy the verification to a live server that i provide
    # VCR will record that transaction for further replay
    describe "authorization & certificate creation" do
      let(:account_key) {
          <<-DOC.strip_heredoc
          -----BEGIN RSA PRIVATE KEY-----
          MIIEogIBAAKCAQEAsVV526Ht43vXCoJjKp4VN1wzDclaIfbyWt/XL8apRbORvB00
          cwznEvLdTd1oeeZ5/PNxHNU6GIG1eWE9Qsl2TdiZe67gfzuoXoKKPU3m8SlLyzM8
          4c+GhUqGKhfHo0FDgwxu5efReZOUiUKOGJ+m1wBYJ1zwAx8qcwCnrtXlY/DlzO6S
          1/Y9+sxZXuy7CSM3OWl7S83IMOvfCY6Cp+ZLSJLVQpLZIDpDMDVKm/Gl9Rs/jhQI
          r7I0iSFmqbbzhVX9F0gGdM5rUgJzDCUanQaulTF+i5hJgXbmdLWu/Gtaz9rMlPQd
          hUJXCc5/9IZgw5KYEryL/GewMuHYeh3nUOI1ywIDAQABAoIBAH2CMazw/p1ymNAn
          WGhhWkLETp4DVHeVgBIxOuvlfwiF/y9UvDpxd1pB6b+iZL9iEBSnd/cgMu4FX5t4
          5xLN451VH8waCWoDnzbEzXJ2IG2u/KXkrcJkTqEoDazdB77UAiROOG8fk3KosQg0
          wr1KwZqJ89poPLb45+JdJFDpsmD4gPtURwBV7osJRcXZrbQ/+7UmyEoNGVB76PCP
          /yOxG3LgjC/CKzFqES2q3rfyV+v0o2W1LYgCE0OONIWfpXrRYz/AZoavszef28Fl
          +LgCyP8iLVAnsT2rg/Onw2oVZ9lkpdEo8v1Ym/EZhHx4Hyl/mrwmnx/9MW7e3yGy
          HxsjiYECgYEA2lZp6005C737plID/2xVpYKRC/sYZJm8ehV8KzTWm+ZxmDPwtLz3
          noePKnc8Glf+MX3N+5IBC2S6tj5+/LcT2zcCvDVks3iKiPAKHBN9cpx/ksS2ixTR
          Sp+mMcFbyxDXu5LQT/C7+qI25yjpPTh4aBL+JWt2UgC7NLWEhoItk80CgYEAz+xg
          ygtUeJzC1LMxY6u9UjGT1b75MJAXf+gDPixqNCyMzP6otGVDKKJQC/53d31A/8oF
          1azWt4yYLzSfTzsaI+aby6pn5bp0t4DaeY8fyny9VQZvSolz4iDwdGPPQ4tfQzj8
          IW+5tDdCLH+waeogbxK43QlpuLtJ+SgzpRVWB/cCgYAtRnoUVyEbNDw40w0NLFPe
          TGLzjxAR3GdfEZF8DCrsjS7FFxA1CnJ2pzmi3rLR66lEbggGwNICoNKu8+q1UOmH
          LbMdgBzvsnFX0B7oj4oV+CnkL3KDCMAVr2FxM91rEIUL2nfj+9GfOYAVE0C6dzlQ
          q4+UBuK0Qn6PgYyHr/rviQKBgHqSFDTHHRLFBq2wvQrOsRqFE2tL20ZfixrhwRej
          wy/im1Y1QWqmz0Ji/OE1L2QHOIwRogLmkuU9QnGBifCBHNXRGkKjv//TPP74PNKw
          JsONaWd4FZ9RDDlfxaA3PnXI8W2FaEylukmc0au90ld9p4US+luDMwmtjtwMcPV+
          cGrdAoGAbDUnt4tITZ/sGSiKY0znTXBTgfQuVi7rk3uIeau7uxAaOny006eHyecx
          rfslBuyXgqLKB9/rbfA9Vy02hQwc+0xRkQtpaDGIOugSST7ZrLfX8MhFPS/wFDqV
          KCaxWx68GyDxcw8j7w5J2etgl+RSH3uuBDwFszz1yVkwfECVMUk=
          -----END RSA PRIVATE KEY-----
          DOC
      }
      let(:key_path) { File.join(@current_dir, "account_key.pem") }

      specify "validate" do
        Timecop.freeze Time.parse("2015-12-05 15:45 CET") do
          File.write(key_path, account_key)
          VCR.use_cassette "authorize/stw" do
            webroot_path = File.join(@current_dir, 'webroot')
            Dir.mkdir(webroot_path)

            stdout = capture(:stdout) {
              app.invoke "authorize", ["stefanwienert.de"],
              color: false,
              test: true,
              account_key: key_path,
              webroot_path: webroot_path
            }
            expect(stdout).to include "Authorization successful for stefanwienert.de"
            # deletes file if successful
            expect(Dir["#{webroot_path}/*"].length).to be == 0
          end
        end
      end

      specify "create csr + certificate" do
        Timecop.freeze Time.parse("2015-12-05 16:00 CET") do
          File.write(key_path, account_key)
          private_key_path = File.join(@current_dir, "key.pem")
          # We need to fixate private key to verify the generated certificates match
          File.write private_key_path, <<-DOC.strip_heredoc
						-----BEGIN RSA PRIVATE KEY-----
						MIIEpAIBAAKCAQEAzPB6oj/SvD5OvlfNEjI72+Dk3Z96zTR8nEwucDa4nPCdmUq5
						s8/his/EV2hvQ51NYEFDl66gwp/XedVwy20ZJwUtOTxTxoQ+D3kO5h4aQywXnyv1
						h/vi4pFEF1G5OAQaRvoax3B4T5Ta9rJnriTWXDZgvSbJV0MPgazuuQF7risPNJYH
						jHyRCbFO6JOTIB8IgeaLZbWoVW907e6cpAS1wa0Q6C1xxZDHXRBQN31e+dNJkyyJ
						u+Rh56AXm7/+q+RySa2E1So4VaYO0QWK0Ux1x8vN+nS8wyOP4VndXH6++fvSRx4V
						mzLv6Iq87aSS8rg3YYGpFQwyD4EXWSRVlz86qQIDAQABAoIBABKmX8KcJEVVNj1E
						KDlbsO7VjH5OoRJDkIN4u1Ei6bH+g5kLn9KpPFExjyCVNGrmyb/UsJ4BGkgb27QO
						pHEewIc4hWEMCGOsbSljTuPKIYGzZYLqsTFqzr7nkVa97SkX1nxXDlDP/2LenP6O
						RbknSQqjODJ+cRwr0iFu51qWs/apcrEOJgT/jenFaUKOqu9JbfMJ+PIEqqPLm5Ia
						WgieJcqJ41Qgvcwun37FxygdYFpcrev8er/9kvYtGvsR0caX1Pji4ycdZP9F8Apm
						yhMlXd1gIJadeYv6Mtoa7g1hvQcAtltTgzXH7ctBguf3zGSDHqauvp4c/ZBAnUfJ
						TkaJNAECgYEA9g5ZGsT23Y+6a4Fg3eYJ3KEDUog6uWrPPQvAy/X8SsdFbisFJ1/X
						0lsCo9DS9CskbySRUVw3Nx6FOMOBAOlWmgFDuOxzKgtM3lMRQ0HykvQblkhTH/Nq
						yqiV9awPsmG228S+3SESRcN2UfzcUmMZYiMPXsOftNs5WSnoYikfjMkCgYEA1Ti+
						xHednRlT/VSobYufgYj7bptOx2gKLrXMdQm2ElplqrjcqU5aiaM427VHq+RFwzly
						7PqIeA9TexTSGWKtoJ9MQ1L4z5eoXwHeHDWT4E4xw67HzuJymL09HcKkg+RtmMLZ
						iBbAiFsFuw86akUf/CRJ4r9/j7GyePk12l6FjuECgYEAjvdRQKOXCK9dUt+up9/k
						dQQ9CPRMorVzynWMxTWdLNnR9qwaZ4FhxkDJLOPF3sc+eTGXGd3p2yXppEy8JQpv
						HjaD4evJEnHUbQ1450pnJomdidlmKxdlQnFoCIG78Rqjg9gySgvQMSbcFdFFNr2L
						3yCd6qLhpdUG4k7eTkK0qTkCgYEApEEAhGz5GCqIzyDGVw02JR2XQ4+U0nxNS8p0
						5LxEbEMDCs85/ZsEl/8LMAWoXryNGWVKKVCejI6R6sERUMj5pEDTCRID5jeYVwgj
						SGvlrOfP4kTkW3WKfitZx3FINupjm0iPNwz/6IrmEUIb5/20NBLocCrBY7qqGBMy
						7zPdg0ECgYBFxm3QfgG21SXMcI7Y9I+p6/LnDgtlk7vwrMAtH7HsKA1WE0MVlPtM
						tyM4bLlbNGUdAaS8c20aayT89JZQD8xYWrR2toxf1aWP+a1LCB7sf6CWEzJAFBRz
						tI3N7MDYHnZFmkayHI3/UrGBTlGSpl21LQJ578Ig66TiOSsEVcUPZQ==
						-----END RSA PRIVATE KEY-----
          DOC
          VCR.use_cassette "certificate/stw" do
            cert_path = File.join(@current_dir, "cert.pem")
            fullchain_path = File.join(@current_dir, "fullchain.pem")
            chain_path = File.join(@current_dir, "chain.pem")
            stdout = capture(:stdout) {
            app.invoke "cert", ["stefanwienert.de"],
              color: false,
              test: true,
              certificate_path: cert_path,
              private_key_path: private_key_path,
              fullchain_path: fullchain_path,
              chain_path: chain_path,
              account_key: key_path
            }
            [ cert_path, private_key_path, fullchain_path, chain_path].each {|path|
              expect(File.exists?(path)).to be == true
            }
            expect(stdout).to include "Certificate valid until"

            cert = OpenSSL::X509::Certificate.new File.read fullchain_path
            key = OpenSSL::PKey::RSA.new File.read private_key_path
            cert.verify(key)
          end
        end
      end
    end

    specify "cert still valid" do
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
        out = capture(:stdout) do
          expect {
            app.invoke("cert", ['example.com'], certificate_path: cert_path, color: false, test: true)
          }.to raise_error(SystemExit)
        end
        expect(out).to include 'still valid till 2016-03-03'
      end
    end
  end

end
