require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'sinatra/json'

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db")

class Note
  include DataMapper::Resource
  property :id, Serial
  property :content, Text, :required => true
  property :complete, Boolean, :required => true, :default => false
  property :created_at, DateTime
  property :updated_at, DateTime
end

DataMapper.finalize.auto_upgrade!

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

get '/' do
  @notes = Note.all :order => :id.desc
  @title = 'All Notes'
  erb :home
end

post '/' do
  n = Note.new
  n.content = params[:content]
  n.created_at = Time.now
  n.updated_at = Time.now
  n.save

  redirect '/'
end

get '/rss.xml' do
  @notes = Note.all :order => :id.desc
  builder :rss
end

get '/:id' do

  @note = Note.get params[:id]
  @title = "Editing note: #{@note.content}"
  erb :edit
end


put '/:id' do
  n = Note.get params[:id]
  n.content = params[:content]
  n.complete = params[:complete] ? 1 : 0
  n.updated_at = Time.now
  n.save

  redirect '/'
end

get '/:id/delete' do
  @note = Note.get params[:id]
  @title = "Confirm deletion of note ##{params[:id]}"
  erb :delete
end

delete '/:id' do
  n = Note.get params[:id]
  n.destroy
  redirect '/'
end

get '/:id/complete' do
  n = Note.get params[:id]
  n.complete = 1
  n.save
  redirect '/'
end

get '/notes/json' do
  @notes = Note.all :order => :id.desc
  json(@notes, :encoder => :to_json, :content_type => :js)
end

get '/add/:note' do
  n = Note.new
  n.content = params[:note]
  n.created_at = Time.now
  n.updated_at = Time.now
  n.save

  redirect '/'
end


not_found do
  "Page not found"
end