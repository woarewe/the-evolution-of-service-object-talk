# frozen_string_literal: true

module API
  module V1
    class OrdersController < ApplicationController
      def create
        user = User.find_by(auth_token: params[:auth_token])

        if user.nil?
          render status: :unprocessable_entity, json: { error: "User not found" }
          return
        end

        order = user.submit_order(permitted_params)
        if order
          render status: :ok, json: order.as_json
        else
          render status: :unprocessable_entity, json: { error: "Something went wrong" }
        end
      end

      private

      def permitted_params
        params.permit(
          :cart_id,
          address: %i[country state city zip street street2]
        )
      end
    end
  end
end
