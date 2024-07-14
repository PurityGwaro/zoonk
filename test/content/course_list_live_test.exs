defmodule ZoonkWeb.CourseListLiveTest do
  @moduledoc false
  use ZoonkWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Zoonk.Fixtures.Content
  import Zoonk.Fixtures.Organizations

  alias Zoonk.Accounts

  describe "/courses (non-authenticated users)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn} do
      result = get(conn, ~p"/courses")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "/courses (guest user, school doesn't allow guests)" do
    setup do
      set_school_with_guest_user(%{conn: build_conn()}, %{allow_guests?: false})
    end

    test "redirects to the login page", %{conn: conn} do
      result = get(conn, ~p"/courses")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "/courses (allow guests)" do
    setup do
      set_school(%{conn: build_conn()}, %{allow_guests?: true})
    end

    test "renders the page", %{conn: conn} do
      conn = get(conn, ~p"/courses")
      assert redirected_to(conn) == ~p"/courses"

      {:ok, lv, _html} = live(conn, ~p"/courses")
      assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("courses")|)
      refute has_element?(lv, ~s|a:fl-icontains("update your email address")|)
    end

    test "displays warning after a user completes three lessons", %{conn: conn} do
      conn = get(conn, ~p"/courses")
      token = conn.private[:plug_session]["user_token"]
      user = Accounts.get_user_by_session_token(token)
      generate_user_lesson(user.id, 0, number_of_lessons: 3)

      {:ok, lv, _html} = live(conn, ~p"/courses")
      assert has_element?(lv, ~s|a:fl-icontains("update your email address")|)
    end
  end

  describe "/courses (guest user)" do
    setup :set_school_with_guest_user

    test "displays warning after a user completes three lessons", %{conn: conn, user: user} do
      generate_user_lesson(user.id, 0, number_of_lessons: 3)

      {:ok, lv, _html} = live(conn, ~p"/courses")
      assert has_element?(lv, ~s|a:fl-icontains("update your email address")|)
    end

    test "doesn't display warning after completing only two lessons", %{conn: conn, user: user} do
      generate_user_lesson(user.id, 0, number_of_lessons: 2)

      {:ok, lv, _html} = live(conn, ~p"/courses")
      refute has_element?(lv, ~s|a:fl-icontains("update your email address")|)
    end
  end

  describe "/courses (doesn't allow guests)" do
    setup do
      set_school(%{conn: build_conn()}, %{allow_guests?: false})
    end

    test "redirects to the login page", %{conn: conn} do
      result = get(conn, ~p"/courses")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "/courses (public school, students, approved)" do
    setup :app_setup

    test "lists public courses from the current school", %{conn: conn, school: school} do
      assert_course_list(conn, school)
    end
  end

  describe "/courses (private school, students, approved)" do
    setup do
      app_setup(%{conn: build_conn()}, public_school?: false)
    end

    test "lists public courses from the current school", %{conn: conn, school: school} do
      assert_course_list(conn, school)
    end

    test "doesn't display guest warning for regular users", %{conn: conn, user: user} do
      generate_user_lesson(user.id, 0)
      {:ok, lv, _html} = live(conn, ~p"/courses")
      refute has_element?(lv, ~s|a:fl-icontains("update your email address")|)
    end
  end

  describe "/courses (private school, students, not approved)" do
    setup do
      app_setup(%{conn: build_conn()}, public_school?: false, school_user: :pending)
    end

    test "returns 403", %{conn: conn} do
      assert_error_sent(403, fn -> get(conn, ~p"/courses") end)
    end
  end

  describe "/courses (public, teachers, approved)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :teacher)
    end

    test "lists all courses from the selected school", %{conn: conn, school: school} do
      assert_course_list(conn, school)
    end
  end

  describe "/courses (private, teachers, approved)" do
    setup do
      app_setup(%{conn: build_conn()}, public_school?: false, school_user: :teacher)
    end

    test "lists all courses from the selected school", %{conn: conn, school: school} do
      assert_course_list(conn, school)
    end
  end

  describe "/courses (public, managers, approved)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "lists all courses from the selected school", %{conn: conn, school: school} do
      assert_course_list(conn, school)
    end
  end

  describe "/courses (private, managers)" do
    setup do
      app_setup(%{conn: build_conn()}, public_school?: false, school_user: :manager)
    end

    test "lists all courses from the selected school", %{conn: conn, school: school} do
      assert_course_list(conn, school)
    end
  end

  describe "/courses (main app)" do
    setup do
      app_setup(%{conn: build_conn()})
    end

    test "displays the create school menu", %{conn: conn} do
      assert_create_school_menu(conn)
    end

    test "doesn't display the create school menu for a child school", %{conn: conn, school: school} do
      child_school = school_fixture(%{school_id: school.id})
      host = "#{child_school.slug}.#{school.custom_domain}"
      conn = Map.put(conn, :host, host)
      {:ok, lv, _html} = live(conn, ~p"/courses")
      refute has_element?(lv, ~s|li a:fl-icontains("create school")|)
    end

    test "doesn't display courses from child schools", %{conn: conn, school: school} do
      child_school = school_fixture(%{school_id: school.id})
      course = course_fixture(%{school_id: child_school.id, published?: true})
      {:ok, lv, _html} = live(conn, ~p"/courses")
      refute has_element?(lv, get_course_el(course))
    end
  end

  defp course_el(id, course), do: ~s|#courses-#{id} a[href="/c/#{course.slug}"]|
  defp get_course_el(course), do: course_el("list", course)

  defp assert_course_list(conn, school) do
    assert_public_courses(conn, school)
  end

  defp assert_public_courses(conn, school) do
    # It shouldn't display unpublished courses.
    unpublished_course = course_fixture(%{school_id: school.id, published?: false})

    # It shouldn't display private courses
    private_course = course_fixture(%{school_id: school.id, published?: true, public?: false})

    # It should display published courses from the selected school.
    published_course = course_fixture(%{school_id: school.id, published?: true})

    {:ok, lv, _html} = live(conn, ~p"/courses")

    assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("courses")|)

    refute has_element?(lv, get_course_el(unpublished_course))
    refute has_element?(lv, get_course_el(private_course))
    assert has_element?(lv, get_course_el(published_course))
  end

  defp assert_create_school_menu(conn) do
    {:ok, lv, _html} = live(conn, ~p"/courses")
    assert has_element?(lv, ~s|li a:fl-icontains("create school")|)
  end
end
