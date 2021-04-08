# frozen_string_literal: true

class AddressValidator
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :country, :string
  attribute :state, :string
  attribute :city, :string
  attribute :zip, :string
  attribute :street, :string
  attribute :street2, :string

  validates :country, presence: true
  validates :state, presence: true
  validates :city, presence: true
  validates :zip, presence: true
  validates :street, presence: true
end
