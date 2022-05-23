defmodule DoAuth.User do
  @moduledoc """
  A corporate-friendly user auth system with E-Mail password reset capability.
  """
  import Algae

  alias Uptight.Text, as: T
  alias Uptight.Base.Urlsafe, as: U

  defdata do
    email :: T.t() | nil \\ nil
    nickname :: T.t() | nil \\ nil
    cred :: U.t() | nil \\ nil
  end
end
