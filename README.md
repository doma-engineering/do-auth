# DoAuth

  * Install project dependencies with `sudo apt install erlang elixir make postgresql libsodium-dev gcc g++ inotify-tools`
  * Install the correct version of `nodejs`:
    * `mkdir -p "${HOME}/.local/bin"
    * `N\_PREFIX="${HOME}/.local" npx n install 15.8.0`
    * `echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> ~/.bashrc`
  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
