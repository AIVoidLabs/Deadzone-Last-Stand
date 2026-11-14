extends GutTest
## Duman testi: GUT çalışıyor ve proje ayarları beklendiği gibi.


func test_gut_runs() -> void:
	assert_true(true, "GUT çalışıyor")


func test_renderer_is_forward_plus() -> void:
	var method: String = ProjectSettings.get_setting("rendering/renderer/rendering_method")
	assert_eq(method, "forward_plus")
