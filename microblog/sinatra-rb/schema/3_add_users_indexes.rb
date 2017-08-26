Sequel.migration do
  up do
    alter_table(:users) do
      add_index :login, unique: true
      add_index :email, unique: true
    end
  end

  down do
  end
end
