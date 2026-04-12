extends Control

# ═══════════════════════════════════════════════════════════
# minijeu_dictee.gd — "Mini dictée illustrée"
# Scène : res://scenes/minijeux/minijeu_dictee.tscn
#
# Règle : associer le mot entendu (affiché) à l'image correcte
#         parmi 3 propositions. 4 questions.
# ═══════════════════════════════════════════════════════════

signal minijeu_termine(succes: bool)

const QUESTIONS := [
	{"mot": "CHAT",    "images": ["🐱", "🐶", "🐦"], "bonne": 0},
	{"mot": "MAISON",  "images": ["🏠", "🌳", "🚗"], "bonne": 0},
	{"mot": "SOLEIL",  "images": ["🌧️", "☀️", "🌙"], "bonne": 1},
	{"mot": "LIVRE",   "images": ["📚", "🎵", "✏️"], "bonne": 0},
]

@onready var label_mot      : Label = $LabelMot
@onready var label_question : Label = $LabelQuestion
@onready var container_choix: HBoxContainer = $ContainerChoix

var _question_actuelle : int  = 0
var _bonnes_reponses   : int  = 0
var _termine           : bool = false

func _ready() -> void:
	_afficher_question()

func _afficher_question() -> void:
	if _question_actuelle >= QUESTIONS.size():
		_conclure()
		return

	var q := QUESTIONS[_question_actuelle]
	label_mot.text      = q["mot"]
	label_question.text = "Question %d / %d" % [_question_actuelle + 1, QUESTIONS.size()]

	# Vide les boutons précédents
	for c in container_choix.get_children():
		c.queue_free()

	# Crée les boutons images
	for i in range(q["images"].size()):
		var btn := Button.new()
		btn.text = q["images"][i]
		btn.custom_minimum_size = Vector2(90, 90)
		btn.add_theme_font_size_override("font_size", 36)
		var idx := i
		btn.pressed.connect(func(): _repondre(idx))
		container_choix.add_child(btn)

func _repondre(index: int) -> void:
	if _termine: return
	var q := QUESTIONS[_question_actuelle]
	if index == q["bonne"]:
		_bonnes_reponses += 1
		label_mot.modulate = Color.GREEN
	else:
		GameManager.perdre_energie(5)
		label_mot.modulate = Color.RED

	await get_tree().create_timer(0.5).timeout
	label_mot.modulate = Color.WHITE
	_question_actuelle += 1
	_afficher_question()

func _conclure() -> void:
	_termine = true
	var succes := _bonnes_reponses >= 3
	label_mot.text = "✓ %d / %d" % [_bonnes_reponses, QUESTIONS.size()] if succes else "✗ %d / %d" % [_bonnes_reponses, QUESTIONS.size()]
	await get_tree().create_timer(1.0).timeout
	queue_free()
	minijeu_termine.emit(succes)
