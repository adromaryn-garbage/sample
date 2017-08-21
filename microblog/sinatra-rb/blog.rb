require 'sinatra'
require 'sinatra/reloader' if development?
require 'slim'
require 'sequel'
require 'bcrypt'

DB ||= Sequel.connect(adapter: 'mysql',
                    host: 'localhost',
                    database: 'microblog',
                    user: ENV['MICROBLOG_DB_USERNAME'],
                    password: ENV['MICROBLOG_DB_PASSWORD'])

class Blog < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end
  set :sessions => true
  set :slim, :format => :html

  register do
    def auth (type)
      condition do
        redirect "/login" unless send("is_#{type}?")
      end
    end
  end

  helpers do
    def is_user?
      @current_user != nil
    end
  end

  before do
    @current_user = DB[:users].where(id: session[:user_id]).first
  end

  get "/login" do
    slim :login
  end

  post "/login" do
    login = params['login']
    password = params['password']
    user = DB[:users].where(login: login).first
    session[:user_id] = user[:id] if (user and BCrypt::Password.new(user[:password_digest]) == password)
    redirect "/"
  end

  get "/signup" do
    slim :signup
  end

  post "/signup" do
    login = params['login']
    email = params['email']
    password = params['password']
    password_confirmation = params['password-confirmation']
    redirect "/signup" if (login == '' or email == '' or password == '')
    redirect "/signup" unless password == password_confirmation
    password_hash = BCrypt::Password.create(password)
    users = DB[:users]
    redirect "/signup" if (users.where(email: email).first or users.where(login: login).first)
    users.insert(login: login, email: email, password_digest: password_hash)
    redirect "/login"
  end

  get '/', :auth => :user do
    slim :index
  end
end