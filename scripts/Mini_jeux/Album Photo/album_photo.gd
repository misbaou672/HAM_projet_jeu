extends Control

# Signaux pour le GameManager
signal reussi
signal echoue

# On définit quel bouton est le bon (0 pour le premier, 1 pour le deuxième, etc.)
# @export permet de changer ce chiffre directement dans l'inspecteur Godot !
@export var index_bonne_photo : int = 0

@onready var conteneur = $CenterContainer/HBoxContainer

func _ready():
	# On parcourt tous les boutons pour les connecter
	var photos = conteneur.get_children()
	for i in range(photos.size()):
		# On connecte le clic et on envoie le numéro de la photo
		photos[i].pressed.connect(_sur_photo_cliquee.bind(i))

func _sur_photo_cliquee(index_choisi: int):
	if index_choisi == index_bonne_photo:
		print("Bravo ! C'est le bon souvenir.")
		emit_signal("reussi")
		desactiver_tout()
	else:
		print("Ce n'est qu'un faux souvenir...")
		emit_signal("echoue")

func desactiver_tout():
	for photo in conteneur.get_children():
		photo.disabled = true
