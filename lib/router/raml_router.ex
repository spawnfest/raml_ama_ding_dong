defmodule RAML.Router do
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, _opts) do
    {headers, status, body} = handle_request(conn |> fetch_query_params)

    conn
    |> merge_resp_headers(headers)
    |> send_resp(status, body)
  end

  defp handle_request(%{path_info: path, method: method, req_headers: req_headers, params: query_params}) do
    method_atom = method |> String.downcase |> String.to_atom
    headers = req_headers |> Enum.into(%{})
    response = RAML.Specification.response_for(path, method_atom, headers, query_params)

    {response.headers, response.status, response.body}
  end
end
