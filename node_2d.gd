show_textbox()
	change_state(State.READING)
	tween = get_tree().create_tween()
	tween.tween_property(
		label,
		"visible_characters",
		next_text.length(),
		next_text.length() * CHAR_READ_RATE
		).from(0)
	tween.connect("finished", Callable(self, "on_tween_finished"))
	end_symbol.text = "..."
