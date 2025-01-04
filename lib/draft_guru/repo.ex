defmodule DraftGuru.Repo do
  use Ecto.Repo,
    otp_app: :draft_guru,
    adapter: Ecto.Adapters.Postgres
end
