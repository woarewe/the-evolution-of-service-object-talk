# frozen_string_literal: true

class User < ApplicationRecord
  has_many :carts
  has_many :orders
end
