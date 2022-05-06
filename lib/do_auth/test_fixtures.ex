defmodule DoAuth.TestFixtures do
  @moduledoc """
  Fixtures for Megalith tests
  """

  alias Uptight.Binary
  alias Uptight.Text, as: T

  # credo:disable-for-this-file

  def crypto do
    quote do
      import Witchcraft.Functor

      def very_weak_params_fixture() do
        %{mem: 100_000, ops: 1, salt_size: 16}
      end

      def password_fixture() do
        "hello🏯wōrld👹" |> T.new!()
      end

      def slip_fixture() do
        %{
          mem: 100_000,
          ops: 1,
          salt:
            <<97, 86, 168, 171, 251, 152, 8, 19, 211, 166, 117, 126, 0, 95, 114, 149>>
            |> Binary.new!()
        }
      end

      def main_key_fixture() do
        {<<12, 104, 113, 58, 16, 120, 235, 132, 112, 134, 139, 233, 218, 113, 105, 86, 88, 92,
           178, 25, 148, 200, 35, 40, 184, 241, 124, 43, 206, 171, 247, 4>>
         |> Binary.new!(), slip_fixture()}
      end

      def signing_key_id_1_fixture() do
        %{
          public:
            <<135, 239, 26, 131, 57, 35, 38, 126, 239, 6, 121, 177, 246, 42, 233, 181, 98, 193,
              100, 126, 8, 206, 121, 105, 146, 12, 220, 59, 116, 84, 7, 188>>,
          secret:
            <<77, 72, 93, 178, 84, 19, 51, 69, 29, 84, 20, 29, 154, 216, 187, 83, 217, 147, 109,
              200, 157, 114, 49, 191, 42, 191, 1, 184, 8, 251, 185, 245, 135, 239, 26, 131, 57,
              35, 38, 126, 239, 6, 121, 177, 246, 42, 233, 181, 98, 193, 100, 126, 8, 206, 121,
              105, 146, 12, 220, 59, 116, 84, 7, 188>>
        }
        |> Witchcraft.Functor.map(&Binary.new!/1)
      end

      def signing_key_fixture(n) do
        {mkey, _} = main_key_fixture()
        mkey |> DoAuth.Crypto.derive_signing_keypair(n)
      end

      def server_keypair_fixture() do
        %{
          public:
            <<196, 32, 166, 36, 137, 39, 40, 96, 191, 83, 23, 16, 117, 237, 48, 216, 144, 130,
              252, 0, 227, 242, 122, 201, 103, 99, 10, 223, 134, 134, 84, 147>>,
          secret:
            <<116, 169, 57, 180, 48, 45, 29, 121, 102, 151, 192, 69, 26, 67, 112, 135, 224, 98,
              132, 127, 118, 144, 51, 242, 29, 201, 119, 209, 92, 199, 70, 61, 196, 32, 166, 36,
              137, 39, 40, 96, 191, 83, 23, 16, 117, 237, 48, 216, 144, 130, 252, 0, 227, 242,
              122, 201, 103, 99, 10, 223, 134, 134, 84, 147>>
        }
        |> Witchcraft.Functor.map(&Binary.new!/1)
      end
    end
  end

  defmacro __using__(fixtures) when is_list(fixtures) do
    Enum.map(fixtures, fn fixture -> apply(__MODULE__, fixture, []) end)
  end
end
