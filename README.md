# Valley Built CrossFit

Marketing site for Valley Built CrossFit, built from the Claude Design file
(`design/`), with a small admin area and a live PushPress class schedule.

Rails 8.1 · SQLite · Hotwire (Turbo + Stimulus) · Solid Queue/Cache · Kamal.

## Local development

```sh
bundle install
bin/rails db:prepare        # creates the DB and seeds the design's copy
bin/rails server
```

- Site: http://localhost:3000
- Admin: http://localhost:3000/admin — sign in at `/login`, sign out at `/logout`
  (dev seed user `admin@example.com` / `password`)
- Put `PUSHPRESS_API_KEY=...` in `.env` (git-ignored) for the live schedule.
- Run `bin/rails dev:cache` once so the schedule is cached between page loads.

Tests: `bin/rails test` (PushPress is faked; no network).

## How the pieces fit

| Area | Where |
| --- | --- |
| Home page sections | `app/views/pages/*` |
| Styles (ported from the design) | `app/assets/stylesheets/site.css` |
| Editable content | `Site` (singleton copy/settings), `Program`, `Pillar`, `Step`, `MembershipOption`, `Coach`, `Faq`, `Workout` |
| Admin CRUD | `app/controllers/admin/*` (generic `ResourcesController`) |
| “Get your options” form | `Lead` → saved + emailed via `LeadMailer`, listed under Admin → Inquiries |

### PushPress

`Pushpress::Client` talks to the Platform API v3 (`API-KEY` header).
`Schedule` pulls a Sun–Sat week of classes (matching PushPress), counts reservations per class,
looks up coach names, and caches the result for 10 minutes.
`RefreshScheduleJob` re-warms the next three weeks every 5 minutes
(`config/recurring.yml`), so visitors never wait on PushPress.

- “Reserve spot” links to the class's PushPress landing page.
- PushPress doesn't expose class capacity, so “spots open” uses
  **Admin → Site content → PushPress → Class capacity**. Class types listed
  as uncapped (default `General`, e.g. Open Build) show “Open session”.
- Workouts of the day are entered in Admin → Workouts (PushPress's API has no WOD endpoint).

## Deploying to your own server (Kamal)

1. Install Docker on the server and point DNS for the domain at it.
2. Edit `config/deploy.yml`: server IP, `proxy.host`, `APP_HOST`, SMTP settings.
3. Export secrets locally (read by `.kamal/secrets`):
   `PUSHPRESS_API_KEY`, `SMTP_USERNAME`, `SMTP_PASSWORD` (and keep `config/master.key`).
4. `bin/kamal setup` (first time), then `bin/kamal deploy` for updates.
5. Create your admin login: `bin/kamal create-admin`.

SQLite databases and uploaded photos live in the `valleybuilt_storage` Docker
volume. Back that volume up.
