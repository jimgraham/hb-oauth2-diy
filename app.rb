require 'sinatra/base'
require 'sinatra/flash'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'oauth2'
require 'json'
require 'pry'

class HbConsumer < Sinatra::Base

  configure do
    enable :sessions
    register Sinatra::Flash
    set :bind, '0.0.0.0'
    set :port, 8888
    set :force_ssl, true
  end

  # The scopes requested from Shopify Identity.
  # If we do not provide SCOPES we will get an error.
  SCOPES = "email openid profile"

  # A client that talks to Shopify Identity. We make connections via
  # `client.auth_code.` "Authorization Code" is a specific type of flow
  # in the OAuth spec.
  def client
    OAuth2::Client.new(
      ENV["CLIENT_ID"],
      ENV["CLIENT_SECRET"],
      :scope => SCOPES,
      :site => "http://accounts.shopify.com"
    )
  end

  get "/" do
    erb :intro
  end

  # Redirect to Shopify for login / signup
  # 
  get "/auth/test" do
    # the prompt=none says "don't prompt, see if the user is already logged in"
    redirect client.auth_code.authorize_url(
      :prompt => "none",
      :scope => SCOPES,
      :redirect_uri => redirect_uri
    )
  end

  # Shopify calls this route with a temporary access code that 
  # we can exchange for an access token
  # We store the access_token in the session. Could put it in a cookie
  get '/oauth2callback/data' do
    # look if Shopify returns an error to us in
    # the `error` or `error_description` query params
    auth_error = params[:error]
    if auth_error
      # check for login error
      if auth_error == "login_required"
        # redirect asking for chance to login.
        redirect client.auth_code.authorize_url(
          :scope => SCOPES,
          :redirect_uri => redirect_uri
        )
      end

      flash[:error] = "We received an Error:\n #{auth_error} #{params[:error_description]}"
      redirect "/"
    end

    # exchange the temp code for an access token.
    access_token = client.auth_code.get_token(
      params[:code],
      :scope => SCOPES,
      :redirect_uri => redirect_uri
    )

    # save the access token in the session. Could put this in a cookie.
    session[:access_token] = access_token.token
    # The refresh token would be also available on `access_token.refresh_token`

    @message = "Successfully authenticated with the server"
    erb :success
  end

  # To show what this can do, we fetch information about the user.
  #
  # fetch from accounts.shopify.com/oauth/userinfo to get the information
  # for the User that just signed in.
  get '/page_2' do
    @message = get_response('userinfo')
    erb :success
  end

  get '/page_1' do
    @message = get_response('userinfo')
    erb :page1
  end

  private

  def get_response(url)
    access_token = OAuth2::AccessToken.new(client, session[:access_token])

    JSON.parse(access_token.get("/oauth/#{url}").body)
  end

  def redirect_uri
    uri = URI.parse(request.url)
    uri.path = '/oauth2callback/data'
    uri.query = nil
    uri.to_s
  end
end


# This sets up the server to run SSL
WEBAPP_ROOT = File.expand_path File.dirname(__FILE__)

webrick_options = {
  :Port               => 8888,
  :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
  :DocumentRoot       => WEBAPP_ROOT,
  :SSLEnable          => true,
  :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
  :SSLCertificate     => OpenSSL::X509::Certificate.new(
    File.open(File.join(WEBAPP_ROOT, "localhost.pem")).read
  ),
  :SSLPrivateKey      => OpenSSL::PKey::RSA.new(
     File.open(File.join(WEBAPP_ROOT, "localhost-key.pem")).read
  ),
  :SSLCertName        => [ [ "CN",WEBrick::Utils::getservername ] ],
  :app                => HbConsumer
}

Rack::Server.start webrick_options
