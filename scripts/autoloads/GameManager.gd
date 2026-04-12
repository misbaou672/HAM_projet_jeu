extends Node

# ═══════════════════════════════════════════════════════════
# GameManager.gd — AUTOLOAD (version complète Jours 1-3)
# ═══════════════════════════════════════════════════════════

# ── État global ─────────────────────────────────────────────
var energie         : int  = 100
var jour_actuel     : int  = 1
var dans_reve       : bool = false
var boucle_actuelle : int  = 1
var infos_reve      : Dictionary = {}

# ── Parcours (bifurcation jour 2 minuit) ────────────────────
var parcours_lumiere : bool = true   # true = lumière, false = ombre

# ── Relations PNJ ───────────────────────────────────────────
var relation_pnj : Dictionary = {
	"mere"     : 50,
	"amie"     : 50,
	"maitresse": 30,
	"voisin"   : 20,
}

# ── Seuils fins ─────────────────────────────────────────────
const SEUIL_FIN_LUMIERE := 100
const SEUIL_FIN_GRISE   := 30
const SEUIL_BIFURCATION := 50   # Jour 2 minuit

# ── Signaux ─────────────────────────────────────────────────
signal energie_changee(nouvelle_valeur: int)
signal jour_change(nouveau_jour: int)
signal partie_terminee(type_fin: String)

# ════════════════════════════════════════════════════════════
# ÉNERGIE
# ════════════════════════════════════════════════════════════

func perdre_energie(montant: int) -> void:
	energie = max(0, energie - montant)
	energie_changee.emit(energie)
	_verifier_game_over()

func gagner_energie(montant: int) -> void:
	energie = min(100, energie + montant)
	energie_changee.emit(energie)

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
	dans_reve       = false
	boucle_actuelle = 1
	infos_reve.clear()

	# Bifurcation jour 2 → jour 3+
	if jour_actuel == 2:
		parcours_lumiere = energie > SEUIL_BIFURCATION

	jour_actuel += 1
	jour_change.emit(jour_actuel)

	if jour_actuel > 14:
		declencher_fin()
	else:
		_charger_prochain_jour()

func _charger_prochain_jour() -> void:
	var chemin : String
	match jour_actuel:
		1  : chemin = "res://scenes/jours/jour_1.tscn"
		2  : chemin = "res://scenes/jours/jour_2.tscn"
		3  : chemin = "res://scenes/jours/jour_3.tscn"
		_  : chemin = "res://scenes/real_world.tscn"
	SceneManager.aller_a(chemin)

# ════════════════════════════════════════════════════════════
# FINS
# ════════════════════════════════════════════════════════════

func declencher_fin() -> void:
	var type_fin : String
	if   energie >= SEUIL_FIN_LUMIERE : type_fin = "lumiere"
	elif energie >= SEUIL_FIN_GRISE   : type_fin = "grise"
	else                               : type_fin = "horreur"
	partie_terminee.emit(type_fin)
	SceneManager.aller_a("res://scenes/endings/fin_%s.tscn" % type_fin)

# ════════════════════════════════════════════════════════════
# PNJ
# ════════════════════════════════════════════════════════════

func modifier_relation(pnj: String, delta: int) -> void:
	if relation_pnj.has(pnj):
		relation_pnj[pnj] = clampi(relation_pnj[pnj] + delta, 0, 100)

func get_relation(pnj: String) -> int:
	return relation_pnj.get(pnj, 0)

# ════════════════════════════════════════════════════════════
# INDICES (persistance entre boucles)
# ════════════════════════════════════════════════════════════

func sauvegarder_indice(cle: String, valeur: Variant) -> void:
	infos_reve[cle] = valeur

func get_indice(cle: String, defaut: Variant = null) -> Variant:
	return infos_reve.get(cle, defaut)
