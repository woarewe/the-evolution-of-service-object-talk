class CreateAddresses < ActiveRecord::Migration[6.1]
  def up
    create_table :addresses do |t|
      t.string :country, null: false
      t.string :state, null: false
      t.string :city, null: false
      t.string :street, null: false
      t.string :street2
      t.string :zip, null: false

      t.timestamps null: false
    end
  end

  def down
    drop_table(:addresses)
  end
end
