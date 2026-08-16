# Ashen Oath — Combat Slice (Godot 4)

An offline 2D action game built in **Godot 4.3** (GDScript), developed from the
`ashen_oath_game_brief.md` design document. This repository is the **combat slice**
(the brief's explicit first milestone): one hunter, two enemy families, the Mill Bride
boss, and the full readable-combat loop — no account, no ads, no network.

## What is implemented
- **Ren Vale** (balanced duelist): 4-hit ground string, hold-to-heavy, dodge, guard/parry,
  two skills (Oath Nail seal, Crosswind Step), and the **Seven Quiet Cuts** ultimate.
- **Enemies**: Husk (slow, telegraphs, teaches finisher) and Raker (3-hit combo, 3rd hit
  parry-friendly).
- **Mill Bride boss**: saw-sweep projectiles (reflectable), fabric volley, spin sweep,
  two phases, posture-break windows.
- **Systems**: posture / stagger / finisher, Resolve -> Ultimate, guard meter + guard break,
  dodge i-frames (2 charges), perfect-dodge slow, hit-stop, screen shake, camera follow.
- **Touch controls**: floating virtual stick (left), Attack / Guard / Skill A / Skill B /
  Ultimate buttons (right), horizontal swipe to dash, pause.
- **Offline local save** (best time + rank) via `user://`.
- **Landscape, 16:9 design frame**, GL Compatibility renderer for broad Android support.

## Build (GitHub Actions)
Pushing to `main` triggers `.github/workflows/build-android.yml`, which installs Godot 4.3,
the Android SDK, and exports a signed **APK** artifact.
1. Open the **Actions** tab → *Build Android* → the run triggered by your push.
2. When it finishes, download the **ashen-oath-android** artifact (contains `ashen-oath.apk`).
3. Install on an Android device (enable "Install unknown apps" for your file manager).

The build signs with a generated debug keystore, so **no secret is required** in CI.

## Build locally (optional)
1. Install [Godot 4.3](https://godotengine.org/) and the Android SDK (platform 34, build-tools 34).
2. Set the Android SDK path in Editor → Editor Settings → Export → Android.
3. Import this folder, open **Project → Export**, pick the Android preset, and export.

## Controls
- **Left side drag** — move.
- **ATK** — strike / advance the combo. **Hold ATK** — heavy.
- **GRD** — guard; tap on the enemy's cue to **parry**.
- **Swipe right** — dash (i-frames; perfect dodge slows enemies).
- **A / B** — Oath Nail (pin) / Crosswind Step.
- **ULT** — Seven Quiet Cuts (lights at full Resolve).
- Break an enemy's posture, then strike to **finish**.

## Notes
- The HUD text is currently English. Arabic localization strings and RTL are structured for
  later; adding a Noto Sans Arabic `.ttf` via a Theme/FontFile enables Arabic glyphs.
- Art is procedural (ink-silhouette placeholders) so the slice is self-contained; the brief's
  hand-painted pipeline drops in without code changes.
- All IP here is original; the game is fully offline.
