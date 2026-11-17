extends SceneTree
## Görüntüleri yan yana tek galeri görseline birleştirir (görsel seçenekleri karşılaştırmak için).
## godot --headless --path . -s res://tools/godot/make_gallery.gd -- <çıktı.png> <girdi1.png> <girdi2.png> ...
## Her girdi CELL_WIDTH genişliğe küçültülür; aralarına ince koyu çizgi konur.

const CELL_WIDTH: int = 960
const GAP: int = 8


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Kullanım: -- <çıktı.png> <girdi.png> ...")
		quit(1)
		return
	var images: Array[Image] = []
	for path: String in args.slice(1):
		var image: Image = Image.load_from_file(path)
		if image == null:
			push_error("Okunamadı: %s" % path)
			quit(1)
			return
		image.convert(Image.FORMAT_RGB8)
		var height: int = int(round(float(image.get_height()) * CELL_WIDTH / image.get_width()))
		image.resize(CELL_WIDTH, height, Image.INTERPOLATE_LANCZOS)
		images.append(image)
	var cell_height: int = images[0].get_height()
	var width: int = images.size() * CELL_WIDTH + (images.size() - 1) * GAP
	var out: Image = Image.create_empty(width, cell_height, false, Image.FORMAT_RGB8)
	out.fill(Color(0.02, 0.02, 0.02))
	for i: int in images.size():
		out.blit_rect(images[i], Rect2i(0, 0, CELL_WIDTH, cell_height), Vector2i(i * (CELL_WIDTH + GAP), 0))
	out.save_png(args[0])
	print("Galeri: %s (%d x %d)" % [args[0], width, cell_height])
	quit(0)
