extends Node2D

# ═══════════════════════════════════════════════════════════
# jour_2.gd — Jour 2 : Devoirs et Détente
# Scène : res://scenes/jours/jour_2.tscn
#
# Séquence :
#   1. Mini dictée illustrée (classe)
#   2. Jeu de balle récréation
#   3. Rêve : Cirque sans Fin
#   4. BIFURCATION MINUIT : energie > 50 → parcours lumière
#                           energie ≤ 50 → parcours ombre
# ═══════════════════════════════════════════════════════════

enum Etape { DICTEE, BALLE, REVE, RETOUR }

var _etape_actuelle : Etape = Etape.DICTEE

@onready var calque_ui : CanvasLayer = $UILayer

func _ready() -> void:
	GameManager.jour_actuel = 2
	_lancer_etape(Etape.DICTEE)

func _lancer_etape(etape: Etape) -> void:
	_etape_actuelle = etape
	match etape:
		Etape.DICTEE  : _lancer_dictee()
		Etape.BALLE   : _lancer_jeu_balle()
		Etape.REVE    : _entrer_reve()
		Etape.RETOUR  : _fin_nuit()

# ── 1. Mini dictée ──────────────────────────────────────────
func _lancer_dictee() -> void:
	var minijeu = preload("res://scenes/minijeux/minijeu_dictee.tscn").instantiate()
	minijeu.minijeu_termine.connect(_on_dictee_termine)
	calque_ui.add_child(minijeu)

func _on_dictee_termine(succes: bool) -> void:
	if succes:
		GameManager.gagner_energie(8)
	_lancer_etape(Etape.BALLE)

# ── 2. Jeu de balle ─────────────────────────────────────────
func _lancer_jeu_balle() -> void:
	var minijeu = preload("res://scenes/minijeux/minijeu_balle.tscn").instantiate()
	minijeu.minijeu_termine.connect(_on_balle_termine)
	calque_ui.add_child(minijeu)

func _on_balle_termine(succes: bool) -> void:
	if succes:
		# Bonus cumulé si les deux mini-jeux réussis
		GameManager.gagner_energie(7)   # total +15 avec la dictée
	_lancer_etape(Etape.REVE)

# ── 3. Rêve : Cirque sans Fin ───────────────────────────────
func _entrer_reve() -> void:
	var zoom := _creer_zoom_bulle()
	calque_ui.add_child(zoom)
	await get_tree().create_timer(1.2).timeout
	SceneManager.aller_au_reve(2)   # niveau_2 = Cirque

# ── 4. Retour + bifurcation ─────────────────────────────────
func _fin_nuit() -> void:
	# Bifurcation jour 4 : GameManager garde l'info via jour_actuel
	# Le GameManager.fin_de_nuit() incrémente le jour et charge real_world
	# La scène real_world ou jour_3 vérifiera energie > 50
	GameManager.fin_de_nuit()

func _creer_zoom_bulle() -> Control:
	var ctrl := Control.new()
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	var rect := ColorRect.new()
	rect.color = Color(0.48, 0.18, 0.75, 0.0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.add_child(rect)
	var tw := ctrl.create_tween()
	tw.tween_property(rect, "color:a", 1.0, 1.0)
	return ctrl
