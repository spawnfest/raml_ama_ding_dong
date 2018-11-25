defmodule RAML.Specification do
  use GenServer

  alias Router.Resources

  def init(state) do
    {:ok, state, {:continue, :finish_init}}
  end

  def start_link(opts) do
    path = Keyword.fetch!(opts, :path)

    case GenServer.start_link(__MODULE__, %{path: path, contents: nil}, opts) do
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:ok, pid} -> {:ok, pid}
    end
  end

  def handle_continue(:finish_init, state) do
    contents =
      state.path
      |> RAML.Parser.parse

    {:noreply, %{state | contents: contents}}
  end

  def response_for(path, method, headers) do
    GenServer.call({:global, __MODULE__}, {:response_for, path, method, headers})
  end

  def contents do
    GenServer.call({:global, __MODULE__}, {:contents})
  end

  def handle_call({:contents}, _from, state) do
    {:reply, state.contents, state}
  end

  def handle_call({:response_for, path, method, headers}, _from, state) do
    content_type = headers["content-type"]
    default_content_type = Map.get(state.contents, :media_type, :not_supported)

    response =
      with {:ok, resource} <- Resources.get_resource(state.contents, path),
           {:ok, method} <- Resources.validate_method(resource, method)
      do
        handle_method(method, content_type, default_content_type)
      else
        :not_found -> not_found_response()
        :method_not_allowed -> method_not_allowed_response()
      end

    {:reply, response, state}
  end

  defp handle_method(_method, _content_type, _default_content_type) do
    %{ content_type: "text/plain", status: 200, body: "ok" }
  end

  def not_found_response do
    %{
      content_type: "text/plain",
      status: 404,
      body: "Not Found\n"
    }
  end

  def method_not_allowed_response do
    %{
      content_type: "text/plain",
      status: 405,
      body: "Method Not Allowed\n"
    }
  end
end
