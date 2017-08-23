require 'sinatra'
require 'sinatra/reloader' if development?
require 'slim'
require 'sequel'
require 'bcrypt'

DB ||= Sequel.connect(adapter: 'mysql2',
                    host: 'localhost',
                    database: 'microblog',
                    user: ENV['MICROBLOG_DB_USERNAME'],
                    password: ENV['MICROBLOG_DB_PASSWORD'])

class Blog < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end
  enable :method_override
  set :sessions => true
  set :slim, :format => :html

  register do
    def auth(type)
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
    slim :login, layout: :layout
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

  get "/logout" do
    session.delete(:user_id)
    redirect "/login"
  end

  get '/', :auth => :user do
    @user = @current_user
    @posts = DB[:posts].where(user_id: @current_user[:id])
    slim :'posts/index'
  end

  get '/posts/new', :auth => :user do
    slim :'posts/new'
  end

  post '/posts', :auth => :user do
    title = params['title']
    content = params['content']
    id = DB[:posts].insert(title: title, content: content, user_id: @current_user[:id])
    redirect "/posts/#{id}"
  end

  get '/posts/:id' do
    id = params[:id]
    @post = DB[:posts].where(id: id).first
    redirect '/' unless @post
    slim :'posts/show'
  end

  get '/:user_id/posts' do
    user_id = params[:user_id]
    @user = DB[:users].where(id: user_id).first
    redirect "/" unless @user
    @posts = DB[:posts].where(user_id: user_id)
    slim :'posts/index'
  end

  get '/posts/:id/edit', :auth => :user do
    @post = DB[:posts].where(id: params[:id]).first
    redirect '/' unless (@post and @post[:id] = @current_user[:id])
    slim :'posts/edit'
  end

  patch '/posts/:id', :auth => :user do
    id = params[:id]
    title = params['title']
    content = params['content']
    post = DB[:posts].where(id: id).first
    redirect '/' unless post and post[:user_id] == @current_user[:id]
    DB[:posts].where(id: id).update(title: title, content: content)
    redirect "/posts/#{id}"
  end
end
