# frozen_string_literal: true

module API
  module V1
    class OrdersController < ApplicationController
      def create
        dependencies = {
          user_model: User,
          order_model: Order,
          address_validator: AddressValidator,
          address_model: Address,
          order_mailer: OrderMailer,
          cart_model: Cart
        }
        result = CreateOrder.call(dependencies: dependencies, params: params.permit!)
        if result.success?
          render status: :ok, json: result.data
        else
          render status: :unprocessable_entity, json: result.errors
        end
      end
    end
  end
end
