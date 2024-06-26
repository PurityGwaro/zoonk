defmodule ZoonkWeb.Live.Login do
  @moduledoc false
  use ZoonkWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    email_or_username = Phoenix.Flash.get(socket.assigns.flash, :email_or_username)
    form = to_form(%{"email_or_username" => email_or_username}, as: "user")
    socket = socket |> assign(form: form) |> assign(page_title: dgettext("auth", "Sign in"))
    {:ok, socket, temporary_assigns: [form: form]}
  end
end
