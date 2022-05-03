require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, "secret"
  set :erb, :escape_html => true
end

before do
  session[:lists] ||= []
end

# Data Structure:
  # Lists
    # session[:lists] ==>
    # [
    # { id: 1, name: Homework, todos: [{}, {}...] },
    # { id: 2, name: Work, todos: [{}, {}...] }
    # ]
  # Todos:
    # session[:lists][:name][:todos] ==>
    # [
    # { id: 1, name: English, completed: false },
    # { id: 2, name: Science, completed: true }
    # ]

helpers do
  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining_count(list) == 0
  end
  
  def list_class(list)
    "complete" if list_complete?(list)
  end
  
  def todos_remaining_count(list)
    list[:todos].select { |todo| todo[:completed] == false }.size
  end
  
  def todos_count(list)
    list[:todos].size
  end

  def sort_lists(lists)
    lists.partition { |list| !list_complete?(list) }.flatten.each do |list|
      yield list
    end
  end

  def sort_todos(todos)
    todos.partition { |todo| !todo[:completed] }.flatten.each do |todo|
      yield todo
    end
  end
end

def next_id(todos_or_lists)
  max_id = todos_or_lists.map { |todo_or_list| todo_or_list[:id] }.max || 0
  max_id + 1
end

def load_list(list_id)
  list_index = session[:lists].index { |list| list[:id] == list_id }
  list = session[:lists][list_index] if list_id && list_index
  return list if list
  
  session[:error] = "The specified list was not found."
  redirect "/lists"
end

get "/" do
  redirect "/lists"
end

# View all lists
get "/lists" do
  @lists = session[:lists]

  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo must be between 1 and 100 characters."
  end
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    id = next_id(session[:lists])
    session[:lists] << { id: id, name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# View a single todo list
get "/lists/:index" do
  @list_id = params[:index].to_i
  @list = load_list(@list_id)
  
  erb :list, layout: :layout
end

# Edit an existing todo list
get "/lists/:index/edit" do
  index = params[:index].to_i
  @list = load_list(index)
  erb :edit_list, layout: :layout
end

# Update an existing todo list
post "/lists/:index" do
  index = params[:index].to_i
  list_name = params[:list_name].strip
  @list = load_list(index)
  
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{index}"
  end
end

# Delete an existing todo list
post "/lists/:index/delete" do
  index = params[:index].to_i
  session[:lists].delete_if { |list| list[:id] == index }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "The list has been deleted."
    redirect "/lists"
  end
end

# Add a todo to a list
post "/lists/:index/todos" do
  @list_id = params[:index].to_i
  @list = load_list(@list_id)
  text = params[:todo].strip
  
  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    id = next_id(@list[:todos])
    @list[:todos] << { id: id, name: text, completed: false }
    session[:success] = "The todo has been added."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a list
post "/lists/:list_id/todos/:todo_id/delete" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  
  @list[:todos].delete_if { |todo| todo[:id] == params[:todo_id].to_i }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo has been deleted."
    redirect "/lists/#{@list_id}"
  end
end

# Update the status of a todo
post "/lists/:list_id/todos/:todo_id/mark" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  is_completed = params[:completed] == "true"
  todo_index = @list[:todos].index { |todo| todo[:id] == params[:todo_id].to_i }
  @list[:todos][todo_index][:completed] = is_completed
  
  session[:success] = "The todo has been updated."

  redirect "/lists/#{@list_id}"
end

# Mark all todos as complete for a list
post "/lists/:list_id/complete_all" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  @list[:todos].each { |todo| todo[:completed] = true }
  
  session[:success] = "All todos have been completed."
  
  redirect "/lists/#{@list_id}"
end
