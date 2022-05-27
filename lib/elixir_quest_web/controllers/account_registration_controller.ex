defmodule ElixirQuestWeb.AccountRegistrationController do
  use ElixirQuestWeb, :controller

  alias ElixirQuest.Accounts
  alias ElixirQuest.Accounts.Account
  alias ElixirQuestWeb.AccountAuth

  def new(conn, _params) do
    changeset = Accounts.change_account_registration(%Account{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"account" => account_params}) do
    case Accounts.register_account(account_params) do
      {:ok, account} ->
        {:ok, _} =
          Accounts.deliver_account_confirmation_instructions(
            account,
            &Routes.account_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, "Account created successfully.")
        |> AccountAuth.log_in_account(account)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
