defmodule RAML.Specification do
  use GenServer

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

    response =
      state.contents.resources
      |> Enum.find({:err, :notfound}, &(&1.path == path))
      |> build_response(method, content_type)

    {:reply, response, state}
  end

  defp build_response({:err, :notfound}, _, _) do
    %{
      content_type: "text/plain",
      status: 404,
      body: "Not Found"
    }
  end
  defp build_response(%{methods: methods}, method, requested_content_type) do
    methods
    |> Map.fetch(method)
    |> handle_method(requested_content_type)
  end

  defp handle_method(:error, _) do
    %{
      content_type: "text/plain",
      status: 405,
      body: "Method Not Allowed"
    }
  end
  defp handle_method({:ok, method}, requested_content_type) do
    method.responses["200"].body.media_types
    |> Map.fetch(requested_content_type)
    |> handle_content_type(requested_content_type)
  end

  defp handle_content_type(:error, _) do
    %{
      content_type: "text/plain",
      status: 415,
      body: "Unsupported Media Type"
    }
  end
  defp handle_content_type({:ok, content_type}, requested_content_type) do
    %{
      content_type: requested_content_type,
      status: 200,
      body: content_type.example.value || "No Example Provided"
    }
  end
end
