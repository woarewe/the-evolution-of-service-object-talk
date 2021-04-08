class CreateUsers < ActiveRecord::Migration[6.1]
  def up
    create_table :users do |t|
      t.string :username, null: false
      t.string :auth_token, null: false
      t.string :email, null: false
      t.decimal :balance, null: false

      t.timestamps null: false
    end

    add_index(:users, :username, unique: true)
    add_index(:users, :auth_token, unique: true)
    add_index(:users, :email, unique: true)
  end

  def down
    drop_table(:users)
  end
end
