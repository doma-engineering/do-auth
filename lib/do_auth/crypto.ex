defmodule DoAuth.Crypto do
  @moduledoc """
  Wrappers around just enough of enacl to be able to exectute both client and
  server parts of the protocol.
  """

  alias Uptight.Binary
  alias Uptight.Base, as: B
  alias Uptight.Text, as: T
  alias Uptight.Result
  alias :enacl, as: C

  import DynHacks

  import Witchcraft.Functor

  # @typedoc """
  # Catch-all standin while https://github.com/jlouis/enacl/issues/59 gets sorted out.
  # """
  # @type pwhash_limit :: atom()

  @typedoc """
  Enacl iolist.
  """
  @type enacl_iolist ::
          binary
          | maybe_improper_list(
              binary | maybe_improper_list(any, binary | []) | byte,
              binary | []
            )

  @typedoc """
  Enacl text data representation.
  """
  @type enacl_text :: T.t() | enacl_iolist()

  @typedoc """
  Message representation: either enacl text or urlsafe encoding of some binary.
  """
  @type enacl_message :: enacl_text() | B.Urlsafe.t()

  @typedoc """
  Derivation limits type. Currently used in default_params function and slip
  type.
  They govern how many instructions and how much memory is allowed to be
  consumed by the system.
  """
  @type limits :: %{ops: C.pwhash_limit(), mem: C.pwhash_limit()}

  @typedoc """
  Libsodium-compatible salt size.

  Used in default_params, but NOT used in @type slip!
  If you change this parameter, you MUST change :salt, <<_ :: ...>> section
  of @type slip as well!
  Some additional safety is provided by defining a simple macro @salt_size
  below.
  """
  @type salt_size :: pos_integer()
  @salt_size 16
  @type salt :: Binary.t()

  @typedoc """
  Hash sizes, analogously.
  """
  @type hash_size :: pos_integer()
  @hash_size 32
  @type hash :: Binary.t()

  @typedoc """
  Main key derivation slip.
  Returned by `main_key_init`, and required for `main_key_reproduce`.
  """
  @type slip :: %{
          :ops => C.pwhash_limit(),
          :mem => C.pwhash_limit(),
          :salt => salt()
        }

  @type slip_raw :: %{
          :ops => C.pwhash_limit(),
          :mem => C.pwhash_limit(),
          :salt => binary()
        }

  @type params :: %{
          :ops => C.pwhash_limit(),
          :mem => C.pwhash_limit(),
          :salt_size => salt_size()
        }

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
  @type keypair :: %{secret: Binary.t(), public: Binary.t()}

  @typedoc """
  A keypair that maybe has its secret component omitted.
  """
  @type keypair_opt :: %{optional(:secret) => Binary.t(), :public => Binary.t()}

  @typedoc """
  Marked private (secret) key.
  """
  @type secret :: %{secret: Binary.t()}

  @typedoc """
  Marked public key.
  """
  @type public :: %{public: Binary.t()}

  @typedoc """
  Detached signature along with the public key needed to validate.
  """
  @type detached_sig :: %{public: Binary.t(), signature: Binary.t()}

  @typedoc """
  Only accept atoms as keys of canonicalisable entities.
  """
  @type canonicalisable_key :: atom()

  @typedoc """
  Only accept atoms, strings and numbers as values of canonocalisable entities.
  """
  @type canonicalisable_value ::
          atom()
          | B.t()
          | T.t()
          | number()
          | DateTime.t()
          | list(canonicalisable_value())
          | %{canonicalisable_key() => canonicalisable_value()}

  @type canonicalised_value ::
          B.t() | T.t() | number() | list(list(T.t() | canonicalised_value()))

  @doc """
  Generate slip and main key from password with given parameters.
  This function is used directly for testing and flexibility, but shouldn't be normally used.
  For most purposes, you should use `main_key_init/1`.

  NB! I've used autogenerated spec here, because for some reason, after I moved to enacl types, local typedefs for slip and params stopped working. Gah.
  """
  @spec main_key_init(enacl_text(), params()) :: {Binary.t(), slip()}
  def main_key_init(pass, %{ops: ops, mem: mem, salt_size: salt_size}) do
    pass = unwrap_pass(pass)
    salt = C.randombytes(salt_size)
    mkey = C.pwhash(pass, salt, ops, mem)
    slip = %{ops: ops, mem: mem, salt: salt}
    {mkey |> Binary.new!(), slip |> tighten_slip()}
  end

  @spec randombytes_enc(pos_integer()) :: String.t()
  def randombytes_enc(size \\ 32) do
    randombytes(size).encoded
  end

  @spec randombytes_raw(pos_integer()) :: binary()
  def randombytes_raw(size \\ 32) do
    C.randombytes(size)
  end

  @spec randombytes(pos_integer()) :: Uptight.Base.Urlsafe.t()
  def randombytes(size \\ 32) do
    randombytes_raw(size) |> Uptight.Binary.new!() |> Uptight.Base.safe!()
  end

  defp tighten_slip(%{salt: <<raw_salt::binary>>} = x) do
    %{x | salt: raw_salt |> Binary.new!()}
  end

  defp unwrap_pass(%T{} = pass) do
    T.un(pass)
  end

  defp unwrap_pass(pass) when is_list(pass) do
    pass
  end

  @doc """
  Generate slip and main key from password.
  """
  @spec main_key_init(enacl_text()) :: {Binary.t(), slip}
  def main_key_init(pass) do
    main_key_init(pass, default_params())
  end

  @doc """
  Generate main key from password and a slip.
  """
  @spec main_key_reproduce(enacl_text(), slip()) :: Binary.t()
  def main_key_reproduce(%T{} = pass, slip) do
    main_key_reproduce_raw(pass |> unwrap_pass, slip |> unwrap_slip)
  end

  defp unwrap_slip(%{salt: salt} = slip) do
    %{slip | salt: salt |> Binary.un()}
  end

  @spec main_key_reproduce_raw(binary() | enacl_iolist(), slip_raw()) :: Binary.t()
  def main_key_reproduce_raw(pass, %{ops: ops, mem: mem, salt: salt}) do
    C.pwhash(pass, salt, ops, mem) |> Binary.new!()
  end

  @doc """
  Create a signing keypair from main key at index n.
  """
  @spec derive_signing_keypair(Binary.t(), pos_integer) :: keypair()
  def derive_signing_keypair(mkey, n) do
    C.kdf_derive_from_key(mkey |> Binary.un(), "signsign", n)
    |> C.sign_seed_keypair()
    |> map(&Binary.new!/1)
  end

  @spec urlsafe_server_pk() :: B.Urlsafe.t()
  def urlsafe_server_pk() do
    urlsafe_server_keypair()[:public]
  end

  @spec server_pk() :: Binary.t()
  def server_pk() do
    server_keypair()[:public]
  end

  @doc """
  Wrapper around detached signatures that creates an object tracking
  corresponding public key.
  """
  @spec sign(enacl_message(), keypair()) :: detached_sig()
  def sign(msg, kp) do
    sign_raw(msg |> unwrap_message(), kp |> unwrap_keypair())
  end

  defp unwrap_message(%T{} = msg) do
    msg |> T.un()
  end

  defp unwrap_message(%B.Urlsafe{} = msg) do
    msg.encoded
  end

  defp unwrap_message(msg) when is_list(msg) do
    msg
  end

  defp unwrap_message(<<msg::binary>>) do
    msg
  end

  defp unwrap_keypair(%{secret: _, public: _} = kp) do
    kp |> map(&Binary.un/1)
  end

  @spec sign_raw(
          enacl_message,
          %{:public => any, :secret => binary, optional(any) => any}
        ) :: any
  def sign_raw(msg, %{secret: sk, public: pk}) do
    %{public: pk, signature: C.sign_detached(msg, sk)} |> map(&Binary.new!/1)
  end

  @doc """
  Verify a detached signature object.
  """
  @spec verify(enacl_message(), detached_sig()) :: boolean()
  def verify(msg, %{public: pk, signature: sig}) do
    C.sign_verify_detached(sig |> Binary.un(), msg |> unwrap_message(), pk |> Binary.un())
  end

  @spec verify_raw(
          binary
          | maybe_improper_list
          | %{:__struct__ => Uptight.Base.Urlsafe | Uptight.Text, optional(any) => any},
          %{:public => binary, :signature => binary, optional(any) => any}
        ) :: boolean
  @doc """
  Verify a raw detached signature object.
  """
  def verify_raw(msg, %{public: <<pk::binary>>, signature: <<sig::binary>>}) do
    C.sign_verify_detached(sig |> base2raw(), msg |> unwrap_message(), pk |> base2raw())
  end

  @doc """
  Verifies a map that has a proof embedded into it by converting said object into a map, deleting embedding, canonicalising the result and verifying the result against the embedding.
  This function is configurable via options and has the following options:
   * :proof_field - which field carries the embedded proof. Defaults to "proof".
   * ignore: [] - list of fields to ignore. Defaults to ["id"].
   * :signature_field - which field carries the detached signature. Defaults to "signature".
   * :key_extractor - a function that retreives public key needed to verify embedded proof. Defaults to taking 0th element of DID.all_by_string ran against "verificationMethod" field of the proof object.
  As per https://www.w3.org/TR/vc-data-model/, proof object may be a list, this function accounts for it.
  Uses Uptight.Result for returning a value. Exceptions are wrapped in Err and aren't re-raised.
  """
  @spec verify_map(map(), list(), list()) :: Result.t()
  def verify_map(
        %{} = verifiable_map,
        overrides \\ [],
        defaults \\ [
          proof_field: "proof",
          signature_field: "signature",
          key_extractor: fn proof_map ->
            Map.get(proof_map, "verificationMethod")
          end,
          ignore: ["id"]
        ]
      ) do
    Result.new(fn ->
      opts = Keyword.merge(defaults, overrides)

      verifiable_canonical =
        Enum.reduce(
          [opts[:proof_field] | opts[:ignore]],
          verifiable_map,
          fn x, acc ->
            Map.delete(acc, x)
          end
        )
        |> canonicalise_term!()

      proofs =
        case Map.get(verifiable_map, opts[:proof_field]) do
          proofs = [_ | _] -> proofs
          [] -> throw(%{"empty proof list" => verifiable_map})
          proof -> [proof]
        end

      valid_until = Map.get(verifiable_map, "validUntil", Map.get(verifiable_map, "expirationDate"))

      if valid_until do
        t1 = valid_until |> Tau.from_raw_utc_iso8601!()
        :lt = DateTime.compare(Tau.now(), t1)
      end

      true =
        Enum.reduce_while(
          proofs,
          false,
          &verify_step(&1, &2, opts, verifiable_canonical, verifiable_map)
        )
    end)
  end

  defp verify_step(proof_map, _, opts, verifiable_canonical, verifiable_map) do
    extracted = %{
      public: opts[:key_extractor].(proof_map),
      signature: Map.get(proof_map, opts[:signature_field])
    }

    extracted
    |> verify_one_sig(verifiable_canonical, verifiable_map)
  end

  defp verify_one_sig(detached_sig, verifiable_canonical, verifiable_map) do
    if verify_raw(verifiable_canonical |> Jason.encode!(), detached_sig) do
      {:cont, true}
    else
      {:halt,
       %{
         "signature verification failed" => %{
           "verifiable object" => verifiable_map,
           "canonical representation" => verifiable_canonical,
           "detached signature" => detached_sig
         }
       }}
    end
  end

  @doc """
  Keypairs are encoded with `Binary.t()`, but it will change once we move back to the total `Uptight.Base.t()` APIs everywhere!

  Signs a map and embeds detached signature into it.
  This function is configurable via options and has the following options:
   * :proof_field - which field carries the embedded proof. Defaults to "proof".
   * :signature_field - which field of the proof carries the detached signature. Defaults to "signature".
   * :signature - if present, this function won't use :secret from keypair, but instead will add this signature verbatim. No verification shall be conducted in case the signature provided is invalid!
   * :key_field - which field of the proof stores information related to key retrieval. Defaults to "verificationMethod".
   * :key_field_constructor - a function that takes the public key and options and constructs value for :key_field, perhaps stateful. By default it queries for a DID corresponding to the key and returns its string representation.
   * :if_did_missing - if set to :insert, default key constructor will insert a new DID, otherwise will error out. By default set to :fail.
   * ignore: [] - list of fields to omit from building a canonicalised object. Defaults to ["id"].
  """
  @spec sign_map(keypair_opt(), map(), list(), list()) :: Result.t()
  def sign_map(
        kp,
        the_map,
        overrides \\ [],
        defaults \\ sign_map_def_opts()
      ) do
    Result.new(fn ->
      opts = Keyword.merge(defaults, overrides)

      to_prove =
        Enum.reduce(
          opts[:ignore],
          the_map,
          fn x, acc ->
            Map.delete(acc, x)
          end
        )

      canonical_claim = to_prove |> canonicalise_term!()
      %{signature: sig, public: pk} = canonical_claim |> canonical_sign!(kp)
      did = opts[:key_field_constructor].(pk, opts) |> Result.from_ok()
      issuer = did
      # proof_map = Proof.from_signature64!(issuer, sig |> raw2base()) |> Proof.to_map()
      proof_map = sig64_to_proof_map(issuer, sig |> raw2base())
      Map.put(to_prove, opts[:proof_field], proof_map)
    end)
  end

  @doc """
  Keypairs are encoded with `Binary.t()`, but it will change once we move back to the total `Uptight.Base.t()` APIs everywhere!
  """
  @spec sign_map!(keypair_opt(), map(), list(), list()) :: map
  def sign_map!(kp, to_prove, overrides \\ [], defopts \\ sign_map_def_opts()) do
    sign_map(kp, to_prove, overrides, defopts) |> Result.from_ok()
  end

  @spec sign_map_def_opts :: [
          {:key_field_constructor, (any, any -> any)}
          | {:key_field, <<_::144>>}
          | {:proof_field, <<_::40>>}
          | {:signature_field, <<_::72>>},
          ...
        ]
  def sign_map_def_opts() do
    [
      proof_field: "proof",
      signature_field: "signature",
      key_field: "verificationMethod",
      key_field_constructor: fn pk, _opts ->
        Result.new(fwrap(pk |> raw2base()))
      end,
      ignore: ["id"]
    ]
  end

  @doc """
  Keyed (salted) generic hash of an iolist, represented as a URL-safe Base64 string.
  The key is obtained from the application configuration's paramterer "hash_salt".
  Note: this parameter is expected to be long-lived and secret.
  Note: the hash size is crypto_generic_BYTES, manually written down as
  @hash_size macro in this file.
  """
  @spec salted_hash(enacl_text()) :: String.t()
  def salted_hash(msg) do
    with key <- Application.get_env(:doma, :crypto) |> Keyword.fetch!(:hash_salt) |> T.un() do
      C.generichash(@hash_size, msg, key) |> raw2base()
    end
  end

  @doc """
  Unkeyed generic hash of an iolist, represented as a URL-safe Base64 string.
  Note: the hash size is crypto_generic_BYTES, manually written down as
  @hash_size macro in this file.
  """
  @spec bland_hash(enacl_text()) :: String.t()
  def bland_hash(msg) do
    C.generichash(@hash_size, msg) |> raw2base()
  end

  @spec canonicalise_term(canonicalisable_value()) :: Result.t()
  #          {:ok, canonicalised_value()} | {:error, any()}
  def canonicalise_term(x), do: Result.new(fn -> canonicalise_term!(x) end)

  @spec is_canonicalised?(any()) :: boolean()
  def is_canonicalised?(<<_::binary>>), do: true
  def is_canonicalised?(x) when is_number(x), do: true
  def is_canonicalised?([]), do: true
  def is_canonicalised?([x | rest]), do: is_canonicalised?(x) && is_canonicalised?(rest)
  def is_canonicalised?(_), do: false

  @doc """
    Preventing canonicalisation bugs by ordering maps lexicographically into a
    list. NB! This makes it so that list representations of JSON objects are
    also accepted by verifiers, but it's OK, since no data can seemingly be
    falsified like this.

    TODO: Audit this function really well, both here and in JavaScript reference
    implementation, since a bug here can sabotage the security guarantees of the
    cryptographic system.
  """
  @spec canonicalise_term!(canonicalisable_value()) :: canonicalised_value()
  def canonicalise_term!(v) when is_binary(v) or is_number(v) do
    v
  end

  def canonicalise_term!(%T{} = v) do
    T.un(v)
  end

  def canonicalise_term!(%Binary{} = v) do
    B.safe!(v).encoded
  end

  def canonicalise_term!(%B.Urlsafe{encoded: x}) do
    x
  end

  def canonicalise_term!(v) when is_atom(v) do
    Atom.to_string(v)
  end

  def canonicalise_term!(%DateTime{} = tau) do
    DateTime.to_iso8601(tau)
  end

  def canonicalise_term!(xs) when is_list(xs) do
    Enum.map(xs, fn v -> canonicalise_term!(v) end)
  end

  def canonicalise_term!(%{} = kv) do
    canonicalise_term_do(Map.keys(kv) |> Enum.sort(), kv, []) |> Enum.reverse()
  end

  def canonicalise_term!(xs) when is_tuple(xs) do
    canonicalise_term!(Tuple.to_list(xs))
  end

  defp canonicalise_term_do([], _, acc), do: acc

  defp canonicalise_term_do([x | rest], kv, acc) when is_atom(x) or is_binary(x) do
    x_canonicalised =
      if is_atom(x) do
        Atom.to_string(x)
      else
        x
      end

    canonicalise_term_do(rest, kv, [[x_canonicalised, canonicalise_term!(kv[x])] | acc])
  end

  @spec binary_server_keypair :: %{secret: Binary.t(), public: Binary.t()}
  def binary_server_keypair() do
    server_keypair()
  end

  @spec urlsafe_server_keypair :: %{secret: B.Urlsafe.t(), public: B.Urlsafe.t()}
  def urlsafe_server_keypair() do
    server_keypair() |> map(&B.safe!/1)
  end

  @doc """
  Simple way to get the server keypair.

  TODO: Move to Urlsafe by default API everywhere.
  """
  @spec server_keypair :: keypair()
  def server_keypair() do
    # This is kind of a fixture, embedded into the source code.
    cenv = fn -> Application.get_env(:doma, :crypto) end

    kp_maybe = cenv.() |> Keyword.get(:server_keypair, {})

    # TODO: Check for entropy, and if entropy is insufficient, crash.
    # Insufficient entropy could be a signal of misuse of the config.
    if kp_maybe == {} do
      with slip <-
             %{
               mem: :moderate,
               ops: :moderate,
               salt:
                 <<84, 5, 187, 21, 147, 222, 144, 242, 242, 64, 139, 14, 25, 160, 85, 88>>
                 |> Binary.new!()
             } do
        kp =
          cenv.()
          |> Keyword.get(
            :secret_key_base,
            Keyword.fetch(cenv.(), :text__secret_key_base) |> t_new_maybe()
          )
          |> main_key_reproduce(slip)
          |> derive_signing_keypair(1)

        Application.put_env(:doma, :crypto, cenv.() |> Keyword.put_new(:server_keypair, kp))

        kp
      end
    else
      kp_maybe
    end
  end

  @spec t_new_maybe(:error | binary) :: :error | T.t()
  defp t_new_maybe(:error), do: :error
  defp t_new_maybe({:ok, <<x::binary>>}), do: T.new!(x)

  @doc """
  DON'T USE THIS FUNCTION, IT'S EXPORTED JUST FOR BETTER TYPECHEKING!
  """
  @spec server_keypair64 :: keypair()
  def server_keypair64() do
    server_keypair() |> map(&raw2base/1)
  end

  @spec base2raw(binary | T.t() | B.Urlsafe.t()) :: binary()
  def base2raw(<<x::binary>>) do
    B.mk_url!(x).raw
  end

  def base2raw(%T{text: x}) do
    base2raw(x)
  end

  def base2raw(%B.Urlsafe{raw: x}) do
    x
  end

  @doc """
  DON'T USE THIS FUNCTION, IT'S EXPORTED JUST FOR BETTER TYPECHEKING!
  """
  @spec raw2base(binary | Binary.t() | B.Urlsafe.t()) :: binary()
  def raw2base(<<x::binary>>) do
    B.raw_to_urlsafe!(x).encoded
  end

  def raw2base(%Binary{binary: x}) do
    raw2base(x)
  end

  def raw2base(%B.Urlsafe{encoded: x}) do
    x
  end

  @spec canonical_sign!(canonicalised_value, keypair) :: detached_sig()
  def canonical_sign!(canonical_term, kp) do
    canonical_sign(canonical_term, kp) |> Result.from_ok()
  end

  @spec canonical_sign(canonicalised_value(), keypair()) :: Result.t()
  def canonical_sign(canonical_term, kp) do
    Result.new(fn ->
      true = is_canonicalised?(canonical_term)
      Jason.encode!(canonical_term) |> T.new!() |> sign(kp)
    end)
  end

  @doc """
  See #26!
  """
  @spec sig64_to_proof_map(String.t(), String.t(), DateTime.t() | nil) :: map()
  def sig64_to_proof_map(<<issuer::binary>>, <<sig64::binary>>, timestamp \\ nil) do
    timestamp =
      if timestamp |> is_nil do
        Tau.now() |> DateTime.to_string()
      else
        timestamp
      end

    %{
      "verificationMethod" => issuer,
      "signature" => sig64,
      "created" => timestamp,
      "type" => "Libsodium2021",
      "proofPurpose" => "assertionMethod"
    }
  end
end
