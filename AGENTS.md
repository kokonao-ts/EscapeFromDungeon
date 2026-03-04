# Agent Instructions for EscapeFromDungeon

## Verification

Before submitting any changes, you **must** run the verification script to ensure the project remains in a working state. This script checks for GDScript syntax errors, performs linting, and validates game logic and resource paths.

### Running Verification

Run the following command from the repository root:

```bash
./scripts/verify.sh
```

If the script fails, you must address the errors before submitting.

### Automation Tools

- `gdtoolkit`: Provides `gdparse` for syntax checking and `gdlint` for style checking.
- `manual_verify.py`: A custom Python script that checks for specific game logic implementations and verifies that all `res://` paths in resources actually exist.

## Coding Standards

- Follow GDScript 2.0 conventions.
- Use explicit typed arrays (e.g., `Array[CardResource]`) to avoid runtime errors.
- Ensure all new resources (.tres) and scenes (.tscn) have valid references.
