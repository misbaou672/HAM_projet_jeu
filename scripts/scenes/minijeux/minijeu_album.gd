extends Control

# ═══════════════════════════════════════════════════════════
# minijeu_album.gd — "Album Photo"
# Règle : identifier la vraie photo parmi 3 versions
#         (une normale, deux altérées/floues)
# 3 rounds. Bonne réponse = toujours l'index 0 après shuffle.
# ═══════════════════════════════════════════════════════════

signal minijeu_termine(succes: bool)

const ROUNDS := 3

@onready var label_consigne : Label        = $LabelConsigne
@onready var container      : HBoxContainer = $ContainerPhotos

var _round_actuel    : int  = 0
var _bonnes_reponses : int  = 0
var _bonne_index     : int  = 0
var _termine         : bool = false

func _ready() -> void:
	label_consigne.text = "Quelle photo est la vraie ?"
	_afficher_round()

func _afficher_round() -> void:
	if _round_actuel >= ROUNDS:
		_conclure()
		return

	for c in container.get_children():
		c.queue_free()

	# 3 boutons : 1 "vrai" + 2 "altérés"
	var descriptions := ["📷 Vraie photo", "📷 Floue…", "📷 Déformée"]
	descriptions.shuffle()
	_bonne_index = descriptions.find("📷 Vraie photo")

	for i in range(descriptions.size()):
		var btn := Button.new()
		btn.text = descriptions[i]
		btn.custom_minimum_size = Vector2(140, 100)
		var idx := i
		btn.pressed.connect(func(): _repondre(idx))
		container.add_child(btn)

func _repondre(index: int) -> void:
	if _termine: return
	if index == _bonne_index:
		_bonnes_reponses += 1
		label_consigne.modulate = Color.GREEN
		label_consigne.text = "Bien vu !"
	else:
		GameManager.perdre_energie(4)
		label_consigne.modulate = Color.RED
		label_consigne.text = "Ce n'est pas la vraie…"

	await get_tree().create_timer(0.6).timeout
	label_consigne.modulate = Color.WHITE
	label_consigne.text     = "Quelle photo est la vraie ?"
	_round_actuel += 1
	_afficher_round()

func _conclure() -> void:
	_termine = true
	var succes := _bonnes_reponses >= 2
	label_consigne.text = "✓ %d / %d" % [_bonnes_reponses, ROUNDS] if succes else "✗ %d / %d" % [_bonnes_reponses, ROUNDS]
	await get_tree().create_timer(0.8).timeout
	queue_free()
	minijeu_termine.emit(succes)
