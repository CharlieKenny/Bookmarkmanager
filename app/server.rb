require 'data_mapper'
require 'sinatra/base'
require './lib/tag'
require './lib/user'
require './lib/link' 
require_relative 'helpers/application'
require_relative 'data_mapper_setup'
require 'rack-flash'


class Bookmarkmanager < Sinatra::Base
 include Helpers
 enable :sessions
 set :session_secret, 'super secret'
 use Rack::Flash
 use Rack::MethodOverride
 set :partial_template_engine, :erb


  get '/' do
    @links = Link.all
    erb :index
  end

  post '/links' do 
    url = params['url']
    title = params['title']
    tags = params['tags'].split(' ').map do |tag_name|
      Tag.first_or_create(text: tag_name)
    end
    Link.create(url: url, title: title, tags: tags)
    redirect to('/')
  end

  get '/tags/:text' do
    tag = Tag.first(text: params[:text])
    @links = tag ? tag.links : []
    erb :index
  end

  get '/users/new' do
    @user = User.new
    erb :'users/new'
  end

  
  post '/users' do
  @user = User.new(email: params[:email],
                  password: params[:password],
                  password_confirmation: params[:password_confirmation])
    if @user.save
      session[:user_id] = @user.id
      redirect to('/')
    else
      flash.now[:errors] = @user.errors.full_messages
      erb :'users/new'
    end
  end

  get '/sessions/new' do

    erb :'sessions/new'
  end

  delete '/sessions' do
    session.clear
    flash[:notice] = ['Good bye!']
    redirect to '/sessions/new'

  end


  # This will allow us to use a new method in our server file, 'delete'. The final piece to this puzzle is that we need a Sinatra 'delete' method to handle the incoming signout request. It will need to set a flash message, invalidate the session for the user who is signing out and then redirect appropriately. See if you can set it up correctly.

  post '/sessions' do
    email, password = params[:email], params[:password]
    user = User.authenticate(email, password)
    if user
      session[:user_id] = user.id
      redirect to('/')
    else
      flash[:errors] = ['The email or password is incorrect']
      erb :'sessions/new'
    end
  end

  run! if app_file == $0
end

