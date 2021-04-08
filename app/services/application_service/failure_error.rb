# frozen_string_literal: true

class ApplicationService
  class FailureError < StandardError
    attr_reader :data

    def initialize(data)
      @data = data
    end
  end
end
