defmodule CookiesTest.Repo do
  use Ecto.Repo,
    otp_app: :cookies_test,
    adapter: Ecto.Adapters.Postgres
end
