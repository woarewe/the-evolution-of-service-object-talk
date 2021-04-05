class CreateProducts < ActiveRecord::Migration[6.1]
  def up
    create_table :products do |t|
      t.string :title, null: false
      t.decimal :unit_price, null: false
      t.integer :stock_quantity, null: false

      t.timestamps null: false
    end

    add_index(:products, :title, unique: true)
  end

  def down
    drop_table(:products)
  end
end
