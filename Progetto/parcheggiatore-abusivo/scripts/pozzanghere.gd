extends MeshInstance3D
## **'E pozzanghere** (0.62, asset esterni).
##
## Lo shader di shadecore_dev (CC0) dalla biblioteca esterna: sulle
## superfici orizzontali si formano chiazze d'acqua che riflettono quello
## che c'è intorno (riflessi a schermo) con i cerchi della pioggia che ci
## cade dentro. Si vede **solo nella giornata di pioggia**, e **solo col
## renderer Forward+** (l'exe su PC): il renderer Compatibility della build
## web non ha la texture di profondità negli shader spatial, e lì questo
## nodo non si costruisce proprio (se si costruisse, lo shader darebbe
## errore di compilazione anche da spento).
##
## È un triangolo che copre lo schermo, appeso alla telecamera del
## giocatore (come `fullscreen_mesh.gd` della biblioteca, senza la parte
## `@tool` che serve solo nell'editor). Costa: si spegne quando la qualità
## scende a BASSA (vedi `qualita.gd`).

const SHADER := "res://assets/shaders/pozzanghere.gdshader"

var _t: float = 0.0


## Si può usare qui? (Forward+ e shader presente.)
static func si_puo() -> bool:
	return RenderingServer.get_rendering_device() != null \
		and ResourceLoader.exists(SHADER)


func _ready() -> void:
	name = "Pozzanghere"
	gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 16384.0
	var am := ArrayMesh.new()
	var v := PackedVector3Array([Vector3(-1.0, -1.0, 0.0), Vector3(3.0, -1.0, 0.0),
		Vector3(-1.0, 3.0, 0.0)])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mesh = am
	var m := ShaderMaterial.new()
	m.shader = load(SHADER)
	m.set_shader_parameter("compatibility_renderer", false)
	material_override = m
	_aggiorna()


func _process(delta: float) -> void:
	_t += delta
	if _t < 0.5:
		return
	_t = 0.0
	_aggiorna()


func _aggiorna() -> void:
	var chiove: bool = GameManager.tipo_giornata == "pioggia"
	var bassa: bool = int(GameManager.qualita_salvata) == 0
	visible = chiove and not bassa and not GameManager.dentro_casa
