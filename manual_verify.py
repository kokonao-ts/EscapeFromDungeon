import re

def check_file(filepath, patterns):
    print(f"Checking {filepath}...")
    with open(filepath, 'r') as f:
        content = f.read()
    for pattern, description in patterns:
        if re.search(pattern, content):
            print(f"  [PASS] {description}")
        else:
            print(f"  [FAIL] {description}")

# Stats.gd logic
check_file('src/entities/Stats.gd', [
    (r'var strength: int = 0', "strength property exists"),
    (r'var weak: int = 0', "weak property exists"),
    (r'var vulnerable: int = 0', "vulnerable property exists"),
    (r'modified_damage = floor\(modified_damage \* 1.5\)', "vulnerable damage multiplier exists"),
    (r'func end_turn\(\):', "end_turn function exists")
])

# CardResource.gd properties
check_file('src/cards/CardResource.gd', [
    (r'var hits: int = 1', "hits property exists"),
    (r'var vulnerable: int = 0', "vulnerable property exists"),
    (r'var exhaust: bool = false', "exhaust property exists"),
    (r'var self_damage: int = 0', "self_damage property exists")
])

# CombatManager.gd logic
check_file('src/combat/CombatManager.gd', [
    (r'base_damage \+= player.stats.strength', "strength added to damage"),
    (r'base_damage = floor\(base_damage \* 0.75\)', "weak reduces damage"),
    (r'for i in range\(card.hits\):', "multi-hit logic exists"),
    (r'target.stats.vulnerable \+= card.vulnerable', "applying vulnerable exists"),
    (r'player.take_damage\(card.self_damage\)', "self damage logic exists"),
    (r'deck_manager.exhaust_card\(card\)', "exhaust logic exists")
])

# DeckManager.gd
check_file('src/combat/DeckManager.gd', [
    (r'var exhaust_pile: Array\[CardResource\] = \[\]', "exhaust_pile exists"),
    (r'func exhaust_card\(card: CardResource\):', "exhaust_card function exists")
])

# EntityUI.gd
check_file('src/ui/EntityUI.gd', [
    (r'status_text \+= " Str: %d" % stats.strength', "Strength display exists"),
    (r'status_text \+= " Vul: %d" % stats.vulnerable', "Vulnerable display exists")
])
