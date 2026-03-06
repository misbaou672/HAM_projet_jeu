extends Node2D

# ═══════════════════════════════════════════════════════════
# real_world.gd
# Attacher à : scenes/real_world.tscn
# Noeuds requis :
#   - HUD             (instance de scenes/ui/hud.tscn)
#   - DialogueBox     (instance de scenes/ui/dialogue_box.tscn)
#   - Mara            (instance de scenes/characters/mara.tscn)
#   - Camera2D        (sur Mara, limites à configurer)
#   - BoutonDormir    (TextureButton ou Area2D — pour aller au rêve)
#   - EffetHallucination (CanvasLayer avec shader, visible = false)
# ═══════════════════════════════════════════════════════════

@onready var effet_hallucination : CanvasLayer = $EffetHallucination
@onready var mara                : CharacterBody2D = $Mara

# ════════════════════════════════════════════════════════════
# PRÊT
# ════════════════════════════════════════════════════════════

func _ready() -> void:
	_appliquer_effets_fatigue()
	_configurer_limites_camera()

	# Sauvegarde automatique à chaque retour dans le monde réel
	_sauvegarder()

	# Message de réveil selon l'énergie
	if GameManager.jour_actuel > 1:
		_afficher_message_reveil()

# ════════════════════════════════════════════════════════════
# CHAQUE FRAME
# ════════════════════════════════════════════════════════════

func _process(_delta: float) -> void:
	_appliquer_effets_fatigue()

# ════════════════════════════════════════════════════════════
# EFFETS DE FATIGUE
# ════════════════════════════════════════════════════════════

func _appliquer_effets_fatigue() -> void:
	var e : int = GameManager.energie

	# Désaturation progressive du monde réel
	var sat : float = lerpf(0.0, 1.0, e / 100.0)
	RenderingServer.set_default_clear_color(
		Color(0.72, 0.75, 0.78).lerp(Color(0.5, 0.5, 0.5), 1.0 - sat)
	)

	# Hallucinations sous 30%
	if e < 30:
		effet_hallucination.visible = true
		var mat = effet_hallucination.get_child(0).material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("intensite", (30.0 - e) / 30.0)
		# Déclenche une hallucination aléatoire toutes les ~10 secondes
		if not $TimerHallucination.is_stopped():
			return
		$TimerHallucination.wait_time = randf_range(8.0, 14.0)
		$TimerHallucination.start()
	else:
		effet_hallucination.visible = false

# ════════════════════════════════════════════════════════════
# ALLER DORMIR → ENTRER DANS LE RÊVE
# ════════════════════════════════════════════════════════════

func _on_bouton_dormir_pressed() -> void:
	SceneManager.aller_au_reve(GameManager.jour_actuel)

# ════════════════════════════════════════════════════════════
# MESSAGES ET HALLUCINATIONS
# ════════════════════════════════════════════════════════════

func _afficher_message_reveil() -> void:
	var e : int = GameManager.energie
	var msg : String
	if e >= 70:
		msg = "Mara se réveille… le rêve s'efface doucement."
	elif e >= 40:
		msg = "Mara se réveille fatiguée. Ses paupières pèsent."
	elif e >= 20:
		msg = "Mara s'est réveillée en sursaut. Tout tourne."
	else:
		msg = "Mara ne sait plus si elle dort encore…"

	# Affiche un label flottant temporaire
	var label := Label.new()
	label.text = msg
	label.add_theme_font_size_override("font_size", 14)
	label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 3.0).set_delay(2.0)
	tween.tween_callback(label.queue_free)

func _on_timer_hallucination_timeout() -> void:
	# Fait apparaître brièvement une ombre ou forme étrange
	var hallucinations := ["ombre_murale", "visage_fenetre", "main_plafond"]
	var type : String = hallucinations[randi() % hallucinations.size()]
	var chemin : String = "res://scenes/ui/hallucinations/%s.tscn" % type
	if ResourceLoader.exists(chemin):
		var hallu = load(chemin).instantiate()
		add_child(hallu)

# ════════════════════════════════════════════════════════════
# CONFIGURATION CAMÉRA
# ════════════════════════════════════════════════════════════

func _configurer_limites_camera() -> void:
	var cam : Camera2D = mara.get_node("Camera2D")
	if cam:
		cam.limit_left   = 0
		cam.limit_top    = 0
		cam.limit_right  = 1920   # adapter à la largeur de votre scène
		cam.limit_bottom = 360

func _sauvegarder() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("partie","energie",GameManager.energie)
	cfg.set_value("partie","jour_actuel",GameManager.jour_actuel)
	cfg.set_value("partie","relations",GameManager.relation_pnj)
	cfg.save("user://reverie_save.cfg")
