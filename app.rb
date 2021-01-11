require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'oauth2'
require 'json'
require 'pry'

class HbConsumer < Sinatra::Base
  configure do
    enable :sessions
    set :bind, '0.0.0.0'
    set :port, 8888
    set :force_ssl, true
  end

  SCOPES = "email openid profile"

  def client
    OAuth2::Client.new(
      ENV["CLIENT_ID"],
      ENV["CLIENT_SECRET"],
      :scope => SCOPES,
      :site => "http://accounts.shopify.com"
    )
  end

  get "/auth/test" do
    redirect client.auth_code.authorize_url(
      :scope => SCOPES,
      :redirect_uri => redirect_uri
    )
  end

  get '/oauth2callback/data' do
    # binding.pry
    
    # need error handling here.
    access_token = client.auth_code.get_token(
      params[:code],
      :scope => SCOPES,
      :redirect_uri => redirect_uri
    )
    session[:access_token] = access_token.token
    @message = "Successfully authenticated with the server"
    erb :success
  end

  # Build to get email / profile data
  get '/page_2' do
    @message = get_response('data.json')
    erb :success
  end
  get '/page_1' do
    @message = get_response('data.json')
    erb :page1
  end

  def get_response(url)
    access_token = OAuth2::AccessToken.new(client, session[:access_token])
    p access_token
    JSON.parse(access_token.get("/api/v1/#{url}").body)
  end

  def redirect_uri
    uri = URI.parse(request.url)
    uri.path = '/oauth2callback/data'
    uri.query = nil
    uri.to_s
  end
end

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
