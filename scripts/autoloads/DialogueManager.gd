extends Node

# ═══════════════════════════════════════════════════════════
# DialogueManager.gd — AUTOLOAD
# Déclarer dans : Projet > Paramètres > Autoload > Nom : DialogueManager
# Gère les dialogues PNJ depuis n'importe quelle scène
# ═══════════════════════════════════════════════════════════

signal dialogue_termine
signal choix_fait(index: int, donnees: Dictionary)

var _boite_active : Node = null
var dialogue_en_cours : bool = false

# ════════════════════════════════════════════════════════════
# DÉMARRER UN DIALOGUE
# ════════════════════════════════════════════════════════════
# Utilisation :
#   DialogueManager.demarrer("res://data/dialogues/mere_jour1.json")

func demarrer(chemin_json: String) -> void:
	if dialogue_en_cours:
		return

	# Charge les données JSON
	var fichier = FileAccess.open(chemin_json, FileAccess.READ)
	if not fichier:
		push_error("DialogueManager : fichier introuvable → " + chemin_json)
		return

	var donnees = JSON.parse_string(fichier.get_as_text())
	fichier.close()

	if donnees == null:
		push_error("DialogueManager : JSON invalide → " + chemin_json)
		return

	dialogue_en_cours = true

	# Trouve la boîte de dialogue dans la scène active
	_boite_active = get_tree().get_first_node_in_group("dialogue_ui")
	if not _boite_active:
		push_error("DialogueManager : aucun noeud dans le groupe 'dialogue_ui'")
		return

	_boite_active.afficher(donnees)

func terminer() -> void:
	dialogue_en_cours = false
	_boite_active     = null
	emit_signal("dialogue_termine")
