extends Node

# ═══════════════════════════════════════════════════════════
# GameManager.gd — AUTOLOAD
# Déclarer dans : Projet > Paramètres > Autoload > Nom : GameManager
# ═══════════════════════════════════════════════════════════

# ── État global de la partie ────────────────────────────────
var energie      : int  = 100   # 0 à 100
var jour_actuel  : int  = 1     # 1 à 14
var dans_reve    : bool = false
var boucle_actuelle : int = 1   # nombre de fois qu'on a recommencé le rêve
var infos_reve   : Dictionary = {}  # indices trouvés, persistent entre boucles

# ── Relations PNJ (0 = neutre, 100 = max confiance) ─────────
var relation_pnj : Dictionary = {
	"mere"    : 50,
	"amie"    : 50,
	"maitresse": 30,
	"voisin"  : 20,
}

# ── Seuils des fins ─────────────────────────────────────────
const SEUIL_FIN_LUMIERE  = 100   # énergie exactement à 100 → bonne fin
const SEUIL_FIN_GRISE    = 30    # 30–99 → fin grise
# en dessous de 30 → fin horreur

# ── Signaux ─────────────────────────────────────────────────
signal energie_changee(nouvelle_valeur: int)
signal jour_change(nouveau_jour: int)
signal partie_terminee(type_fin: String)

# ════════════════════════════════════════════════════════════
# ÉNERGIE
# ════════════════════════════════════════════════════════════

func perdre_energie(montant: int) -> void:
	energie = max(0, energie - montant)
	emit_signal("energie_changee", energie)
	_verifier_game_over()

func gagner_energie(montant: int) -> void:
	energie = min(100, energie + montant)
	emit_signal("energie_changee", energie)

func _verifier_game_over() -> void:
	if energie <= 0:
		declencher_fin()

# ════════════════════════════════════════════════════════════
# PROGRESSION
# ════════════════════════════════════════════════════════════

func nouvelle_boucle() -> void:
	boucle_actuelle += 1
	perdre_energie(15)

func fin_de_nuit() -> void:
	dans_reve      = false
	boucle_actuelle = 1
	infos_reve.clear()
	jour_actuel    += 1
	emit_signal("jour_change", jour_actuel)

	if jour_actuel > 14:
		declencher_fin()
	else:
		SceneManager.aller_a("res://scenes/real_world.tscn")

# ════════════════════════════════════════════════════════════
# FINS
# ════════════════════════════════════════════════════════════

func declencher_fin() -> void:
	var type_fin : String
	if energie >= SEUIL_FIN_LUMIERE:
		type_fin = "lumiere"
	elif energie >= SEUIL_FIN_GRISE:
		type_fin = "grise"
	else:
		type_fin = "horreur"

	emit_signal("partie_terminee", type_fin)
	SceneManager.aller_a("res://scenes/endings/fin_%s.tscn" % type_fin)

# ════════════════════════════════════════════════════════════
# PNJ
# ════════════════════════════════════════════════════════════

func modifier_relation(pnj: String, delta: int) -> void:
	if relation_pnj.has(pnj):
		relation_pnj[pnj] = clamp(relation_pnj[pnj] + delta, 0, 100)

func get_relation(pnj: String) -> int:
	return relation_pnj.get(pnj, 0)

# ════════════════════════════════════════════════════════════
# SAUVEGARDE SIMPLE (persistance entre scènes)
# ════════════════════════════════════════════════════════════

func sauvegarder_indice(cle: String, valeur) -> void:
	infos_reve[cle] = valeur

func get_indice(cle: String, defaut = null):
	return infos_reve.get(cle, defaut)
