class_name AmbienceStream
extends RefCounted
## Ortam dosyalarını yükler. Döngü .import ayarıyla değil kodda verilir: dosya adı değişince (gerçek CC0 ses)
## import dosyasını elle düzeltmek gerekmez. load() kaynağı kendisi önbelleğe alır; burada statik önbellek yok (çıkışta sızıntı yapar).

## Döngülü (tüm dosya boyunca ileri) ya da tek seferlik akış; yüklenemezse null.
static func load_stream(file: String, looping: bool) -> AudioStream:
	var base: AudioStream = load(AmbienceData.path_of(file)) as AudioStream
	if base == null:
		push_error("Ortam sesi yüklenemedi: %s" % AmbienceData.path_of(file))
		return null
	var stream: AudioStream = base
	if looping and base is AudioStreamWAV:
		var wav: AudioStreamWAV = (base as AudioStreamWAV).duplicate() as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = _sample_count(wav)
		stream = wav
	return stream


static func _sample_count(wav: AudioStreamWAV) -> int:
	var bytes_per_sample: int = 2 if wav.format == AudioStreamWAV.FORMAT_16_BITS else 1
	var channels: int = 2 if wav.stereo else 1
	return wav.data.size() / (bytes_per_sample * channels)
