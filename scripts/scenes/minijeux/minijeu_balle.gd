extends Control

# ═══════════════════════════════════════════════════════════
# minijeu_balle.gd — "Jeu de balle" (rythme)
# Scène : res://scenes/minijeux/minijeu_balle.tscn
#
# Règle : cliquer (ou appuyer sur Espace) quand la balle
#         est dans la zone verte. 5 passes à réussir.
# ═══════════════════════════════════════════════════════════

signal minijeu_termine(succes: bool)

const PASSES_REQUISES := 5
const VITESSE_BALLE   := 280.0

@onready var balle       : ColorRect = $Balle
@onready var zone_verte  : ColorRect = $ZoneVerte
@onready var label_info  : Label     = $LabelInfo
@onready var label_score : Label     = $LabelScore

var _score       : int   = 0
var _direction   : float = 1.0   # 1 = droite, -1 = gauche
var _termine     : bool  = false
var _peut_cliquer: bool  = true

func _ready() -> void:
	balle.position.x = 40.0
	label_info.text  = "Espace ou clic quand la balle est dans la zone !"
	_mettre_a_jour_score()

func _process(delta: float) -> void:
	if _termine: return
	balle.position.x += VITESSE_BALLE * _direction * delta
	# Rebondit aux bords
	if balle.position.x > size.x - 30:
		_direction = -1.0
	elif balle.position.x < 0:
		_direction = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if _termine or not _peut_cliquer: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_tenter_passe()
	elif event.is_action_pressed("ui_accept"):
		_tenter_passe()

func _tenter_passe() -> void:
	_peut_cliquer = false
	var rect_zone  := zone_verte.get_global_rect()
	var centre_balle := balle.global_position + balle.size * 0.5

	if rect_zone.has_point(centre_balle):
		_score += 1
		balle.color = Color.GREEN
		_mettre_a_jour_score()
		if _score >= PASSES_REQUISES:
			_reussir()
			return
	else:
		balle.color = Color.RED
		GameManager.perdre_energie(4)

	await get_tree().create_timer(0.4).timeout
	if not _termine:
		balle.color    = Color.WHITE
		_peut_cliquer  = true

func _mettre_a_jour_score() -> void:
	label_score.text = "Passes : %d / %d" % [_score, PASSES_REQUISES]

func _reussir() -> void:
	_termine = true
	label_info.text = "Super ! Léa est ravie !"
	await get_tree().create_timer(0.8).timeout
	queue_free()
	minijeu_termine.emit(true)
