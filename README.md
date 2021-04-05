# DoAuth

## Dependencies

 - Ubuntu 20.04 (LTS)
 - Erlang/OTP R22
 - Elixir v1.9.1
 - Make
 - PostgreSQL v12

## Prepare dev env

1. Generate two secrets with `phx.gen.secret`
2. Populate `config/dev.secret.exs` following example in `config/test.non-secret.exs`
3. Run `make dev` to insert pre-commit hooks and other boring things related to
   dev environment set-up, such as initialise a local PgSQL 12 database and add
   a user to it.

## Running in dev env

`mix phx.server`

## Prepare release

We don't know how to work with releases in Elixir yet, but the following two
steps are necessary for sure:

1. Generate two secrets with `phx.gen.secret`
2. Populate `config/prod.secret.exs` following example in `config/test.non-secret.exs`
