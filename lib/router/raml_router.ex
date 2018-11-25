defmodule RAML.Router do
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, _opts) do
    {content_type, status, body} = handle_request(conn)

    conn
    |> put_resp_content_type(content_type)
    |> send_resp(status, body)
  end

  defp handle_request(%{path_info: path, method: method, req_headers: req_headers}) do
    method_atom = method |> String.downcase |> String.to_atom
    headers = req_headers |> Enum.into(%{})
    response = RAML.Specification.response_for(path, method_atom, headers)

    {response.content_type, response.status, response.body}
  end
end
