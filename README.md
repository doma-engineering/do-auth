# DoAuth

## Conventions

- Encoders MUST use urlsafe-base-64 encoding for every binary data type.
- Functions that work with encoded data MUST be postfixed with `64`, for example: `DID.by_pk64`.
- Functions that work with raw binaries SHOULD have the same name, but without postfix: `DID.by_pk`.
- Functions that work with external credentials or data types MUST be postfixed with `_map`, for example: `Credential.verify_map`.
- Functions that work with data, embedded into Ecto SHOULD have the same name, but without postfix: `Credential.verify`.

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
