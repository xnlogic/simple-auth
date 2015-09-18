class UserMailer < ApplicationMailer
  default from: "no-reply@lightmesh.com"

  def sign_up_confirmation(user, base)
    @user = user
    @base = base
    mail :to => user.email, :subject => "Registration Confirmation"
  end

  def activation_notification(user, base)
    @user = user
    @base = base
    mail :to => user.email, :subject => "Account activated"
  end

  def ldap_account_notification(user, base)
    @user = user
    @base = base
    mail :to => user.email, :subject => "Your LDAP login has been added"
  end

  def sign_up_notification(user, base)
    @user = user
    @base = base
    recipients = User.where(:notify_of_signup => true)
    if recipients.count > 0
      mail :to => recipients.map(&:email).join(", "), :subject => 'New User Signup'
    end
  end
end
