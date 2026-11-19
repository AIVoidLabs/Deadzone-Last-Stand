extends SceneTree
## Kare dizisinden kontak sayfası.
## godot --headless --path . -s res://tools/godot/contact_sheet.gd -- --dir=build/movies/x --out=build/movies/x_sheet.png --cols=4 --rows=3 --fps=30 --skip=0 [--width=1600]

const GAP: int = 4


func _init() -> void:
	var dir: String = ""
	var out: String = ""
	var cols: int = 4
	var rows: int = 3
	var fps: int = 30
	var skip: float = 0.0
	var width: int = 1600
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--dir="):
			dir = arg.trim_prefix("--dir=")
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--cols="):
			cols = arg.trim_prefix("--cols=").to_int()
		elif arg.begins_with("--rows="):
			rows = arg.trim_prefix("--rows=").to_int()
		elif arg.begins_with("--fps="):
			fps = arg.trim_prefix("--fps=").to_int()
		elif arg.begins_with("--skip="):
			skip = arg.trim_prefix("--skip=").to_float()
		elif arg.begins_with("--width="):
			width = arg.trim_prefix("--width=").to_int()
	var root_path: String = ProjectSettings.globalize_path("res://")
	var files: PackedStringArray = []
	for f: String in DirAccess.get_files_at(root_path.path_join(dir)):
		if f.ends_with(".png"):
			files.append(f)
	files.sort()
	var first: int = mini(int(skip * fps), maxi(files.size() - 1, 0))
	var count: int = cols * rows
	if files.size() == 0:
		push_error("Kare yok: " + dir)
		quit(1)
		return
	var cell_w: int = (width - GAP * (cols - 1)) / cols
	var sample: Image = Image.load_from_file(root_path.path_join(dir).path_join(files[0]))
	var cell_h: int = int(cell_w * float(sample.get_height()) / sample.get_width())
	var sheet: Image = Image.create(width, cell_h * rows + GAP * (rows - 1), false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.1, 0.1, 0.1))
	var span: int = files.size() - first
	for i: int in count:
		var idx: int = first + int(float(i) * span / count)
		var img: Image = Image.load_from_file(root_path.path_join(dir).path_join(files[idx]))
		img.convert(Image.FORMAT_RGB8)
		img.resize(cell_w, cell_h, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(img, Rect2i(0, 0, cell_w, cell_h), Vector2i((i % cols) * (cell_w + GAP), (i / cols) * (cell_h + GAP)))
	var out_abs: String = root_path.path_join(out)
	DirAccess.make_dir_recursive_absolute(out_abs.get_base_dir())
	sheet.save_png(out_abs)
	print("SHEET ", out, " frames=", files.size(), " first=", first)
	quit()
