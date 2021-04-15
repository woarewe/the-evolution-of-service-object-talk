# frozen_string_literal: true

class CreateOrder < ApplicationService
  extend Dry::Initializer

  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:call)

  option :user_model, default: -> { User }
  option :order_model, default: -> { Order }
  option :address_validator, default: -> { AddressValidator }
  option :order_mailer, default: -> { OrderMailer }
  option :address_model, default: -> { Address }
  option :cart_model, default: -> { Cart }

  def call(params)
    user = yield find_user(params[:auth_token])
    cart = yield find_cart(params[:cart_id])
    address_attributes = yield validate_address(params[:address])
    address = create_address!(address_attributes)
    user = yield charge_user(user, cart)
    order_summary = build_order_summary(cart)
    order = create_order!(user, cart, address, order_summary)
    notify_user(order)
    Success(order)
  end

  private

  def find_user(auth_token)
    user = user_model.find_by(auth_token: auth_token)
    return Failure("User not found") if user.nil?

    Success(user)
  end

  def find_cart(cart_id)
    cart = cart_model.find_by(id: cart_id)
    return Failure("Cart not found") if cart.nil?

    Success(cart)
  end

  def validate_address(address_params)
    validator = address_validator.new(address_params)
    return Failure(validator.errors) if validator.invalid?

    Success(validator.attributes)
  end

  def create_address!(address_params)
    address_model.create!(address_params)
  end

  def charge_user(user, cart)
    user.with_lock do
      return Failure("Not enough money") if cart.total > user.balance
      user.update!(balance: user.balance - cart.total)
    end
    Success(user)
  end

  def build_order_summary(cart)
    lines = cart.line_items.map do |line_item|
      "#{line_item.product.title}: #{line_item.product.unit_price}$ X #{line_item.quantity} = #{line_item.total}"
    end
    lines << "Total: #{cart.total}$"
    lines.join("\n")
  end

  def create_order!(user, cart, address, order_summary)
    order_model.create!(
      total: cart.total,
      cart: cart,
      user: user,
      summary: order_summary,
      shipping_address: address
    )
  end

  def notify_user(order)
    order_mailer.submitted_successfully(order)
  end
end
