# frozen_string_literal: true

module API
  module V1
    class OrdersController < ApplicationController
      def create
        # business logic here
      end

      private

      def permitted_params
        params.permit(
          :auth_token,
          :cart_id,
          address: %i[country state city zip street street2]
        )
      end
    end
  end
end
