defmodule DoAuth.Crypto do
  @moduledoc """
  This module provides cryptographic functions for DoAuth.
  Normally you would use main_key_init and main_key_reproduce to derive a main key from a password.
  Then you would use main_key to derive a signing key.
  """
  alias Uptight.Text, as: T
  alias Uptight.Base, as: B
  alias Uptight.Binary
  import Uptight.Assertions
  require Uptight.Assertions

  alias :enacl, as: C

  import Witchcraft.Functor

  ########################################
  ####             Types!             ####
  ########################################

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

  If you change this parameter, you MUST change :salt, <<_ :: ...>> section of @type slip as well!

  Some additional safety is provided by defining a simple macro @salt_size below.
  """
  @type salt_size :: pos_integer()
  @salt_size 16

  @typedoc """
  Uptight type for salt.
  """
  @type salt :: Binary.t()

  @typedoc """
  Hash size, analogous to salt size.
  """
  @type hash_size :: pos_integer()
  # @hash_size 32
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

  @typedoc """
  Main key derivation slip, as returned by `main_key_init`.
  The only difference is that :salt is a raw binary, not a Binary.t().
  """
  @type slip_raw :: %{
          :ops => C.pwhash_limit(),
          :mem => C.pwhash_limit(),
          :salt => binary()
        }

  @typedoc """
  Configures the main key derivation slip.
  """
  @type params :: %{
          :ops => C.pwhash_limit(),
          :mem => C.pwhash_limit(),
          :salt_size => salt_size()
        }

  @typedoc """
  A signing keypair that has both secret and public components.
  Each component is tagged with an atom.
  """
  @type keypair :: %{secret: Binary.t() | B.Urlsafe.t(), public: Binary.t() | B.Urlsafe.t()}

  @typedoc """
  A signing keypair that maybe has its secret component omitted.
  """
  @type keypair_opt :: %{optional(:secret) => Binary.t(), :public => Binary.t()}

  @typedoc """
  Secret signing key tagged with an atom.
  """
  @type secret :: %{secret: Binary.t()}

  @typedoc """
  Public signing key tagged with an atom.
  """
  @type public :: %{public: Binary.t()}

  @typedoc """
  Detached signature along with the public key needed to validate.
  """
  @type detached_sig :: %{public: Binary.t(), signature: Binary.t()}

  @typedoc """
  Detached signature along with the public key needed to validate, represented as Urlsafe Base64.
  """
  @type detached_sig_b64 :: %{public: B.Urlsafe.t(), signature: B.Urlsafe.t()}

  ########################################
  ####  Pure cryptographic functions  ####
  ########################################

  @doc """
  Less secure main key derivation function.
  It only uses the password, and uses default parameters.

  # Example

  iex> alias OnTheMap.Crypto, as: OC
  OnTheMap.Crypto
  iex> OC.main_key_less_secure("password" |> Uptight.Text.new!(), OC.test_params_please_ignore())
  %Uptight.Binary{
    binary: <<42, 107, 111, 184, 100, 238, 62, 33, 105, 15, 89, 137, 77, 197, 23, 3, 39, 216,
              154, 2, 128, 191, 162, 36, 170, 202, 74, 121, 34, 245, 148, 208>>
  }
  """
  @spec main_key_less_secure(password :: T.t(), params :: params()) :: Binary.t()
  def main_key_less_secure(
        %T{} = password,
        %{ops: ops, mem: mem, salt_size: salt_size} \\ default_params()
      ) do
    raw_password = T.un(password)

    # If we make salt full of zeros, we become succeptible to ever so unlikely rainbow table attack.
    # Thus we set salt to some fixed cute string that is exactly salt_length bytes long.
    salt = "OnTheMap" |> pad_raw(salt_size)

    C.pwhash(raw_password, salt, ops, mem) |> Binary.new!()
  end

  @doc """
  Generate a signing keypair from a password.

  # Example

  iex> alias Uptight.Text, as: T
  Uptight.Text
  iex> alias OnTheMap.Crypto, as: OC
  OnTheMap.Crypto
  iex> keypair = OC.keypair_from_password("password" |> T.new!(), OC.test_params_please_ignore())
  %{
    public: %Uptight.Binary{
      binary: <<97, 250, 213, 48, 56, 246, 186, 132, 239, 62, 16, 30, 133, 3, 4,
        72, 208, 206, 94, 53, 70, 143, 97, 165, 169, 245, 128, 153, 56, 149, 186,
        234>>
    },
    secret: %Uptight.Binary{
      binary: <<42, 107, 111, 184, 100, 238, 62, 33, 105, 15, 89, 137, 77, 197,
        23, 3, 39, 216, 154, 2, 128, 191, 162, 36, 170, 202, 74, 121, 34, 245,
        148, 208, 97, 250, 213, 48, 56, 246, 186, 132, 239, 62, 16, 30, 133, 3, 4,
        72, 208, 206, 94, 53, 70, 143, 97, 165, 169, 245, 128, 153, 56, 149, 186,
        234>>
    }
  }
  iex> keypair1 = OC.keypair_from_password("not password" |> T.new!(), OC.test_params_please_ignore())
  %{
    public: %Uptight.Binary{
      binary: <<7, 126, 214, 195, 47, 220, 124, 227, 121, 116, 106, 198, 116, 149,
        101, 254, 105, 199, 5, 116, 226, 53, 222, 83, 25, 172, 69, 106, 250, 234,
        218, 206>>
    },
    secret: %Uptight.Binary{
      binary: <<134, 180, 125, 62, 16, 72, 148, 210, 138, 116, 216, 59, 34, 38,
        222, 174, 6, 47, 115, 113, 49, 232, 197, 219, 186, 232, 15, 15, 22, 153,
        32, 245, 7, 126, 214, 195, 47, 220, 124, 227, 121, 116, 106, 198, 116,
        149, 101, 254, 105, 199, 5, 116, 226, 53, 222, 83, 25, 172, 69, 106, 250,
        234, 218, 206>>
    }
  }
  iex> keypair1 == keypair
  false
  """
  @spec keypair_from_password(password :: T.t(), params :: params()) :: {Binary.t(), Binary.t()}
  def keypair_from_password(%T{} = password, params \\ default_params()) do
    main_key = main_key_less_secure(password, params)
    keypair_from_main_key(main_key)
  end

  @doc """
  Get first signing keypair from a main key.
  """
  @spec keypair_from_main_key(main_key :: Binary.t()) :: {Binary.t(), Binary.t()}
  def keypair_from_main_key(main_key) do
    main_key |> Binary.un() |> C.sign_seed_keypair() |> map(&Binary.new!/1)
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

  @doc """
  Generate slip and main key from password with given parameters.
  This function is used directly for testing and flexibility, but shouldn't be normally used.
  For most purposes, you should use `main_key_init/1`.
  """
  @spec main_key_init(password :: T.t(), params :: params()) :: {Binary.t(), slip()}
  def main_key_init(
        %T{} = password,
        %{ops: ops, mem: mem, salt_size: salt_size} \\ default_params()
      ) do
    raw_password = T.un(password)
    salt = C.randombytes(salt_size)
    mkey = C.pwhash(raw_password, salt, ops, mem)
    slip = %{ops: ops, mem: mem, salt: salt}
    {mkey |> Binary.new!(), slip |> tighten_slip()}
  end

  @doc """
  Generate main key from password and a slip.
  """
  @spec main_key_reproduce(password :: T.t(), slip :: slip()) :: Binary.t()
  def main_key_reproduce(%T{} = pass, slip) do
    main_key_reproduce_raw(pass |> T.un(), slip |> unwrap_slip)
  end

  defp unwrap_slip(%{salt: salt} = slip) do
    %{slip | salt: salt |> Binary.un()}
  end

  defp main_key_reproduce_raw(pass, %{ops: ops, mem: mem, salt: salt}) do
    C.pwhash(pass, salt, ops, mem) |> Binary.new!()
  end

  @doc """
  Wrapper around detached signatures that creates an object tracking
  corresponding public key.
  Note that we allow "Uptight iolist" as a message, which is a list of `Uptight.Text` objects.
  """
  @spec sign(T.t() | list(T.t()), keypair()) :: detached_sig()
  def sign(msg, kp) do
    sign_raw(msg |> unwrap_message(), kp |> unwrap_keypair())
  end

  defp unwrap_message(%T{} = msg) do
    msg |> T.un()
  end

  defp unwrap_message(msg) when is_list(msg) do
    msg |> map(&T.un/1)
  end

  defp unwrap_keypair(%{secret: %Binary{}, public: %Binary{}} = kp) do
    kp |> map(&Binary.un/1)
  end

  defp unwrap_keypair(%{secret: %B.Urlsafe{}, public: %B.Urlsafe{}} = kp) do
    kp |> map(fn x -> x.raw end)
  end

  defp sign_raw(msg, %{secret: sk, public: pk}) do
    %{public: pk, signature: C.sign_detached(msg, sk)} |> map(&B.raw_to_urlsafe!/1)
  end

  @doc """
  Verify a detached signature.

  # Example

  iex> import Witchcraft.Functor
  Witchcraft.Functor
  iex> alias Uptight.Text, as: T
  Uptight.Text
  iex> alias OnTheMap.Crypto, as: OC
  OnTheMap.Crypto
  iex> keypair = OC.keypair_from_password("password" |> T.new!(), OC.test_params_please_ignore())
  %{
    public: %Uptight.Binary{
      binary: <<97, 250, 213, 48, 56, 246, 186, 132, 239, 62, 16, 30, 133, 3, 4,
        72, 208, 206, 94, 53, 70, 143, 97, 165, 169, 245, 128, 153, 56, 149, 186,
        234>>
    },
    secret: %Uptight.Binary{
      binary: <<42, 107, 111, 184, 100, 238, 62, 33, 105, 15, 89, 137, 77, 197,
        23, 3, 39, 216, 154, 2, 128, 191, 162, 36, 170, 202, 74, 121, 34, 245,
        148, 208, 97, 250, 213, 48, 56, 246, 186, 132, 239, 62, 16, 30, 133, 3, 4,
        72, 208, 206, 94, 53, 70, 143, 97, 165, 169, 245, 128, 153, 56, 149, 186,
        234>>
    }
  }
  iex> msg = "Hello, world!" |> T.new!()
  %Uptight.Text{
    text: "Hello, world!"
  }
  iex> sig = OC.sign(msg, keypair)
  %{
    public: %Uptight.Base.Urlsafe{
      encoded: "YfrVMDj2uoTvPhAehQMESNDOXjVGj2GlqfWAmTiVuuo=",
      raw: <<97, 250, 213, 48, 56, 246, 186, 132, 239, 62, 16, 30, 133, 3, 4, 72,
        208, 206, 94, 53, 70, 143, 97, 165, 169, 245, 128, 153, 56, 149, 186,
        234>>
    },
    signature: %Uptight.Base.Urlsafe{
      encoded: "qNcrsE3GwZZ_QTomv4Z8JRROOjnbLploBjWtR-GjXaHm7ca5F0qTA5_Sppi7ZxWDV0g4Or4h4LLaOLyM1WPzDw==",
      raw: <<168, 215, 43, 176, 77, 198, 193, 150, 127, 65, 58, 38, 191, 134, 124,
        37, 20, 78, 58, 57, 219, 46, 153, 104, 6, 53, 173, 71, 225, 163, 93, 161,
        230, 237, 198, 185, 23, 74, 147, 3, 159, 210, 166, 152, 187, 103, 21, 131,
        87, 72, 56, 58, 190, 33, 224, 178, 218, 56, 188, 140, 213, 99, 243, 15>>
    }
  }
  iex> OC.verify(["Hello", ", world!"] |> map(&T.new!/1), sig)
  true
  """
  @spec verify(
          T.t() | list(T.t()),
          detached_sig() | detached_sig_b64()
        ) :: boolean()

  def verify(
        msg,
        %{public: %Binary{} = pk, signature: %Binary{} = sig}
      ) do
    C.sign_verify_detached(sig |> Binary.un(), msg |> unwrap_message(), pk |> Binary.un())
  end

  def verify(
        msg,
        %{public: %B.Urlsafe{} = pk, signature: %B.Urlsafe{} = sig}
      ) do
    C.sign_verify_detached(sig.raw, msg |> unwrap_message(), pk.raw)
  end

  @doc """
  Currently we use moderate limits, because we want to support small computers.
  TODO:
  Use configurable values here, based on the power of a computer.
  """
  @spec default_params :: params()
  def default_params(), do: %{ops: :moderate, mem: :moderate, salt_size: @salt_size}

  @doc """
  Parameters, which are used for testing.
  They aren't secure, but they are fast.
  """
  @spec test_params_please_ignore :: params()
  def test_params_please_ignore(), do: %{ops: 1, mem: 8200, salt_size: @salt_size}
  # defp identity_id_query(raw_pk64) do
  # end

  @doc """
  Returns true if the provided public key is valid, false otherwise.
  It also checks if the base64 urlencoding is valid.

  ## Examples

  iex> OnTheMap.Crypto.valid_pk?("a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v=")
  true

  iex> OnTheMap.Crypto.valid_pk?("Wpu60Ur4nxrpKWdBBnxacjKbKAWqRR9TDYZoFJ2a3KI=")
  true

  This one returns false, because the public key is not a valid urlencoded base64 string.
  iex> OnTheMap.Crypto.valid_pk?("/a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v")
  false

  Same for this one. The padding is incorrect here.
  iex> OnTheMap.Crypto.valid_pk?("a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u===")

  This one returns false, because the public key is not 44 characters long.
  iex> OnTheMap.Crypto.valid_pk?("this0string1s0length0is0forty0three0chars==")
  false
  """
  @spec valid_pk?(String.t()) :: boolean
  def valid_pk?(pk) do
    Uptight.Base.mk_url(pk) |> Uptight.Result.is_ok?() &&
      String.length(pk) === 44
  end

  # Very boring stuff

  defp tighten_slip(%{salt: <<raw_salt::binary>>} = x) do
    %{x | salt: raw_salt |> Binary.new!()}
  end

  @doc """
  Function that uses standard Elixir tools to pad a string to a given length.
  If the string is longer than the given length, it is truncated.
  If the string is shorter than the given length, it is padded with spaces.

  Example:
  iex> OnTheMap.Crypto.pad_raw("hello", 10)
  "hello     "
  iex> OnTheMap.Crypto.pad_raw("hello", 3)
  "hel"
  """
  @spec pad_raw(binary, non_neg_integer) :: binary
  def pad_raw(string, length) do
    string
    |> String.pad_trailing(length, " ")
    |> String.slice(0..(length - 1))
  end

  # Explain this function with @doc.
  @doc """
  To generate server keypair, we use two bound functions: cenv and kp_maybe.
  cenv is a function that returns the current environment of :doma application. It's just a thunk.
  kp_maybe is a function that returns the :server_keypair from the environment of :doma application or an empty tuple if it's absent.

  Afterwards, we check if the keypair was absent, and if it was, we generate a new one.

  To do that, we use a slip, which is a map with three keys: :ops, :mem, and :salt. It's a non-secret data that is used to generate a main key
  Then we search for a secret key base in the environment of :doma application. If it's absent, we crash;
  Generate a main key from the secret key base and the slip;
  Derive a signing keypair from the main key;
  Finally, we return the keypair.
  """
  @spec server_keypair :: keypair()
  def server_keypair() do
    # This is kind of a fixture, embedded into the source code.
    cenv = fn ->
      tap(
        Application.get_env(:doma, :crypto),
        fn x ->
          assert !is_nil(x),
                 """
                 You must configure :doma :crypto in your secret configuration
                 to preferrably have a full keypair under :server_keypair
                 or just a password under :secret_key_base.
                 """
        end
      )
    end

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
          |> Keyword.get(:secret_key_base)
          # In case you forgot to use Uptight in your config, we've got you covered.
          |> t_new_maybe()
          |> main_key_reproduce(slip)
          |> derive_signing_keypair(1)

        Application.put_env(:doma, :crypto, cenv.() |> Keyword.put_new(:server_keypair, kp))

        kp
      end
    else
      kp_maybe |> tighten_keypair()
    end
  end

  # Given Text (%T{}), return it.
  # Given string, construct Text.
  # Otherwise, crash.
  # @spec t_new_maybe(T.t() | String.t()) :: T.t()
  defp t_new_maybe(%T{} = t), do: t
  defp t_new_maybe(str), do: T.new!(str)

  # Given a keypair, return it as a map of Binary.
  # Given a map of raw strings, return it as a map of Binary.
  # Otherwise, crash.
  defp tighten_keypair(kp = %{public: %Binary{} = _pk, secret: %Binary{} = _sk}), do: kp
  defp tighten_keypair(kp), do: kp |> map(&Binary.new!/1)
end
