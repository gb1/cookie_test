defmodule CookiesTestWeb.PageController do
  use CookiesTestWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
