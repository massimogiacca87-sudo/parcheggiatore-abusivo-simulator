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
