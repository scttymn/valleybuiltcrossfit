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
- To see the site as it will look at another moment (which day is today,
  which classes are over), start it with `TRAVEL_TO`:
  `TRAVEL_TO="2026-10-07 12:00" bin/rails server`. The clock stands still at
  that moment, in the app's time zone, until the server restarts. Development
  only; `config/initializers/travel_to.rb`. In Claude Code's browser pane, the
  `rails-oct7-noon` preview does the same.

Tests: `bin/rails test` (PushPress is faked; no network).

## How the pieces fit

| Area | Where |
| --- | --- |
| Home page sections | `app/views/pages/*` |
| Styles (ported from the design) | `app/assets/stylesheets/site.css` |
| Editable content | `Site` (singleton copy/settings), `Program`, `Pillar`, `Step`, `MembershipOption`, `Coach`, `Faq`, `Workout` |
| Admin CRUD | `app/controllers/admin/*` (generic `ResourcesController`) |
| “Get your options” form | `Lead` → saved + emailed via `LeadMailer`, listed under Admin → Inquiries |
| Error pages (404/422/500) | `ErrorsController` + `app/views/errors/`, rendered in the theme (`config.exceptions_app`); see them in development at `/404`, `/422`, `/500` |
| “Find us” map | `app/assets/images/map.svg`, colored by `site.css` from the theme; rebuild from OpenStreetMap with `bin/rails runner script/build_map.rb` if the gym moves |

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

## Deploying with Coolify

The repo builds from its own `Dockerfile` (Rails 8 default: Thruster + Puma on
port 80), so Coolify needs no build configuration beyond choosing the Dockerfile
build pack.

1. **Application** → source: this Git repo, branch `main`, build pack `Dockerfile`.
   Clone over SSH by the host's own address &mdash; `git.svnmns.com` is proxied
   through Cloudflare, which carries no SSH, so port 22 there is a black hole.
   Forgejo listens on **2222**: `ssh://git@192.168.0.99:2222/scttymn/valley-built-crossfit.git`.
   Add Coolify's public key under the repo's Settings → Deploy Keys; Forgejo
   scopes deploy keys per repository, so a key that works for another repo is
   still refused here.
2. **Persistent storage**: mount a volume at `/rails/storage`. The SQLite
   databases and every uploaded photo live there &mdash; without it, each deploy
   starts empty.
3. **Environment variables**:
   | Variable | Why |
   | --- | --- |
   | `RAILS_MASTER_KEY` | contents of `config/master.key` (not in git) |
   | `PUSHPRESS_API_KEY` | class schedule |
   | `PUSHPRESS_WEBHOOK_URL` | inquiry form → Grow workflow |
   | `TURNSTILE_SITE_KEY`, `TURNSTILE_SECRET_KEY` | form captcha (omit and it's off) |
   | `SOLID_QUEUE_IN_PUMA=true` | runs the schedule refresh + mail jobs in the web process |
   | `APP_HOST` | domain, for links in emails |
   | `DISABLE_SSL=true` | only on a plain-http host, e.g. the generated `sslip.io` URL before a real domain is pointed at it. Without it, session cookies are marked secure and nobody can log in over http. Drop it once the domain has a certificate. |
   | `SMTP_ADDRESS`, `SMTP_USERNAME`, `SMTP_PASSWORD` | only used if the webhook fails |
4. **Health check**: `/up`.
5. After the first deploy, create your admin login from Coolify's terminal:
   `bin/rails admin:create`.
6. **Deploy on push to `main`**: Coolify's *Advanced → Auto deploy* is "Deploy
   on push (webhooks)", and the Forgejo repo has a webhook (Settings → Webhooks):
   type **Gitea**, target `http://192.168.0.55:8000/webhooks/source/gitea/events/manual`
   (Coolify's LAN address — the `:8000` URL Coolify prints uses the public IP),
   POST `application/json`, **Push events**, branch filter `main`, and the secret
   from Coolify's *Webhooks → Manual Git webhooks → Gitea*. A good delivery
   answers `"Deployment queued."`; a wrong secret is refused and nothing deploys.

The database is created and migrated automatically on boot, and `db:seed_once`
loads the design's content on any site that has no headline yet, so the first
deploy comes up with real content in place. A site that is already set up is
left alone, including content the admin has deliberately deleted.

## Deploying to your own server (Kamal)

1. Install Docker on the server and point DNS for the domain at it.
2. Edit `config/deploy.yml`: server IP, `proxy.host`, `APP_HOST`, SMTP settings.
3. Export secrets locally (read by `.kamal/secrets`):
   `PUSHPRESS_API_KEY`, `SMTP_USERNAME`, `SMTP_PASSWORD` (and keep `config/master.key`).
4. `bin/kamal setup` (first time), then `bin/kamal deploy` for updates.
5. Create your admin login: `bin/kamal create-admin`.

SQLite databases and uploaded photos live in the `valleybuilt_storage` Docker
volume. Back that volume up.
