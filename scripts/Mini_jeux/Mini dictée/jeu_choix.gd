extends Control

signal reussi
signal echoue

@onready var boutons = [
	$ConteneurBoutons/Reponse1, 
	$ConteneurBoutons/Reponse2, 
	$ConteneurBoutons/Reponse3
]

# On définit la réponse attendue (ici, le bouton n°1 "Un robot" - index 1)
var index_bonne_reponse = 1 

func _ready():
	# On connecte tous les boutons
	for i in range(boutons.size()):
		boutons[i].pressed.connect(_sur_reponse_choisie.bind(i))

func _sur_reponse_choisie(index_clique: int):
	# On désactive tous les boutons pour empêcher de cliquer plusieurs fois
	for btn in boutons:
		btn.disabled = true
		
	if index_clique == index_bonne_reponse:
		print("Bonne réponse !")
		emit_signal("reussi")
	else:
		print("Mauvaise réponse...")
		emit_signal("echoue")	
