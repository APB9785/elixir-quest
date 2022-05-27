defmodule ElixirQuestWeb.CreateNewPc do
  @moduledoc """
  Modal to insert new PC name.
  """
  use ElixirQuestWeb, :live_component

  alias ElixirQuest.PlayerChars
  alias ElixirQuest.PlayerChars.PlayerChar, as: PC
  alias ElixirQuest.Repo

  def mount(socket) do
    base_attrs = PlayerChars.base_attrs()

    {:ok,
     assign(socket,
       changeset: PlayerChars.change_pc_registration(%PC{}, base_attrs),
       base_attrs: base_attrs
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, account_id: assigns.account_id)}
  end

  def handle_event("validate", %{"player_char" => params}, socket) do
    %{account_id: account_id, base_attrs: base_attrs} = socket.assigns
    attrs = Map.merge(base_attrs, %{name: params["name"], account_id: account_id})

    changeset =
      %PC{}
      |> PlayerChars.change_pc_registration(attrs)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("create_new_pc", %{"player_char" => _params}, socket) do
    case Repo.insert(socket.assigns.changeset) do
      {:ok, _pc} ->
        send(self(), :new_pc_created)
        {:noreply, socket}

      {:error, changeset} ->
        IO.inspect(changeset)
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp name_field do
    [
      "border border-black rounded-xl focus:ring-gray-500 focus:border-gray-900 ",
      "focus:outline-none focus:ring bg-gray-200"
    ]
  end
end
