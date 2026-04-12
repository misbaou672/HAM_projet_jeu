extends Control

# ═══════════════════════════════════════════════════════════
# minijeu_petit_dej.gd — "Petit déjeuner" (drag & drop)
# Scène : res://scenes/minijeux/minijeu_petit_dej.tscn
#
# Règle : glisser les bons aliments dans le bol
#         (pain, lait, céréales) — ignorer les mauvais
# Nœuds requis :
#   Control (racine)
#   ├── Label    (LabelConsigne)
#   ├── Label    (LabelScore)
#   └── Panel    (Bol) — zone cible au centre bas
# ═══════════════════════════════════════════════════════════

signal minijeu_termine(succes: bool)

const ALIMENTS_BONS    := ["🥣 Céréales", "🥛 Lait", "🍞 Pain"]
const ALIMENTS_MAUVAIS := ["🍬 Bonbon", "🍕 Pizza", "🎂 Gâteau"]
const SCORE_REQUIS     := 3

@onready var label_consigne : Label = $LabelConsigne
@onready var label_score    : Label = $LabelScore
@onready var bol            : Panel = $Bol

var _score      : int  = 0
var _termine    : bool = false
var _drag_item  : Control = null
var _drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	label_consigne.text = "Glisse les bons aliments dans le bol !"
	_spawner_aliments()
	_mettre_a_jour_score()

# ── Création des aliments ────────────────────────────────────
func _spawner_aliments() -> void:
	var tous := ALIMENTS_BONS.duplicate()
	tous.append_array(ALIMENTS_MAUVAIS)
	tous.shuffle()

	var cols := 3
	for i in range(tous.size()):
		var lbl := Label.new()
		lbl.text = tous[i]
		lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
		lbl.position = Vector2(60 + (i % cols) * 160, 80 + (i / cols) * 80)
		lbl.add_theme_font_size_override("font_size", 22)

		# Drag via GUI input
		lbl.gui_input.connect(func(ev): _on_aliment_input(ev, lbl))
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(lbl)

func _on_aliment_input(event: InputEvent, lbl: Label) -> void:
	if _termine: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_item   = lbl
			_drag_offset = lbl.get_local_mouse_position()
		else:
			_deposer_aliment(lbl)
			_drag_item = null

func _input(event: InputEvent) -> void:
	if _drag_item and event is InputEventMouseMotion:
		_drag_item.global_position = event.global_position - _drag_offset

func _deposer_aliment(lbl: Label) -> void:
	# Vérifie si l'aliment est dans le bol
	var rect_bol  := bol.get_global_rect()
	var centre    := lbl.global_position + lbl.size * 0.5
	if rect_bol.has_point(centre):
		if lbl.text in ALIMENTS_BONS:
			_score += 1
			lbl.modulate = Color.GREEN
			_mettre_a_jour_score()
			await get_tree().create_timer(0.3).timeout
			lbl.queue_free()
			if _score >= SCORE_REQUIS:
				_reussir()
		else:
			# Mauvais aliment → rebondit
			lbl.modulate = Color.RED
			GameManager.perdre_energie(3)
			await get_tree().create_timer(0.3).timeout
			if is_instance_valid(lbl):
				lbl.modulate = Color.WHITE

func _mettre_a_jour_score() -> void:
	label_score.text = "%d / %d" % [_score, SCORE_REQUIS]

func _reussir() -> void:
	_termine = true
	label_consigne.text = "Parfait ! Bon appétit !"
	await get_tree().create_timer(0.8).timeout
	queue_free()
	minijeu_termine.emit(true)
