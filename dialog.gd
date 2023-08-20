extends CanvasLayer

var endpoint_url = "http://localhost:11434/api/generate"
var model = "battle-rapper"
var context = []
var waiting = false # waiting for api response
var display_queue = ""

func _ready():
	$HTTPRequest.request_completed.connect(_on_request_completed)
	generate("Alright, let's get this battle started.", context)

func _input(event):
	if waiting:
		return
		
	if event.is_action_pressed("submit"):
		if display_queue.length() > 0:
			add_to_display(display_queue)
			return
		var speaking = get_node("TextboxContainer/MarginContainer/HBoxContainer/Label").text	
		if speaking == "You:":
			var prompt = get_node("TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Dialog").text
			if prompt.length() == 0:
				return
			waiting = true
			get_node("TextboxContainer/MarginContainer/HBoxContainer/Label").text = "Robo Rapper 9000:"
			get_node("TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Dialog").text = "loading..."
			generate(prompt, context)
			waiting = false
			return
		# end of robots turn to speak
		get_node("TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Dialog").text = ""
		get_node("TextboxContainer/MarginContainer/HBoxContainer/End").hide()
		get_node("TextboxContainer/MarginContainer/HBoxContainer/Label").text = "You:"
	
	var speaking = get_node("TextboxContainer/MarginContainer/HBoxContainer/Label").text	
	if display_queue.length() > 0 || speaking != "You:":
		return
		
	if event is InputEventKey and event.pressed and !event.is_echo():
		var current_text = get_node("TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Dialog").text		
		var unicode = event.unicode
		if unicode == 0:
			if current_text.length() > 0:
				get_node("TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Dialog").text = current_text.left(current_text.length() - 1)
		if unicode >= 32 and unicode < 127:  # Basic ASCII printable characters range
			var character = char(unicode)
			get_node("TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Dialog").text += character
		
func generate(prompt, context):
	var json_body = {
		"model": model,
		"prompt": prompt,
		"context": context
	}
	
	var headers = ["Content-Type: application/json", "X-Streamed: false"]
	var body = JSON.stringify(json_body)
	$HTTPRequest.request(endpoint_url, headers, HTTPClient.METHOD_POST, body)

func _on_request_completed(result, response_code, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	add_to_display(response["response"])
	context= response["context"]
	
func add_to_display(input):
	get_node("TextboxContainer/MarginContainer/HBoxContainer/End").show()
	input = input.replace("&#39;", "'")
	if input.length() >= 140:
		get_node("TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Dialog").text = input.left(139)
		display_queue = input.substr(139, input.length() - 139)
	else:
		get_node("TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Dialog").text = input
		display_queue = ""
