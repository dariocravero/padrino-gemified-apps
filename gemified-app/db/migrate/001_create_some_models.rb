Sequel.migration do
  up do
    create_table :some_models do
      primary_key :id
      String :property
    end
  end

  down do
    drop_table :some_models
  end
end
