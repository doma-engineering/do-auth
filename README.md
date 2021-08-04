# DoAuth

  * Install project dependencies with `sudo apt install erlang elixir make postgresql libsodium-dev gcc g++ inotify-tools`
  * Install the correct version of `nodejs`:
    * `mkdir -p "${HOME}/.local/bin"
    * `N_PREFIX="${HOME}/.local" npx n install 15.8.0`
    * `echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> ~/.bashrc`
  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:8666`](http://localhost:8666) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

# [The mess we're in](https://www.youtube.com/watch?v=lKXe3HUG2l4)

Given criminal lack of types in Elixir (is Gleam a 1.0 candidate?), we resort to dialyzer for a lot of things. It can't save us from `String.t() ~ binary()` though (infamous `pk` vs `pk64` in our codebase that sometimes causes bugs), and the fact that we're a bit loosey-goosey with the tightness of our map typings doesn't really help. Finally, there is a grand clash between storing structured data in PGSQL and complying with schematic, but still rather dynamic JSON-based [standard](https://www.w3.org/TR/vc-data-model/#base-context).

## Schemas

Schemas map to PgSQL table definitions and often diverge from the standard. Some of these divergences are by design, while some are stemming from incremental implementation route that we took in DoAuth.

### Query builders and runners

### preload and build\_preload

### [Seven deadly `sin`s](https://www.youtube.com/watch?v=A6n-m57dtsA)

We use an anti-pattern called "select or insert" (short: `sin`) for many things. On Sat Jul 24 00:49:37 BST 2021, here's the list of things we have `sin`s implemented for:

```
sweater@conflagrate:~/srht/do-auth$ rg 'def sin_'
lib/do_auth/schema/issuer.ex
14:  def sin_one_did(did) do

lib/do_auth/schema/key.ex
15:  def sin_one_pk64(pk64) do

lib/do_auth/schema/subject.ex
17:  def sin_any_credential_subject(credential_subject) do

lib/do_auth/schema/did.ex
19:  def sin_one_pk(pk) do
34:  def sin_one_pk64(pk64) do
```

The biggest problem of it, is that we don't quite understand the implications of this approach with append-only transaction-heavy postgres.

Also, for naive nickserv implementation, we make a transaction that, for a short period of time when a nickname has to be registered, obtains an exclusive lock on the whole `credentials` table, which is a horrible thing to do.
Absolutely not sure about Postgresql's execution model, so I have no idea if we really need it and how do other services register unique names concurrently.

### misc.location

Particular tediousness is created by "id" fields in JSON, that -- really -- are normally just "locations" of various objects. To address this, we put what will end up to be "id" field in "misc" object of Credentials and then, as we call Credential.to_map, we retrieve it and set "id" to it.

## Maps and strings

Maps are the preferred way of communicaiton between funcitons as it currently stands.
Every schema has a to_map or to_string property, and it's suggested to convert schema to map early.

## JSON

We are living in the world where we need to sign JSON. A data format that is intriniscally unordered.
To cope with this, we define a logical way to canonicalise it, which is -- hopefully -- standard because it's very natural, but we won't vouch for that.
What we do is we transform fields into tuples, mapping over all the fields of JSON objects.
We recursively order these tuples alphanumerically and insert them one by one into a list.
We then transform said list into a minimal (non-pretty-printed) JSON blob.
These blobs are then signed.

As one can imagine, combination of deviations between the standard fields and PgSQL schema together some fields (such as `id` and `proof`) being omitted from the object that is being signed, causes a lot of bugs while developing features.

Currently we strive to implement enough DID/VC protocols to catch them all, validating the core functions such as `Crypto.verify_map` and `Presentation.present_credential_map`.

## Continuations

Please, use result tuples by default, even if your function may return `true` by default. It's useful to then ergonomically embed your functions into continuations, as seen in `DoAuth.NickServ`, for example.

A prime example of not just returning `:ok` is `Crypto.verify_map`.
