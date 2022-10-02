defmodule Front.PageController do
  use Front, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
