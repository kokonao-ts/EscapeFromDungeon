class_name CardResource
extends Resource

enum Type { ATTACK, SKILL, POWER }
enum Target { ENEMY, SELF, ALL_ENEMIES }
enum CharacterClass {
	IRONCLAD,
	SILENT,
	WATCHER,
	NEUTRAL,
	GOBLIN_ASSASSIN,
	GOBLIN_MAGE,
	GOBLIN_SHARED
}
enum Rarity { COMMON, UNCOMMON, RARE, STARTER }

@export var card_id: String = ""
@export var card_name: String = "Card"
@export var character_class: CharacterClass = CharacterClass.IRONCLAD
@export var rarity: Rarity = Rarity.COMMON
@export var cost: int = 1
@export var type: Type = Type.ATTACK
@export var target: Target = Target.ENEMY
@export var icon: String = "card_placeholder.png"
@export_multiline var description: String = ""

@export_group("Effects")
@export var damage: int = 0
@export var block: int = 0
@export var draw_cards: int = 0
@export var energy_gain: int = 0
@export var hits: int = 1

@export_group("Statuses")
@export var vulnerable: int = 0
@export var weak: int = 0
@export var strength: int = 0
@export var burn: int = 0
@export var chill: int = 0

@export_group("Special")
@export var exhaust: bool = false
@export var self_damage: int = 0
@export var free_if_chilled: bool = false
@export var is_technique: bool = false
@export var is_goblin_special: bool = false

func apply_effects(user: Entity, targets: Array[Entity], combat_manager):
	# Damage Calculation
	var base_damage = damage
	if base_damage > 0:
		base_damage += user.stats.strength
		if user.stats.weak > 0:
			base_damage = floor(base_damage * 0.75)

	# Apply effects to targets
	for t in targets:
		if not t.is_alive():
			continue

		if base_damage > 0:
			for i in range(hits):
				t.take_damage(base_damage)
				# Thorns damage back to user
				if t.stats.thorns > 0:
					user.stats.lose_hp(t.stats.thorns)
				# Electrified damage back to user
				if t.stats.electrified > 0:
					user.stats.lose_hp(t.stats.electrified)

		if vulnerable > 0:
			t.stats.vulnerable += vulnerable
			t.update_ui()

		if weak > 0:
			t.stats.weak += weak
			t.update_ui()

		if burn > 0:
			t.stats.burn += burn
			t.update_ui()

		if chill > 0:
			combat_manager.apply_chill(t, chill)

	# Apply effects to user
	if block > 0:
		user.add_block(block)

	if draw_cards > 0:
		combat_manager.deck_manager.draw_cards(draw_cards)

	combat_manager.energy += energy_gain

	if strength > 0:
		user.stats.strength += strength
		user.update_ui()

	if self_damage > 0:
		user.stats.lose_hp(self_damage)
		user.update_ui()
