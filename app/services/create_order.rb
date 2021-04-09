# frozen_string_literal: true

class CreateOrder < ApplicationService
  extend Dry::Monads[:result]
  class << self
    include Dry::Monads::Do.for(:call)
  end

  DEFAULT_DEPENDENCIES = {
    user_model: User,
    order_model: Order,
    address_validator: AddressValidator,
    address_model: Address,
    order_mailer: OrderMailer,
    cart_model: Cart
  }.freeze

  def self.call(dependencies: {}, params:)
    dependencies = DEFAULT_DEPENDENCIES.merge(dependencies)

    user = yield find_user(dependencies, params)
    cart = yield find_cart(dependencies, params)
    address_attributes = yield validate_address(dependencies, params)
    address = create_address!(dependencies, address_attributes)
    user = yield charge_user(user, cart)
    order_summary = build_order_summary(cart)
    order = create_order!(dependencies, user, cart, address, order_summary)
    notify_user(dependencies, order)
    Success(order)
  end

  private

  def self.find_user(dependencies, params)
    user = dependencies[:user_model].find_by(auth_token: params[:auth_token])
    return Failure("User not found") if user.nil?

    Success(user)
  end

  def self.find_cart(dependencies, params)
    cart = dependencies[:cart_model].find_by(id: params[:cart_id])
    return Failure("Cart not found") if cart.nil?

    Success(cart)
  end

  def self.validate_address(dependencies, params)
    validator = dependencies[:address_validator].new(params[:address])
    return Failure(validator.errors) if validator.invalid?

    Success(validator.attributes)
  end

  def self.create_address!(dependencies, address_params)
    dependencies[:address_model].create!(address_params)
  end

  def self.charge_user(user, cart)
    user.with_lock do
      return Failure("Not enough money") if cart.total > user.balance
      user.update!(balance: user.balance - cart.total)
    end
    Success(user)
  end

  def self.build_order_summary(cart)
    lines = cart.line_items.map do |line_item|
      "#{line_item.product.title}: #{line_item.product.unit_price}$ X #{line_item.quantity} = #{line_item.total}"
    end
    lines << "Total: #{cart.total}$"
    lines.join("\n")
  end

  def self.create_order!(dependencies, user, cart, address, order_summary)
    dependencies[:order_model].create!(
      total: cart.total,
      cart: cart,
      user: user,
      summary: order_summary,
      shipping_address: address
    )
  end

  def self.notify_user(dependencies, order)
    dependencies[:order_mailer].submitted_successfully(order)
  end
end
