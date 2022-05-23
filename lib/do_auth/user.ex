defmodule DoAuth.User do
  @moduledoc """
  A corporate-friendly user auth system with E-Mail password reset capability.
  """
  import Algae

  alias Uptight.Text, as: T
  alias Uptight.Base.Urlsafe, as: U

  defdata do
    email :: T.t()
    nickname :: T.t()
    cred :: U.t()
  end
end
