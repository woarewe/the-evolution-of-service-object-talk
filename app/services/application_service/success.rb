# frozen_string_literal: true

class ApplicationService
  class Success < Result
    alias_method :data, :payload

    def success?
      true
    end

    def failure?
      false
    end
  end
end
