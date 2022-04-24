require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, "secret"
end

before do
  session[:lists] ||= []
end

helpers do
  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining_count(list) == 0
  end
  
  def list_class(list)
    "complete" if list_complete?(list)
    # put in a conditional for the edge case of a new list without todos
  end
  
  def todos_remaining_count(list)
    list[:todos].select { |todo| todo[:completed] == false }.size
  end
  
  def todos_count(list)
    list[:todos].size
  end
  
  def index_list_array(lists, &block)
    index_list = []
    lists.each_with_index do |list, index|
      index_list << { index => list }
    end
    
    sorted_lists = index_list.sort_by { |index_list| list_complete?(index_list.values[0]) ? 1 : 0 }
    
    sorted_lists.each do |list|
      yield list.values[0], list.keys[0]
    end
  end
  
  def index_todo_array(todos, &block)
    index_todo = []
    todos.each_with_index do |todo, index|
      index_todo << { index => todo }
    end
    
    sorted_todos = index_todo.sort_by { |index_todo| index_todo.values[0][:completed] ? 1 : 0 }
    
    sorted_todos.each do |todo|
      yield todo.values[0], todo.keys[0]
    end
  end
end

get "/" do
  redirect "/lists"
end

# GET /lists        -> view all lists
# GET /lists/new    -> new list form
# POST /lists       -> create new list
# GET /lists/1      -> view a single list

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
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

get "/lists/:index" do
  @list_id = params[:index].to_i
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

# Edit an existing todo list
get "/lists/:index/edit" do
  index = params[:index].to_i
  @list = session[:lists][index]
  erb :edit_list, layout: :layout
end

# Update an existing todo list
post "/lists/:index" do
  index = params[:index].to_i
  list_name = params[:list_name].strip
  @list = session[:lists][index]
  
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
  session[:lists].delete_at(index)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

# Add a todo to a list
post "/lists/:index/todos" do
  @list_id = params[:index].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip
  
  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: text, completed: false }
    session[:success] = "The todo has been added."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a list
post "/lists/:list_id/todos/:todo_id/delete" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  @list[:todos].delete_at(params[:todo_id].to_i)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{@list_id}"
end

# Update the status of a todo
post "/lists/:list_id/todos/:todo_id/mark" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  is_completed = params[:completed] == "true"
  @list[:todos][params[:todo_id].to_i][:completed] = is_completed
  
  session[:success] = "The todo has been updated."

  redirect "/lists/#{@list_id}"
end

# Mark all todos as complete for a list
post "/lists/:list_id/complete_all" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  @list[:todos].each { |todo| todo[:completed] = true }
  
  session[:success] = "All todos have been completed."
  
  redirect "/lists/#{@list_id}"
end