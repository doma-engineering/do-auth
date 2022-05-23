defmodule DoAuth.AmendmentsTest do
  @moduledoc """
  Here we write a model for testing regression from #12.
  We arguably check the invite logic here in a way that's better than one in invite_test.exs, but we're leaving the latter intact just in case.
  """

  # credo:disable-for-this-file

  alias Uptight.Base, as: B

  use Plug.Test
  # We delete the database, hence async: false here
  use ExUnit.Case, async: false
  use PropCheck
  use PropCheck.StateM.ModelDSL

  use DoAuth.TestFixtures, [:crypto]
  import DynHacks

  alias DoAuth.{Invite, Crypto}
  alias Uptight.Result

  alias PropCheck.BasicTypes, as: BT
  alias DoAuth.Credential, as: Cred

  defmodule State do
    @moduledoc """
    State for the statem test model.
    We track a single "mutable" UTF-8 string and assert that amendments with the same key work.
    Moving forward, we should improve this model: rotate keys, for instance, but so far we really need to move fast.
    """
    # Map that tells which cred ID should resolve to which UTF-8 String
    defstruct value: %{}

    @type t :: %__MODULE__{}
  end

  @spec initial_state() :: State.t()
  def initial_state(), do: %State{}

  defcommand :insert do
    # @spec impl(utf8()) :: Result.t()
    def impl(x) do
      # Fixture?!
      skp = Crypto.server_keypair()
      ak = skp.public |> B.binary_to_urlsafe!() |> Map.get(:encoded)
      Cred.transact_cred(skp, %{"gen" => x}, amendingKeys: ak) |> Result.from_ok()
    end

    # @spec pre(State.t(), list()) :: boolean()
    def pre(_, [bs]) do
      String.length(bs) > 15
    end

    # @spec next(State.t(), list(), map()) :: State.t()
    def next(state0, [bs], %{} = res) do
      # IO.inspect(state0)
      # IO.inspect(bs)
      # IO.inspect(res)
      # IO.inspect("*& *  * * * * * * *")

      assert is_nil(Map.get(state0.value, bs)),
             "There is no #{inspect(bs)} in #{inspect(state0)}."

      id_sig = Cred.sig(res).encoded

      assert id_sig == res["id"],
             "Credentials have signature as their IDs. Namely, #{inspect(res)}."

      %State{value: Map.put_new(state0.value, id_sig, bs)}
    end

    def next(state0, _, _), do: state0

    # @spec post(State.t(), list(), Result.t()) :: boolean()
    def post(_, _, _) do
      # pks = :sys.get_state(Invite)["views"]["public_key"]
      assert true
    end
  end

  # Sorry for any()
  @spec command_gen(State.t()) :: any()
  def command_gen(_) do
    frequency([
      {1, {:insert, [BT.utf8(1024)]}}
      # {1, {:amend, [BT.utf8(1024), BT.float(0.0, 1.0)]}}
    ])
  end

  # test "granted invitations aren't premium by default" do
  #   granted = Invite.grant_root_invite() |> Result.from_ok()
  # end

  PropCheck.App.start(:f, :m)

  property "adjustments update most recent payload", [
    {:numtests, 100},
    :noshrink
    # :verbose
  ] do
    File.rm_rf!(Path.join(["db", "nonode@nohost"]))
    PropCheck.App.start(:f, :m)
    DoAuth.Otp.Application.start()
    GenServer.stop(Invite)

    :erlang.system_flag(:backtrace_depth, 40)

    Application.put_env(:doma, :crypto,
      secret_key_base:
        "iNK@_+:T\l_M/+SR:v.EFxQX83:;0:'Ml5B$NH'(VZ+o8*y[q(j#9Rw9'B8iXUHxC^XD"
        |> Uptight.Text.new!()
    )

    imp(
      forall cmds <- commands(__MODULE__) do
        # SETUP!
        PropCheck.App.start(:f, :m)
        # END OF SETUP!

        {history, state, res} = run_commands(__MODULE__, cmds)

        # TEARDOWN!
        # END OF TEARDOWN!

        (res == :ok)
        |> aggregate(command_names(cmds))
        |> when_fail(
          IO.puts("""
          History: #{inspect(history, pretty: true)}
          State: #{inspect(state, pretty: true)}
          Result: #{inspect(res, pretty: true)}
          """)
        )
      end,
      fn _ ->
        File.rm_rf!(Path.join(["db", "nonode@nohost"]))
      end
    )
  end
end
