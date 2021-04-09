# frozen_string_literal: true

module API
  module V1
    class OrdersController < ApplicationController
      def create
        result = CreateOrder.call(params: params.permit!)
        if result.success?
          render status: :ok, json: result.success.as_json
        else
          render status: :unprocessable_entity, json: { errors: result.failure }
        end
      end
    end
  end
end
