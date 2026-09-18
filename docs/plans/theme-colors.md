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

## Accent → logo green (client requirement)

- `--accent` is the logo's green, `#607248`, exactly — the client specified it.
  Batch 2's default accent is therefore `#607248`, not the design file's `#a8bb5c`.
- The supporting shades keep their previous lightness, re-hued to the logo's hue
  with saturation scaled to its lower chroma (26 vs 50). The dark slot tints
  needed a small bump over proportional (wash C7→11, edge C13→15) to stay
  ≥ ΔE 4 from the neutral lines.
- Known consequence: the accent as **small text** is below the 4.5:1
  guideline — eyebrows, "N open", links. (Measured on the black background
  adopted next: 4.0:1 on the page, 3.7:1 on a surface, 3.3:1 on a schedule
  slot. An earlier note said 3.5:1 on black; that figure was against the old
  `#14150f` background.) `--accent-dim` (6.1:1) is the readable same-hue option if the client
  agrees to it for small text only.

## Background → logo black

- `--bg` is `#000000`, the logo PNG's baked-in background. The logo is placed
  with `mix-blend-mode: screen` to hide that black, which also lightened the
  logo's own colors against the old `#14150f`; on black, screen is a no-op and
  the nav logo renders pixel-exact (`#607248`, `#d3c7b7`, checked in a 4×
  headless capture).
- The dark "ground" tokens (surfaces, lines, slot tints, borders) dropped by the
  same L* as the background (6.5), keeping their tint — same layering, based on
  black. Text colors unchanged.
- Batch 2's default background is therefore `#000000`.

## Batch 2 — Derive the palette from three colors

### Design
- **`Theme`** (`app/models/theme.rb`), a pure value object: `Theme.new(background:, text:, accent:)`
  with `DEFAULTS = { background: "#000000", text: "#f2f1e8", accent: "#607248" }`.
- **One rule for every other shade**, in CIE Lab:
  `shade = background + s·(text − background) + u·(accent − background)`,
  with a fixed `(s, u)` per token. The pairs are fitted to the current palette —
  checked with a throwaway least-squares fit: all 13 derived shades land within
  **ΔE 1.5** of today's values (9 of them within 0.5). Because the rule moves
  toward whatever the text and accent are, a light theme works the same way: its
  surfaces go slightly darker than white and its slot tints go pale green.
- Lab → sRGB clamps to gamut, so every output is a valid `#rrggbb`.
- The three error colors stay fixed constants in `Theme`.
- `Theme#variables` → `{ "--bg" => "#000000", … }` for all 19 color tokens.
- **Layout** emits `<style>:root{…}</style>` from `Site.instance.theme` and
  `theme-color` from its background. The color tokens leave `site.css :root`
  (fonts and `--stripes` stay) — one source of truth.
- `Site#theme` returns `Theme.default` in this batch (no columns yet).
- The palette test's color math moves into `Theme` and the test reuses it.

### Contract pin
- `Theme.new` takes three `#rrggbb` strings (validated upstream in Batch 3;
  `Theme` raises `ArgumentError` on anything else — it is never handed raw input).
- Output: exactly the tokens `site.css` references, each a lowercase `#rrggbb`.
- Pure: no I/O, same input → same output.

### AC ↔ test map (Batch 2)

| AC | Test file | Test name | Lens |
|----|-----------|-----------|------|
| Defaults look like today | `test/models/theme_test.rb` | `the default theme reproduces the current palette within ΔE 2` | Parity |
| Every token defined | `test/assets/palette_test.rb` | `every variable the stylesheet uses is defined` (now counting `Theme` output) | Contract |
| No colors left in CSS | `test/assets/palette_test.rb` | `site.css contains no color literals` | Honest surface |
| Palette stays distinct | `test/assets/palette_test.rb` | `no two theme colors are within ΔE 3 of each other` | Parity |
| Light theme works | `test/models/theme_test.rb` | `a light theme derives distinct colors and keeps text readable on every surface` | Contract |
| Extreme input stays valid | `test/models/theme_test.rb` | `saturated or extreme inputs still produce valid hex for every token` | Contract |
| Bad input can't reach CSS | `test/models/theme_test.rb` | `anything but six-digit hex is refused` | Contract |
| Page carries the theme | `test/controllers/pages_controller_test.rb` | `the page declares the theme colors in a style tag` | Contract |
| Browser chrome matches | `test/controllers/pages_controller_test.rb` | `theme-color matches the palette background` (now read from `Theme`) | Contract |
| No visible change | — evidence | Pixel diff vs. a fresh "before" capture, desktop and phone | Parity |

### Batch 2 result — done

- All map rows green; full suite 86/86.
- Map correction during execution: the WCAG row expected the logo green at
  3.5:1 on black; it is **4.0:1** (3.5 was against the old `#14150f`). The test
  was wrong, not the code — fixed, and the figures in this plan corrected.
- Pixel diff vs. a fresh pre-Batch-2 capture: phone 11 pixels off (noise is ~8);
  desktop 246, all inside the embedded Google Map, which loaded an extra
  point-of-interest label on one run. No difference from the theme.
- Layout reads `Site.instance` once per render (review pass).

## Batch 3 — Admin color editor with live sample

### Design
- Migration: `sites.theme_background`, `theme_text`, `theme_accent` (nullable
  strings; `nil` = default). `Site#theme` builds from them, falling back per
  color to the default for anything stored that isn't valid hex (defense in
  depth: a value set from the console still can't reach the `<style>` tag).
- `Site` validations: strip, add a missing `#`, downcase; blank → `nil`;
  anything else that isn't `#rrggbb` → error on that field. **Contrast never
  blocks a save** (decided): the sample shows text/background and
  accent/background ratios and flags anything under 4.5:1 / 3:1 **with a
  suggestion**: the nearest color of the same hue and saturation (lightness
  moved away from the background) that meets the guideline, with a **Use this**
  button that puts it in the picker. `Theme.suggest(color, against:, ratio:)`
  owns the search, so the preview and any later caller share it.
- **Settings → Colors**: three `<input type="color">` (with the hex shown), a
  **Reset colors** button (separate submit that nils all three and nothing else).
- **Live sample**: an `<iframe>` beside the pickers showing
  `GET /admin/settings/theme_preview?…` — a small page rendered with the real
  `site.css` and the real `Theme`: heading with accent, eyebrow, body and muted
  text, primary button, a program card, two schedule slots, a chip, a link, and
  the contrast ratios. A Stimulus controller updates the iframe `src`
  (debounced) as the pickers move. One implementation of the palette — the
  preview never re-derives colors in JavaScript.
- Preview endpoint is admin-only and never writes.

### AC ↔ test map (Batch 3)

| AC | Test file | Test name | Lens |
|----|-----------|-----------|------|
| Saves and shows on site | `test/controllers/admin_test.rb` | `admin saves theme colors and the public page uses them` | Contract |
| Normalizes input | `test/models/site_test.rb` | `theme colors normalize case and a missing #, and blank means default` | Contract |
| Rejects garbage / CSS injection | `test/models/site_test.rb` | `theme colors reject anything that isn't six-digit hex` | Contract |
| Low contrast warns, never blocks | `test/controllers/admin_test.rb` | `a low-contrast theme still saves, and the preview flags it` | Contract |
| Suggestion passes and keeps the hue | `test/models/theme_test.rb` | `a suggestion meets the ratio, keeps the hue, and moves as little as it can` | Contract |
| Suggestion on a light background | `test/models/theme_test.rb` | `on a light background the suggestion goes darker, not lighter` | Contract |
| No suggestion when none is needed | `test/models/theme_test.rb` | `a color that already passes is returned unchanged` | Honest surface |
| Preview offers it | `test/controllers/admin_test.rb` | `the preview suggests a readable color with a Use this button` | Contract |
| Reset | `test/controllers/admin_test.rb` | `reset colors restores the defaults and leaves other settings alone` | Contract |
| Anonymous can't save | `test/controllers/admin_test.rb` | `anonymous visitors cannot change theme colors` | Authz |
| Anonymous can't preview | `test/controllers/admin_test.rb` | `the theme preview is admin-only` | Authz |
| Preview renders the picked colors | `test/controllers/admin_test.rb` | `the preview renders the requested colors without saving them` | Contract |
| Preview survives bad input | `test/controllers/admin_test.rb` | `the preview falls back to the saved theme for invalid colors` | Contract |
| Bad DB value never renders | `test/controllers/pages_controller_test.rb` | `a malformed stored color never reaches the style tag` | Contract |
| Migration | — | `bin/rails db:migrate` up and down; `schema.rb` regenerated | Migrate & deploy |

### Batch 3 result — done (split 3a editor / 3b suggestions: 15 rows was past the slicing signal)

- All map rows green; full suite 100/100. Admin tests live in
  `test/controllers/admin/theme_test.rb` (the plan said `admin_test.rb`; that
  file is `admin/admin_test.rb`, and a theme file of its own reads better).
- Migration up → down → up clean; `schema.rb` has the three columns.
- Suggestion for the logo green as body text: `#697b50` (4.55:1). As an accent
  it isn't flagged (4.0:1 clears 3:1).
- Rendered the sample page offline (no login) for a low-contrast dark theme —
  warning, ratio, suggestion and Use this button present — and for a light
  theme, which derives correctly (pale green slots, light cards).
- Live interaction verified in the browser once Scotty signed in (no save):
  typing `#333333` for text redrew the sample and raised the warning (1.7:1,
  suggesting `#757575` at 4.6:1); Use this set both the hex field and the
  swatch to `#757575` and redrew the sample without the warning.

## Brand defaults and a themed admin (after Batch 3)

- **Defaults are the client's logo** (`docs/brand/vbc-logo.png`, supplied by
  the client): background `#000000`, text `#d3c7b8` (the lettering), accent
  `#607248` (the mark). A test reads the file's three most common colors and
  compares — a new logo can't leave the defaults behind. The site's text is
  now cream rather than the design file's `#f2f1e8` (decided, visible).
- The nav logo asset (`logo-valley-built-horizontal.png`) has cream `#d3c7b7`,
  one step off the client's file; invisible, left as is.
- With cream text, `--accent-wash` came out ΔE 2.8 from `--line`. Its (s, u)
  moved from (−0.098, 0.419) to (−0.14, 0.49): ΔE 4.3 from its nearest shade,
  and still within ΔE 1.8 of the hand-built value. The parity test now checks
  the formula against the hand-built palette *from its own base colors*
  (`#f2f1e8` text), since the defaults changed on purpose.
- **The admin and login follow the saved theme** (decided): `admin.css`'s
  `--a-*` roles map onto theme shades, its 13 literals are gone, and the palette
  tests now cover both stylesheets. Page background is `--bg` (black), panels
  and sidebar `--surface`, inputs `--surface-2`. The delete-link red joined the
  fixed error colors as `--danger`.
- Known risk, accepted: an unreadable saved theme makes the admin unreadable
  too. The sample warns before saving and Reset restores the defaults.
- A color equal to its default is stored as `nil`. The editor always submits
  all three fields, so saving Settings for anything else used to pin the
  defaults as custom colors. Reset only appears when a color is actually
  custom (`Site#theme_customized?`); otherwise the section says the defaults
  are in use.

## Batch 4.0 — Collapsible admin menu groups: Settings and Site content (before 4a/4b)

### Why
Settings holds the theme editor, its sample, soon a contrast guide — and image
quality. Site content is seven unrelated sections on one page with jump links.
Scotty: collapsible menu groups, one focused view per section.

### Design
- **One nav-group partial** used by both groups: a native `<details>`/`<summary>`
  (no JavaScript; keyboard and screen-reader support built in). The group title
  is a toggle, not a link. It renders `open` when the current page is one of its
  items and closed elsewhere; the current item is marked active.
- **Site content ▾** — one page per section, from the existing
  `Admin::SitesController::SECTIONS` (Contact, Hero, Programs/steps & schedule,
  Drop-in, Membership, Find us). Routes `/admin/site/:section/edit` and
  `PATCH /admin/site/:section`; the slug is the section name parameterized.
  Each page permits **only its own section's fields**; the hero photo
  upload/remove handling moves with it. Unknown section → 404. The old
  `/admin/site/edit` → first section. Jump links go away.
- **Settings ▾** — Theme, Photos, **PushPress** (moved from Site content: it is
  configuration, not copy). `namespace :settings` with
  `resource :theme` (`edit update`, `get :preview`), `resource :photos`,
  `resource :pushpress`; each permits only its own fields. `/admin/settings` and
  the old `/admin/settings/edit` → Theme. `SettingsController` and its view go.
- The list pages (Programs, Pillars, …) stay top-level for now.

### AC ↔ test map

**4.0a — menu groups + Settings**

| AC | Test file | Test name | Lens |
|----|-----------|-----------|------|
| Groups collapse; open on their own pages | `test/controllers/admin/navigation_test.rb` | `a menu group is open on its own pages and closed elsewhere, with the current page marked` | Contract |
| Group title is a toggle, not a link | `test/controllers/admin/navigation_test.rb` | `a menu group's title is a toggle, not a link` | Contract |
| Each settings page saves only its fields | `test/controllers/admin/settings_test.rb` | `each settings page ignores fields that belong to another` | Authz / Contract |
| Old address still works | `test/controllers/admin/settings_test.rb` | `the old settings address lands on the theme page` | Contract |
| Anonymous blocked | `test/controllers/admin/settings_test.rb` | `anonymous visitors cannot open or save any settings page` | Authz |
| Theme unchanged | `test/controllers/admin/theme_test.rb` | existing tests at the new paths | Contract |
| All pages render | `test/controllers/admin/admin_test.rb` | `every admin page renders` (paths updated) | Contract |

**4.0b — Site content sections**

| AC | Test file | Test name | Lens |
|----|-----------|-----------|------|
| One section per page | `test/controllers/admin/site_content_test.rb` | `each section page shows only that section's fields` | Contract |
| Saves only its section | `test/controllers/admin/site_content_test.rb` | `saving a section ignores fields from other sections` | Authz / Contract |
| Hero photo still uploads/removes | `test/controllers/admin/site_content_test.rb` | `the hero section uploads and removes the photo` | Contract |
| Unknown section | `test/controllers/admin/site_content_test.rb` | `an unknown section is not found` | Contract |
| Old address | `test/controllers/admin/site_content_test.rb` | `the old site content address lands on the first section` | Contract |
| Anonymous blocked | `test/controllers/admin/site_content_test.rb` | `anonymous visitors cannot open or save a section` | Authz |

## Batch 4 — Readable by construction: 16 → 10 colors, design fixes, contrast guide

### Why
Measured on the logo defaults, five text pairings fall below WCAG AA even though
the editor warns about nothing: "11 open" on a slot 3.2:1, footer links and
placeholders 3.7:1, small green labels and links 4.0:1, coach name on a slot
4.2:1, button and announcement text 4.0:1. The derived shades sit at fixed
positions between the three picks, so their contrast is whatever that position
yields. Setting text shades *by contrast* guarantees them for any theme, and —
because readable text on this background only has room between 4.5:1 and 10.1:1
— collapses the near-duplicate text shades on its own.

### Design
- **One list of pairings** in `Theme` — every place text sits on a color: role,
  foreground, background, minimum (4.5 normal text, 3 large text). It drives the
  admin guide, the warnings and the tests; nothing restates it.
- **Ten colors** (+4 fixed error colors):

  | Role | Set by |
  |---|---|
  | `--bg`, `--ink`, `--accent` | the admin's picks |
  | `--ink-soft` | ~7:1 on the hardest background* |
  | `--muted` | 4.5:1 on the hardest background* |
  | `--accent-text` | `Theme.suggest(accent, …, 4.5)` on the hardest background* — logo hue, lightness moved just enough |
  | `--surface` | fixed step from the background (cards, panels) |
  | `--line` | fixed step (all borders) |
  | `--accent-wash` | fixed step toward the accent (slots, selected) |
  | `--accent-line` | fixed step toward the accent (green borders, hover) |

  \*Hardest background = whichever of `--bg`, `--surface`, `--accent-wash` gives
  the text the least contrast, per theme. If the picks themselves can't reach a
  target (text too close to the background), text shades stop at the text
  color and the guide shows the failure on the pick.
- **Merges:** `surface-2` → `surface`; `line-strong` → `line`; `muted-soft` →
  `muted`; `accent-wash-2` → slot hover changes border, not fill;
  `accent-edge` + `accent-border` → `accent-line`; `accent-dim` + `accent-pale`
  → `accent-text` (hover goes to `--ink`).
- **Text on the accent** (`--on-accent`): whichever of background or text
  contrasts more with the accent — a choice, not a new color. The logo green
  reaches 4.0:1 at best, so:
- **Design fixes where a color can't be fixed** (the green is the client's):
  primary button text 17px → 19px bold (large text, 3:1 — option B);
  announcement bar becomes the card shade with a green top edge and cream text
  (option C). Approved.
- **Danger text** (delete links) = `Theme.suggest("#e0785a", against: bg, 4.5)`,
  so it stays readable on a light theme too.
- **Admin contrast guide** under the sample: each pairing, its ratio, what it
  needs, pass/fail — for the colors in the pickers, before saving. Warnings with
  a suggestion remain, now only for the three picks.

### AC ↔ test map

**4a — the palette** (model + CSS)

| AC | Test file | Test name | Lens |
|----|-----------|-----------|------|
| Every pairing passes, several themes | `test/models/theme_test.rb` | `every pairing meets its minimum for the logo, light, and high-color themes` | Contract |
| Text shades hit their targets | `test/models/theme_test.rb` | `muted and accent text land at 4.5:1 on the hardest background, not above it` | Contract |
| Unreachable target doesn't overshoot | `test/models/theme_test.rb` | `when the picks can't reach a target, text shades stop at the text color` | Contract |
| On-accent picks the better side | `test/models/theme_test.rb` | `text on the accent is whichever of background or text reads better` | Contract |
| Ten, distinct | `test/assets/palette_test.rb` | existing: used / defined / no literals / ΔE ≥ 3 (now over 10) | Honest surface |
| Pairing list matches the CSS | `test/assets/palette_test.rb` | `every text color the stylesheets use on a background is in the pairing list` | Honest surface |

**4b — design fixes + guide** (CSS + admin)

| AC | Test file | Test name | Lens |
|----|-----------|-----------|------|
| Button text is large | `test/assets/palette_test.rb` | `primary button text is at least 19px bold` | Contract |
| Bar off the green | `test/controllers/pages_controller_test.rb` | `the announcement bar sits on the card shade` (CSS rule check) | Contract |
| Guide shows every pairing | `test/controllers/admin/theme_test.rb` | `the preview lists every pairing with its ratio and minimum` | Contract |
| Guide flags a failing pick | `test/controllers/admin/theme_test.rb` | `a pick that fails shows as failing in the guide, with a suggestion` | Contract |
| Visible change is the planned one | — evidence | before/after screenshots; list what changed | Parity |

## Agent loop checkpoints

- Before touching CSS: screenshot the current site (the "before" set) so the
  comparison is against real pixels, not memory.
- Red tests → report the RED map, continue.
- Batch 1 green → screenshots side by side + review pass.
- Ready → full suite + rubocop on touched Ruby files.

## Open questions

1. ~~Coach name dims slightly~~ — accepted.
2. ~~Contrast rule~~ — never block; warn in the sample (text under 4.5:1,
   accent under 3:1) with a same-hue suggestion and a Use this button.
   The client's green is 4.0:1 on black (3.3:1 on a schedule slot).
3. ~~Batch 4 design fixes~~ — approved: button B (19px bold), announcement
   bar C (card shade, green top edge). PushPress moves under Settings.
4. Order: 4.0a (menu groups + Settings) → 4.0b (Site content sections) →
   4a (palette) → 4b (design fixes + guide).
5. Later, maybe: fold list pages into their sections (Programs text + Programs
   list, Membership text + Membership options). Not in scope.
