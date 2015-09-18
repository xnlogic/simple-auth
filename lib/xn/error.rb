module XN
  module Error
    class ApiError < StandardError
      attr_reader :status
      def initialize(message, status = nil)
        super message
        @status = status
      end
    end
    class UnauthorizedError < ApiError; end
    class NotFoundError < ApiError; end
    class BadRequestError < ApiError; end
  end
end
