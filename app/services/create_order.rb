# frozen_string_literal: true

class CreateOrder < ApplicationService
  def self.call(params)
    @params = params
    find_user!
    find_cart!
    validate_address!
    create_address!
    charge_user!
    build_order_summary
    create_order!
    notify_user
    Success.new(@order)
  rescue FailureError => error
    Failure.new(error.data)
  end

  private

  def self.find_user!
    @user = User.find_by(auth_token: @params[:auth_token])
    raise FailureError.new("User not found") if @user.nil?
  end

  def self.find_cart!
    @cart = Cart.find_by(id: @params[:cart_id])
    raise FailureError.new("Cart not found") if @cart.nil?
  end

  def self.validate_address!
    @validator = AddressValidator.new(@params[:address])
    raise FailureError.new(@validator.errors) if @validator.invalid?
  end

  def self.create_address!
    @address = Address.create!(@validator.attributes)
  end

  def self.charge_user!
    @user.with_lock do
      raise FailureError.new("Not enough money") if @cart.total > @user.balance
      @user.update!(balance: @user.balance - @cart.total)
    end
  end

  def self.build_order_summary
    lines = @cart.line_items.map do |line_item|
      "#{line_item.product.title}: #{line_item.product.unit_price}$ X #{line_item.quantity} = #{line_item.total}"
    end
    lines << "Total: #{@cart.total}$"
    @order_summary = lines.join("\n")
  end

  def self.create_order!
    @order = Order.create!(
      total: @cart.total,
      cart: @cart,
      user: @user,
      summary: @order_summary,
      shipping_address: @address
    )
  end

  def self.notify_user
    OrderMailer.submitted_successfully(@order)
  end
end
