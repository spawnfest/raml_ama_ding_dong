defmodule RAML.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    path = "test/support/fixtures/hello_world.raml"

    children = [
      Plug.Cowboy.child_spec(scheme: :http, plug: RAML.Router, options: [port: 4001]),
      {RAML.Specification, name: {:global, RAML.Specification}, path: path}
    ]

    opts = [strategy: :one_for_one, name: RAML.Specification]

    Supervisor.start_link(children, opts)
  end
end
