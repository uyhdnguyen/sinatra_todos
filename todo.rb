# frozen_string_literal: false

require 'securerandom'
require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'sinatra/content_for'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

#####################################################################################
=begin  
HELPER METHODS
=end

# Return an error message if the list name is invalid. Return nil if name is valid
def error_for_list_name(name)
  if !(1..100).cover? name.size
    'List name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'List name must be unique.'
  end
end

# Return an error message if the list name is invalid. Return nil if name is valid
def error_for_todo(name)
  if !(1..100).cover? name.size
    'Todo must be between 1 and 100 characters.'
  end
end

helpers do
  def list_complete?(list)
    todos_count > 0 && todos_remaining_count == 0
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todos_count(list)
    list[:todos].size
  end

  def todos_remaining_count(list)
    list[:todos].select { |todo| todo[:complete] }.size
  end

end

#####################################################################################


before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# View list of lists
get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# 1.0 Render the new list form (Create a form that sends POST request)
get '/lists/new' do
  erb :new_list, layout: :layout
end

# 1.1 Create a POST request to create  new list
post '/lists' do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] <<  { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# 2.1 Render a single todo list
get '/lists/:id' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

# 3.1 Render the edit form an existing todo list (Create a form that sends POST request)
get '/lists/:id/edit' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  erb :edit_list, layout: :layout
end

# 3.2 Create a POST request to edit the existing todo list
post '/lists/:id' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = 'The list has been updated.'
    redirect "/lists/#{:@list_id}"
  end
end

# 3.3 Delete an existing todo list
post '/lists/:id/destroy' do
  @list_id = params[:id].to_i
  session[:lists].delete_at @list_id
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

# Add new todo to an existing list
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip
  p @list
  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << {name: text, completed: false}

    session[:success] = "The todo was added."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a list
post '/lists/:list_id/todos/:id/destroy' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  todo_id = params[:id].to_i
  @list[:todos].delete_at todo_id
  session[:success] = "The todo has been deleted."
  redirect "lists/#{@list_id}"
end

# Update status of a todo
post "/lists/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  
  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "The todo has been updated"
  redirect "/lists/#{@list_id}"
end

# Complete all todos in a todo list
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  @list[:todos].each do |todo|
    todo[:completed] = true
  end

  session[:success] = "All todo have been completed."
  redirect "/lists/#{@list_id}"
end