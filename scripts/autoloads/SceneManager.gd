extends Node

# ═══════════════════════════════════════════════════════════
# SceneManager.gd — AUTOLOAD
# Déclarer dans : Projet > Paramètres > Autoload > Nom : SceneManager
# Gère toutes les transitions entre scènes avec fondu
# ═══════════════════════════════════════════════════════════

# Chemin vers la scène de transition (overlay noir)
const TRANSITION_SCENE = "res://scenes/ui/transition.tscn"

var _en_transition : bool = false

# ════════════════════════════════════════════════════════════
# NAVIGATION
# ════════════════════════════════════════════════════════════

func aller_a(chemin: String) -> void:
	if _en_transition:
		return
	_en_transition = true
	_transition_vers(chemin)

func aller_au_reve(numero_niveau: int) -> void:
	GameManager.dans_reve    = true
	GameManager.boucle_actuelle = 1
	var chemin = "res://scenes/dream_world/niveau_%d.tscn" % numero_niveau
	aller_a(chemin)

func revenir_realite() -> void:
	GameManager.dans_reve = false
	aller_a("res://scenes/real_world.tscn")

# ════════════════════════════════════════════════════════════
# TRANSITION AVEC FONDU
# ════════════════════════════════════════════════════════════

func _transition_vers(chemin: String) -> void:
	# Crée l'overlay de transition par-dessus tout
	var overlay = ColorRect.new()
	overlay.color         = Color.BLACK
	overlay.modulate.a    = 0.0
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	var canvas = CanvasLayer.new()
	canvas.layer = 100          # toujours devant tout
	canvas.add_child(overlay)
	get_tree().root.add_child(canvas)

	# Fondu au noir
	var tween = canvas.create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.4)
	await tween.finished

	# Change la scène
	get_tree().change_scene_to_file(chemin)
	await get_tree().process_frame
	await get_tree().process_frame

	# Fondu depuis le noir
	var tween2 = canvas.create_tween()
	tween2.tween_property(overlay, "modulate:a", 0.0, 0.4)
	await tween2.finished

	canvas.queue_free()
	_en_transition = false
