require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'digest/sha1'
require 'data_mapper'
# require 'builder'
# require 'sinatra/json'
require 'sinatra/base'
require 'rack-flash'
require 'sinatra/redirect_with_flash'
require 'haml'
require 'bcrypt'

enable :sessions
use Rack::Flash, :sweep => true

SITE_TITLE = "Recall"
SITE_DESCRIPTION = "'cause you're too busy to remember"

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db")

class Note
  include DataMapper::Resource
  property :id, Serial
  property :content, Text, :required => true
  property :complete, Boolean, :required => true, :default => false
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :user
end

class User
  include DataMapper::Resource
  property :id, Serial
  property :username, Text, :required => true
  property :password_hash, Text, :required => true
  property :password_salt, Text, :required => true

  has n, :notes
end

DataMapper.finalize.auto_upgrade!

helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def login?
    if session[:username].nil?
      return false
    else
      return true
    end
  end
end

get '/' do
  unless login?
    redirect '/login', :error => 'You need to login'
  end


  @notes = @current_user.notes.all :order => :id.desc
  @title = 'All Notes'
  if @notes.empty?
    flash[:error] = 'No notes found. Add your first below.'
  end
  haml :home
end

get '/login' do
  @title = 'Login'
  haml :login
end

post '/login' do
  u = User.first :username => params[:username]
  # u.password_hash
  BCrypt::Engine.hash_secret(params[:password], u.password_salt)
  if u.password_hash == BCrypt::Engine.hash_secret(params[:password], u.password_salt)
    session[:username] = params[:username]
    session[:userid] = u.id
    redirect '/', :notice => 'Login successfully'
  else
    redirect '/login', :error => 'Wrong username or password'
  end

end

get '/signup' do
  @title = 'Sign Up'
  haml :signup
end

post '/signup' do
  password_salt = BCrypt::Engine.generate_salt
  password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)

  u = User.new
  u.username = params[:username]
  u.password_hash = password_hash
  u.password_salt = password_salt
  u.save

  redirect '/login', :notice => 'User created successfully'
end

post '/' do

  n = @current_user.notes.new
  n.content = params[:content]
  n.created_at = Time.now
  n.updated_at = Time.now
  if n.save
    redirect '/', :notice => 'Note Created succesfully.'
  else
    redirect '/', :error => 'Failed to save note.'
  end
end
get '/logout' do
  session[:username] = nil
  redirect '/login', :notice => 'Logout successfully'
end

get '/rss.xml' do
  @notes = Note.all :order => :id.desc
  builder :rss
end

get '/:id' do

  @note = @current_user.notes.get params[:id]

  if @note
    @title = "Editing note: #{@note.content}"
    haml :edit
  else
    redirect '/', :error => "Can't find that note"
  end
end


put '/:id' do
  n = @current_user.notes.get params[:id]
  unless n
    redirect '/', :error => "Can't find that note"
  end
  n.content = params[:content]
  n.complete = params[:complete] ? 1 : 0
  n.updated_at = Time.now
  if n.save
    redirect '/', :notice => 'Note updated successfully'
  else
    redirect '/', :error => 'Error updating successfully'
  end
end

get '/:id/delete' do
  @note = @current_user.notes.get params[:id]
  if @note
    @title = "Confirm deletion of note ##{params[:id]}"
    haml :delete
  else
    redirect '/', :error => "Can't find that note"
  end
end

delete '/:id' do
  n = @current_user.notes.get params[:id]
  if n.destroy
    redirect '/', :notice => 'Note deleted successfully'
  else
    redirect '/', :error => 'Error while deleting note'
  end
end

get '/:id/complete' do
  n = @current_user.notes.get params[:id]
  unless n
    redirect '/', :error => "Can't find that note"
  end
  n.complete = 1
  if n.save
    redirect '/', :notice => 'Note marked as complete.'
  else
    redirect '/', :error => 'Eror marking note as complete'
  end
end

get '/notes/json' do
  @notes = Note.all :order => :id.desc
  json(@notes, :encoder => :to_json, :content_type => :js)
end

get '/add/:note' do
  n = @current_user.notes.new
  n.content = params[:note]
  n.created_at = Time.now
  n.updated_at = Time.now
  n.save

  redirect '/'
end


not_found do
  "Page not found"
end

before do
  @current_user = User.get session[:userid]
end