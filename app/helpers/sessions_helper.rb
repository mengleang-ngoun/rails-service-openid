module SessionsHelper

  def client
    @client ||= OpenIDConnect::Client.new(
      identifier: ENV['OPENID_CLIENT_ID'],
      secret: ENV['OPENID_CLIENT_SECRET'],
      redirect_uri: ENV['OPENID_REDIRECT_URI'],
      host: ENV['OPENID_OIDC_HOST'],
      authorization_endpoint: ENV['OPENID_AUTH_ENDPOINT'],
      token_endpoint: ENV['OPENID_TOKEN_ENDPOINT'],
      userinfo_endpoint: ENV['OPENID_USER_ENDPOINT']
    )
  end

  def authorization_uri
    session[:state] = SecureRandom.hex(16)
    session[:nonce] = SecureRandom.hex(16)

    client.authorization_uri(
      state: session[:state],
      nonce: session[:nonce]
    )
  end

  def scope
    default_scope = %w(profile name)

    # Add scope for social provider if social login is requested
    if params[:provider].present?
      # default_scope
      default_scope << params[:provider]
    else
      default_scope
    end
  end

  def log_in(access_token)
    # puts "ACCESS_TOKEN: #{access_token}"
    # session[:access_token] = access_token
    # byebug
    user_data = user_info(access_token)
    # byebug
    # preferred_username
    if user_data
      user = User.find_by email: user_data.email
      unless user
        user = User.create(name: user_data.name, email: user_data.email, uid: user_data.sub, username: user_data.preferred_username)
      end

      if user
        session[:user_id] = user.id
      end
    end
  end

  def log_out
    # revoke
    # session.delete(:access_token)
    session.delete(:user_id)
    @current_user = nil
  end

  def user_info(access_token)
    begin
      access_token = OpenIDConnect::AccessToken.new(
        access_token: access_token,
        client: client
      )

      access_token.userinfo!
    rescue
      return nil 
    end
  end

  def get_user
    return nil unless session[:user_id].present?

    User.find_by id: session[:user_id]
  end

  def current_user
    @current_user ||= get_user
  end

  def saml_settings
    idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
    # http://base.sso.com:8080/realms/master/protocol/saml/descriptor
    settings = idp_metadata_parser.parse_remote("http://base.sso.com:8080/realms/master/protocol/saml/descriptor")
    settings.assertion_consumer_service_url = "http://localhost:3333/saml_callback"
    settings.sp_entity_id                   = "http://localhost:3333/"
    settings.name_identifier_format         = "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
    
    settings.certificate = "-----BEGIN CERTIFICATE-----
MIIDazCCAlOgAwIBAgIUbA6rREHIxA2Q7KF7zoXMmEgRw98wDQYJKoZIhvcNAQEL
BQAwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoM
GEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDAeFw0yMzAxMTcwOTM0NTRaFw0yNDAx
MTcwOTM0NTRaMEUxCzAJBgNVBAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEw
HwYDVQQKDBhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQCuCTuHmpuLT2PQXbVnigFwcg8fclsq+y1i8LqxNS23
to1NLEYQswk0MxGUlQUqTe2rumHOKd5FJUDWpnhN7cTrnIcOv028iCyfFwDNjj14
b0qXQPw5Dn+JRPfjqdtW/DCC61vsvks8UZud592V2OqFGFLB34vY6jHfyfBqaAQ/
5cgw8kv27jHN7ancil48BIURBt+RwOiEH85uV9Vo2lZjq8COIXdAKAjzjsKcXc25
DAAmWsPyw8kO93c5OKCMW8FUTcpP1ekTtYOqjw0SOyCAQXSE1GVM7vNj2tmrN93S
HJdH1gxXNrKVEV4jEoNZFNcWqqH4XNOEyL3mu1pVf6nlAgMBAAGjUzBRMB0GA1Ud
DgQWBBQHukTvts93JlOMQxECtlgG9dzAITAfBgNVHSMEGDAWgBQHukTvts93JlOM
QxECtlgG9dzAITAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQBV
3CgywNd1cDUdGo6kMiNBIyHMcWfswuwtiqEZUw4LM8yZsrJx7r96FBlbsFej0tAL
5TDx6P5lFSBQUx36+Rr11qeZCGE/mU025GmxSGJmg4NTYlz57TjtzW9QiYygJiEb
wZ7zs/f7d91cM94j81JT/y9IIDR8s8Y0FxT/SmH3bLrJCJx6kcqa5cHzAPhRHxCK
1ebnJWwipB2IO6Nn630NH+0uK5269+ehHdLBQf4CxNImSMDavqBsE7HyEyDZZj90
JCkUGrWNOugt60ZYYsoeOHAvMl30dfRqkZyJ3yRwiqI5AUWxOY6nPB5ZhTzv8hXP
UJ44o9nnBYuxvsbBM+Ih
-----END CERTIFICATE-----
    "
    settings.private_key = "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEArgk7h5qbi09j0F21Z4oBcHIPH3JbKvstYvC6sTUtt7aNTSxG
ELMJNDMRlJUFKk3tq7phzineRSVA1qZ4Te3E65yHDr9NvIgsnxcAzY49eG9Kl0D8
OQ5/iUT346nbVvwwgutb7L5LPFGbnefdldjqhRhSwd+L2Oox38nwamgEP+XIMPJL
9u4xze2p3IpePASFEQbfkcDohB/OblfVaNpWY6vAjiF3QCgI847CnF3NuQwAJlrD
8sPJDvd3OTigjFvBVE3KT9XpE7WDqo8NEjsggEF0hNRlTO7zY9rZqzfd0hyXR9YM
VzaylRFeIxKDWRTXFqqh+FzThMi95rtaVX+p5QIDAQABAoIBAFkkIXmzlzgj0dxI
I0KFTXdq9JQG3uuE/BpRc06RDnmq53U/2CN1kKFMBxUzvxGMGNB9BtuyVkbUbgGE
AtrnjpWf9w12rzqCBVj3T1H6KUImvu36OzZ+VpTY3p+dwNstESv9oXgBgEfFBRA8
UyMNmBHUA4+KEPdp/WHC7YGTBZo0H2PeOG5vddP6d9cu+9VN482KhYv43vrlzaow
yvjUDFxkJ4RHfhtcLbIHp+RoE6ITibVunkXfkVoElg6v8TldSQeCpk+aMWhvJskG
w2TtzDSX8g5tqfXlNGCzexUBt+5VNqugnS2ZXegPBlNKVSrJlJ8KnQRjvUsvjveF
zSOwWAECgYEA30THHFuytDDX+iYZBnxqxraptOcFJhsxA32SkSqvE7hMZgyAiCLS
FTUvPpy4OxC304YpeDvCBQr9AHcjww0oUEjhvBxNWa8yCb7egVXLVgiKjecAJdz+
oL9GUf0b3kvfVlhKhX9WO4BO7tuUD8U+zB7DXS2FCKpe5cK+ORr4YvECgYEAx4zE
On3jHW9TGEWksMqCH8K0Y1tujwKkiedDw1C5QNX0MHeCKqOaNv2pQzxKmx8fXxLz
ZyKlVzjEpu5zjd5EQyDPB/YH8TvBGlDdHF0hFCZqtYP2eMKNpsrVuKr2Eq5n7D8r
TprwPXnwNHKP9T8pwPU5inlTwLvPaQwoiKFKDjUCgYBkGcsHnNk/TpLWtZQMw2WA
GE94Kwe08QYFoZw/95otRjkCm+JYpvv3xDOdZ9h1quYwMPuQy4IOjsGmHsRq5BBK
BpMmqq3HYvQVSH0sEZIrzYKJYqM/VpjW60sU4V1ISk4kwUsQFWpNHRbGoq38cBva
moRO12TI4NHRQ4HTypLIkQKBgAtRU4vRugDgYIEe6hFQ2wJ8I4kDFYks6DIeGLzK
JkekGt5o2MwcTVHTHzd+Auk7YacdxwpRb7k7sgOZwJoKQirggH1+GcM31WLttSy3
p3miGClFW8RLnIcaN/bqU1yJ4cEHcChcJ0YFVXdUDBAnzfFwtxvAd9yVilT16JKf
OzkFAoGBAJ7tSoDH34PBmVJW+pJ6sZgzCSHGwsEhxgYRRFyXfQPHqo/xZR8Q4gPO
OhR/9y4PNZH5OTot1ATg1mLRIoqX2+4b4kgh6jqbfRnl7FJAL4bhj/Z8V8eZxo3J
9YPLYsv81B7SAd0D/HTS4ECdLZ638jTEuTQvmCbw5nyKc/TdB+1x
-----END RSA PRIVATE KEY-----
    "
    settings.security[:metadata_signed] = true # Enable signature on Metadata
    # settings.security[:digest_method]    = XMLSecurity::Document::SHA1
    # settings.security[:signature_method] = XMLSecurity::Document::RSA_SHA1
    # settings.security[:strict_audience_validation] = true
    # settings.security[:want_assertions_signed]  = true
    # settings.security[:want_assertions_encrypted] = true
    settings
  end
end
