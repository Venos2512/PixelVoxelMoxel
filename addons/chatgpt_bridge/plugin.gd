@tool
extends EditorPlugin

const BridgeDock = preload("res://addons/chatgpt_bridge/bridge_dock.gd")

var dock: Control


func _enter_tree() -> void:
    dock = BridgeDock.new()
    dock.name = "ChatGPT Bridge"
    dock.configure(get_editor_interface())
    add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, dock)


func _exit_tree() -> void:
    if is_instance_valid(dock):
        remove_control_from_docks(dock)
        dock.queue_free()
