class CreateLineItems < ActiveRecord::Migration[6.1]
  def up
    create_table :line_items do |t|
      t.integer :product_id, null: false
      t.integer :quantity, null: false, default: 1
      t.integer :cart_id, null: false

      t.timestamps null: false
    end

    add_index(:line_items, :product_id)
    add_index(:line_items, :cart_id)
    add_foreign_key(:line_items, :carts)
    add_foreign_key(:line_items, :products)
  end

  def down
    drop_table(:line_items)
  end
end
