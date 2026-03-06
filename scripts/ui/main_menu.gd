extends Control

# ═══════════════════════════════════════════════════════════
# main_menu.gd
# Attacher à : scenes/ui/main_menu.tscn
# Structure de la scène :
#   Control (racine)
#   └── VBoxContainer
#       ├── TitreLabel       (Label — "REVERIE")
#       ├── BoutonJouer      (Button)
#       ├── BoutonContinuer  (Button)
#       └── BoutonQuitter    (Button)
# ═══════════════════════════════════════════════════════════

@onready var btn_jouer     : Button = $VBoxContainer/BoutonJouer
@onready var btn_continuer : Button = $VBoxContainer/BoutonContinuer
@onready var btn_quitter   : Button = $VBoxContainer/BoutonQuitter

const SAVE_PATH := "user://reverie_save.cfg"

# ════════════════════════════════════════════════════════════
# PRÊT
# ════════════════════════════════════════════════════════════

func _ready() -> void:
	btn_jouer.pressed.connect(_on_jouer)
	btn_continuer.pressed.connect(_on_continuer)
	btn_quitter.pressed.connect(_on_quitter)

	# Continuer disponible seulement si une sauvegarde existe
	btn_continuer.disabled = not FileAccess.file_exists(SAVE_PATH)

	# Animation d'apparition du titre
	$VBoxContainer.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property($VBoxContainer, "modulate:a", 1.0, 1.2)

# ════════════════════════════════════════════════════════════
# BOUTONS
# ════════════════════════════════════════════════════════════

func _on_jouer() -> void:
	_reinitialiser_partie()
	SceneManager.aller_a("res://scenes/real_world.tscn")

func _on_continuer() -> void:
	_charger_sauvegarde()
	SceneManager.aller_a("res://scenes/real_world.tscn")

func _on_quitter() -> void:
	get_tree().quit()

# ════════════════════════════════════════════════════════════
# SAUVEGARDE
# ════════════════════════════════════════════════════════════

func _reinitialiser_partie() -> void:
	GameManager.energie      = 100
	GameManager.jour_actuel  = 1
	GameManager.dans_reve    = false
	GameManager.boucle_actuelle = 1
	GameManager.infos_reve.clear()
	for pnj in GameManager.relation_pnj:
		GameManager.relation_pnj[pnj] = 50

func _charger_sauvegarde() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	GameManager.energie     = cfg.get_value("partie", "energie",     100)
	GameManager.jour_actuel = cfg.get_value("partie", "jour_actuel", 1)
	var relations : Dictionary = cfg.get_value("partie", "relations", {})
	for pnj in relations:
		GameManager.relation_pnj[pnj] = relations[pnj]

static func sauvegarder() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("partie", "energie",     GameManager.energie)
	cfg.set_value("partie", "jour_actuel", GameManager.jour_actuel)
	cfg.set_value("partie", "relations",   GameManager.relation_pnj)
	cfg.save(SAVE_PATH)
