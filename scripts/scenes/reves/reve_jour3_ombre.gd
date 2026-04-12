extends Node2D

# ═══════════════════════════════════════════════════════════
# reve_jour3_ombre.gd — Nuit 3 Parcours Ombre
# "Galerie des Visages Vides"
# Perte : -35 pts en cas d'échec
# Certaines voix mentent — il faut trouver les vraies
# ═══════════════════════════════════════════════════════════

const PERTE_ECHEC  := 35
const DUREE_LIMITE := 75.0
const MAX_ERREURS  := 3   # au-delà, les portraits prennent les traits de Mara

@onready var champ_mot      : LineEdit = $UILayer/ChampMot
@onready var label_voix     : Label    = $UILayer/LabelVoix
@onready var label_feedback : Label    = $UILayer/LabelFeedback
@onready var label_timer    : Label    = $UILayer/LabelTimer
@onready var label_erreurs  : Label    = $UILayer/LabelErreurs

var _temps_restant : float = DUREE_LIMITE
var _resolu        : bool  = false
var _erreurs       : int   = 0
var _portraits_rendus: int = 0
const PORTRAITS_REQUIS := 4

# Voix : [texte affiché, mot attendu, c'est un mensonge?]
const VOIX := [
	["Je suis une mère… je veux mon… SOLEIL.", "soleil", false],
	["Donne-moi la NUIT, la nuit profonde…", "nuit", true],     # mensonge → donner "lumiere"
	["Je cherche mon… ENFANT.", "enfant", false],
	["Offre-moi l'OUBLI…", "oubli", true],                       # mensonge → donner "souvenir"
	["Je veux retrouver mon… SOURIRE.", "sourire", false],
]
const CORRECTIONS_MENSONGES := {"nuit": "lumiere", "oubli": "souvenir"}

var _voix_actuelle : int = 0

func _ready() -> void:
	champ_mot.text_submitted.connect(_on_mot_soumis)
	champ_mot.grab_focus()
	modulate = Color(0.7, 0.6, 0.8, 1.0)
	_afficher_voix()

func _process(delta: float) -> void:
	if _resolu: return
	_temps_restant -= delta
	var min := int(_temps_restant) / 60
	var sec := int(_temps_restant) % 60
	label_timer.text = "%d:%02d" % [min, sec]
	if _temps_restant <= 0.0:
		_boucle_ratee()

func _afficher_voix() -> void:
	if _voix_actuelle >= VOIX.size():
		_reussir()
		return
	var v := VOIX[_voix_actuelle]
	label_voix.text = "👁 « %s »" % v[0]

func _on_mot_soumis(mot: String) -> void:
	var mot_clean := mot.to_lower().strip_edges()
	champ_mot.text = ""
	if _voix_actuelle >= VOIX.size(): return

	var v := VOIX[_voix_actuelle]
	var est_mensonge : bool  = v[2]
	var mot_attendu  : String = v[1]
	var bonne_reponse: bool

	if est_mensonge:
		# Voix menteuse : il faut donner le contraire
		var correction : String = CORRECTIONS_MENSONGES.get(mot_attendu, "")
		bonne_reponse = (mot_clean == correction)
	else:
		bonne_reponse = (mot_clean == mot_attendu)

	if bonne_reponse:
		_portraits_rendus += 1
		label_feedback.text    = "✓ Portrait rendu (%d/%d)" % [_portraits_rendus, PORTRAITS_REQUIS]
		label_feedback.modulate = Color.GREEN
		GameManager.gagner_energie(4)
		_voix_actuelle += 1
		await get_tree().create_timer(0.8).timeout
		_afficher_voix()
	else:
		_erreurs += 1
		label_erreurs.text = "Erreurs : %d / %d" % [_erreurs, MAX_ERREURS]
		label_feedback.modulate = Color.RED
		GameManager.perdre_energie(8)

		if _erreurs >= MAX_ERREURS:
			# Les portraits prennent les traits de Mara
			label_feedback.text = "😱 Les portraits te ressemblent…"
			_effet_identite_perdue()
		else:
			label_feedback.text = "Cette voix ment peut-être…"

		await get_tree().create_timer(1.0).timeout
		label_feedback.modulate = Color.WHITE
		label_feedback.text = ""

func _effet_identite_perdue() -> void:
	# Effet visuel : teinte rouge, flash
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(0.9, 0.5, 0.5, 1.0), 0.3)
	tw.tween_property(self, "modulate", Color(0.7, 0.6, 0.8, 1.0), 0.5)

func _reussir() -> void:
	_resolu = true
	label_voix.text    = "Les portraits ont retrouvé leur visage."
	label_feedback.text = ""
	await get_tree().create_timer(1.5).timeout
	GameManager.fin_de_nuit()

func _boucle_ratee() -> void:
	GameManager.nouvelle_boucle()
	GameManager.perdre_energie(PERTE_ECHEC - 15)
	if GameManager.energie <= 0: return
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()
