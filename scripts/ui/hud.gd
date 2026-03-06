extends CanvasLayer

# ═══════════════════════════════════════════════════════════
# hud.gd
# Attacher à : scenes/ui/hud.tscn
# Structure de la scène :
#   CanvasLayer (racine — ce script)
#   └── Panel
#       ├── JaugeEnergie     (ProgressBar)
#       ├── LabelJour        (Label — "Jour X / 14")
#       ├── LabelEnergie     (Label — "Énergie : XX")
#       └── VignetteEcran    (ColorRect — coins sombres, modulate.a = 0 par défaut)
# ═══════════════════════════════════════════════════════════

@onready var jauge          : ProgressBar = $Panel/JaugeEnergie
@onready var label_jour     : Label       = $Panel/LabelJour
@onready var label_energie  : Label       = $Panel/LabelEnergie
@onready var vignette       : ColorRect   = $Panel/VignetteEcran

# Couleurs de la jauge selon l'énergie
const COULEUR_HAUTE   := Color("4CAF50")   # vert
const COULEUR_MOYENNE := Color("FF9800")   # orange
const COULEUR_BASSE   := Color("F44336")   # rouge

# ════════════════════════════════════════════════════════════
# PRÊT
# ════════════════════════════════════════════════════════════

func _ready() -> void:
	GameManager.energie_changee.connect(_on_energie_changee)
	GameManager.jour_change.connect(_on_jour_change)
	_actualiser()

# ════════════════════════════════════════════════════════════
# MISE À JOUR
# ════════════════════════════════════════════════════════════

func _actualiser() -> void:
	_on_energie_changee(GameManager.energie)
	_on_jour_change(GameManager.jour_actuel)

func _on_energie_changee(valeur: int) -> void:
	jauge.value        = valeur
	label_energie.text = "Énergie : %d" % valeur

	# Couleur de la jauge
	var style := jauge.get_theme_stylebox("fill") as StyleBoxFlat
	if style:
		if valeur > 60:
			style.bg_color = COULEUR_HAUTE
		elif valeur > 30:
			style.bg_color = COULEUR_MOYENNE
		else:
			style.bg_color = COULEUR_BASSE

	# Vignette de fatigue sur les bords de l'écran
	var intensite : float = (30.0 - valeur) / 30.0 if valeur < 30 else 0.0
	vignette.modulate.a = clamp(intensite * 0.6, 0.0, 0.6)

	# Battement de coeur (son) quand énergie critique
	if valeur <= 20:
		_activer_battement(true)
	else:
		_activer_battement(false)

func _on_jour_change(jour: int) -> void:
	label_jour.text = "Jour %d / 14" % jour

# ════════════════════════════════════════════════════════════
# EFFETS SONORES
# ════════════════════════════════════════════════════════════

var _battement_actif : bool = false

func _activer_battement(actif: bool) -> void:
	if _battement_actif == actif:
		return
	_battement_actif = actif
	if actif:
		_boucle_battement()

func _boucle_battement() -> void:
	if not _battement_actif:
		return
	# Joue le son de battement si le noeud existe
	if has_node("SonBattement"):
		$SonBattement.play()
	await get_tree().create_timer(1.2).timeout
	_boucle_battement()
