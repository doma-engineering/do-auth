# DoAuth

It's a really cool system. Use it for authentication, because that's how authentication should be. No IDPs, no bullshit. Your users own their identity.

## Mailer

Set up [smtp](https://github.com/fewlinesco/bamboo_smtp#installation). We use `:do_auth` app here, not `:doma` meta-app, so we configure against it. Your strategy will be:

```elixir
config :do_auth, DoAuth.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "smtp.your.mailserver",
  # ...
```

If you ever want to send E-Mail on behalf of DoAuth from your app, you can now use `DoAuth.Mailer.deliver_now!(your_email)`.

In principle, it's possible to increase security by having an operator enter a PIN to decrypt a secret encrypted at rest.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `do_auth` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:do_auth, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/do_auth](https://hexdocs.pm/do_auth).
