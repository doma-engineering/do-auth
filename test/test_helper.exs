:erlang.system_flag(:backtrace_depth, 40)
File.rm_rf!(Path.join(["db", "nonode@nohost"]))

Application.put_env(:doma, :crypto,
  secret_key_base:
    "iNK@_+:T\l_M/+SR:v.EFxQX83:;0:'Ml5B$NH'(VZ+o8*y[q(j#9Rw9'B8iXUHxC^XD" |> Uptight.Text.new!()
)

DoAuth.Otp.Application.start()
ExUnit.start()

ExUnit.after_suite(fn _ ->
  File.rm_rf!(Path.join(["db", "nonode@nohost"]))
end)
