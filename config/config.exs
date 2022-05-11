import Config

config :logger,
  handle_otp_reports: true,
  handle_sasl_reports: true

secret_cfg = "#{Mix.env()}.secret.exs"

if File.exists?("./config/" <> secret_cfg) do
  import_config secret_cfg
end

# config :doma, :crypto, text__secret_key_base: "some very random text, yeah"
