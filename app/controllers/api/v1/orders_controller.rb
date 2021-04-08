# frozen_string_literal: true

module API
  module V1
    class OrdersController < ApplicationController
      def create
        @user = User.find_by(auth_token: params[:auth_token])

        if @user.nil?
          render status: :unprocessable_entity, json: { errors: "User not found" }
          return
        end

        @cart = Cart.find_by(id: permitted_params[:cart_id])

        if @cart.nil?
          render status: :unprocessable_entity, json: { errors: "Cart not found" }
          return
        end

        @validator = AddressValidator.new(permitted_params[:address])

        if @validator.invalid?
          render status: :unprocessable_entity, json: { errors: @validator.errors }
          return
        end

        @address = Address.create!(@validator.attributes)

        if charge_user(@cart.total)
          @order = Order.create(
            total: @cart.total,
            cart: @cart,
            user: @user,
            summary: build_order_summary,
            shipping_address: @address
          )
          OrderMailer.submitted_successfully(@order)
          render status: :ok, json: @order.as_json
        else
          render status: :unprocessable_entity, json: { errors: "Not enough money" }
        end
      end

      private

      def permitted_params
        params.permit(
          :cart_id,
          address: %i[country state city zip street street2]
        )
      end

      def charge_user(amount)
        @user.with_lock do
          raise ActiveRecord::Rollback if amount > @user.balance
          @user.update!(balance: @user.balance - amount)
        end
      end

      def build_order_summary
        lines = @cart.line_items.map do |line_item|
          "#{line_item.product.title}: #{line_item.product.unit_price}$ X #{line_item.quantity} = #{line_item.total}"
        end
        lines << "Total: #{@cart.total}$"
        lines.join("\n")
      end
    end
  end
end
