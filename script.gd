tool
extends Node

onready var spectrum = AudioServer.get_bus_effect_instance(0, 0)

var definition = 6
var total_w = 400
var total_h = 200

var min_freq = 20
var max_freq = 20000

var max_db = -16
var min_db = -55

export(float) var accel = 10
var histogram = []



func update_shader():
	$visualiser.mesh.material.set_shader_param("hist_1", histogram[0])
	$visualiser.mesh.material.set_shader_param("hist_2", histogram[1])
	$visualiser.mesh.material.set_shader_param("hist_3", histogram[2])
	$visualiser.mesh.material.set_shader_param("hist_4", histogram[3])
	$visualiser.mesh.material.set_shader_param("hist_5", histogram[4])
	$visualiser.mesh.material.set_shader_param("hist_6", histogram[5])


func _ready():
	max_db += $audio.volume_db
	min_db += $audio.volume_db

	for i in range(definition):
		histogram.append(0)


func _process(delta):
	var freq = min_freq
	var interval = (max_freq - min_freq) / definition
	
	for i in range(definition):
		
		var freqrange_low = float(freq - min_freq) / float(max_freq - min_freq)
		freqrange_low = freqrange_low * freqrange_low * freqrange_low * freqrange_low
		freqrange_low = lerp(min_freq, max_freq, freqrange_low)
		
		freq += interval
		
		var freqrange_high = float(freq - min_freq) / float(max_freq - min_freq)
		freqrange_high = freqrange_high * freqrange_high * freqrange_high * freqrange_high
		freqrange_high = lerp(min_freq, max_freq, freqrange_high)
		
		var mag = spectrum.get_magnitude_for_frequency_range(freqrange_low, freqrange_high)
		mag = linear2db(mag.length())
		mag = (mag - min_db) / (max_db - min_db)
		
		mag += 0.3 * (freq - min_freq) / (max_freq - min_freq)
		mag = clamp(mag, 0.05, 1)
		
		histogram[i] = 0.1 + lerp(histogram[i], mag, accel * delta)
	
	update_shader()
