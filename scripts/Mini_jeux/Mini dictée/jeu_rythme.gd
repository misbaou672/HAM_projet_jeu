extends Node2D

signal reussi
signal echoue

@onready var balle = $Balle
@onready var cible = $Cible

var vitesse_balle = 300.0
var balle_est_dans_cible = false
var jeu_fini = false

func _ready():
	# On demande à la cible de nous prévenir quand la balle entre ou sort de sa zone
	cible.area_entered.connect(_sur_balle_entree)
	cible.area_exited.connect(_sur_balle_sortie)

func _process(delta):
	# Si le jeu n'est pas fini, la balle avance vers la droite en continu
	if not jeu_fini:
		balle.position.x += vitesse_balle * delta
		
		# Si la balle sort de l'écran sans qu'on ait cliqué, c'est raté
		if balle.position.x > 1200: # À adapter selon la taille de ton écran
			jeu_fini = true
			emit_signal("echoue")

# La touche "Espace" (ui_accept) ou le Clic par défaut de Godot
func _input(event):
	if jeu_fini:
		return
		
	if event.is_action_pressed("ui_accept"):
		jeu_fini = true # Le joueur a pris sa décision, on arrête le jeu
		
		if balle_est_dans_cible:
			print("Parfait timing !")
			emit_signal("reussi")
		else:
			print("Trop tôt ou trop tard !")
			emit_signal("echoue")

# ---- Fonctions connectées aux signaux de la Cible ----
func _sur_balle_entree(area_qui_entre):
	if area_qui_entre == balle:
		balle_est_dans_cible = true

func _sur_balle_sortie(area_qui_sort):
	if area_qui_sort == balle:
		balle_est_dans_cible = false
