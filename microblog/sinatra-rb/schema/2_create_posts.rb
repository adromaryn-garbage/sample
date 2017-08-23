Sequel.migration do
  up do
    create_table(:posts) do
      primary_key :id
      String :title, null: false
      String :content, null: false, text: true
      Integer :user_id, null: false, index: true
    end
  end

  down do
    drop_table(:posts)
  end
end
