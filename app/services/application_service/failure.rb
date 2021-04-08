# frozen_string_literal: true

class ApplicationService
  class Failure < Result
    def errors
      case payload
      when Hash, ActiveModel::Errors then payload
      when String then { error: payload }
      else raise "Unsupported type of payload for failure"
      end
    end

    def success?
      false
    end

    def failure?
      true
    end
  end
end
