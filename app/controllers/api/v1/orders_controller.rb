# frozen_string_literal: true

module API
  module V1
    class OrdersController < ApplicationController
      def create
        result = CreateOrder.call(params.permit!) # or Creator.new.call(params.permit!)
        if result.success?
          render status: :ok, json: result.data
        else
          render status: :unprocessable_entity, json: result.errors
        end
      end
    end
  end
end
