@tool
extends VBoxContainer

const PROTOCOL_HEADER := "CHATGPT_BRIDGE_PATCH_V1"
const MAX_CONTEXT_CHARS := 180000
const MAX_FILE_CHARS := 30000
const MAX_SCENE_SCRIPTS := 10
const BACKUP_FILE := "user://chatgpt_bridge/last_backup.json"

var editor_interface: EditorInterface
var context_box: TextEdit
var patch_box: TextEdit
var preview_box: TextEdit
var status_label: Label
var include_scene_file: CheckButton
var include_scene_scripts: CheckButton
var include_selected_files: CheckButton
var last_backup: Dictionary = {}


func configure(value: EditorInterface) -> void:
    editor_interface = value


func _ready() -> void:
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    custom_minimum_size = Vector2(390, 500)
    _build_ui()
    _load_backup_from_disk()
    _set_status("Sẵn sàng. Bấm 'Tạo context'.")


func _build_ui() -> void:
    var title := Label.new()
    title.text = "ChatGPT Bridge"
    title.add_theme_font_size_override("font_size", 18)
    add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Dùng quota ChatGPT: copy context → chat → paste patch → apply"
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    add_child(subtitle)

    add_child(HSeparator.new())

    var options := HFlowContainer.new()
    add_child(options)

    include_scene_file = CheckButton.new()
    include_scene_file.text = "Scene"
    include_scene_file.button_pressed = true
    options.add_child(include_scene_file)

    include_scene_scripts = CheckButton.new()
    include_scene_scripts.text = "Scripts"
    include_scene_scripts.button_pressed = true
    options.add_child(include_scene_scripts)

    include_selected_files = CheckButton.new()
    include_selected_files.text = "File đã chọn"
    include_selected_files.button_pressed = true
    options.add_child(include_selected_files)

    var context_buttons := HBoxContainer.new()
    add_child(context_buttons)

    var build_btn := Button.new()
    build_btn.text = "Tạo context"
    build_btn.tooltip_text = "Gom scene tree, node được chọn và code liên quan"
    build_btn.pressed.connect(_on_build_context)
    context_buttons.add_child(build_btn)

    var copy_btn := Button.new()
    copy_btn.text = "Copy"
    copy_btn.pressed.connect(_on_copy_context)
    context_buttons.add_child(copy_btn)

    var run_btn := Button.new()
    run_btn.text = "▶ Run"
    run_btn.pressed.connect(_on_run_current_scene)
    context_buttons.add_child(run_btn)

    var stop_btn := Button.new()
    stop_btn.text = "■ Stop"
    stop_btn.pressed.connect(_on_stop_scene)
    context_buttons.add_child(stop_btn)

    context_box = TextEdit.new()
    context_box.placeholder_text = "Context gửi sang ChatGPT sẽ xuất hiện ở đây..."
    context_box.custom_minimum_size = Vector2(0, 170)
    context_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
    context_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
    add_child(context_box)

    add_child(HSeparator.new())

    var patch_title := Label.new()
    patch_title.text = "Patch từ ChatGPT"
    add_child(patch_title)

    var patch_buttons := HBoxContainer.new()
    add_child(patch_buttons)

    var paste_btn := Button.new()
    paste_btn.text = "Paste clipboard"
    paste_btn.pressed.connect(_on_paste_patch)
    patch_buttons.add_child(paste_btn)

    var preview_btn := Button.new()
    preview_btn.text = "Preview"
    preview_btn.pressed.connect(_on_preview_patch)
    patch_buttons.add_child(preview_btn)

    var apply_btn := Button.new()
    apply_btn.text = "Apply"
    apply_btn.pressed.connect(_on_apply_patch)
    patch_buttons.add_child(apply_btn)

    var undo_btn := Button.new()
    undo_btn.text = "Undo lần cuối"
    undo_btn.pressed.connect(_on_undo_last)
    patch_buttons.add_child(undo_btn)

    patch_box = TextEdit.new()
    patch_box.placeholder_text = PROTOCOL_HEADER + "\n<<<REPLACE_IN_FILE res://path/file.gd>>>\n<<<SEARCH>>>\n...\n<<<WITH>>>\n...\n<<<END>>>"
    patch_box.custom_minimum_size = Vector2(0, 170)
    patch_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
    patch_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
    add_child(patch_box)

    preview_box = TextEdit.new()
    preview_box.editable = false
    preview_box.custom_minimum_size = Vector2(0, 105)
    preview_box.placeholder_text = "Kết quả kiểm tra patch..."
    preview_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
    add_child(preview_box)

    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    add_child(status_label)


func _on_build_context() -> void:
    context_box.text = _build_context()
    DisplayServer.clipboard_set(context_box.text)
    _set_status("Đã tạo và copy context vào clipboard. Dán vào ChatGPT.")


func _on_copy_context() -> void:
    if context_box.text.strip_edges().is_empty():
        context_box.text = _build_context()
    DisplayServer.clipboard_set(context_box.text)
    _set_status("Đã copy context.")


func _on_paste_patch() -> void:
    patch_box.text = DisplayServer.clipboard_get()
    _set_status("Đã paste clipboard. Bấm Preview trước khi Apply.")


func _on_preview_patch() -> void:
    var result := _parse_and_simulate_patch(patch_box.text)
    preview_box.text = result.get("report", "")
    if result.get("ok", false):
        _set_status("Patch hợp lệ. Có thể Apply.")
    else:
        _set_status("Patch chưa hợp lệ. Không có file nào bị thay đổi.")


func _on_apply_patch() -> void:
    var result := _parse_and_simulate_patch(patch_box.text)
    preview_box.text = result.get("report", "")
    if not result.get("ok", false):
        _set_status("Không Apply: patch không hợp lệ.")
        return

    var final_files: Dictionary = result.get("final_files", {})
    var originals: Dictionary = result.get("originals", {})
    if final_files.is_empty():
        _set_status("Không có thay đổi để Apply.")
        return

    last_backup = originals.duplicate(true)
    if not _save_backup_to_disk(last_backup):
        _set_status("Không thể lưu backup, đã hủy Apply để đảm bảo an toàn.")
        return

    for path in final_files.keys():
        if not _write_text_file(path, final_files[path]):
            _restore_backup(last_backup)
            _set_status("Lỗi khi ghi %s. Đã rollback." % path)
            return

    if editor_interface != null:
        editor_interface.get_resource_filesystem().scan()
    _set_status("Đã Apply %d file. Có thể dùng 'Undo lần cuối'." % final_files.size())


func _on_undo_last() -> void:
    if last_backup.is_empty():
        _load_backup_from_disk()
    if last_backup.is_empty():
        _set_status("Chưa có backup để Undo.")
        return

    if _restore_backup(last_backup):
        if editor_interface != null:
            editor_interface.get_resource_filesystem().scan()
        _set_status("Đã Undo thay đổi gần nhất.")
        last_backup.clear()
        _clear_backup_file()
    else:
        _set_status("Undo gặp lỗi ở một hoặc nhiều file.")


func _on_run_current_scene() -> void:
    if editor_interface == null:
        return
    if editor_interface.is_playing_scene():
        editor_interface.stop_playing_scene()
    editor_interface.play_current_scene()
    _set_status("Đang chạy scene hiện tại.")


func _on_stop_scene() -> void:
    if editor_interface != null and editor_interface.is_playing_scene():
        editor_interface.stop_playing_scene()
        _set_status("Đã dừng game.")


func _build_context() -> String:
    var out := PackedStringArray()
    out.append("# GODOT CHATGPT BRIDGE CONTEXT")
    out.append("")
    out.append("Bạn đang hỗ trợ chỉnh trực tiếp một project Godot 4.x.")
    out.append("Hãy phân tích context bên dưới. Nếu cần sửa file, CUỐI câu trả lời hãy xuất patch đúng protocol V1.")
    out.append("Không dùng unified diff. Không đổi format marker. SEARCH phải khớp nguyên văn nội dung hiện tại.")
    out.append("")
    out.append(_patch_protocol_help())
    out.append("")

    var root: Node = null
    if editor_interface != null:
        root = editor_interface.get_edited_scene_root()

    if root == null:
        out.append("## CURRENT SCENE\nKhông có scene đang mở.")
    else:
        out.append("## CURRENT SCENE")
        out.append("Path: %s" % root.scene_file_path)
        out.append("Root: %s (%s)" % [root.name, root.get_class()])
        out.append("")
        out.append("### SCENE TREE")
        out.append(_scene_tree_text(root))

        var selected_nodes := _get_selected_nodes()
        out.append("")
        out.append("### SELECTED NODES")
        if selected_nodes.is_empty():
            out.append("(none)")
        else:
            for node in selected_nodes:
                out.append(_node_summary(node))

        if include_scene_file.button_pressed and not root.scene_file_path.is_empty():
            out.append("")
            out.append(_file_section(root.scene_file_path, "CURRENT SCENE FILE"))

        if include_scene_scripts.button_pressed:
            var scripts := _collect_scene_script_paths(root)
            if not scripts.is_empty():
                out.append("")
                out.append("## SCENE SCRIPTS")
                for script_path in scripts:
                    out.append(_file_section(script_path, script_path))

    if include_selected_files.button_pressed and editor_interface != null:
        var selected_paths := editor_interface.get_selected_paths()
        if not selected_paths.is_empty():
            out.append("")
            out.append("## FILESYSTEM SELECTION")
            for path in selected_paths:
                out.append(String(path))
                if _is_context_text_file(String(path)) and FileAccess.file_exists(String(path)):
                    out.append(_file_section(String(path), String(path)))

    out.append("")
    out.append("## REQUEST")
    out.append("Hãy trả lời yêu cầu của tôi dựa trên context này. Nếu sửa code/file, xuất patch V1 ở cuối câu trả lời.")

    var text := "\n".join(out)
    if text.length() > MAX_CONTEXT_CHARS:
        text = text.substr(0, MAX_CONTEXT_CHARS) + "\n\n[CONTEXT TRUNCATED BY PLUGIN]"
    return text


func _patch_protocol_help() -> String:
    return """## PATCH PROTOCOL V1
Khi cần sửa file, dùng chính xác:

CHATGPT_BRIDGE_PATCH_V1
<<<REPLACE_IN_FILE res://path/file.gd>>>
<<<SEARCH>>>
đoạn cũ phải khớp chính xác
<<<WITH>>>
đoạn mới
<<<END>>>

Tạo file mới:

<<<CREATE_FILE res://path/new_file.gd>>>
nội dung file mới
<<<END_FILE>>>

Có thể có nhiều block. Không được xóa file trong protocol V1."""


func _scene_tree_text(root: Node) -> String:
    var lines := PackedStringArray()
    _append_tree_line(root, root, 0, lines)
    return "\n".join(lines)


func _append_tree_line(root: Node, node: Node, depth: int, lines: PackedStringArray) -> void:
    if depth > 12:
        return
    var indent := "  ".repeat(depth)
    var script_suffix := ""
    var script = node.get_script()
    if script != null and script is Script and not script.resource_path.is_empty():
        script_suffix = " [script=%s]" % script.resource_path
    lines.append("%s- %s (%s)%s" % [indent, node.name, node.get_class(), script_suffix])
    for child in node.get_children():
        if child is Node:
            _append_tree_line(root, child, depth + 1, lines)


func _get_selected_nodes() -> Array[Node]:
    if editor_interface == null:
        return []
    var selection := editor_interface.get_selection()
    if selection == null:
        return []
    var result: Array[Node] = []
    for item in selection.get_selected_nodes():
        if item is Node:
            result.append(item)
    return result


func _node_summary(node: Node) -> String:
    var lines := PackedStringArray()
    lines.append("- Path: %s" % String(node.get_path()))
    lines.append("  Type: %s" % node.get_class())
    var script = node.get_script()
    if script != null and script is Script:
        lines.append("  Script: %s" % script.resource_path)
    return "\n".join(lines)


func _collect_scene_script_paths(root: Node) -> PackedStringArray:
    var unique := {}
    var stack: Array[Node] = [root]
    while not stack.is_empty() and unique.size() < MAX_SCENE_SCRIPTS:
        var node: Node = stack.pop_back()
        var script = node.get_script()
        if script != null and script is Script:
            var path := String(script.resource_path)
            if path.begins_with("res://") and FileAccess.file_exists(path):
                unique[path] = true
        for child in node.get_children():
            if child is Node:
                stack.append(child)
    var paths := PackedStringArray()
    for path in unique.keys():
        paths.append(String(path))
    paths.sort()
    return paths


func _file_section(path: String, heading: String) -> String:
    var content := _read_text_file(path)
    if content.length() > MAX_FILE_CHARS:
        content = content.substr(0, MAX_FILE_CHARS) + "\n[FILE TRUNCATED]"
    return "### %s\n```text\n%s\n```" % [heading, content]


func _is_context_text_file(path: String) -> bool:
    var ext := path.get_extension().to_lower()
    return ext in ["gd", "tscn", "tres", "gdshader", "cfg", "json", "txt", "md"]


func _parse_and_simulate_patch(text: String) -> Dictionary:
    var parsed := _parse_patch(text)
    if not parsed.get("ok", false):
        return parsed

    var ops: Array = parsed.get("ops", [])
    var working: Dictionary = {}
    var originals: Dictionary = {}
    var report := PackedStringArray()
    report.append("Patch V1: %d operation(s)" % ops.size())

    for op in ops:
        var path := String(op.get("path", ""))
        var path_error := _validate_path(path)
        if not path_error.is_empty():
            return {"ok": false, "report": "ERROR %s: %s" % [path, path_error]}

        if not originals.has(path):
            if FileAccess.file_exists(path):
                originals[path] = _read_text_file(path)
                working[path] = originals[path]
            else:
                originals[path] = null
                working[path] = ""

        if op.get("type", "") == "replace":
            if originals[path] == null:
                return {"ok": false, "report": "ERROR: file không tồn tại: %s" % path}
            var old_text := String(op.get("search", ""))
            var new_text := String(op.get("with", ""))
            if old_text.is_empty():
                return {"ok": false, "report": "ERROR: SEARCH rỗng tại %s" % path}
            var current := String(working[path])
            var first := current.find(old_text)
            if first < 0:
                return {"ok": false, "report": "ERROR: SEARCH không khớp tại %s\n--- SEARCH ---\n%s" % [path, _clip(old_text, 900)]}
            if current.find(old_text, first + old_text.length()) >= 0:
                return {"ok": false, "report": "ERROR: SEARCH khớp nhiều hơn 1 vị trí tại %s. Hãy yêu cầu ChatGPT dùng đoạn SEARCH đặc trưng hơn." % path}
            working[path] = current.substr(0, first) + new_text + current.substr(first + old_text.length())
            report.append("OK replace: %s (%d → %d chars)" % [path, old_text.length(), new_text.length()])

        elif op.get("type", "") == "create":
            if originals[path] != null:
                return {"ok": false, "report": "ERROR: CREATE_FILE nhưng file đã tồn tại: %s" % path}
            working[path] = String(op.get("content", ""))
            report.append("OK create: %s (%d chars)" % [path, String(working[path]).length()])
        else:
            return {"ok": false, "report": "ERROR: operation không hỗ trợ."}

    report.append("")
    report.append("Sẵn sàng Apply %d file(s)." % working.size())
    return {
        "ok": true,
        "report": "\n".join(report),
        "final_files": working,
        "originals": originals,
        "ops": ops,
    }


func _parse_patch(text: String) -> Dictionary:
    var normalized := text.replace("\r\n", "\n")
    var header_pos := normalized.find(PROTOCOL_HEADER)
    if header_pos < 0:
        return {"ok": false, "report": "ERROR: không thấy %s" % PROTOCOL_HEADER}

    var cursor := header_pos + PROTOCOL_HEADER.length()
    var ops: Array = []

    while cursor < normalized.length():
        var replace_pos := normalized.find("<<<REPLACE_IN_FILE ", cursor)
        var create_pos := normalized.find("<<<CREATE_FILE ", cursor)

        var next_pos := -1
        var kind := ""
        if replace_pos >= 0 and (create_pos < 0 or replace_pos < create_pos):
            next_pos = replace_pos
            kind = "replace"
        elif create_pos >= 0:
            next_pos = create_pos
            kind = "create"
        else:
            break

        if kind == "replace":
            var path_end := normalized.find(">>>", next_pos)
            if path_end < 0:
                return {"ok": false, "report": "ERROR: marker REPLACE_IN_FILE chưa đóng."}
            var prefix_len := "<<<REPLACE_IN_FILE ".length()
            var path := normalized.substr(next_pos + prefix_len, path_end - (next_pos + prefix_len)).strip_edges()

            var search_open := normalized.find("<<<SEARCH>>>", path_end + 3)
            var with_marker := normalized.find("<<<WITH>>>", search_open + 12)
            var end_marker := normalized.find("<<<END>>>", with_marker + 10)
            if search_open < 0 or with_marker < 0 or end_marker < 0:
                return {"ok": false, "report": "ERROR: block REPLACE thiếu SEARCH/WITH/END tại %s" % path}

            var search_start := search_open + "<<<SEARCH>>>".length()
            if normalized.substr(search_start, 1) == "\n":
                search_start += 1
            var search_text := normalized.substr(search_start, with_marker - search_start)
            if search_text.ends_with("\n"):
                search_text = search_text.left(-1)

            var with_start := with_marker + "<<<WITH>>>".length()
            if normalized.substr(with_start, 1) == "\n":
                with_start += 1
            var with_text := normalized.substr(with_start, end_marker - with_start)
            if with_text.ends_with("\n"):
                with_text = with_text.left(-1)

            ops.append({"type": "replace", "path": path, "search": search_text, "with": with_text})
            cursor = end_marker + "<<<END>>>".length()

        else:
            var path_end := normalized.find(">>>", next_pos)
            if path_end < 0:
                return {"ok": false, "report": "ERROR: marker CREATE_FILE chưa đóng."}
            var prefix_len := "<<<CREATE_FILE ".length()
            var path := normalized.substr(next_pos + prefix_len, path_end - (next_pos + prefix_len)).strip_edges()
            var content_start := path_end + 3
            if normalized.substr(content_start, 1) == "\n":
                content_start += 1
            var end_file := normalized.find("<<<END_FILE>>>", content_start)
            if end_file < 0:
                return {"ok": false, "report": "ERROR: CREATE_FILE thiếu END_FILE tại %s" % path}
            var content := normalized.substr(content_start, end_file - content_start)
            if content.ends_with("\n"):
                content = content.left(-1)
            ops.append({"type": "create", "path": path, "content": content})
            cursor = end_file + "<<<END_FILE>>>".length()

    if ops.is_empty():
        return {"ok": false, "report": "ERROR: không tìm thấy operation nào trong patch."}
    return {"ok": true, "ops": ops, "report": "Parsed %d operation(s)." % ops.size()}


func _validate_path(path: String) -> String:
    if not path.begins_with("res://"):
        return "chỉ cho phép path bắt đầu bằng res://"
    if ".." in path:
        return "không cho phép '..' trong path"
    if path.ends_with("/"):
        return "path phải là file"
    var ext := path.get_extension().to_lower()
    if ext not in ["gd", "tscn", "tres", "gdshader", "cfg", "json", "txt", "md"]:
        return "đuôi file không nằm trong allow-list an toàn"
    return ""


func _read_text_file(path: String) -> String:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return ""
    return file.get_as_text()


func _write_text_file(path: String, content: String) -> bool:
    var absolute_dir := ProjectSettings.globalize_path(path.get_base_dir())
    var dir_error := DirAccess.make_dir_recursive_absolute(absolute_dir)
    if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
        return false
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(content)
    file.flush()
    return true


func _save_backup_to_disk(backup: Dictionary) -> bool:
    var absolute_dir := ProjectSettings.globalize_path("user://chatgpt_bridge")
    var dir_error := DirAccess.make_dir_recursive_absolute(absolute_dir)
    if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
        return false
    var file := FileAccess.open(BACKUP_FILE, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(backup, "  "))
    file.flush()
    return true


func _load_backup_from_disk() -> void:
    if not FileAccess.file_exists(BACKUP_FILE):
        return
    var text := _read_text_file(BACKUP_FILE)
    var parsed = JSON.parse_string(text)
    if parsed is Dictionary:
        last_backup = parsed


func _clear_backup_file() -> void:
    if FileAccess.file_exists(BACKUP_FILE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP_FILE))


func _restore_backup(backup: Dictionary) -> bool:
    var all_ok := true
    for path in backup.keys():
        var original = backup[path]
        if original == null:
            if FileAccess.file_exists(path):
                var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
                if err != OK:
                    all_ok = false
        else:
            if not _write_text_file(String(path), String(original)):
                all_ok = false
    return all_ok


func _clip(text: String, max_chars: int) -> String:
    if text.length() <= max_chars:
        return text
    return text.substr(0, max_chars) + "\n[...]"


func _set_status(text: String) -> void:
    if status_label != null:
        status_label.text = text
