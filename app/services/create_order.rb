# frozen_string_literal: true

class CreateOrder < ApplicationService
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:call)

  attr_reader :user_model
  attr_reader :order_model
  attr_reader :address_validator
  attr_reader :order_mailer
  attr_reader :address_model
  attr_reader :cart_model

  def initialize(user_model: User, order_model: Order, address_validator: AddressValidator, order_mailer: OrderMailer,
                address_model: Address, cart_model: Cart)
    @user_model = user_model
    @order_model = order_model
    @address_validator = address_validator
    @order_mailer = order_mailer
    @address_model = address_model
    @cart_model = cart_model
  end

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
