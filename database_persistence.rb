require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "todos")
    @logger = logger
  end
  
  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end
  
  def find_list(id)
    list_sql = "SELECT * FROM lists WHERE id = $1"
    todo_sql = "SELECT * FROM todos WHERE list_id = $1"
    
    list_result = query(list_sql, id)
    todo_result = query(todo_sql, id)
    
    list_tuple = list_result.first
    
    todos_array = []
    todo_result.each do |tuple|
      todos_array << { id: tuple["id"], name: tuple["name"], completed: tuple["completed"] == "t" }
    end
    
    {id: list_tuple["id"], name: list_tuple["name"], todos: todos_array}
  end
  
  def all_lists
    list_sql = "SELECT * FROM lists"
    todo_sql = "SELECT * FROM todos"
    
    list_result = query(list_sql)
    todo_result = query(todo_sql)
    
    list_result.map do |list_tuple|
      todos_array = []
      todo_result.each do |todo_tuple|
        todos_array << { id: todo_tuple["id"], name: todo_tuple["name"], completed: todo_tuple["completed"] == "t" } if list_tuple["id"] == todo_tuple["list_id"]
      end

      {id: list_tuple["id"], name: list_tuple["name"], todos: todos_array}
    end
  end
  
  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1);"
    query(sql, list_name)
  end
  
  def delete_list(index)
    # I don't have to worry about deleting todos first because of the on delete cascade clause
    sql = "DELETE FROM lists WHERE id = $1"
    query(sql, index)
  end
  
  def update_list_name(index, new_name)
    # list = find_list(index)
    # list[:name] = new_name
    sql = "UPDATE lists SET name = $1 WHERE id = $2;"
    query(sql, new_name, index)
  end
  
  def add_todo_item(list_id, text)
    sql = "INSERT INTO todos (name, list_id) VALUES ($1, $2);"
    query(sql, text, list_id)
  end
  
  def delete_todo_item(list_id, todo_id)
    # list = find_list(list_id)
    # list[:todos].delete_if { |todo| todo[:id] == todo_id }
    sql = "DELETE FROM todos WHERE list_id = $1 AND id = $2;"
    query(sql, list_id, todo_id)
  end
  
  def update_todo_status(list_id, todo_id, completed_status)
    # list = find_list(list_id)
    # todo_index = list[:todos].index { |todo| todo[:id] == todo_id }
    # list[:todos][todo_index][:completed] = completed_status
    sql = "UPDATE todos SET completed = $1 WHERE list_id = $2 AND id = $3;"
    query(sql, completed_status, list_id, todo_id)
  end
  
  def mark_all_todos_complete(list_id)
    # list = find_list(list_id)
    # list[:todos].each { |todo| todo[:completed] = true }
    sql = "UPDATE todos SET completed = true WHERE list_id = $1;"
    query(sql, list_id)
  end
end