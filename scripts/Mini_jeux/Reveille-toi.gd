extends Node2D

# --- SIGNAUX PERSONNALISÉS ---
# Ils permettent de dire au jeu principal : "C'est gagné !" ou "C'est perdu !"
signal reussi
signal echoue

# --- VARIABLES ---
@onready var boutons = [$Etoile1, $Etoile2, $Etoile3]
@onready var timer = $TimerAffichage

var sequence_a_reproduire = []
var index_joueur = 0
var interaction_active = false # Empêche le joueur de cliquer pendant l'animation

func _ready():
	# On connecte les clics des boutons par le code (plus simple pour vous !)
	for i in range(boutons.size()):
		# On lie chaque bouton à la fonction de clic, en lui passant son numéro (0, 1 ou 2)
		boutons[i].pressed.connect(_sur_etoile_cliquee.bind(i))
	
	# On lance le jeu après 1 seconde
	await get_tree().create_timer(1.0).timeout
	lancer_nouvelle_sequence()

# --- LOGIQUE ---
func lancer_nouvelle_sequence():
	interaction_active = false
	index_joueur = 0
	
	# Choisit une étoile au hasard (0, 1 ou 2) et l'ajoute à la séquence
	var nouvelle_etoile = randi() % boutons.size()
	sequence_a_reproduire.append(nouvelle_etoile)
	
	montrer_sequence()

func montrer_sequence():
	# Fait clignoter les étoiles une par une
	for id_etoile in sequence_a_reproduire:
		var btn = boutons[id_etoile]
		# On "allume" l'étoile (on simule qu'elle est désactivée visuellement)
		btn.modulate = Color(1, 0, 0) # Devient rouge (ou la couleur que tu veux)
		timer.start(0.5)
		await timer.timeout # On attend 0.5 sec
		btn.modulate = Color(1, 1, 1) # Retour à la normale
		timer.start(0.2)
		await timer.timeout # Petite pause entre deux étoiles
		
	# À la fin, c'est au joueur !
	interaction_active = true

func _sur_etoile_cliquee(id_etoile: int):
	# Si ce n'est pas le tour du joueur, on ignore le clic
	if not interaction_active:
		return
		
	# Vérifie si l'étoile cliquée est la bonne
	if id_etoile == sequence_a_reproduire[index_joueur]:
		index_joueur += 1
		# A-t-il fini la séquence actuelle ?
		if index_joueur == sequence_a_reproduire.size():
			if sequence_a_reproduire.size() == 3: # Gagne après 3 tours réussis
				print("Victoire totale !")
				emit_signal("reussi")
			else:
				# Passe au tour suivant
				await get_tree().create_timer(1.0).timeout
				lancer_nouvelle_sequence()
	else:
		# Mauvaise étoile !
		print("Erreur !")
		emit_signal("echoue")
		sequence_a_reproduire.clear() # On vide la liste pour recommencer
