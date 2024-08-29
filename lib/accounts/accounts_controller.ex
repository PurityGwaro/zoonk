defmodule ZoonkWeb.AccountsController do
  @moduledoc false
  use ZoonkWeb, :controller

  alias Zoonk.Accounts
  alias Zoonk.Shared.Utilities

  @type conn :: Plug.Conn.t()

  @spec create(conn(), map()) :: conn()
  def create(conn, user_params) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        jwt = Accounts.generate_jwt(user)
        render(conn, :index, %{user: user, jwt: jwt})

      {:error, %Ecto.Changeset{} = changeset} ->
        changeset_errors = Utilities.traverse_errors(changeset)

        conn
        |> put_status(400)
        |> render(:index, errors: changeset_errors)
    end
  end
end
