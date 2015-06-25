module Concerns
  module SignIn
    protected

    attr_accessor :token, :token_error

    def create_token(user)
      begin
        self.token = user.create_api_token
      rescue XN::Error::ApiError => e
        self.token_error = {
          status: (e.status || 400),
          message: "Unable to generate token: #{ e.message }"
        }
      end
    end

    # Only call this when creating a user management session.
    def sign_in(resource_name, user, *args)
      create_token(user)
      session['api_token'] = token ? token['token'] : nil
      super
    end

    def respond_with_token
      respond_to do |format|
        format.json do
          create_token(resource)
          # Perform additional authentication based on status.
          if token
            render json: token
          elsif token_error
            render json: { error: token_error.message }, status: token_error.status
          else
            respond_with({}, status: :unauthorized)
          end
        end
        format.html do
          sign_in resource_name, resource
          yield
        end
      end
    end
  end
end
