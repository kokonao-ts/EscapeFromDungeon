import os

cards = [
    # Starter
    {"id": "bash", "name": "Bash", "cost": 2, "type": 0, "target": 0, "description": "Deal 8 damage. Apply 2 Vulnerable.", "damage": 8, "vulnerable": 2},

    # Common
    {"id": "anger", "name": "Anger", "cost": 0, "type": 0, "target": 0, "description": "Deal 6 damage. Add a copy of this card to your discard pile.", "damage": 6},
    {"id": "armaments", "name": "Armaments", "cost": 1, "type": 1, "target": 1, "description": "Gain 5 Block. Upgrade a card in your hand for the rest of combat.", "block": 5},
    {"id": "body_slam", "name": "Body Slam", "cost": 1, "type": 0, "target": 0, "description": "Deal damage equal to your current Block."},
    {"id": "clash", "name": "Clash", "cost": 0, "type": 0, "target": 0, "description": "Can only be played if every card in your hand is an Attack. Deal 14 damage.", "damage": 14},
    {"id": "cleave", "name": "Cleave", "cost": 1, "type": 0, "target": 2, "description": "Deal 8 damage to ALL enemies.", "damage": 8},
    {"id": "clothesline", "name": "Clothesline", "cost": 2, "type": 0, "target": 0, "description": "Deal 12 damage. Apply 2 Weak.", "damage": 12, "weak": 2},
    {"id": "flex", "name": "Flex", "cost": 0, "type": 1, "target": 1, "description": "Gain 2 Strength. At the end of your turn, lose 2 Strength.", "strength": 2},
    {"id": "havoc", "name": "Havoc", "cost": 1, "type": 1, "target": 1, "description": "Play the top card of your draw pile and Exhaust it."},
    {"id": "headbutt", "name": "Headbutt", "cost": 1, "type": 0, "target": 0, "description": "Deal 9 damage. Put a card from your discard pile on top of your draw pile.", "damage": 9},
    {"id": "heavy_blade", "name": "Heavy Blade", "cost": 2, "type": 0, "target": 0, "description": "Deal 14 damage. Strength affects Heavy Blade 3 times.", "damage": 14}, # Simplified
    {"id": "iron_wave", "name": "Iron Wave", "cost": 1, "type": 0, "target": 0, "description": "Gain 5 Block. Deal 5 damage.", "damage": 5, "block": 5},
    {"id": "perfected_strike", "name": "Perfected Strike", "cost": 2, "type": 0, "target": 0, "description": "Deal 6 damage. Deals an additional 2 damage for ALL of your cards containing 'Strike'.", "damage": 6},
    {"id": "pommel_strike", "name": "Pommel Strike", "cost": 1, "type": 0, "target": 0, "description": "Deal 9 damage. Draw 1 card.", "damage": 9, "draw_cards": 1},
    {"id": "shrug_it_off", "name": "Shrug It Off", "cost": 1, "type": 1, "target": 1, "description": "Gain 8 Block. Draw 1 card.", "block": 8, "draw_cards": 1},
    {"id": "sword_boomerang", "name": "Sword Boomerang", "cost": 1, "type": 0, "target": 2, "description": "Deal 3 damage to a random enemy 3 times.", "damage": 3, "hits": 3},
    {"id": "thunderclap", "name": "Thunderclap", "cost": 1, "type": 0, "target": 2, "description": "Deal 4 damage and apply 1 Vulnerable to ALL enemies.", "damage": 4, "vulnerable": 1},
    {"id": "true_grit", "name": "True Grit", "cost": 1, "type": 1, "target": 1, "description": "Gain 7 Block. Exhaust a random card from your hand.", "block": 7},
    {"id": "twin_strike", "name": "Twin Strike", "cost": 1, "type": 0, "target": 0, "description": "Deal 5 damage twice.", "damage": 5, "hits": 2},
    {"id": "warcry", "name": "Warcry", "cost": 0, "type": 1, "target": 1, "description": "Draw 1 card. Put a card from your hand onto the top of your draw pile. Exhaust.", "draw_cards": 1, "exhaust": True},
    {"id": "wild_strike", "name": "Wild Strike", "cost": 1, "type": 0, "target": 0, "description": "Deal 12 damage. Shuffle a Wound into your draw pile.", "damage": 12},

    # Uncommon
    {"id": "battle_trance", "name": "Battle Trance", "cost": 0, "type": 1, "target": 1, "description": "Draw 3 cards. You cannot draw additional cards this turn.", "draw_cards": 3},
    {"id": "blood_for_blood", "name": "Blood for Blood", "cost": 4, "type": 0, "target": 0, "description": "Costs 1 less energy for each time you lose HP in this combat. Deal 18 damage.", "damage": 18},
    {"id": "bloodletting", "name": "Bloodletting", "cost": 0, "type": 1, "target": 1, "description": "Lose 3 HP. Gain 2 Energy.", "energy_gain": 2, "self_damage": 3},
    {"id": "burning_pact", "name": "Burning Pact", "cost": 1, "type": 1, "target": 1, "description": "Exhaust 1 card. Draw 2 cards.", "draw_cards": 2},
    {"id": "carnage", "name": "Carnage", "cost": 2, "type": 0, "target": 0, "description": "Ethereal. Deal 20 damage.", "damage": 20},
    {"id": "combust", "name": "Combust", "cost": 1, "type": 2, "target": 1, "description": "At the end of your turn, lose 1 HP and deal 5 damage to ALL enemies."},
    {"id": "dark_embrace", "name": "Dark Embrace", "cost": 2, "type": 2, "target": 1, "description": "Whenever a card is Exhausted, draw 1 card."},
    {"id": "disarm", "name": "Disarm", "cost": 1, "type": 1, "target": 0, "description": "Enemy loses 2 Strength. Exhaust.", "exhaust": True},
    {"id": "dual_wield", "name": "Dual Wield", "cost": 1, "type": 1, "target": 1, "description": "Choose an Attack or Power card in your hand. Add a copy of it into your hand."},
    {"id": "entrench", "name": "Entrench", "cost": 2, "type": 1, "target": 1, "description": "Double your current Block."},
    {"id": "evolve", "name": "Evolve", "cost": 1, "type": 2, "target": 1, "description": "Whenever you draw a Status card, draw 1 card."},
    {"id": "feel_no_pain", "name": "Feel No Pain", "cost": 1, "type": 2, "target": 1, "description": "Whenever a card is Exhausted, gain 3 Block."},
    {"id": "fire_breathing", "name": "Fire Breathing", "cost": 1, "type": 2, "target": 1, "description": "Whenever you draw a Status or Curse card, deal 6 damage to ALL enemies."},
    {"id": "flame_barrier", "name": "Flame Barrier", "cost": 2, "type": 1, "target": 1, "description": "Gain 12 Block. Whenever you are attacked this turn, deal 4 damage back.", "block": 12},
    {"id": "ghostly_armor", "name": "Ghostly Armor", "cost": 1, "type": 1, "target": 1, "description": "Ethereal. Gain 10 Block.", "block": 10},
    {"id": "hemokinesis", "name": "Hemokinesis", "cost": 1, "type": 0, "target": 0, "description": "Lose 2 HP. Deal 15 damage.", "damage": 15, "self_damage": 2},
    {"id": "inflame", "name": "Inflame", "cost": 1, "type": 2, "target": 1, "description": "Gain 2 Strength.", "strength": 2},
    {"id": "intimidate", "name": "Intimidate", "cost": 0, "type": 1, "target": 2, "description": "Apply 1 Weak to ALL enemies. Exhaust.", "weak": 1, "exhaust": True},
    {"id": "metallicize", "name": "Metallicize", "cost": 1, "type": 2, "target": 1, "description": "At the end of your turn, gain 3 Block."},
    {"id": "power_through", "name": "Power Through", "cost": 1, "type": 1, "target": 1, "description": "Add 2 Wounds to your hand. Gain 15 Block.", "block": 15},
    {"id": "rage", "name": "Rage", "cost": 0, "type": 1, "target": 1, "description": "Whenever you play an Attack this turn, gain 3 Block."},
    {"id": "rampage", "name": "Rampage", "cost": 1, "type": 0, "target": 0, "description": "Deal 8 damage. Every time this card is played, increase its damage by 5 for this combat.", "damage": 8},
    {"id": "reckless_charge", "name": "Reckless Charge", "cost": 0, "type": 0, "target": 0, "description": "Deal 7 damage. Shuffle a Dazed into your draw pile.", "damage": 7},
    {"id": "rupture", "name": "Rupture", "cost": 1, "type": 2, "target": 1, "description": "Whenever you lose HP from a card, gain 1 Strength."},
    {"id": "searing_blow", "name": "Searing Blow", "cost": 2, "type": 0, "target": 0, "description": "Deal 12 damage. Can be upgraded any number of times.", "damage": 12},
    {"id": "second_wind", "name": "Second Wind", "cost": 1, "type": 1, "target": 1, "description": "Exhaust all non-Attack cards in your hand. Gain 5 Block for each card Exhausted."},
    {"id": "seeing_red", "name": "Seeing Red", "cost": 1, "type": 1, "target": 1, "description": "Gain 2 energy. Exhaust.", "energy_gain": 2, "exhaust": True},
    {"id": "sentinel", "name": "Sentinel", "cost": 1, "type": 1, "target": 1, "description": "Gain 5 Block. If this card is Exhausted, gain 2 energy.", "block": 5},
    {"id": "sever_soul", "name": "Sever Soul", "cost": 2, "type": 0, "target": 0, "description": "Exhaust all non-Attack cards in your hand. Deal 16 damage.", "damage": 16},
    {"id": "shockwave", "name": "Shockwave", "cost": 2, "type": 1, "target": 2, "description": "Apply 3 Weak and Vulnerable to ALL enemies. Exhaust.", "weak": 3, "vulnerable": 3, "exhaust": True},
    {"id": "spot_weakness", "name": "Spot Weakness", "cost": 1, "type": 1, "target": 0, "description": "If the enemy intends to attack, gain 3 Strength."},
    {"id": "upper_cut", "name": "Upper Cut", "cost": 2, "type": 0, "target": 0, "description": "Deal 13 damage. Apply 1 Weak. Apply 1 Vulnerable.", "damage": 13, "weak": 1, "vulnerable": 1},
    {"id": "whirlwind", "name": "Whirlwind", "cost": -1, "type": 0, "target": 2, "description": "Deal 5 damage to ALL enemies X times."},

    # Rare
    {"id": "barricade", "name": "Barricade", "cost": 3, "type": 2, "target": 1, "description": "Block no longer expires at the start of your turn."},
    {"id": "berserk", "name": "Berserk", "cost": 0, "type": 2, "target": 1, "description": "Gain 2 Vulnerable. At the start of your turn, gain 1 Energy.", "vulnerable": 2}, # Self vulnerable
    {"id": "bludgeon", "name": "Bludgeon", "cost": 3, "type": 0, "target": 0, "description": "Deal 32 damage.", "damage": 32},
    {"id": "brutality", "name": "Brutality", "cost": 0, "type": 2, "target": 1, "description": "At the start of your turn, lose 1 HP and draw 1 card."},
    {"id": "corruption", "name": "Corruption", "cost": 3, "type": 2, "target": 1, "description": "Skills cost 0. Whenever you play a Skill, Exhaust it."},
    {"id": "demon_form", "name": "Demon Form", "cost": 3, "type": 2, "target": 1, "description": "At the start of your turn, gain 2 Strength."},
    {"id": "double_tap", "name": "Double Tap", "cost": 1, "type": 1, "target": 1, "description": "This turn, your next Attack is played twice."},
    {"id": "exhume", "name": "Exhume", "cost": 1, "type": 1, "target": 1, "description": "Put a card from your Exhaust pile into your hand. Exhaust.", "exhaust": True},
    {"id": "feed", "name": "Feed", "cost": 1, "type": 0, "target": 0, "description": "Deal 10 damage. If this kills a non-minion enemy, raise your Max HP by 3. Exhaust.", "damage": 10, "exhaust": True},
    {"id": "fiend_fire", "name": "Fiend Fire", "cost": 2, "type": 0, "target": 0, "description": "Exhaust your hand. Deal 7 damage for each Exhausted card. Exhaust.", "damage": 7, "exhaust": True},
    {"id": "immolate", "name": "Immolate", "cost": 2, "type": 0, "target": 2, "description": "Deal 21 damage to ALL enemies. Add a Burn into your discard pile.", "damage": 21},
    {"id": "impervious", "name": "Impervious", "cost": 2, "type": 1, "target": 1, "description": "Gain 30 Block. Exhaust.", "block": 30, "exhaust": True},
    {"id": "juggernaut", "name": "Juggernaut", "cost": 2, "type": 2, "target": 1, "description": "Whenever you gain Block, deal 5 damage to a random enemy."},
    {"id": "limit_break", "name": "Limit Break", "cost": 1, "type": 1, "target": 1, "description": "Double your Strength. Exhaust.", "exhaust": True},
    {"id": "offering", "name": "Offering", "cost": 0, "type": 1, "target": 1, "description": "Lose 6 HP. Gain 2 energy. Draw 3 cards. Exhaust.", "energy_gain": 2, "draw_cards": 3, "self_damage": 6, "exhaust": True},
    {"id": "reaper", "name": "Reaper", "cost": 2, "type": 0, "target": 2, "description": "Deal 4 damage to ALL enemies. Heal HP equal to unblocked damage. Exhaust.", "damage": 4, "exhaust": True},
]

template = """[gd_resource type="Resource" script_class="CardResource" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/cards/CardResource.gd" id="1_x"]

[resource]
script = ExtResource("1_x")
card_id = "{id}"
card_name = "{name}"
cost = {cost}
type = {type}
target = {target}
icon = "card_placeholder.png"
description = "{description}"
damage = {damage}
block = {block}
draw_cards = {draw_cards}
energy_gain = {energy_gain}
hits = {hits}
vulnerable = {vulnerable}
weak = {weak}
strength = {strength}
exhaust = {exhaust}
self_damage = {self_damage}
"""

os.makedirs("src/cards/resources", exist_ok=True)

for card in cards:
    # Fill defaults
    card.setdefault("damage", 0)
    card.setdefault("block", 0)
    card.setdefault("draw_cards", 0)
    card.setdefault("energy_gain", 0)
    card.setdefault("hits", 1)
    card.setdefault("vulnerable", 0)
    card.setdefault("weak", 0)
    card.setdefault("strength", 0)
    card.setdefault("exhaust", "false")
    card.setdefault("self_damage", 0)

    if isinstance(card["exhaust"], bool):
        card["exhaust"] = "true" if card["exhaust"] else "false"

    # Capitalize card name if it's just the ID
    if not card.get("name"):
        card["name"] = card["id"].replace("_", " ").title()

    content = template.format(**card)
    filepath = f"src/cards/resources/{card['name'].replace(' ', '')}.tres"
    with open(filepath, "w") as f:
        f.write(content)
    print(f"Generated {filepath}")
