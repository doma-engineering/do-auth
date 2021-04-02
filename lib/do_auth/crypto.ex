defmodule DoAuth.Crypto do
  @moduledoc """
  Wrappers around just enough of enacl to be able to exectute both client and
  server parts of the protocol.
  """

  alias :enacl, as: C

  @typedoc """
  Derivation limits type. Currently used in default_params function and slip
  type.
  They govern how many instructions and how much memory is allowed to be
  consumed by the system.
  """
  @type limits :: %{ops: C.pwhash_limit(), mem: C.pwhash_limit()}

  @typedoc """
  Used in default_params, but NOT used in @type slip!
  If you change this parameter, you MUST change :salt, <<_ :: ...>> section
  of @type slip as well!

  Some additional safety is provided by defining a simple macro @salt_size
  below.
  """
  @type salt_size :: 16
  @salt_size 16
  @type salt :: <<_::16>>

  @typedoc """
  Main key derivation slip.
  Returned by `main_key_init`, and required for `main_key_reproduce`.
  """
  @type slip :: %{ops: C.pwhash_limit(), mem: C.pwhash_limit(), salt: salt()}

  @type params :: %{ops: C.pwhash_limit(), mem: C.pwhash_limit(), salt_size: salt_size()}

  @doc """
  Currently we use moderate limits, because we want to support small computers.
  TODO:
  Use configurable values here, based on the power of a computer.
  """
  @spec default_params :: params()
  def default_params(), do: %{ops: :moderate, mem: :moderate, salt_size: @salt_size}

  @doc """
  Generate slip and main key from password with given parameters.
  This function is used directly for testing and flexibility, but shouldn't be normally used.
  For most purposes, you should use `main_key_init/1`.
  """
  @spec main_key_init(iolist(), params()) :: {binary, slip()}
  def main_key_init(pass, %{ops: ops, mem: mem, salt_size: salt_size}) do
    salt = C.randombytes(salt_size)
    mkey = C.pwhash(pass, salt, ops, mem)
    slip = %{ops: ops, mem: mem, salt: salt}
    {mkey, slip}
  end

  @doc """
  Generate slip and main key from password.
  """
  @spec main_key_init(iolist()) :: {binary, slip()}
  def main_key_init(pass) do
    main_key_init(pass, default_params())
  end

  @doc """
  Generate main key from password and a slip.
  """
  @spec main_key_reproduce(iolist(), slip()) :: binary()
  def main_key_reproduce(pass, %{ops: ops, mem: mem, salt: salt}) do
    C.pwhash(pass, salt, ops, mem)
  end
end
