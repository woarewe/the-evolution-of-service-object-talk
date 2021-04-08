# frozen_string_literal: true

class ApplicationService
  class Result
    attr_reader :payload

    def initialize(payload)
      @payload = payload
    end

    def success?
      raise NotImplementedError
    end

    def failure?
      raise NotImplementedError
    end
  end
end
