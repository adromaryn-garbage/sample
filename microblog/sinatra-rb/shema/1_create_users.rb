Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id
      String :login, null: false
      String :email, null: false
      String :password_digest, null: false
    end
  end

  down do
    drop_table(:users)
  end
end