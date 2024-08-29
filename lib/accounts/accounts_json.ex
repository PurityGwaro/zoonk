defmodule ZoonkWeb.AccountsJSON do
  @moduledoc false

  @spec index(map()) :: map()
  def index(%{jwt: jwt, user: user}) do
    user_params =
      user
      |> Map.from_struct()
      |> Map.drop([:__meta__, :hashed_password, :password])

    %{data: %{jwt: jwt, user: user_params}}
  end

  def index(%{errors: errors}) do
    %{errors: errors}
  end
end
