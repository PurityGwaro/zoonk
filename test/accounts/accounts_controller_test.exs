defmodule ZoonkWeb.AccountsControllerTest do
  use ZoonkWeb.ConnCase, async: true

  describe "POST /api/users/signup" do
    alias Zoonk.Accounts.User
    alias Zoonk.Repo

    test "registers a user with valid params", %{conn: conn} do
      params = %{
        "username" => "pury",
        "password" => "Password#",
        "email" => "pury@gmail.com"
      }

      assert response =
               conn
               |> post("/api/users/signup", params)
               |> json_response(200)

      assert %{
               "data" => %{
                 "jwt" => _token,
                 "user" => %{
                   "avatar" => nil,
                   "confirmed_at" => nil,
                   "current_password" => nil,
                   "date_of_birth" => nil,
                   "email" => "pury@gmail.com",
                   "first_name" => nil,
                   "guest?" => false,
                   "id" => registered_user_id,
                   "inserted_at" => registered_user_inserted_at,
                   "language" => "en",
                   "last_name" => nil,
                   "sound_effects?" => false,
                   "updated_at" => registered_user_updated_at,
                   "username" => "pury"
                 }
               }
             } = response

      fetched_user = Repo.get_by(User, email: params["email"])

      assert registered_user_id == fetched_user.id

      assert {_ok, converted_inserted_at, _other} = DateTime.from_iso8601(registered_user_inserted_at)
      assert converted_inserted_at == fetched_user.inserted_at

      assert {_ok, converted_updated_at, _other} = DateTime.from_iso8601(registered_user_updated_at)
      assert converted_updated_at == fetched_user.updated_at
    end

    test "returns an error response with invalid params", %{conn: conn} do
      params = %{
        "username" => "pury",
        "password" => "Password",
        "email" => "purygmail.com"
      }

      assert response =
               conn
               |> post("/api/users/signup", params)
               |> json_response(400)

      assert %{
               "errors" => %{
                 "email" => ["must have a domain name", "must have the @ sign and no spaces"],
                 "password" => ["at least one digit or punctuation character"]
               }
             } = response
    end

    test "returns an error response with missing params", %{conn: conn} do
      assert response =
               conn
               |> post("/api/users/signup", %{})
               |> json_response(400)

      assert %{
               "errors" => %{
                 "email" => ["can't be blank"],
                 "password" => ["can't be blank"],
                 "username" => ["can't be blank"]
               }
             } = response
    end
  end
end
