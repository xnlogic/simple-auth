module Concerns
  module SignIn
    protected

    attr_accessor :token, :token_error

    def sign_in(resource_name, user)
      begin
        self.token = user.create_api_token
        session['api_token'] = token['token']
      rescue XN::Error::ApiError => e
        session['api_token'] = nil
        self.token_error = {
          status: (e.status || 400),
          message: "Unable to generate token: #{ e.message }"
        }
      end
      super
    end

    def respond_with_token
      respond_to do |format|
        format.json do
          # Perform additional authentication based on status.
          if token
            render json: token
          elsif token_error
            render json: { error: token_error.message }, status: token_error.status
          else
            respond_with({}, status: :unauthorized)
          end
        end
        yield format
      end
    end
  end
end
