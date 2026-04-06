extends CharacterBody2D

# ═══════════════════════════════════════════════════════════
# mara.gd — Top-down style Pokémon
# Placer les sprites dans : res://scenes/characters/
# Animations dans AnimatedSprite2D :
#   idle_bas / idle_haut / idle_gauche / idle_droite
#   marche_bas / marche_haut / marche_gauche / marche_droite
# ═══════════════════════════════════════════════════════════

@export var vitesse_max : float = 120.0

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var camera : Camera2D         = $Camera2D

var _pnj_proche     : Node   = null
var _direction_face : String = "bas"

# ════════════════════════════════════════════════════════════
func _ready() -> void:
	add_to_group("joueur")
	DialogueManager.dialogue_termine.connect(_on_dialogue_termine)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed   = 8.0
	camera.enabled                    = true

# ════════════════════════════════════════════════════════════
func _physics_process(_delta: float) -> void:
	if DialogueManager.dialogue_en_cours:
		velocity = Vector2.ZERO
		_jouer_animation("idle_" + _direction_face)
		return

	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up",   "ui_down")
	)

	if dir.length() > 1.0:
		dir = dir.normalized()

	if dir != Vector2.ZERO:
		velocity = dir * vitesse_max
		if   abs(dir.x) >= abs(dir.y) and dir.x > 0 : _direction_face = "droite"
		elif abs(dir.x) >= abs(dir.y) and dir.x < 0 : _direction_face = "gauche"
		elif dir.y < 0                               : _direction_face = "haut"
		else                                         : _direction_face = "bas"
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_mettre_a_jour_animation(dir != Vector2.ZERO)

# ════════════════════════════════════════════════════════════
# ANIMATIONS
# ════════════════════════════════════════════════════════════

func _mettre_a_jour_animation(en_mouvement: bool) -> void:
	var anim : String
	if en_mouvement:
		match _direction_face:
			"droite" : anim = "marche_droite"
			"gauche" : anim = "marche_gauche"
			"haut"   : anim = "marche_haut"
			_        : anim = "marche_bas"
	else:
		anim = "idle_" + _direction_face

	sprite.speed_scale = clamp(1.0 - (100 - GameManager.energie) / 200.0, 0.5, 1.0)
	_jouer_animation(anim)

func _jouer_animation(nom: String) -> void:
	if sprite.animation != nom:
		sprite.play(nom)

# ════════════════════════════════════════════════════════════
# INTERACTIONS
# ════════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interagir") \
	and _pnj_proche \
	and not DialogueManager.dialogue_en_cours:
		_pnj_proche.demarrer_dialogue()

func set_pnj_proche(pnj: Node) -> void:
	_pnj_proche = pnj

func clear_pnj_proche() -> void:
	_pnj_proche = null

func _on_dialogue_termine() -> void:
	pass
