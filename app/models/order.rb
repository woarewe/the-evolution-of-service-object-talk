class Order < ApplicationRecord
  belongs_to :user
  belongs_to :cart
  belongs_to :shipping_address, class_name: "Address"
end
