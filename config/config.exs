import Config

config :logger,
  handle_otp_reports: true,
  handle_sasl_reports: true

secret_cfg = "#{Mix.env()}.secret.exs"

if File.exists?("./config/" <> secret_cfg) do
  import_config secret_cfg
end

config :do_auth, DoAuth.Web, port: 8111

### Don't use the following keys in this file, the following lines are just an example for you to make your secret configs!

config :doma, :crypto, text__secret_key_base: "some very random text, yeah", server_keypair: {}

if Mix.env() == :test, do: import_config "test.exs"

# config :do_auth, DoAuth.Mailer,
#   adapter: Bamboo.SMTPAdapter,
#   server: "smtp.domain",
#   hostname: "your.domain",
#   port: 1025,
#   username: "your.name@your.domain", # or {:system, "SMTP_USERNAME"}
#   password: "pa55word", # or {:system, "SMTP_PASSWORD"}
#   tls: :if_available, # can be `:always` or `:never`
#   allowed_tls_versions: [:"tlsv1", :"tlsv1.1", :"tlsv1.2"], # or {:system, "ALLOWED_TLS_VERSIONS"} w/ comma separated values (e.g. "tlsv1.1,tlsv1.2")
#   tls_log_level: :error,
#   tls_verify: :verify_peer, # optional, can be `:verify_peer` or `:verify_none`
#   tls_cacertfile: "/somewhere/on/disk", # optional, path to the ca truststore
#   tls_cacerts: "…", # optional, DER-encoded trusted certificates
#   tls_depth: 3, # optional, tls certificate chain depth
#   tls_verify_fun: {&:ssl_verify_hostname.verify_fun/3, check_hostname: "example.com"}, # optional, tls verification function
#   ssl: false, # can be `true`
#   retries: 1,
#   no_mx_lookups: false, # can be `true`
#   auth: :if_available # can be `:always`. If your smtp relay requires authentication set it to `:always`.
