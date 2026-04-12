extends Node2D

# ═══════════════════════════════════════════════════════════
# jour_1.gd — Jour 1 : Réveil et Préparation
# Scène : res://scenes/jours/jour_1.tscn
#
# Séquence :
#   1. Réveil → mini-jeu "Réveille-toi !" (étoiles)
#   2. Dialogue avec maman
#   3. Mini-jeu "Petit déjeuner" (drag & drop)
#   4. Transition vers l'école → rêve (Maison à l'envers)
#   5. Retour réalité → fin de journée
# ═══════════════════════════════════════════════════════════

enum Etape { REVEIL, DIALOGUE_MAMAN, PETIT_DEJ, ECOLE, REVE, RETOUR }

var _etape_actuelle : Etape = Etape.REVEIL

@onready var calque_ui : CanvasLayer = $UILayer

func _ready() -> void:
	# Jour 1 : énergie initiale à 70
	GameManager.energie = 70
	GameManager.jour_actuel = 1
	GameManager.dans_reve   = false
	_lancer_etape(Etape.REVEIL)

# ════════════════════════════════════════════════════════════
func _lancer_etape(etape: Etape) -> void:
	_etape_actuelle = etape
	match etape:
		Etape.REVEIL         : _lancer_minijeu_reveil()
		Etape.DIALOGUE_MAMAN : _lancer_dialogue_maman()
		Etape.PETIT_DEJ      : _lancer_minijeu_petit_dej()
		Etape.ECOLE          : _aller_ecole()
		Etape.REVE           : _entrer_reve()
		Etape.RETOUR         : _retour_maison()

# ── 1. Mini-jeu réveil ──────────────────────────────────────
func _lancer_minijeu_reveil() -> void:
	var minijeu = preload("res://scenes/minijeux/minijeu_reveil.tscn").instantiate()
	minijeu.minijeu_termine.connect(_on_reveil_termine)
	calque_ui.add_child(minijeu)

func _on_reveil_termine(succes: bool) -> void:
	if succes:
		GameManager.gagner_energie(5)
	_lancer_etape(Etape.DIALOGUE_MAMAN)

# ── 2. Dialogue maman ───────────────────────────────────────
func _lancer_dialogue_maman() -> void:
	DialogueManager.dialogue_termine.connect(_on_dialogue_maman_termine, CONNECT_ONE_SHOT)
	DialogueManager.demarrer("res://data/dialogues/mere_jour1.json")

func _on_dialogue_maman_termine() -> void:
	_lancer_etape(Etape.PETIT_DEJ)

# ── 3. Mini-jeu petit déjeuner ──────────────────────────────
func _lancer_minijeu_petit_dej() -> void:
	var minijeu = preload("res://scenes/minijeux/minijeu_petit_dej.tscn").instantiate()
	minijeu.minijeu_termine.connect(_on_petit_dej_termine)
	calque_ui.add_child(minijeu)

func _on_petit_dej_termine(succes: bool) -> void:
	if succes:
		GameManager.gagner_energie(8)
	_lancer_etape(Etape.ECOLE)

# ── 4. Aller à l'école ──────────────────────────────────────
func _aller_ecole() -> void:
	# Transition vers la salle de classe, puis rêve automatique
	await get_tree().create_timer(0.5).timeout
	_lancer_etape(Etape.REVE)

# ── 5. Entrer dans le rêve (Maison à l'envers) ─────────────
func _entrer_reve() -> void:
	# Zoom bulle de rêve
	var zoom_anim = _creer_zoom_bulle()
	calque_ui.add_child(zoom_anim)
	await get_tree().create_timer(1.2).timeout
	SceneManager.aller_au_reve(1)   # niveau_1 = Maison à l'envers

# ── 6. Retour maison ────────────────────────────────────────
func _retour_maison() -> void:
	GameManager.fin_de_nuit()

# ── Utilitaire : animation zoom bulle ──────────────────────
func _creer_zoom_bulle() -> Control:
	var ctrl := Control.new()
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	var cercle := ColorRect.new()
	cercle.color = Color(0.48, 0.18, 0.75, 0.0)
	cercle.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.add_child(cercle)
	var tw := ctrl.create_tween()
	tw.tween_property(cercle, "color:a", 1.0, 1.0)
	return ctrl
