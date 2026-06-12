class_name SettingsPanel
extends PanelContainer
## Sliders de volume Música/SFX — aplicam no AudioManager e persistem.
## Reusado pelo menu principal e pelo pause.

@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	%MusicLabel.text = Strings.get_text(&"UI_MUSIC_VOLUME")
	%SfxLabel.text = Strings.get_text(&"UI_SFX_VOLUME")
	_close_button.text = Strings.get_text(&"UI_BACK")
	_music_slider.value = SaveManager.get_volume(&"Music")
	_sfx_slider.value = SaveManager.get_volume(&"SFX")
	_music_slider.value_changed.connect(_on_volume.bind(&"Music"))
	_sfx_slider.value_changed.connect(_on_volume.bind(&"SFX"))
	_close_button.pressed.connect(hide)
	hide()


func open() -> void:
	show()


func _on_volume(value: float, bus: StringName) -> void:
	AudioManager.set_bus_volume(bus, value)
	SaveManager.set_volume(bus, value)
