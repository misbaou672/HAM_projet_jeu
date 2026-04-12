extends Node2D

# ═══════════════════════════════════════════════════════════
# reve_jour2_cirque.gd — Nuit 2 : Le Cirque sans Fin
# Scène : res://scenes/reves/reve_jour2_cirque.tscn
#
# Coût : -25 pts par boucle ratée
# Mot magique : "CABO" (ou d'autres)
# ═══════════════════════════════════════════════════════════

const PERTE_BOUCLE := 25
const DUREE_LIMITE := 60.0

@onready var champ_mot     : LineEdit = $UILayer/ChampMot
@onready var label_feedback: Label    = $UILayer/LabelFeedback
@onready var label_timer   : Label    = $UILayer/LabelTimer
@onready var manege        : Node2D   = $Manege

var _temps_restant : float = DUREE_LIMITE
var _resolu        : bool  = false
var _vitesse_manege: float = 60.0   # degrés/seconde

# Mots qui fonctionnent
const MOTS_MAGIQUES := ["cabo", "dors", "stop", "arret", "arrêt", "pause", "fige", "calme"]

func _ready() -> void:
	champ_mot.text_submitted.connect(_on_mot_soumis)
	champ_mot.grab_focus()

func _process(delta: float) -> void:
	if _resolu: return

	# Le manège tourne de plus en plus vite
	_vitesse_manege += delta * 5.0
	if is_instance_valid(manege):
		manege.rotation_degrees += _vitesse_manege * delta

	_temps_restant -= delta
	var min := int(_temps_restant) / 60
	var sec := int(_temps_restant) % 60
	label_timer.text = "%d:%02d" % [min, sec]

	if _temps_restant <= 0.0:
		_boucle_ratee()

func _on_mot_soumis(mot: String) -> void:
	var mot_clean := mot.to_lower().strip_edges()
	champ_mot.text = ""

	if mot_clean in MOTS_MAGIQUES:
		_arreter_manege()
	else:
		label_feedback.text = "Ce mot ne fonctionne pas ici…"
		label_feedback.modulate = Color.RED
		GameManager.perdre_energie(3)
		await get_tree().create_timer(1.0).timeout
		label_feedback.modulate = Color.WHITE
		label_feedback.text = ""

func _arreter_manege() -> void:
	_resolu = true
	label_feedback.text    = "✨ Le manège s'endort…"
	label_feedback.modulate = Color.GREEN
	_vitesse_manege = 0.0

	# Animation d'arrêt progressif
	if is_instance_valid(manege):
		var tw := create_tween()
		tw.tween_property(manege, "rotation_degrees",
			manege.rotation_degrees, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(2.0).timeout
	GameManager.fin_de_nuit()

func _boucle_ratee() -> void:
	GameManager.nouvelle_boucle()
	GameManager.perdre_energie(PERTE_BOUCLE - 15)   # -15 déjà prélevés par nouvelle_boucle
	if GameManager.energie <= 0:
		return
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()
