import re
import os
import sys

def check_file(filepath, patterns):
    print(f"Checking {filepath}...")
    if not os.path.exists(filepath):
        print(f"  [FAIL] File not found: {filepath}")
        return False

    with open(filepath, 'r') as f:
        content = f.read()

    all_pass = True
    for pattern, description in patterns:
        if re.search(pattern, content):
            print(f"  [PASS] {description}")
        else:
            print(f"  [FAIL] {description}")
            all_pass = False
    return all_pass

def check_resource_paths():
    print("Checking resource paths in .tres, .tscn, and .gd files...")
    all_pass = True
    resource_pattern = re.compile(r'res://([^\s"\'\) ]+)')

    for root, dirs, files in os.walk('src'):
        for file in files:
            if file.endswith(('.tres', '.tscn', '.gd')):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', errors='ignore') as f:
                    content = f.read()
                    paths = resource_pattern.findall(content)
                    for path in paths:
                        # Clean up path (sometimes they have extra characters if regex was too broad)
                        clean_path = path.split('"')[0].split("'")[0]

                        # Skip template paths with %
                        if '%' in clean_path:
                            continue

                        # Skip assets/real/ as it's gitignored and may not exist in sandbox
                        if clean_path.startswith('assets/real/'):
                            continue

                        if not os.path.exists(clean_path):
                            print(f"  [FAIL] {filepath}: Broken reference -> res://{clean_path}")
                            all_pass = False

    if all_pass:
        print("  [PASS] All resource paths are valid.")
    return all_pass

def main():
    success = True

    # Stats.gd logic
    if not check_file('src/entities/Stats.gd', [
        (r'var strength: int = 0', "strength property exists"),
        (r'var weak: int = 0', "weak property exists"),
        (r'var vulnerable: int = 0', "vulnerable property exists"),
        (r'modified_damage = floor\(modified_damage \* 1.5\)', "vulnerable damage multiplier exists"),
        (r'func end_turn\(\):', "end_turn function exists")
    ]): success = False

    # CardResource.gd logic
    if not check_file('src/cards/CardResource.gd', [
        (r'var hits: int = 1', "hits property exists"),
        (r'var vulnerable: int = 0', "vulnerable property exists"),
        (r'var exhaust: bool = false', "exhaust property exists"),
        (r'var self_damage: int = 0', "self_damage property exists"),
        (r'base_damage \+= user.stats.strength', "strength added to damage"),
        (r'base_damage = floor\(base_damage \* 0.75\)', "weak reduces damage"),
        (r'for i in range\(hits\):', "multi-hit logic exists"),
        (r't.stats.vulnerable \+= vulnerable', "applying vulnerable exists"),
        (r'user.stats.lose_hp\(self_damage\)', "self damage logic exists")
    ]): success = False

    # CombatManager.gd logic
    if not check_file('src/combat/CombatManager.gd', [
        (r'deck_manager.exhaust_card\(card\)', "exhaust logic exists"),
        (r'card.apply_effects\(player, targets, self\)', "delegation to apply_effects exists")
    ]): success = False

    # DeckManager.gd
    if not check_file('src/combat/DeckManager.gd', [
        (r'var exhaust_pile: Array\[CardResource\] = \[\]', "exhaust_pile exists"),
        (r'func exhaust_card\(card: CardResource\):', "exhaust_card function exists")
    ]): success = False

    # EntityUI.gd
    if not check_file('src/ui/EntityUI.gd', [
        (r'status_text \+= " Str:%d" % stats.strength', "Strength display exists"),
        (r'status_text \+= " Vul:%d" % stats.vulnerable', "Vulnerable display exists")
    ]): success = False

    # Resource path check
    if not check_resource_paths():
        success = False

    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()
