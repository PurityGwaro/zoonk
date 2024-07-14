defmodule SchoolSeed do
  @moduledoc false

  alias Zoonk.Accounts
  alias Zoonk.Organizations

  @app %{
    name: "Zoonk",
    custom_domain: "zoonk.test",
    email: "noreply@zoonk.org",
    public?: true,
    slug: "zoonk",
    managers: ["einstein"],
    teachers: ["curie"],
    students: ["newton"]
  }

  @schools [
    %{
      name: "Apple",
      custom_domain: "apple.test",
      email: "noreply@example.com",
      public?: true,
      slug: "apple",
      managers: ["lovelace"],
      teachers: ["tesla"],
      students: ["franklin"]
    },
    %{
      name: "Google",
      custom_domain: nil,
      email: "noreply@example.com",
      public?: false,
      slug: "google",
      managers: ["pasteur"],
      teachers: ["davinci"],
      students: ["goodall"]
    }
  ]

  @doc """
  Seeds the database with schools.
  """
  def seed(args \\ %{}) do
    multiple? = Map.get(args, :multiple?, false)
    app = create_app()
    schools = generate_school_attrs(multiple?)
    Enum.each(schools, fn attrs -> create_school(attrs, app, multiple?: multiple?) end)
  end

  defp generate_school_attrs(false), do: @schools
  defp generate_school_attrs(true), do: generate_school_attrs()

  defp generate_school_attrs() do
    random_schools =
      Enum.map(1..30, fn idx ->
        %{
          name: "School #{idx}",
          custom_domain: nil,
          email: "noreply@example.com",
          public?: false,
          slug: "school-#{idx}",
          managers: ["lovelace"],
          teachers: ["tesla"],
          students: ["franklin"]
        }
      end)

    @schools ++ random_schools
  end

  defp create_school(attrs, app, opts) do
    multiple? = Keyword.get(opts, :multiple?, false)
    manager = Accounts.get_user_by_username(Enum.at(attrs.managers, 0))
    attrs = Map.merge(attrs, %{created_by_id: manager.id, school_id: app.id})
    {:ok, school} = Organizations.create_school(attrs)
    create_school_users(school, attrs)
    create_students(school, multiple?)
  end

  defp create_app() do
    manager = Accounts.get_user_by_username(Enum.at(@app.managers, 0))
    attrs = Map.merge(@app, %{created_by_id: manager.id})
    {:ok, school} = Organizations.create_school(attrs)
    create_school_users(school, attrs)
    school
  end

  defp create_school_users(school, attrs) do
    Enum.each(attrs.managers, fn manager -> create_school_user(school, manager, :manager) end)
    Enum.each(attrs.teachers, fn teacher -> create_school_user(school, teacher, :teacher) end)
    Enum.each(attrs.students, fn student -> create_school_user(school, student, :student) end)
  end

  defp create_students(_school, false), do: nil

  defp create_students(school, true) do
    Enum.each(1..200, fn idx -> create_school_user(school, "user_#{idx}", :student) end)
  end

  defp create_school_user(school, username, role) do
    user = Accounts.get_user_by_username(username)
    Organizations.create_school_user(school, user, school_user_attrs(user, role))
  end

  defp school_user_attrs(user, role) do
    %{role: role, approved?: true, approved_by_id: user.id, approved_at: DateTime.utc_now()}
  end
end
