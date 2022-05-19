defmodule DoAuth.Regression12Test do
  @moduledoc """
  Here we write a model for testing regression from #12.
  We arguably check the invite logic here in a way that's better than one in invite_test.exs, but we're leaving the latter intact just in case.
  """

  # credo:disable-for-this-file

  alias Uptight.Base, as: B

  use Plug.Test
  use ExUnit.Case, async: false
  use PropCheck
  use PropCheck.StateM.ModelDSL

  use DoAuth.TestFixtures, [:crypto]
  alias DoAuth.{Invite, Crypto}
  alias Uptight.Result

  import DynHacks

  defmodule State do
    @moduledoc """
    State for the statem test model.
    We track fulfilled invites as credentials, track ids of refused ones and track all the generated ones.
    """
    defstruct fulfilled: [],
              refused: [],
              generated: []

    @type t :: %__MODULE__{}
  end

  @min_key_id 2
  @max_key_id 20

  @spec initial_state() :: State.t()
  def initial_state(), do: %State{}

  defcommand :fulfill do
    # @spec impl(pos_integer()) :: Result.t()
    def impl(n) do
      # Fixture?!
      granted = Invite.grant_root_invite() |> Result.from_ok()
      kp1 = signing_key_fixture(n) |> Witchcraft.Functor.map(&B.safe!/1)
      res = Invite.fulfill(kp1[:public], granted)
      res
    end

    # @spec pre(State.t(), list()) :: boolean()
    def pre(_, [1]) do
      false
    end

    def pre(_, _) do
      true
    end

    defp with_result_next(state0, [n], res) do
      fulfilled1 = (Result.is_ok?(res) && [n | state0.fulfilled]) || state0.fulfilled
      refused1 = (Result.is_err?(res) && [n | state0.refused]) || state0.refused
      # This can't really go into post-condition without an extra query to the
      # invite server, so we just make sure that the invariant of always having
      # just one fulfillment holds like this.
      if Result.is_ok?(res) do
        assert [n] = Enum.filter(fulfilled1, &(&1 == n)),
               "There is only one credential generated for PK ##{n}"

        assert Crypto.verify_map(res.ok),
               "Invite server has generated a valid invite for PK ##{n}"

        # This checks for regression!
        assert is_nil(res.ok["validUntil"]), "Invite doesn't expire for PK ##{n}"
      else
        assert [] != Enum.filter(refused1, &(&1 == n))
      end

      %State{fulfilled: fulfilled1, refused: refused1, generated: [n | state0.generated]}
    end

    # @spec next(State.t(), list(), Result.t()) :: State.t()
    def next(state0, [n], %Result.Ok{} = res), do: with_result_next(state0, [n], res)
    def next(state0, [n], %Result.Err{} = res), do: with_result_next(state0, [n], res)
    def next(state0, _, _), do: state0
    # @spec post(State.t(), list(), Result.t()) :: boolean()
    def post(_, _, _) do
      pks = :sys.get_state(Invite)["views"]["public_key"]
      assert @max_key_id - @min_key_id + 1 >= Enum.count(pks)
    end
  end

  def next(state0, _, _) do
    state0
  end

  # Sorry for any()
  @spec command_gen(State.t()) :: any()
  def command_gen(_) do
    frequency([{1, {:fulfill, [PropCheck.BasicTypes.integer(@min_key_id, @max_key_id)]}}])
  end

  # test "granted invitations aren't premium by default" do
  #   granted = Invite.grant_root_invite() |> Result.from_ok()
  # end

  PropCheck.App.start(:f, :m)

  property "Invite server works with sequential fulfillments", [
    {:numtests, 100},
    :noshrink,
    :verbose
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
