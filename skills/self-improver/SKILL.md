---
name: self-improver
description: "Meta-skill that lets the bot audit, test, and auto-improve its own ClawBee skills. Analyzes SKILL.md files, runs test commands, detects failures, and rewrites broken steps. Triggers on: /improve skills, /skills audit, /skills test, /self-improve, /skills fix, 'improve your skills', 'check your skills', 'what skills are broken'."
metadata:
  author: open-claw
  version: 1.0.0
  category: meta
---

# Self-Improver

Audits and improves ClawBee's own skills. Reads each SKILL.md, runs test commands, identifies what's broken, and rewrites the failing parts.

---

## `/improve skills` — Full Audit + Auto-Fix

Run a complete audit of all installed skills, then fix any that fail.

### Step 1: Discover skills

```bash
ls /data/workspace/clawbee/skills/
```

For each skill directory found, read its `SKILL.md`:

```bash
cat /data/workspace/clawbee/skills/<skill>/SKILL.md
```

---

### Step 2: Test each skill

Run the smoke test for each skill. A skill **passes** if the command exits 0 and returns non-empty output.

**fridge-scanner**
```bash
python3 -c "from openai import OpenAI; print('openai ok')" && echo PASS || echo FAIL
```

**fridge-tracker**
```bash
sqlite3 /data/workspace/pantry.db "SELECT COUNT(*) FROM fridge;" 2>&1 && echo PASS || echo FAIL
```

**meal-planner**
```bash
sqlite3 /data/workspace/pantry.db "SELECT name FROM sqlite_master WHERE type='table';" 2>&1 && echo PASS || echo FAIL
```

**price-hunter**
```bash
sqlite3 /data/workspace/pantry.db "SELECT COUNT(*) FROM prices;" 2>&1 && echo PASS || echo FAIL
```

**shopping-agent**
```bash
sqlite3 /data/workspace/pantry.db "SELECT COUNT(*) FROM fridge;" 2>&1 && echo PASS || echo FAIL
```

**orchestrator**
```bash
sqlite3 /data/workspace/pantry.db "SELECT COUNT(*) FROM meal_plans;" 2>&1 && echo PASS || echo FAIL
```

---

### Step 3: Diagnose failures

For each **FAIL**:

1. Read the full SKILL.md for that skill
2. Identify the broken step (wrong path, missing dependency, stale command)
3. Produce a diff — old step vs. fixed step

Common failure patterns and fixes:

| Symptom | Root cause | Fix |
|---------|-----------|-----|
| `No such file or directory: /data/workspace/pantry.db` | DB not initialized | Run `sqlite3 /data/workspace/pantry.db "CREATE TABLE IF NOT EXISTS fridge (item TEXT PRIMARY KEY, quantity TEXT, updated_at TEXT);"` |
| `ModuleNotFoundError: openai` | Missing Python package | `python3 -m pip install openai --break-system-packages` |
| `No such file or directory: /data/workspace/clawbee` | Skills not cloned | `git clone --quiet https://github.com/mary4data/ClawBee.git /data/workspace/clawbee` |
| Script exits with wrong path | Script path drifted | Update SKILL.md step to use absolute path from `/data/workspace/clawbee/skills/<skill>/` |
| DB table missing | Schema not migrated | Add `CREATE TABLE IF NOT EXISTS` to the affected skill's init step |

---

### Step 4: Apply fixes

For each broken skill, rewrite the broken SKILL.md step in-place on the container:

```bash
# Backup first
cp /data/workspace/clawbee/skills/<skill>/SKILL.md /data/workspace/clawbee/skills/<skill>/SKILL.md.bak

# Write the fixed version
cat > /data/workspace/clawbee/skills/<skill>/SKILL.md << 'ENDOFSKILL'
[fixed content]
ENDOFSKILL
```

Then verify by re-running the Step 2 smoke test for that skill.

---

### Step 5: Report

Present results as a table:

```
Skill Audit Results — [timestamp]
──────────────────────────────────
✅ fridge-scanner   — openai package OK
✅ fridge-tracker   — pantry.db reachable
⚠️ meal-planner     — Fixed: meal_plans table was missing (now created)
✅ price-hunter     — prices table OK
✅ shopping-agent   — fridge table OK
✅ orchestrator     — meal_plans table OK

1 skill fixed. All skills operational.
```

---

## `/skills audit` — Read-Only Audit (No Fixes)

Same as above but skip Step 4. Just report what's broken without changing anything.

---

## `/skills test <skill>` — Test One Skill

Run the smoke test for a single skill and show its SKILL.md.

```bash
cat /data/workspace/clawbee/skills/<skill>/SKILL.md
```

Then run the relevant test from Step 2.

Report: PASS or FAIL with the raw output.

---

## `/skills update` — Pull Latest from GitHub

Pull the latest skill definitions from the ClawBee repo:

```bash
cd /data/workspace/clawbee && git pull --ff-only origin main 2>&1
```

If `git pull` fails (local changes):
```bash
cd /data/workspace/clawbee && git fetch origin && git reset --hard origin/main 2>&1
```

Then run `/skills audit` to confirm all skills still pass after the update.

---

## `/skills list` — Show All Skills

```bash
for d in /data/workspace/clawbee/skills/*/; do
  name=$(basename "$d")
  ver=$(grep -m1 'version:' "$d/SKILL.md" 2>/dev/null | sed 's/.*version: //')
  echo "$name  $ver"
done
```

---

## Notes

- Never delete a SKILL.md without backing it up first (`.bak` suffix)
- Only fix skills that actually fail the smoke test — don't rewrite working code
- After any fix, re-run the smoke test to confirm it passes before reporting it fixed
- The self-improver cannot improve itself (avoid infinite loops)
- All fixes apply to the **container copy** at `/data/workspace/clawbee/`. Push to GitHub separately with `/skills update` + manual commit
