require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class LocalOverride < Authenticatable
      def auth
        if env['Authorization'].blank?
          @auth = nil
        else
          @auth ||= Rack::Auth::Basic::Request.new(env)
        end
      end

      def valid?
        true
      end

      # NB: fail is a method from Warden::Strategies::Base that shadows the Ruby keyword...fail
      def authenticate!
        if params[:user]
          user = User.find_by(email: params[:user][:user_name])
          if user and user.local? and user.valid_password?(params[:user][:password])
            success!(user)
          else
            fail
          end
        elsif auth
          user = User.find_by(email: auth.credentials.first)
          if user and user.local? and user.valid_password?(auth.credentials[1])
            success!(user)
          else
            fail
          end
        else
          fail
        end
      end
    end
  end
end

Warden::Strategies.add(:local_override, Devise::Strategies::LocalOverride)
