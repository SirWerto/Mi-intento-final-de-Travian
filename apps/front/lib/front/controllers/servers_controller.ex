defmodule Front.ServersController do
  use Front, :controller

  def index(conn, _params) do
    {:ok, servers} = Satellite.MedusaTable.get_unique_servers()
    render(conn, "index.html", servers: servers)
  end

  def select(conn, params = %{"server_id" => server_id}) do
    s = s_from_url(server_id)
    rows = Satellite.MedusaTable.get_predictions_by_server(s)
    render(conn, "select.html", rows: rows)
  end


  def s_to_url(server_id) do
    String.replace(server_id, "://", "@@")
  end

  defp s_from_url(server_id) do
    String.replace(server_id, "@@", "://")
  end


end
