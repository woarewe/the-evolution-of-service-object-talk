class LineItem < ApplicationRecord
  belongs_to :product
  belongs_to :cart

  def total
    @total ||= product.unit_price * quantity
  end
end
