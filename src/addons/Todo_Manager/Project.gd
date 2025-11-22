@tool
extends Panel

signal tree_built # used for debugging

const Todo := preload("res://addons/Todo_Manager/todo_class.gd")

var _sort_alphabetical := true
var _full_path := false

@onready var tree := $Tree as Tree

func build_tree(todo_items : Array[ToDoItem], ignore_paths : Array, patterns : Array, cased_patterns: Array[String], sort_alphabetical : bool, full_path : bool, group_by_priority : bool) -> void:
	_full_path = full_path
	tree.clear()
	var root := tree.create_item()
	root.set_text(0, "Scripts")
	
	if sort_alphabetical:
		todo_items.sort_custom(Callable(self, "sort_alphabetical"))
	else:
		todo_items.sort_custom(Callable(self, "sort_backwards"))
	
	if (group_by_priority):
		build_priority_tree(todo_items.filter(func(i : ToDoItem):
			for ignore_path in ignore_paths:
				if i.script_path.begins_with(ignore_path) or i.script_path.begins_with("res://" + ignore_path) or i.script_path.begins_with("res:///" + ignore_path):
					return false
			
			return true
		), root, ignore_paths, patterns, cased_patterns, full_path)
	else:
		build_per_file_tree(todo_items, root, ignore_paths, patterns, cased_patterns, full_path)
	
	tree_built.emit()

func build_per_file_tree(todo_items : Array[ToDoItem], root: TreeItem, ignore_paths : Array, patterns : Array, cased_patterns: Array[String], full_path : bool) -> void:	
	for todo_item in todo_items:
		var ignore := false
		for ignore_path in ignore_paths:
			var script_path : String = todo_item.script_path
			if script_path.begins_with(ignore_path) or script_path.begins_with("res://" + ignore_path) or script_path.begins_with("res:///" + ignore_path):
				ignore = true
				break
		if ignore: 
			continue
		var script := tree.create_item(root)
		
		if full_path:
			script.set_text(0, todo_item.script_path + " -------")
		else:
			script.set_text(0, todo_item.get_short_path() + " -------")
			
		script.set_metadata(0, todo_item)
		for todo in todo_item.todos:
			var item := tree.create_item(script)
			var content_header : String = todo.content
			if "\n" in todo.content:
				content_header = content_header.split("\n")[0] + "..."
			item.set_text(0, "(%0) - %1".format([todo.line_number, content_header], "%_"))
			item.set_tooltip_text(0, todo.content)
			item.set_metadata(0, todo)
			for i in range(0, len(cased_patterns)):
				if cased_patterns[i] == todo.pattern:
					item.set_custom_color(0, patterns[i][1])

func build_priority_tree(todo_items : Array[ToDoItem], root: TreeItem, ignore_paths : Array, patterns : Array, cased_patterns: Array[String], full_path : bool) -> void:
	for priority in range(0, 6):
		var priority_todo_items : Array[ToDoItem] = todo_items.filter(
		func(todo_item : ToDoItem):
			return todo_item.todos.any(func(todo : ToDo): 
				return is_todo_priority(todo, priority)
			)
		)
		
		if priority_todo_items.size() < 1:
			continue
		
		var amount := 0
		var container := tree.create_item(root)
		
		for todo_item : ToDoItem in priority_todo_items:
			var ignore := false
			for ignore_path in ignore_paths:
				var script_path : String = todo_item.script_path
				if script_path.begins_with(ignore_path) or script_path.begins_with("res://" + ignore_path) or script_path.begins_with("res:///" + ignore_path):
					ignore = true
					break
			if ignore: 
				continue
			
			for p_data : ToDo in todo_item.todos.filter(func(todo:ToDo): return is_todo_priority(todo, priority)):
				var item := tree.create_item(container)
				var content_header : String = p_data.content
				
				if "\n" in p_data.content:
					content_header = content_header.split("\n")[0] + "..."
				
				var content := content_header.substr(4)
				var info := (todo_item.script_path if full_path else todo_item.get_short_path()) + ":" + str(p_data.line_number)
				item.set_text(0, "(%0) ~ %1".format([info, content], "%_"))
				item.set_tooltip_text(0, p_data.content)
				item.set_metadata(0, p_data)
				
				for i in range(0, len(cased_patterns)):
					if cased_patterns[i] == p_data.pattern:
						item.set_custom_color(0, patterns[i][1])
						container.set_custom_color(0, patterns[i][1])
				
				amount += 1
		
		container.set_text(0, "------- " + "P" + str(priority)  + " (" + str(amount) + ")")
		container.collapsed = true

func is_todo_priority (todo : ToDo, priority : int) -> bool:
	return todo.title == "P" + str(priority)

func sort_alphabetical(a, b) -> bool:
	if _full_path:
		if a.script_path < b.script_path:
			return true
		else:
			return false
	else:
		if a.get_short_path() < b.get_short_path():
			return true
		else:
			return false

func sort_backwards(a, b) -> bool:
	if _full_path:
		if a.script_path > b.script_path:
			return true
		else:
			return false
	else:
		if a.get_short_path() > b.get_short_path():
			return true
		else:
			return false
