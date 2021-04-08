# frozen_string_literal: true

class User < ApplicationRecord
  has_many :carts
  has_many :orders

  def submit_order(params)
    cart = Cart.find_by(id: params[:cart_id])
    if cart.nil?
      errors.add(:cart, "not found")
      return
    end

    validator = AddressValidator.new(params[:address])
    if validator.invalid?
      errors.add(:address, validator.errors)
      return
    end

    address = Address.create!(validator.attributes)

    if charge(cart.total)
      order = Order.create(
        total: cart.total,
        cart: cart,
        user: self,
        summary: build_order_summary(cart),
        shipping_address: address
      )
      OrderMailer.submitted_successfully(order)
      order
    else
      errors.add(:user, "not enough money")
      nil
    end
  end

  private

  def charge(amount)
    with_lock do
      raise ActiveRecord::Rollback if amount > balance
      update!(balance: balance - amount)
    end
  end

  def build_order_summary(cart)
    lines = cart.line_items.map do |line_item|
      "#{line_item.product.title}: #{line_item.product.unit_price}$ X #{line_item.quantity} = #{line_item.total}"
    end
    lines << "Total: #{cart.total}$"
    lines.join("\n")
  end
end
