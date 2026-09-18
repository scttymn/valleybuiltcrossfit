# Plan: Theme palette → admin-editable colors

## Goal

Make the site's colors editable from admin. In order:

1. **Consolidate** the palette — collapse barely-distinguishable shades into a
   small, named set of theme tokens, and put every color the site uses behind one.
2. **Derive** that set from three base colors (background, text, accent).
3. **Edit** the three in admin, with a live sample beside the pickers.

Each step ships and looks right on its own before the next starts.

## Scope

Batch 1 (this plan, fully mapped): **palette consolidation** — CSS and layout
only. No database, no admin, no Ruby logic. The site should look the same, with
one deliberate exception listed below.

**Boundary:** admin keeps its own `--a-*` palette; PushPress email templates
(`docs/emails/`) are pasted into PushPress and never read site CSS.
**Boundary:** the three error colors (`.form-errors`) stay fixed — they mean
"something is wrong" and must never follow the accent.

## Evidence (A2)

Measured from `app/assets/stylesheets/site.css` with a throwaway script
(CIE76 ΔE; under ~2 is invisible, under ~5 barely perceptible side by side):

- **34 distinct hex colors**: 17 `:root` tokens + ~17 literals typed straight
  into rules (lines 45, 72-75, 108-109, 150, 161, 185-194, 206, 232, 235, 304,
  309), plus five `rgba()` overlays built from the background and accent, plus
  `theme-color` in `app/views/layouts/application.html.erb:7`.
- **40 color pairs sit within ΔE 5 of each other.** Worst offenders: `#191b15` /
  `#1a1c16` / `#1b1d17` (ΔE 0.5–1.0 — the same color three times), `#171913` vs
  `#191b15` (1.0), `#20241a` vs `#23261c` (1.2), `#232c16` vs `#26301a` (1.9),
  `muted` vs `muted-2` (2.7).
- Your read is right: perceptually this is **background, text, one accent,
  plus a gray** — the other 30 are tones of those.
- Token names describe the current colors (`--olive*`), so they'll lie as soon
  as the accent changes.
- No view reads a color variable; no JS does; admin CSS uses only `--a-*`.

## Design

### The consolidated palette — 16 tokens (+3 fixed error colors)

Every current color maps to the nearest token. ΔE of each move in brackets.

| Token | Value | Absorbs |
|---|---|---|
| `--bg` | `#14150f` | `#0f1009` (2.1), `#14150f`, `#171913` (2.0) |
| `--surface` | `#1a1c16` | `#191b15` (0.5), `#1a1c16`, `#1b1d17` (0.5) |
| `--surface-2` | `#20241a` | `#1d2016` (1.9), `#20241a`, `#23261c` (1.2) |
| `--line` | `#2e3125` | `#2c2f24` (1.1), `#33372a` (2.7) |
| `--line-strong` | `#434735` | `#3b4030` (3.4), `#3f4634` (≤3.4), `#4a4f3c` (≤3.4) |
| `--muted-soft` | `#6f7563` | — |
| `--muted` | `#939587` | `#8f9184` (1.6), `#96988a` (1.1), **`#a8a99b` (7.6)** |
| `--ink-soft` | `#c8c9bc` | `#c3c4b6` (1.9), `#cdcec2` (1.9) |
| `--ink` | `#f2f1e8` | — |
| `--accent-wash` | `#242c18` | `#22291a` (3.5), `#232c16` (1.4), `#26301a` (2.2) |
| `--accent-wash-2` | `#2c3718` | `#2b3315` (2.2), `#2c3a19` (2.1) |
| `--accent-edge` | `#37451f` | — |
| `--accent-border` | `#4a5a28` | — |
| `--accent-dim` | `#8a9a3b` | — |
| `--accent` | `#a8bb5c` | — |
| `--accent-pale` | `#cfdc94` | — |
| `--danger-bg` / `--danger-line` / `--danger-ink` | `#2a1812` / `#7a3b2a` / `#f0c2b0` | fixed |

**34 → 16 (+3).** Every move is ≤ ΔE 3.5 except one:

- **The coach name on a schedule slot** (`#a8a99b`, one use) joins `--muted`
  and gets a touch dimmer (ΔE 7.6). It's the only visible change. It still
  clears 4.5:1 contrast on the slot's green; if it reads worse in the
  screenshot, it moves to `--ink-soft` instead.

### Translucent overlays

The five `rgba()` values become
`color-mix(in srgb, var(--bg) 94%, transparent)` (and likewise for 88%/25%, the
accent texture at 5%, and the dialog backdrop on `--bg` at 84%). They then
follow the theme automatically in Batch 2, instead of being frozen copies of
today's background.

### Where things live

- All 16 tokens stay in `site.css :root` for this batch (Batch 2 moves them
  into generated output).
- `theme-color` meta reads the same background value; for now a single
  constant in the layout, pinned to `--bg` by test.
- `--olive*` → `--accent*` across the stylesheet.

## Contract pin

Surface: **the public stylesheet**, `app/assets/stylesheets/site.css`, read by
every public page.

- Every `var(--…)` the stylesheet uses **is defined in `:root`**. A misspelled
  or renamed variable doesn't error in CSS — it silently renders as nothing
  (transparent background, inherited text). That's the main failure mode of a
  rename this size, so it gets a test, not an eyeball.
- Every color token defined in `:root` **is used** at least once.
- **No color literal** (`#hex`, `rgb()`, `rgba()`, `hsl()`) appears outside
  `:root`, except the three fixed error colors, which live in `:root` too.
- **No two palette tokens within ΔE 3** — the consolidation can't quietly
  creep back.
- Layout `theme-color` equals `--bg`.

## Adversarial AC

1. Nothing in the stylesheet references a variable that isn't defined.
2. Nothing in `:root` is dead.
3. No color is typed directly into a rule — so Batch 2 has one place to change.
4. The palette stays consolidated.
5. The browser chrome color (`theme-color`) matches the page background.
6. The site looks the same as before, apart from the one listed change —
   checked by before/after screenshots at desktop and phone widths.

## Templates

Crash-gap, concurrency, at-least-once: not applicable — no writes, no async.

## AC ↔ test map (Batch 1)

New file `test/assets/palette_test.rb` (plain `ActiveSupport::TestCase` that
parses `site.css`), plus one row in the pages test.

| AC | Test file | Test name | Lens |
|----|-----------|-----------|------|
| 1 | `test/assets/palette_test.rb` | `every variable the stylesheet uses is defined in :root` | Contract |
| 2 | `test/assets/palette_test.rb` | `every color token in :root is used` | Honest surface |
| 3 | `test/assets/palette_test.rb` | `no color literal appears outside :root` | Honest surface |
| 4 | `test/assets/palette_test.rb` | `no two palette tokens are within ΔE 3 of each other` | Parity |
| 5 | `test/controllers/pages_controller_test.rb` | `theme-color matches the palette background` | Contract |
| 6 | — (evidence, not a test) | Before/after screenshots: home at 1280px and 390px, schedule dialog open, program card expanded, form with an error | Parity |

The existing suite also has to stay green — page tests assert on class names
that must not change.

## Batch 1 result — done

- 34 colors → 16 palette tokens + 3 fixed error colors; `--olive*` → `--accent*`.
- All map rows green (`bin/rails test test/assets/palette_test.rb
  test/controllers/pages_controller_test.rb`); full suite 77/77.
- Test fix during execution: the "every variable is defined" row first failed on
  `--program-count`, `--program-columns` and `--i`, which the programs partial
  sets in `style` attributes. The test now counts inline definitions in views,
  and was re-checked to still catch a misspelled `var(--inkk)`.
- Pixel diff vs. the pre-change capture (headless Chrome, 1280px and 390px,
  full page): 84 and 212 pixels differ by more than 2% per channel, against
  ~148 pixels of noise between two captures of the unchanged site. Opening week
  (slots, coach names) and the class dialog compared by eye before/after: no
  visible difference, including the dimmed coach name.
- `--stripes` (placeholder photo pattern) had two more literals not in the
  original count; they now use `--surface-2` / `--surface`.

## Later batches (titles only)

- **Batch 2 — Derive from three.** A Ruby `Theme` computes all 16 tokens from
  background, text and accent; the layout emits them. Defaults must reproduce
  Batch 1's palette within a stated tolerance (the earlier check showed neutrals
  within 1–7/255; accent shades need lightness shifts, not mixing).
- **Batch 3 — Admin editor with live sample.** Three color pickers on Settings,
  a sample panel beside them (button, card, schedule slot, body text, muted text,
  line) that repaints as you pick, six-digit-hex validation, a readable-contrast
  check, and Reset to defaults.

## Agent loop checkpoints

- Before touching CSS: screenshot the current site (the "before" set) so the
  comparison is against real pixels, not memory.
- Red tests → report the RED map, continue.
- Batch 1 green → screenshots side by side + review pass.
- Ready → full suite + rubocop on touched Ruby files.

## Open questions

1. The single visible change — slot coach name dims slightly. OK, or keep it
   on its own token?
