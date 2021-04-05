class CreateCarts < ActiveRecord::Migration[6.1]
  def up
    create_table :carts do |t|
      t.integer :user_id, null: false

      t.timestamps null: false
    end

    add_index(:carts, :user_id)
    add_foreign_key(:carts, :users)
  end

  def down
    drop_table(:carts)
  end
end
