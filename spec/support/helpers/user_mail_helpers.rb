module UserMailHelpers
  ### helper methods

  def clear_all_emails
    TestEmailRedis::Helpers.clean_emails_all
  end

  def get_last_email(email)
    TestEmailRedis::Helpers.get_last_email_for_user @user_hash[:email]
  end


  def api_mail_get_verification_token_from_email(mail)
    # get link from email
    token = nil
    begin
      html = mail['parts'][0]['body']
      token = (/\/verify\/([a-z\d]+)\s+/.match(html).captures rescue nil)
    rescue => e
    end

    if token.is_a? Array
      token = token[0]
    end

    token
  end



  # get link from email
  def mail_get_resetpwd_token_from_email(mail)
    token = nil
    begin
      html = mail['parts'][0]['body']
      token = (/\/resetpassword\/([a-z\d]+)\s+/.match(html).captures rescue nil)
    rescue => e
    end

    if token.is_a? Array
      token = token[0]
    end

    token
  end
end
