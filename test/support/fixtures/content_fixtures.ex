defmodule Zoonk.Fixtures.Content do
  @moduledoc """
  This module defines test helpers for creating entities via the `Zoonk.Content` context.
  """

  import Zoonk.Fixtures.Accounts
  import Zoonk.Fixtures.Organizations

  alias Zoonk.Content
  alias Zoonk.Content.Course
  alias Zoonk.Content.CourseUser
  alias Zoonk.Content.Lesson
  alias Zoonk.Content.LessonStep
  alias Zoonk.Content.StepOption
  alias Zoonk.Content.UserLesson
  alias Zoonk.Repo
  alias ZoonkWeb.Plugs.Translate

  @doc """
  Get valid attributes for a course.
  """
  @spec valid_course_attributes(map()) :: map()
  def valid_course_attributes(attrs \\ %{}) do
    school = Map.get(attrs, :school, school_fixture())

    Enum.into(attrs, %{
      description: "random course description",
      public?: true,
      published?: true,
      language: hd(Translate.supported_locales()),
      name: "course title #{System.unique_integer()}",
      school_id: school.id,
      slug: "course-#{System.unique_integer()}"
    })
  end

  @doc """
  Get valid attributes for a lesson.
  """
  @spec valid_lesson_attributes(map()) :: map()
  def valid_lesson_attributes(attrs \\ %{}) do
    course = Map.get(attrs, :course, course_fixture())

    Enum.into(attrs, %{
      course_id: course.id,
      description: "random lesson description",
      name: "lesson title #{System.unique_integer()}",
      order: 1,
      published?: true
    })
  end

  @doc """
  Get valid attributes for a lesson step.
  """
  @spec valid_lesson_step_attributes(map()) :: map()
  def valid_lesson_step_attributes(attrs \\ %{}) do
    lesson = Map.get(attrs, :lesson, lesson_fixture())

    Enum.into(attrs, %{
      content: "random lesson step content",
      lesson_id: lesson.id,
      kind: :quiz,
      order: 1
    })
  end

  @doc """
  Get valid attributes for a step option.
  """
  @spec valid_step_option_attributes(map()) :: map()
  def valid_step_option_attributes(attrs \\ %{}) do
    lesson_step = Map.get(attrs, :lesson_step, lesson_step_fixture())

    Enum.into(attrs, %{
      correct?: false,
      feedback: "random step option feedback",
      lesson_step_id: lesson_step.id,
      title: "title #{System.unique_integer([:positive, :monotonic])}"
    })
  end

  @doc """
  Generate a course.
  """
  @spec course_fixture(map()) :: Course.t()
  def course_fixture(attrs \\ %{}) do
    preload = Map.get(attrs, :preload, [])
    %Course{} |> Content.change_course(valid_course_attributes(attrs)) |> Repo.insert!() |> Repo.preload(preload)
  end

  @doc """
  Generate a course user.
  """
  @spec course_user_fixture(map()) :: CourseUser.t()
  def course_user_fixture(attrs \\ %{}) do
    course = Map.get(attrs, :course, course_fixture())
    user = Map.get(attrs, :user, user_fixture())
    preload = Map.get(attrs, :preload, [])

    course_user_attrs = Enum.into(attrs, %{approved?: true, approved_at: DateTime.utc_now(), approved_by_id: user.id, role: :student})

    {:ok, course_user} = Content.create_course_user(course, user, course_user_attrs)
    Repo.preload(course_user, preload)
  end

  @doc """
  Generate a lesson.
  """
  @spec lesson_fixture(map()) :: Lesson.t()
  def lesson_fixture(attrs \\ %{}) do
    preload = Map.get(attrs, :preload, [])
    %Lesson{} |> Content.change_lesson(valid_lesson_attributes(attrs)) |> Repo.insert!() |> Repo.preload(preload)
  end

  @doc """
  Generate a lesson step.
  """
  @spec lesson_step_fixture(map()) :: LessonStep.t()
  def lesson_step_fixture(attrs \\ %{}) do
    preload = Map.get(attrs, :preload, :options)
    {:ok, lesson_step} = attrs |> valid_lesson_step_attributes() |> Content.create_lesson_step()
    Repo.preload(lesson_step, preload)
  end

  @doc """
  Generate a step option.
  """
  @spec step_option_fixture(map()) :: StepOption.t()
  def step_option_fixture(attrs \\ %{}) do
    preload = Map.get(attrs, :preload, [])
    {:ok, step_option} = attrs |> valid_step_option_attributes() |> Content.create_step_option()
    Repo.preload(step_option, preload)
  end

  @doc """
  Generate multiple user lessons.

  This is useful when testing completed lessons by a user because we need to test
  a user has completed lessons for multiple days.
  """
  @spec generate_user_lesson(integer(), integer(), list()) :: :ok
  def generate_user_lesson(user_id, days, opts \\ []) do
    number_of_lessons = Keyword.get(opts, :number_of_lessons, 3)
    today = DateTime.utc_now()
    days_ago = DateTime.add(today, days, :day)
    course = Keyword.get(opts, :course, course_fixture())
    correct = Keyword.get(opts, :correct, 1)
    total = Keyword.get(opts, :total, 1)
    attrs = %{course: course, published?: true}
    lessons = Keyword.get(opts, :lessons, Enum.map(1..number_of_lessons, fn _idx -> lesson_fixture(attrs) end))

    Enum.each(lessons, fn lesson ->
      Repo.insert!(%UserLesson{attempts: 1, duration: 5, correct: correct, total: total, user_id: user_id, lesson_id: lesson.id, inserted_at: days_ago, updated_at: days_ago})
    end)
  end
end
