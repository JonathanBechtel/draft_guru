defmodule DraftGuru.Accounts.UserRoles do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "user_roles" do
    field :role, :string
    timestamps(utc: :datetime)
  end

  @valid_roles ["admin", "contributer", "user"]

  @doc false
  def changeset(user_role, attrs) do
    user_role
    |> cast(attrs, [:role])
    |> validate_required([:role], message: "must choose a role")
    |> validate_inclusion([:role], @valid_roles, message: "role must be one of admin, contributor, or user")
  end
end
