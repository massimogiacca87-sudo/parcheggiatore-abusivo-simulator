# Helper per lo shader "rain_puddles_ripples_ssr.gdshader" (CC0, shadecore_dev).
# Originale: https://godotshaders.com/shader/rain-puddles-with-ripples-and-reflection/
# ADATTATO A GODOT 4.3: l'originale usava @export_tool_button (solo Godot 4.4+);
# qui c'è una spunta "esegui_setup" nell'Inspector che fa la stessa cosa.
#
# Uso: aggiungi un MeshInstance3D come figlio della Camera3D, assegnagli questo script,
# spunta "esegui_setup" nell'Inspector, poi in Material Override metti uno ShaderMaterial
# con rain_puddles_ripples_ssr.gdshader.
@tool
extends MeshInstance3D
class_name FullscreenMesh

@export var esegui_setup: bool = false:
	set(value):
		if value:
			setup()

func _ready() -> void:
	if mesh == null:
		setup()

# Passa allo shader quale renderer è attivo (Forward+ su PC, Compatibility su web/mobile):
# serve perché Godot 4.3 non ha la macro CURRENT_RENDERER negli shader.
func _process(_delta: float) -> void:
	var sm := material_override as ShaderMaterial
	if sm == null:
		return
	# in Godot 4.3 il renderer Compatibility (OpenGL) non ha un RenderingDevice
	var compat: bool = RenderingServer.get_rendering_device() == null
	sm.set_shader_parameter("compatibility_renderer", compat)
	set_process(false)
	# Collaudato: in Godot 4.3 il renderer Compatibility (build WEB) non supporta
	# hint_depth_texture negli shader spatial -> lo shader non compila. Lì lo spegniamo.
	if compat and not Engine.is_editor_hint():
		visible = false
		push_warning("Pozzanghere SSR disattivate: il renderer Compatibility di Godot 4.3 non le supporta.")

func setup() -> void:
	gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 16384.0

	if mesh != null:
		mesh = null

	mesh = ArrayMesh.new()

	var verts := PackedVector3Array()
	verts.append(Vector3(-1.0, -1.0, 0.0))
	verts.append(Vector3(3.0, -1.0, 0.0))
	verts.append(Vector3(-1.0, 3.0, 0.0))

	var mesh_array := []
	mesh_array.resize(Mesh.ARRAY_MAX)
	mesh_array[Mesh.ARRAY_VERTEX] = verts

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)
