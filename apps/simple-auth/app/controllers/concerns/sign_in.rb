module Concerns
  module SignIn

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
  end
end
