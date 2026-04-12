extends Node2D

# ═══════════════════════════════════════════════════════════
# reve_jour3_lumiere.gd — Nuit 3 Parcours Lumière
# "L'Océan Renversé" — style Ghibli
# Perte : -30 pts en cas d'échec
# Mots : "bateau", "nuage", "voler", "nager", "poisson"
# ═══════════════════════════════════════════════════════════

const PERTE_ECHEC := 30
const DUREE_LIMITE := 90.0
const MOTS_VALIDES := ["bateau", "nuage", "bateau-nuage", "voler", "nager", "poisson", "etoile", "étoile"]

@onready var champ_mot     : LineEdit = $UILayer/ChampMot
@onready var label_feedback: Label    = $UILayer/LabelFeedback
@onready var label_timer   : Label    = $UILayer/LabelTimer
@onready var mara          : Node2D   = $Mara
@onready var ocean_haut    : Node2D   = $OceanHaut   # l'océan inversé en haut de l'écran

var _temps_restant   : float = DUREE_LIMITE
var _resolu          : bool  = false
var _poissons_trouves: int   = 0
const POISSONS_REQUIS := 3

func _ready() -> void:
	champ_mot.text_submitted.connect(_on_mot_soumis)
	champ_mot.grab_focus()
	# Ambiance lumineuse — teinte bleue/dorée
	modulate = Color(0.9, 0.95, 1.1, 1.0)

func _process(delta: float) -> void:
	if _resolu: return
	_temps_restant -= delta
	var min := int(_temps_restant) / 60
	var sec := int(_temps_restant) % 60
	label_timer.text = "%d:%02d" % [min, sec]
	if _temps_restant <= 0.0:
		_boucle_ratee()

func _on_mot_soumis(mot: String) -> void:
	var mot_clean := mot.to_lower().strip_edges()
	champ_mot.text = ""
	if mot_clean in MOTS_VALIDES:
		_effet_mot(mot_clean)
	else:
		label_feedback.text    = "Ce mot ne flotte pas ici…"
		label_feedback.modulate = Color.ORANGE
		GameManager.perdre_energie(2)
		await get_tree().create_timer(1.0).timeout
		label_feedback.text    = ""

func _effet_mot(mot: String) -> void:
	match mot:
		"bateau", "bateau-nuage":
			_construire_bateau()
		"poisson", "etoile", "étoile":
			_trouver_poisson()
		_:
			_voler()

func _construire_bateau() -> void:
	label_feedback.text    = "☁️ Un bateau-nuage apparaît !"
	label_feedback.modulate = Color.CYAN
	GameManager.gagner_energie(5)
	# Mara peut maintenant atteindre l'océan en haut
	if is_instance_valid(mara):
		var tw := create_tween()
		tw.tween_property(mara, "position:y", 40.0, 2.0).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(2.0).timeout
	_reussir()

func _trouver_poisson() -> void:
	_poissons_trouves += 1
	label_feedback.text    = "🐟 Poisson-étoile trouvé ! (%d/%d)" % [_poissons_trouves, POISSONS_REQUIS]
	label_feedback.modulate = Color.YELLOW
	if _poissons_trouves >= POISSONS_REQUIS:
		await get_tree().create_timer(0.5).timeout
		_construire_bateau()

func _voler() -> void:
	label_feedback.text    = "✨ Mara s'élève légèrement…"
	label_feedback.modulate = Color.WHITE
	GameManager.gagner_energie(3)

func _reussir() -> void:
	_resolu = true
	label_feedback.text    = "🌊 Mara rejoint l'océan renversé !"
	await get_tree().create_timer(1.5).timeout
	GameManager.fin_de_nuit()

func _boucle_ratee() -> void:
	GameManager.nouvelle_boucle()
	GameManager.perdre_energie(PERTE_ECHEC - 15)
	if GameManager.energie <= 0: return
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()
