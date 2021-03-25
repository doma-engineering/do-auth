defmodule DoAuth.ZeroVC do
  @moduledoc """
  DoAuth's non-standard minmialistic verifiable credentials implementation.

  It's called "ZeroVC" for three reasons:
   1. For crytpgraphy it uses libsodium. Sodium is found in excessive amounts
      in diet sodas that are marketed as "zero sugar".
   2. This module (and soon, library) is aimed to be as minimal as we
      possible, to an extent it's not standard-compliant. In a way it's not a VC
      implementation, but it's used to implement VC systems.
   3. Following the logic of (2), it's akin to ZeroMQ not being a MQ / AMQP
      implementation, but rather "sockets on steroids". So we give an homage
      to the creation of Peter Hintjens, who shall never be forgotten.
  """
end
