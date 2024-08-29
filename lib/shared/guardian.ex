defmodule Zoonk.Shared.Guardian do
  @moduledoc """
  Shared methods for token implementation.
  """

  use Guardian, otp_app: :zoonk

  alias Zoonk.Accounts
  alias Zoonk.Accounts.User

  @spec subject_for_token(map(), map()) :: {:ok, String.t()} | {:error, :reason_for_error}
  def subject_for_token(%{id: id}, _claims) do
    sub = to_string(id)
    {:ok, sub}
  end

  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  @spec resource_from_claims(map()) :: {:ok, User.t()} | {:error, :reason_for_error}
  def resource_from_claims(%{"sub" => id}) do
    user_id = String.to_integer(id)
    resource = Accounts.get_user(user_id)
    {:ok, resource}
  end

  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end
end
