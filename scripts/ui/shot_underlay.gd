class_name ShotUnderlay
extends RefCounted
## Görüntü aracı için sahte "arka sahne": bulanıklık ve kararma etkisi görülebilsin diye renkli blokler.

const SEED: int = 7
const BLOCKS: int = 34
const BASE_COLOR: Color = Color(0.2, 0.16, 0.13)
const PALETTE: Array[Color] = [
	Color(0.95, 0.5, 0.15), Color(0.35, 0.3, 0.28), Color(0.15, 0.2, 0.3), Color(0.55, 0.2, 0.12), Color(0.7, 0.65, 0.5),
]


static func add(host: Node) -> void:
	var bg: ColorRect = ColorRect.new()
	UiAssets.fill(bg)
	bg.color = BASE_COLOR
	host.add_child(bg)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED
	for i: int in BLOCKS:
		var block: ColorRect = ColorRect.new()
		var x: float = rng.randf_range(0.0, 0.92)
		var y: float = rng.randf_range(0.0, 0.9)
		block.anchor_left = x
		block.anchor_top = y
		block.anchor_right = x + rng.randf_range(0.03, 0.12)
		block.anchor_bottom = y + rng.randf_range(0.04, 0.16)
		block.color = PALETTE[rng.randi() % PALETTE.size()]
		block.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_child(block)
