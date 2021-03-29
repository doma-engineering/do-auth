# DoAuth

## Prepare dev env

1. Generate two secrets with `phx.gen.secret`
2. Populate `config/dev.secret.exs` following example in `config/test.non-secret.exs`

## Running in dev env

`mix phx.server`

## Prepare release

We don't know how to work with releases in Elixir yet, but the following two
steps are necessary for sure:

1. Generate two secrets with `phx.gen.secret`
2. Populate `config/prod.secret.exs` following example in `config/test.non-secret.exs`
