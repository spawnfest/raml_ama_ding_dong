defmodule RAML.Router do
  defmacro __using__(_opts) do
    quote do
      import Plug.Conn

      def init(options) do
        options
      end
    end
  end

  defmacro build(paths) do
    Enum.map(paths, fn(path) ->
      quote do
        def call(%{path_info: [unquote(path)]} = conn, _opts) do
          conn
          |> put_resp_content_type("text/plain")
          |> send_resp(200, "Hello world")
        end
      end
    end) ++ [ quote do
      def call(conn, _opts) do
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(404, "Not Found")
      end
    end ]
  end
end
