# frozen_string_literal: true

class CreateOrder < ApplicationService
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

    user = find_user!(dependencies, params)
    cart = find_cart!(dependencies, params)
    address_attributes = validate_address!(dependencies, params)
    address = create_address!(dependencies, address_attributes)
    charge_user!(user, cart)
    order_summary = build_order_summary(cart)
    order = create_order!(dependencies, user, cart, address, order_summary)
    notify_user(dependencies, order)
    Success.new(order)
  rescue FailureError => error
    Failure.new(error.data)
  end

  private

  def self.find_user!(dependencies, params)
    user = dependencies[:user_model].find_by(auth_token: params[:auth_token])
    raise FailureError.new("User not found") if user.nil?
    user
  end

  def self.find_cart!(dependencies, params)
    cart = dependencies[:cart_model].find_by(id: params[:cart_id])
    raise FailureError.new("Cart not found") if cart.nil?
    cart
  end

  def self.validate_address!(dependencies, params)
    validator = dependencies[:address_validator].new(params[:address])
    raise FailureError.new(validator.errors) if validator.invalid?
    validator.attributes
  end

  def self.create_address!(dependencies, address_params)
    dependencies[:address_model].create!(address_params)
  end

  def self.charge_user!(user, cart)
    user.with_lock do
      raise FailureError.new("Not enough money") if cart.total > user.balance
      user.update!(balance: user.balance - cart.total)
    end
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
