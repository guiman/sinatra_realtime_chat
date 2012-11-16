require 'sinatra'

users = []
messages = []

class Message
  attr_accessor :body
  attr_reader :owner, :created_at
  
  def initialize(owner, body = nil)
    @owner = owner
    @body = body
    @created_at = Time.now
  end
end

configure do
  enable :sessions
end

before do
  # Set flash sessions value
  if session[:flash]
    @flash= session[:flash]
    session[:flash] = nil
  else
    @flash = nil
  end
end

get '/' do
  redirect '/chat' if session[:current_username] && users.include?(session[:current_username])
  erb :login
end

get '/chat' do
  redirect '/' if !users.include?(session[:current_username]) || session[:current_username].nil?
  
  @messages = messages
  @users = users
  @user = session[:current_username]
  erb :chat
end

post '/say' do
  redirect '/' if !users.include?(session[:current_username]) || session[:current_username].nil?

  messages << Message.new(session[:current_username], params[:message])
  
  redirect '/chat'
end

post '/login' do
  if params[:username] && params[:username].strip != "" && !users.include?(params[:username])
    users << params[:username]
    session[:current_username] = params[:username]
    redirect '/chat'
  end
  
  session[:flash]= "Sorry, user already taken or invalid. Try using other or wait until he/she leaves, your choice."
  redirect '/'
end

get '/logout' do
  if session[:current_username]
    users.delete session[:current_username]
    session.clear
  end
  
  session[:flash]= "Hope to see ya soon!"
  redirect '/'
end