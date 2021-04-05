class CreateOrders < ActiveRecord::Migration[6.1]
  def up
    create_table :orders do |t|
      t.integer :shipping_address_id, null: false
      t.integer :user_id, null: false
      t.decimal :total, null: false
      t.integer :cart_id, null: false
      t.text :summary, null: false

      t.timestamps null: false
    end

    add_index(:orders, :shipping_address_id)
    add_index(:orders, :user_id)
    add_index(:orders, :cart_id, unique: true)

    add_foreign_key(:orders, :addresses, column: :shipping_address_id)
    add_foreign_key(:orders, :carts)
    add_foreign_key(:orders, :users)
  end

  def down
    drop_table(:orders)
  end
end
