defmodule DoAuth.Regression12Test do
  @moduledoc """
  Here we write a model for testing regression from #12.
  We arguably check the invite logic here in a way that's better than one in invite_test.exs, but we're leaving the latter intact just in case.
  """
  alias Uptight.Base, as: B

  use Plug.Test
  use ExUnit.Case, async: true
  use PropCheck
  use PropCheck.StateM
  use PropCheck.StateM.ModelDSL

  use DoAuth.TestFixtures, [:crypto]
  alias DoAuth.{Crypto, Invite}
  alias Uptight.Result

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

  @spec initial_state() :: State.t()
  def initial_state(), do: %State{}

  defcommand :fulfill do
    @spec impl(pos_integer()) :: Result.t()
    def impl(n) do
      # Fixture?!
      granted = Invite.grant_root_invite() |> Result.from_ok()
      kp1 = signing_key_fixture(n) |> Witchcraft.Functor.map(&B.safe!/1)
      Invite.fulfill(kp1[:public], granted)
    end

    @spec pre(State.t(), list()) :: boolean()
    def pre(_state, [n]) when n > 1 and n < 33, do: true

    @spec next(State.t(), list(), Result.t()) :: State.t()
    def next(state0, [n], res) do
      fulfilled1 = (Result.is_ok?(res) && [res.ok | state0[:fulfilled]]) || state0[:fulfilled]
      refused1 = (Result.is_err?(res) && [n | state0[:refused]]) || state0[:refused]
      %State{fulfilled: fulfilled1, refused: refused1, generated: [n | state0[:generated]]}
    end

    @spec post(State.t(), list(), Result.t()) :: boolean()
    def post(%State{fulfilled: fs}, [n], %Result.Ok{ok: cred}) do
      assert [cred] = Enum.filter(fs, &(&1 == cred)),
             "There is only one credential generated for PK ##{n}"

      # This checks for regression!
      assert nil = cred["validUntil"], "Invite doesn't expire for PK ##{n}"

      true
    end

    def post(%State{refused: rs}, [n], %Result.Err{}) do
      assert [] != Enum.filter(rs, n)
      # IO.inspect(".")

      true
    end
  end

  # Sorry
  @spec command_gen(State.t()) :: any()
  def command_gen(_) do
    frequency([{1, {:fulfill, [pos_integer()]}}])
  end

  # test "granted invitations aren't premium by default" do
  #   granted = Invite.grant_root_invite() |> Result.from_ok()
  # end

  property "sequential demo of propchecking" do
    forall cmds <- commands(__MODULE__) do
      # SETUP!
      :erlang.system_flag(:backtrace_depth, 40)
      File.rm_rf!(Path.join(["db", "nonode@nohost"]))

      Application.put_env(:doma, :crypto,
        secret_key_base:
          "iNK@_+:T\l_M/+SR:v.EFxQX83:;0:'Ml5B$NH'(VZ+o8*y[q(j#9Rw9'B8iXUHxC^XD"
          |> Uptight.Text.new!()
      )

      DoAuth.Otp.Application.start()
      # END OF SETUP!

      {_, _, res} = run_commands(cmds)

      # TEARDOWN!
      DoAuth.Otp.Application.stop()
      File.rm_rf!(Path.join(["db", "nonode@nohost"]))
      # END OF TEARDOWN!

      (res == :ok)
      |> aggregate(command_names(cmds))
      |> when_fail(
        IO.puts("""
        History: #{inspect(history)}
        State: #{inspect(state)}
        Result: #{inspect(result)}
        """)
      )
    end
  end
end
