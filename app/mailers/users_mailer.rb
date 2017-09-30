#class UsersMailer < BaseMailer
class UsersMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'users_mailer' # to make sure that your mailer uses the devise views

  default from: Gexcore::Settings.email_from


  # not used
  def confirmation_instructions(record, token, opts={})
    #super
  end

  def gex_config
    Gexcore::Settings
  end

  def verification_email(email, token)
    @user = User.get_by_email email
    @link = Gexcore::VerificationService.get_link_for_user(@user, token)

    mail(
        :to      => @user.email,
        :from    => gex_config.email_from_full,
        :subject => "Verify email"
    ) do |format|
      format.text
      format.html
    end
  end

  def phone_verification_email(email)
    @user = User.get_by_email email
    #@cluster = Cluster.get_by_id @user.main_cluster_id
    @number = @user.phone_number

    mail(
        :to      => @user.email,
        :from    => gex_config.email_from_full,
        :subject => "ClusterGX account: SMS confirmation"
    ) do |format|
      format.text
      format.html
    end
  end

  def registration_email(email)
    @user = User.get_by_email email

    mail(
        :to      => @user.email,
        :from    => gex_config.email_from_full,
        :subject => "ClusterGX account"
    ) do |format|
      format.text
      format.html
    end
  end



  def welcome_email(email)
    @user = User.get_by_email email

    mail(   :to      => @user.email,
            :from    => gex_config.email_from_full,
            :subject => "Welcome"
    ) do |format|
      format.text
      format.html
    end
  end


  def invitation_email(invitation_id)
    # get invitation
    @invitation = Invitation.find(invitation_id)
    @from_user = User.find(@invitation.from_user_id)

    @link = Gexcore::InvitationsService.get_link(@invitation.uid)

    mail(   :to      => @invitation.to_email,
            :from    => gex_config.email_from_full,
            :subject => "Invitation email") do |format|
      format.text
      format.html
    end
  end
  
  def cluster_info_email(cluster_id)
    @cluster = Cluster.find(cluster_id)
    @user = @cluster.primary_admin

    mail(   :to      => @user.email,
            :from    => gex_config.email_from_full,
            :subject => "Cluster info") do |format|
      format.text
      format.html
    end
  end
  
  def share_create_email(user_id, cluster_id)
    @user1 = User.find(user_id)
    @cluster1 = Cluster.find(cluster_id)

    mail(   :to      => @user1.email,
            :from    => gex_config.email_from_full,
            :subject => "Share created") do |format|
      format.text
      format.html
    end
  end

  def share_invitation_email(invitation_id)
    # get invitation share_type
    invitation = Invitation.find(invitation_id)

    @link = Gexcore::InvitationsService.get_link_share(invitation.uid)

    mail(   :to      => invitation.to_email,
            :from    => gex_config.email_from_full,
            :subject => "Share invitation email") do |format|
      format.text
      format.html
    end
  end

  def resetpassword_email(user_id, token)
    user = User.find(user_id)
    #
    @link = Gexcore::UsersService.get_link_resetpassword(user, token)

    mail(   :to      => user.email,
            :from    => gex_config.email_from_full,
            :subject => "Reset password email") do |format|
      format.text
      format.html
    end
  end

end
