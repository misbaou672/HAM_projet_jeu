extends Node2D

# ═══════════════════════════════════════════════════════════
# jour_3.gd — Jour 3 : Fragments de Mémoire
# Scène : res://scenes/jours/jour_3.tscn
#
# Séquence :
#   1. Album photo (identifier vraie photo)
#   2. Puzzle (reconstituer image émotionnelle)
#   3. BIFURCATION RÊVE :
#      - energie > 50 → Parcours Lumière : L'Océan Renversé
#      - energie ≤ 50 → Parcours Ombre   : Galerie des Visages Vides
#   4. Retour réalité (effets selon parcours)
# ═══════════════════════════════════════════════════════════

enum Etape { ALBUM, PUZZLE, REVE, RETOUR }

var _etape_actuelle : Etape = Etape.ALBUM
var _parcours_ombre : bool  = false

@onready var calque_ui      : CanvasLayer = $UILayer
@onready var effet_glitch   : ColorRect   = $EffetGlitch   # visible=false au départ

func _ready() -> void:
	GameManager.jour_actuel = 3
	effet_glitch.visible    = false
	_lancer_etape(Etape.ALBUM)

func _lancer_etape(etape: Etape) -> void:
	_etape_actuelle = etape
	match etape:
		Etape.ALBUM  : _lancer_album()
		Etape.PUZZLE : _lancer_puzzle()
		Etape.REVE   : _choisir_reve()
		Etape.RETOUR : _retour()

# ── 1. Album photo ──────────────────────────────────────────
func _lancer_album() -> void:
	var minijeu = preload("res://scenes/minijeux/minijeu_album.tscn").instantiate()
	minijeu.minijeu_termine.connect(_on_album_termine)
	calque_ui.add_child(minijeu)

func _on_album_termine(succes: bool) -> void:
	var gain := 10 if GameManager.energie > 50 else 8
	if succes:
		GameManager.gagner_energie(gain)
	_lancer_etape(Etape.PUZZLE)

# ── 2. Puzzle ───────────────────────────────────────────────
func _lancer_puzzle() -> void:
	var minijeu = preload("res://scenes/minijeux/minijeu_puzzle.tscn").instantiate()
	minijeu.minijeu_termine.connect(_on_puzzle_termine)
	calque_ui.add_child(minijeu)

func _on_puzzle_termine(succes: bool) -> void:
	var gain := 10 if GameManager.energie > 50 else 7
	if succes:
		GameManager.gagner_energie(gain)
	_lancer_etape(Etape.REVE)

# ── 3. Bifurcation du rêve ──────────────────────────────────
func _choisir_reve() -> void:
	var zoom := _creer_zoom_bulle()
	calque_ui.add_child(zoom)
	await get_tree().create_timer(1.2).timeout

	if GameManager.energie > 50:
		# Parcours Lumière : niveau 3a
		_parcours_ombre = false
		SceneManager.aller_a("res://scenes/reves/reve_jour3_lumiere.tscn")
	else:
		# Parcours Ombre : niveau 3b
		_parcours_ombre = true
		SceneManager.aller_a("res://scenes/reves/reve_jour3_ombre.tscn")

# ── 4. Retour réalité ───────────────────────────────────────
func _retour() -> void:
	if _parcours_ombre:
		_activer_effets_ombre()
	GameManager.fin_de_nuit()

func _activer_effets_ombre() -> void:
	# Interface "glitche" — distorsion visuelle
	effet_glitch.visible = true
	effet_glitch.color   = Color(0.5, 0.0, 0.5, 0.15)
	var tw := create_tween().set_loops(4)
	tw.tween_property(effet_glitch, "color:a", 0.3, 0.1)
	tw.tween_property(effet_glitch, "color:a", 0.05, 0.1)

	# Battements de cœur si < 30%
	if GameManager.energie < 30:
		_jouer_battements()

func _jouer_battements() -> void:
	for i in range(3):
		await get_tree().create_timer(1.0).timeout
		var flash := ColorRect.new()
		flash.color = Color(0.8, 0.0, 0.0, 0.25)
		flash.set_anchors_preset(Control.PRESET_FULL_RECT)
		calque_ui.add_child(flash)
		var tw := create_tween()
		tw.tween_property(flash, "color:a", 0.0, 0.4)
		tw.tween_callback(flash.queue_free)

func _creer_zoom_bulle() -> Control:
	var ctrl := Control.new()
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.color = Color(0.48, 0.18, 0.75, 0.0) if GameManager.energie > 50 else Color(0.1, 0.0, 0.1, 0.0)
	ctrl.add_child(rect)
	var tw := ctrl.create_tween()
	tw.tween_property(rect, "color:a", 1.0, 1.0)
	return ctrl
