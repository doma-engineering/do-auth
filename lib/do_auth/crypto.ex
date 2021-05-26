defmodule DoAuth.Crypto do
  @moduledoc """
  Wrappers around just enough of enacl to be able to exectute both client and
  server parts of the protocol.
  """

  alias :enacl, as: C

  @typedoc """
  TODO: Ask jlouis666 why don't we have pwhash_limit/0 type exported:
  :0:unknown_type
  Unknown type: :enacl.pwhash_limit/0.
  """
  @type pwhash_limit :: atom()

  @typedoc """
  Derivation limits type. Currently used in default_params function and slip
  type.
  They govern how many instructions and how much memory is allowed to be
  consumed by the system.

  """
  @type limits :: %{ops: pwhash_limit(), mem: pwhash_limit()}

  @typedoc """
  Libsodium-compatible salt size.

  Used in default_params, but NOT used in @type slip!
  If you change this parameter, you MUST change :salt, <<_ :: ...>> section
  of @type slip as well!
  Some additional safety is provided by defining a simple macro @salt_size
  below.
  """
  @type salt_size :: 16
  @salt_size 16
  @type salt :: <<_::128>>

  @typedoc """
  Hash sizes, analogously.
  """
  @type hash_size :: 32
  @hash_size 32
  @type hash :: <<_::256>>

  @typedoc """
  Main key derivation slip.
  Returned by `main_key_init`, and required for `main_key_reproduce`.
  """
  @type slip :: %{ops: pwhash_limit(), mem: pwhash_limit(), salt: salt()}

  @type params :: %{ops: pwhash_limit(), mem: pwhash_limit(), salt_size: salt_size()}

  @doc """
  Currently we use moderate limits, because we want to support small computers.
  TODO:
  Use configurable values here, based on the power of a computer.
  """
  @spec default_params :: params()
  def default_params(), do: %{ops: :moderate, mem: :moderate, salt_size: @salt_size}

  @typedoc """
  This is a keypair, marking explicitly what's private (secret) key and
  what's public key.
  """
  @type keypair :: %{secret: binary(), public: binary()}

  @typedoc """
  Marked private (secret) key.
  """
  @type secret :: %{secret: binary()}

  @typedoc """
  Marked public key.
  """
  @type public :: %{public: binary()}

  @typedoc """
  Detached signature along with the public key needed to validate.
  """
  @type detached_sig :: %{public: binary(), signature: binary()}

  @typedoc """
  Only accept atoms as keys of canonicalisable entities.
  """
  @type canonicalisable_key :: atom()

  @typedoc """
  Only accept atoms, strings and numbers as values of canonocalisable entities.
  """
  @type canonicalisable_value ::
          atom()
          | String.t()
          | number()
          | list(canonicalisable_value())
          | %{canonicalisable_key() => canonicalisable_value()}

  @type canonicalised_value ::
          String.t() | number() | list(list(String.t() | canonicalised_value()))

  @doc """
  Generate slip and main key from password with given parameters.
  This function is used directly for testing and flexibility, but shouldn't be normally used.
  For most purposes, you should use `main_key_init/1`.
  """
  @spec main_key_init(binary() | iolist(), params()) :: {binary, slip()}
  def main_key_init(pass, %{ops: ops, mem: mem, salt_size: salt_size}) do
    salt = C.randombytes(salt_size)
    mkey = C.pwhash(pass, salt, ops, mem)
    slip = %{ops: ops, mem: mem, salt: salt}
    {mkey, slip}
  end

  @doc """
  Generate slip and main key from password.
  """
  @spec main_key_init(binary() | iolist()) :: {binary, slip()}
  def main_key_init(pass) do
    main_key_init(pass, default_params())
  end

  @doc """
  Generate main key from password and a slip.
  """
  @spec main_key_reproduce(binary() | iolist(), slip()) :: binary()
  def main_key_reproduce(pass, %{ops: ops, mem: mem, salt: salt}) do
    C.pwhash(pass, salt, ops, mem)
  end

  @doc """
  Create a signing keypair from main key at index n.
  """
  @spec derive_signing_keypair(binary(), pos_integer) :: %{public: binary, secret: binary}
  def derive_signing_keypair(mkey, n) do
    C.kdf_derive_from_key(mkey, "signsign", n) |> C.sign_seed_keypair()
  end

  @doc """
  Wrapper around detached signatures that creates an object tracking
  corresponding public key.
  """
  @spec sign(binary() | iolist(), keypair()) :: detached_sig()
  def sign(msg, %{secret: sk, public: pk}) do
    %{public: pk, signature: C.sign_detached(msg, sk)}
  end

  @doc """
  Verify a detached signature object.
  """
  @spec verify(binary() | iolist(), detached_sig()) :: boolean
  def verify(msg, %{public: pk, signature: sig}) do
    C.sign_verify_detached(sig, msg, pk)
  end

  @doc """
  Keyed (salted) generic hash of an iolist, represented as a URL-safe Base64 string.
  The key is obtained from the application configuration's paramterer "hash_salt".
  Note: this parameter is expected to be long-lived and secret.
  Note: the hash size is crypto_generic_BYTES, manually written down as
  @hash_size macro in this file.
  """
  @spec salted_hash(binary() | iolist()) :: binary()
  def salted_hash(msg) do
    with key <- Application.get_env(:do_auth, DoAuth.Crypto) |> Keyword.fetch!(:hash_salt) do
      C.generichash(@hash_size, msg, key) |> Base.url_encode64()
    end
  end

  @doc """
  Unkeyed generic hash of an iolist, represented as a URL-safe Base64 string.
  Note: the hash size is crypto_generic_BYTES, manually written down as
  @hash_size macro in this file.
  """
  @spec bland_hash(binary() | iolist()) :: binary()
  def bland_hash(msg) do
    C.generichash(@hash_size, msg) |> Base.url_encode64()
  end

  @doc """
  Convert to URL-safe Base 64.
  """
  @spec show(binary) :: String.t()
  def show(x), do: Base.url_encode64(x)

  @doc """
  Read from URL-safe Base 64.
  """
  @spec read!(String.t()) :: binary()
  def read!(x), do: Base.url_decode64!(x)

  @doc """
    Preventing canonicalization bugs by ordering maps lexicographically into a
    list. NB! This makes it so that list representations of JSON objects are
    also accepted by verifiers, but it's OK, since no data can seemingly be
    falsified like this.

    TODO: Audit this function really well, both here and in JavaScript reference
    implementation, since a bug here can sabotage the security guarantees of the
    cryptographic system.
  """
  @spec canonicalise_term(canonicalisable_value()) :: canonicalised_value()

  def canonicalise_term(v) when is_binary(v) or is_number(v) do
    v
  end

  def canonicalise_term(v) when is_atom(v) do
    Atom.to_string(v)
  end

  def canonicalise_term(tau = %DateTime{}) do
    DateTime.to_iso8601(tau)
  end

  def canonicalise_term(xs = []) do
    Enum.map(xs, fn v -> canonicalise_term(v) end)
  end

  def canonicalise_term(kv = %{}) do
    canonicalise_term_do(Map.keys(kv) |> Enum.sort(), kv, []) |> Enum.reverse()
  end

  def canonicalise_term(xs) when is_tuple(xs) do
    canonicalise_term(Tuple.to_list(xs))
  end

  defp canonicalise_term_do([], _, acc), do: acc

  defp canonicalise_term_do([x | rest], kv, acc) when is_atom(x) or is_binary(x) do
    x_canonicalised =
      if is_atom(x) do
        Atom.to_string(x)
      else
        x
      end

    canonicalise_term_do(rest, kv, [[x_canonicalised, canonicalise_term(kv[x])] | acc])
  end

  @doc """
  Simple way to get the server keypair.

  TODO: audit key management practices in Phoenix and here.
  """
  @spec server_keypair :: keypair()
  def server_keypair() do
    with slip <-
           %{
             mem: :moderate,
             ops: :moderate,
             salt: <<84, 5, 187, 21, 147, 222, 144, 242, 242, 64, 139, 14, 25, 160, 85, 88>>
           } do
      Application.get_env(:do_auth, DoAuth.Web)
      |> Keyword.get(:secret_key_base, "")
      |> main_key_reproduce(slip)
      |> derive_signing_keypair(1)
    end
  end
end
