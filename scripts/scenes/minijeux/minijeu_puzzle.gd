extends Control

# ═══════════════════════════════════════════════════════════
# minijeu_puzzle.gd — "Puzzle"
# Règle : cliquer les pièces dans le bon ordre pour
#         reconstituer une image (4 pièces numérotées)
# ═══════════════════════════════════════════════════════════

signal minijeu_termine(succes: bool)

const NB_PIECES := 4
const TEMPS_LIMITE := 20.0

@onready var label_consigne : Label = $LabelConsigne
@onready var label_timer    : Label = $LabelTimer

var _ordre_attendu  : int   = 1
var _temps_restant  : float = TEMPS_LIMITE
var _termine        : bool  = false
var _erreurs        : int   = 0

func _ready() -> void:
	label_consigne.text = "Clique les pièces dans l'ordre !"
	_creer_pieces()

func _process(delta: float) -> void:
	if _termine: return
	_temps_restant -= delta
	label_timer.text = "%.0f" % max(0.0, _temps_restant)
	if _temps_restant <= 0.0:
		_echouer()

func _creer_pieces() -> void:
	# Ordre mélangé — le joueur doit les remettre en ordre
	var ordres := range(1, NB_PIECES + 1)
	ordres = Array(ordres)
	ordres.shuffle()

	var positions := [
		Vector2(80, 120), Vector2(280, 120),
		Vector2(80, 240), Vector2(280, 240)
	]

	for i in range(NB_PIECES):
		var num := ordres[i]
		var btn := Button.new()
		btn.text     = "🧩 %d" % num
		btn.position = positions[i]
		btn.custom_minimum_size = Vector2(100, 80)
		btn.add_theme_font_size_override("font_size", 22)
		var n := num
		btn.pressed.connect(func(): _cliquer_piece(n, btn))
		add_child(btn)

func _cliquer_piece(numero: int, btn: Button) -> void:
	if _termine: return
	if numero == _ordre_attendu:
		btn.modulate = Color.GREEN
		btn.disabled = true
		_ordre_attendu += 1
		if _ordre_attendu > NB_PIECES:
			_reussir()
	else:
		btn.modulate = Color.RED
		_erreurs += 1
		GameManager.perdre_energie(5)
		await get_tree().create_timer(0.4).timeout
		if is_instance_valid(btn):
			btn.modulate = Color.WHITE

func _reussir() -> void:
	_termine = true
	label_consigne.text = "Puzzle réussi ! Un beau souvenir."
	await get_tree().create_timer(0.8).timeout
	queue_free()
	minijeu_termine.emit(true)

func _echouer() -> void:
	_termine = true
	label_consigne.text = "Le souvenir reste flou…"
	await get_tree().create_timer(0.8).timeout
	queue_free()
	minijeu_termine.emit(false)
