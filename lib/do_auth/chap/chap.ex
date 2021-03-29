defmodule DoAuth.CHAP.CHAP do
  @moduledoc """
  This CHAP-inspired implementation is made to be compatible with Plug
  pipelines.

  The idea is that you can drop it into your pipeline and it shall create a
  session based on a chain of challenge-response objects that shall be sent
  along with the responses.

  Authenticated mode:

  Client |  ~GET /api,                | Server
         |   X-CHAP: iam:PK~>         |
         |                            | [Find session for PK]
         |  <~200,                    |
         |    Phoenix Session Cookie, |
         |    X-CHAP-CHAL: chal~      |
         |                            |
         | ~PUT /book/nāves%20ēnā,    |
         |   Phoenix Session Cookie,  |
         |   X-CHAP: sig(chal)~>      |
         |                            |
         |  <~OK, X-CHAP: chal1~      |

  Unauthenticated mode simply repeats the X-CHAP header contents.

  Currently only unauthenticated mode is implemented because it protects from
  replay attacks, but not from MITM, but MITM has a really tiny surface in
  the modern TLS-enabled world.
  """

  use Phoenix.Controller, namespace: DoAuth.Web
  import Plug.Conn

  def init(x), do: x
end
