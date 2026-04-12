extends Control

# ═══════════════════════════════════════════════════════════
# minijeu_reveil.gd — "Réveille-toi !"
# Scène : res://scenes/minijeux/minijeu_reveil.tscn
#
# Règle : cliquer les étoiles dans l'ordre numéroté
#         avant que le timer expire
# Nœuds requis :
#   Control (racine, ce script)
#   ├── Label       (LabelConsigne)
#   ├── Label       (LabelTimer)
#   └── CanvasLayer → zone d'apparition des étoiles
# ═══════════════════════════════════════════════════════════

signal minijeu_termine(succes: bool)

const NB_ETOILES  := 5
const TEMPS_LIMITE := 8.0
const PERTE_J1    := 5   # réduction perte vie jour 1

@onready var label_consigne : Label = $LabelConsigne
@onready var label_timer    : Label = $LabelTimer

var _etoiles        : Array  = []
var _prochain_ordre : int    = 1
var _temps_restant  : float  = TEMPS_LIMITE
var _termine        : bool   = false

func _ready() -> void:
	label_consigne.text = "Clique les étoiles dans l'ordre !"
	_spawner_etoiles()

func _process(delta: float) -> void:
	if _termine: return
	_temps_restant -= delta
	label_timer.text = "%.1f" % max(0.0, _temps_restant)
	if _temps_restant <= 0.0:
		_echouer()

# ── Création des étoiles ─────────────────────────────────────
func _spawner_etoiles() -> void:
	var positions_utilisees : Array = []
	for i in range(1, NB_ETOILES + 1):
		var btn := Button.new()
		btn.text         = "★"
		btn.custom_minimum_size = Vector2(48, 48)

		# Position aléatoire non superposée
		var pos : Vector2
		var tentatives := 0
		while tentatives < 30:
			pos = Vector2(randf_range(60, 540), randf_range(80, 280))
			var trop_proche := false
			for p in positions_utilisees:
				if pos.distance_to(p) < 70:
					trop_proche = true
					break
			if not trop_proche:
				break
			tentatives += 1

		positions_utilisees.append(pos)
		btn.position = pos

		# Mémorise l'ordre pour le callback
		var ordre := i
		btn.pressed.connect(func(): _on_etoile_cliquee(ordre, btn))
		add_child(btn)
		_etoiles.append(btn)

		# Apparition progressive
		btn.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(btn, "modulate:a", 1.0, 0.3).set_delay(i * 0.15)

func _on_etoile_cliquee(ordre: int, btn: Button) -> void:
	if _termine: return
	if ordre == _prochain_ordre:
		# Bonne étoile
		btn.modulate = Color.YELLOW
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(1.4, 1.4), 0.15)
		tw.tween_property(btn, "modulate:a", 0.0, 0.2)
		tw.tween_callback(btn.queue_free)
		_etoiles.erase(btn)
		_prochain_ordre += 1
		if _prochain_ordre > NB_ETOILES:
			_reussir()
	else:
		# Mauvaise étoile — flash rouge + petite pénalité
		btn.modulate = Color.RED
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(btn):
			btn.modulate = Color.WHITE
		GameManager.perdre_energie(PERTE_J1)

func _reussir() -> void:
	_termine = true
	label_consigne.text = "Bien réveillée !"
	await get_tree().create_timer(0.8).timeout
	queue_free()
	minijeu_termine.emit(true)

func _echouer() -> void:
	_termine = true
	label_consigne.text = "Trop lente..."
	GameManager.perdre_energie(PERTE_J1)
	await get_tree().create_timer(0.8).timeout
	queue_free()
	minijeu_termine.emit(false)
