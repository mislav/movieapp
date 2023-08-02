class SigninMailer < ApplicationMailer
  def signin_link
    mail(to: params[:user_email], subject: 'Sign in link for movi.im')
  end
end
