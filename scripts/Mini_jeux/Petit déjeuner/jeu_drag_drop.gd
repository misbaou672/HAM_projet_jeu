extends Node2D

signal reussi
signal echoue

@onready var objet = $ObjetGlissant
@onready var cible = $ZoneCible

var est_en_train_de_glisser = false

func _ready():
	# On demande à l'objet de nous prévenir s'il est cliqué avec la souris
	objet.input_event.connect(_sur_objet_input)

func _process(_delta):
	# Si l'objet est attrapé, il suit la souris en permanence
	if est_en_train_de_glisser:
		objet.global_position = get_global_mouse_position()

# Fonction appelée quand la souris interagit avec l'ObjetGlissant
func _sur_objet_input(_viewport, event, _shape_idx):
	# Si c'est un clic de souris
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Le joueur vient de cliquer -> On attrape l'objet
				est_en_train_de_glisser = true
			else:
				# Le joueur relâche le clic -> On lâche l'objet
				est_en_train_de_glisser = false
				verifier_victoire()

func verifier_victoire():
	# get_overlapping_areas() nous donne toutes les zones que l'objet touche actuellement
	var zones_touchees = objet.get_overlapping_areas()
	
	if cible in zones_touchees:
		print("Objet bien placé !")
		objet.global_position = cible.global_position # Centre l'objet sur la cible
		emit_signal("reussi")
		# Désactive l'objet pour qu'on ne puisse plus le bouger
		objet.input_pickable = false 
	else:
		print("Lâché au mauvais endroit !")
		emit_signal("echoue")
		# Optionnel : le faire revenir à sa position de départ ici
