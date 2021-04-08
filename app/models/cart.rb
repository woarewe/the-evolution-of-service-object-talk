class Cart < ApplicationRecord
  belongs_to :user

  has_many :line_items

  def total
    @total ||= line_items.sum(&:total)
  end
end
