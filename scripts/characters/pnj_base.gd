extends Area2D

# ═══════════════════════════════════════════════════════════
# pnj_base.gd — Script de base pour tous les PNJ
# Attacher à : scenes/characters/pnj_*.tscn
# Noeuds requis :
#   - Sprite2D ou AnimatedSprite2D
#   - CollisionShape2D  (zone de détection)
#   - Label             (nommé LabelInteraction — ex: "[E] Parler")
# ═══════════════════════════════════════════════════════════

# ── À configurer dans l'Inspecteur pour chaque PNJ ─────────
@export var nom_pnj          : String = "PNJ"
@export var chemin_dialogue  : String = ""   # ex: "res://data/dialogues/mere_jour1.json"
@export var id_pnj           : String = ""   # ex: "mere", "amie", "maitresse"
@export var energie_donnee   : int    = 0    # énergie restaurée après dialogue

@onready var label_interaction : Label = $LabelInteraction

# ════════════════════════════════════════════════════════════
# PRÊT
# ════════════════════════════════════════════════════════════

func _ready() -> void:
	label_interaction.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	DialogueManager.dialogue_termine.connect(_on_dialogue_termine)

# ════════════════════════════════════════════════════════════
# ZONE DE DÉTECTION
# ════════════════════════════════════════════════════════════

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("joueur"):
		label_interaction.visible = true
		body.set_pnj_proche(self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("joueur"):
		label_interaction.visible = false
		body.clear_pnj_proche()

# ════════════════════════════════════════════════════════════
# DÉMARRER LE DIALOGUE
# ════════════════════════════════════════════════════════════

func demarrer_dialogue() -> void:
	if chemin_dialogue == "":
		push_warning("PNJ %s : aucun chemin de dialogue défini" % nom_pnj)
		return

	# Sélectionne le bon fichier selon le jour
	var chemin_final : String = _get_chemin_dialogue()
	DialogueManager.demarrer(chemin_final)

func _get_chemin_dialogue() -> String:
	# Cherche d'abord un dialogue spécifique au jour
	var chemin_jour : String = chemin_dialogue.replace(
		".json",
		"_jour%d.json" % GameManager.jour_actuel
	)
	if FileAccess.file_exists(chemin_jour):
		return chemin_jour
	# Sinon dialogue par défaut
	return chemin_dialogue

# ════════════════════════════════════════════════════════════
# APRÈS LE DIALOGUE
# ════════════════════════════════════════════════════════════

func _on_dialogue_termine() -> void:
	if energie_donnee > 0:
		GameManager.gagner_energie(energie_donnee)
	if id_pnj != "":
		GameManager.modifier_relation(id_pnj, 10)
