extends CharacterBody2D

# ═══════════════════════════════════════════════════════════
# mara.gd — Personnage joueur
# Attacher à : scenes/characters/mara.tscn
# Noeuds requis dans la scène :
#   - AnimatedSprite2D  (nommé AnimatedSprite2D)
#   - CollisionShape2D
#   - Camera2D          (nommée Camera2D)
# ═══════════════════════════════════════════════════════════

# ── Paramètres de mouvement ─────────────────────────────────
@export var vitesse_max   : float = 180.0
@export var acceleration  : float = 900.0
@export var friction      : float = 700.0

# ── Coyote time ─────────────────────────────────────────────
const COYOTE_DUREE        : float = 0.12
var   _coyote_timer       : float = 0.0

# ── Saut ────────────────────────────────────────────────────
@export var force_saut    : float = -380.0
const GRAVITE             : float = 0.0

# ── Références ─────────────────────────────────────────────
@onready var sprite   : AnimatedSprite2D = $AnimatedSprite2D
@onready var camera   : Camera2D         = $Camera2D

# ── État interne ────────────────────────────────────────────
var _peut_interagir   : bool = true   # bloqué pendant les dialogues
var _pnj_proche       : Node = null   # PNJ à portée d'interaction

# ════════════════════════════════════════════════════════════
# PRÊT
# ════════════════════════════════════════════════════════════

func _ready() -> void:
	add_to_group("joueur")
	# Écoute la fin des dialogues pour débloquer le mouvement
	DialogueManager.dialogue_termine.connect(_on_dialogue_termine)

# ════════════════════════════════════════════════════════════
# PHYSIQUE (chaque frame)
# ════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	if DialogueManager.dialogue_en_cours:
		_jouer_animation("idle")
		return

	_appliquer_gravite(delta)
	_gerer_coyote(delta)
	_gerer_mouvement(delta)
	_gerer_saut()
	move_and_slide()
	_mettre_a_jour_animation()

func _appliquer_gravite(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITE * delta

func _gerer_coyote(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = COYOTE_DUREE
	else:
		_coyote_timer -= delta

func _gerer_mouvement(delta: float) -> void:
	var direction : float = Input.get_axis("ui_left", "ui_right")

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * vitesse_max, acceleration * delta)
		sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _gerer_saut() -> void:
	var peut_sauter : bool = is_on_floor() or _coyote_timer > 0.0
	if Input.is_action_just_pressed("ui_accept") and peut_sauter:
		velocity.y   = force_saut
		_coyote_timer = 0.0

# ════════════════════════════════════════════════════════════
# INTERACTIONS
# ════════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interagir") and _pnj_proche and not DialogueManager.dialogue_en_cours:
		_pnj_proche.demarrer_dialogue()

# Appelé par les Area2D des PNJ
func set_pnj_proche(pnj: Node) -> void:
	_pnj_proche = pnj

func clear_pnj_proche() -> void:
	_pnj_proche = null

# ════════════════════════════════════════════════════════════
# ANIMATIONS
# ════════════════════════════════════════════════════════════

func _mettre_a_jour_animation() -> void:
	if not is_on_floor():
		_jouer_animation("saut" if velocity.y < 0 else "chute")
	elif abs(velocity.x) > 10.0:
		_jouer_animation("marche")
	else:
		_jouer_animation("idle")

	# Ralentir l'animation selon la fatigue
	var fatigue_ratio : float = 1.0 - (100 - GameManager.energie) / 200.0
	sprite.speed_scale = clamp(fatigue_ratio, 0.5, 1.0)

func _jouer_animation(nom: String) -> void:
	if sprite.animation != nom:
		sprite.play(nom)

# ════════════════════════════════════════════════════════════
# CALLBACKS
# ════════════════════════════════════════════════════════════

func _on_dialogue_termine() -> void:
	pass  # le mouvement reprend automatiquement au prochain frame
