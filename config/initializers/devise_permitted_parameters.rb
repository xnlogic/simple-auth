module DevisePermittedParameters
  extend ActiveSupport::Concern

  included do
    before_action :configure_permitted_parameters
  end

  protected

  def configure_permitted_parameters
    [:user_name, :name, :phone ].each do |p|
      devise_parameter_sanitizer.for(:sign_up) << p
      devise_parameter_sanitizer.for(:account_update) << p
    end
  end

end

DeviseController.send :include, DevisePermittedParameters
