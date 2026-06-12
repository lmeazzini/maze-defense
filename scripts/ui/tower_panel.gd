class_name TowerPanel
extends PanelContainer
## Painel da torre selecionada: stats, upgrade e venda (com valor do refund).

var _economy: Economy

@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _stats_label: Label = %StatsLabel
@onready var _upgrade_button: Button = %UpgradeButton
@onready var _sell_button: Button = %SellButton


func setup(build: BuildController, economy: Economy) -> void:
	_economy = economy
	build.tower_selected.connect(_show_for)
	build.selection_cleared.connect(hide)
	_upgrade_button.pressed.connect(build.upgrade_selected)
	_sell_button.pressed.connect(build.sell_selected)
	hide()


func _show_for(tower: Tower) -> void:
	_name_label.text = Strings.get_text(tower.data.name_key)
	_level_label.text = Strings.get_text(&"UI_LEVEL") % tower.level
	var s := tower.stats()
	_stats_label.text = "%s: %.0f\n%s: %.0f\n%s: %.1f/s" % [
		Strings.get_text(&"UI_DAMAGE"), s.damage,
		Strings.get_text(&"UI_RANGE"), s.range_px,
		Strings.get_text(&"UI_FIRE_RATE"), s.fire_rate,
	]
	if tower.can_upgrade():
		_upgrade_button.text = Strings.get_text(&"UI_UPGRADE") % tower.upgrade_cost()
		_upgrade_button.show()
	else:
		_upgrade_button.hide()
	_sell_button.text = Strings.get_text(&"UI_SELL") % _economy.sell_refund(tower.invested)
	show()
