class SessionsController < ApplicationController
  def new
    redirect_to authorization_uri
  end

  def callback
    # byebug
    # Authorization Response
    code = params[:code]

    # Token Request
    client.authorization_code = code
    access_token = client.access_token! # => OpenIDConnect::AccessToken
    byebug
    
    if access_token
      
      log_in(access_token.to_s)
      redirect_to '/posts'
    else
      redirect_to root_url
    end
  end

  def destroy
    log_out
    redirect_to root_url
  end

  # SAML
  def new_saml
    request = OneLogin::RubySaml::Authrequest.new
    redirect_to(request.create(saml_settings))
  end

  def metadata
    meta = OneLogin::RubySaml::Metadata.new
    render :xml => meta.generate(saml_settings, true)
  end

  def saml_callback
    response = OneLogin::RubySaml::Response.new(
      params[:SAMLResponse],
      :settings => saml_settings
    )
  
    if response.is_valid?
      byebug
      # @user = User.create_or_find_by!(email: response.nameid)
      # sign_in(@user)
      # redirect_to(:logged_in)
    else
      raise response.errors.inspect
    end
  end
end
