class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end
  
  def find_list(list_id)
    list_index = @session[:lists].index { |list| list[:id] == list_id }
    @session[:lists][list_index] if list_id && list_index
  end
  
  def all_lists
    @session[:lists]
  end
  
  def create_new_list(list_name)
    id = next_id(@session[:lists])
    @session[:lists] << { id: id, name: list_name, todos: [] }
  end
  
  def delete_list(index)
    @session[:lists].delete_if { |list| list[:id] == index }
  end
  
  def update_list_name(index, new_name)
    list = find_list(index)
    list[:name] = new_name
  end
  
  def add_todo_item(list_id, text)
    list = find_list(list_id)
    id = next_id(list[:todos])
    list[:todos] << { id: id, name: text, completed: false }
  end
  
  def delete_todo_item(list_id, todo_id)
    list = find_list(list_id)
    list[:todos].delete_if { |todo| todo[:id] == todo_id }
  end
  
  def update_todo_status(list_id, todo_id, completed_status)
    list = find_list(list_id)
    todo_index = list[:todos].index { |todo| todo[:id] == todo_id }
    list[:todos][todo_index][:completed] = completed_status
  end
  
  def mark_all_todos_complete(list_id)
    list = find_list(list_id)
    list[:todos].each { |todo| todo[:completed] = true }
  end
  
  def error(message)
    @session[:error] = message
  end
  
  def success(message)
    @session[:success] = message
  end
  
  private
  
  def next_id(todos_or_lists)
    max_id = todos_or_lists.map { |todo_or_list| todo_or_list[:id] }.max || 0
    max_id + 1
  end
end