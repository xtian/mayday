alias Mayday.{Repo, Accounts.User}

%{
  first_name: "Owner",
  last_name: "Account",
  email: "owner@example.com",
  password: "passwordpassword",
  role: :owner
}
|> then(&User.registration_changeset(%User{}, &1))
|> Repo.insert!()

%{
  first_name: "Admin",
  last_name: "Account",
  email: "admin@example.com",
  password: "passwordpassword",
  role: :admin
}
|> then(&User.registration_changeset(%User{}, &1))
|> Repo.insert!()

%{
  first_name: "Texter",
  last_name: "Account",
  email: "texter@example.com",
  password: "passwordpassword",
  role: :texter
}
|> then(&User.registration_changeset(%User{}, &1))
|> Repo.insert!()
