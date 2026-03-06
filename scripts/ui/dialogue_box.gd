extends Control

# ═══════════════════════════════════════════════════════════
# dialogue_box.gd
# Attacher à : scenes/ui/dialogue_box.tscn
# Ajouter ce noeud au groupe "dialogue_ui" dans Godot
#
# Structure de la scène :
#   Control (racine — ce script)
#   └── Panel
#       ├── Portrait         (TextureRect  — photo du PNJ)
#       ├── NomLabel         (Label        — nom du PNJ)
#       ├── TexteLabel       (RichTextLabel — le texte)
#       └── ChoixContainer   (VBoxContainer — boutons de choix)
# ═══════════════════════════════════════════════════════════

@onready var portrait        : TextureRect   = $Panel/Portrait
@onready var nom_label       : Label         = $Panel/NomLabel
@onready var texte_label     : RichTextLabel = $Panel/TexteLabel
@onready var choix_container : VBoxContainer = $Panel/ChoixContainer

var _donnees         : Dictionary = {}
var _ligne_actuelle  : int        = 0
var _tween_texte     : Tween      = null
var _texte_complet   : bool       = false  # true quand la machine à écrire est finie

# ════════════════════════════════════════════════════════════
# PRÊT
# ════════════════════════════════════════════════════════════

func _ready() -> void:
	add_to_group("dialogue_ui")
	visible = false

# ════════════════════════════════════════════════════════════
# AFFICHER UN DIALOGUE
# ════════════════════════════════════════════════════════════

func afficher(donnees: Dictionary) -> void:
	_donnees        = donnees
	_ligne_actuelle = 0
	visible         = true
	_afficher_ligne(0)

func _afficher_ligne(index: int) -> void:
	var lignes : Array = _donnees.get("lignes", [])
	if index >= lignes.size():
		_fermer()
		return

	var ligne : Dictionary = lignes[index]

	# Portrait
	var chemin_portrait : String = ligne.get("portrait", _donnees.get("portrait", ""))
	if chemin_portrait != "" and ResourceLoader.exists(chemin_portrait):
		portrait.texture = load(chemin_portrait)
		portrait.visible  = true
	else:
		portrait.visible  = false

	# Nom
	nom_label.text = ligne.get("nom", _donnees.get("nom_pnj", ""))

	# Texte — effet machine à écrire
	_texte_complet = false
	var texte : String = ligne.get("texte", "")
	texte_label.text   = ""

	if _tween_texte:
		_tween_texte.kill()

	_tween_texte = create_tween()
	_tween_texte.tween_method(
		func(n: int) -> void: texte_label.text = texte.substr(0, n),
		0, texte.length(),
		texte.length() * 0.04   # 40ms par caractère
	)
	_tween_texte.tween_callback(func() -> void: _texte_complet = true)

	# Vider les choix précédents
	for enfant in choix_container.get_children():
		enfant.queue_free()

	# Afficher les choix si présents
	var choix : Array = ligne.get("choix", [])
	if choix.is_empty():
		choix_container.visible = false
	else:
		# Les choix s'affichent après la machine à écrire
		await _tween_texte.finished
		choix_container.visible = true
		for i in choix.size():
			_creer_bouton_choix(choix[i], i)

# ════════════════════════════════════════════════════════════
# AVANCER DANS LE DIALOGUE (clic / touche)
# ════════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not event.is_action_pressed("ui_accept"):
		return

	# Si la machine à écrire tourne encore → affiche tout d'un coup
	if not _texte_complet:
		if _tween_texte:
			_tween_texte.kill()
		var lignes : Array = _donnees.get("lignes", [])
		texte_label.text = lignes[_ligne_actuelle].get("texte", "")
		_texte_complet   = true
		return

	# Pas de choix → ligne suivante automatique
	if choix_container.get_child_count() == 0:
		_ligne_actuelle += 1
		_afficher_ligne(_ligne_actuelle)

# ════════════════════════════════════════════════════════════
# BOUTONS DE CHOIX
# ════════════════════════════════════════════════════════════

func _creer_bouton_choix(choix: Dictionary, _index: int) -> void:
	var btn : Button = Button.new()
	btn.text = choix.get("texte", "…")
	btn.pressed.connect(func() -> void: _choisir(choix))
	choix_container.add_child(btn)

func _choisir(choix: Dictionary) -> void:
	# Effets du choix
	var gain_energie : int = choix.get("energie", 0)
	if gain_energie > 0:
		GameManager.gagner_energie(gain_energie)
	elif gain_energie < 0:
		GameManager.perdre_energie(-gain_energie)

	var delta_relation : int = choix.get("relation", 0)
	var id_pnj : String = _donnees.get("id_pnj", "")
	if delta_relation != 0 and id_pnj != "":
		GameManager.modifier_relation(id_pnj, delta_relation)

	# Navigation
	var suite : int = choix.get("suite", -1)
	if suite == -1:
		_fermer()
	else:
		_ligne_actuelle = suite
		_afficher_ligne(_ligne_actuelle)

# ════════════════════════════════════════════════════════════
# FERMER
# ════════════════════════════════════════════════════════════

func _fermer() -> void:
	visible = false
	DialogueManager.terminer()
