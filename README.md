# Odkaz pre starostu

Citizen portal of [Odkaz pre starostu](https://novy.odkazprestarostu.sk). Rails app on PostgreSQL with PostGIS.

## Local setup

Tested on macOS and Linux.

### Prerequisites

1. **A Ruby version manager**: mise (set up by the [Installing Ruby on Rails](https://guides.rubyonrails.org/install_ruby_on_rails.html) guide), asdf or rbenv. The project pins Ruby in `.ruby-version` and `.tool-versions` and Rails in `Gemfile.lock`, so don't install either by hand.
2. **System libraries**, on macOS with [Homebrew](https://brew.sh):
   ```sh
   # macOS
   brew install vips libexif pkg-config libpq && brew link --force libpq

   # Ubuntu, Debian
   sudo apt install libvips libexif-dev libpq-dev pkg-config libcurl4-openssl-dev postgresql-client tzdata
   ```
3. **PostgreSQL 17 with PostGIS**, as in `docker-compose.yml`. Easiest is [Docker](https://docs.docker.com/get-started/get-docker/), which `docker compose up -d` below uses. With your own server, skip that step and create the role the app expects. It must be a superuser to enable PostGIS; to use another role, change `DATABASE_URL` in `.env`.
   ```sh
   # Linux
   sudo -u postgres psql -c "CREATE ROLE ops LOGIN SUPERUSER PASSWORD 'ops';"
   # macOS (Homebrew, Postgres.app)
   psql postgres -c "CREATE ROLE ops LOGIN SUPERUSER PASSWORD 'ops';"
   ```

### Setup

```sh
git clone https://github.com/slovensko-digital/ops-portal.git
cd ops-portal
mise install              # or asdf install / rbenv install; check with ruby -v
docker compose up -d      # PostgreSQL + PostGIS; skip with your own server
cp .env.sample .env
bin/setup --skip-server   # gems, database, seed data
PORT=3000 bin/dev
```

Open http://localhost:3000 and log in at `/login` as `jana@example.com` / `password`.

Later runs: `docker compose up -d && PORT=3000 bin/dev`.

## Development

| Command | Purpose |
|---|---|
| `PORT=3000 bin/dev` | App + CSS watcher |
| `bin/rails console` | Console |
| `bin/rails test` | Unit and integration tests |
| `bin/rails test:system` | Browser tests (need Chrome) |
| `bin/rubocop -a` | Lint and autofix |
| `bin/ci` | Everything CI runs |
| `/letter_opener` | Sent emails |
| `/admin/good_job` | Background jobs |

Create the test database once with `RAILS_ENV=test bin/rails db:prepare`. See [docs/TESTING.md](docs/TESTING.md) for what to test where.

Seed users are in [`db/seeds/users.rb`](db/seeds/users.rb); all use the password `password`. Municipal staff, e.g. `stare-mesto@example.com`, log in by email link only: request it on the login page and open it in `/letter_opener`.

### Local limitations

- Submitting a new issue fails at the last step: the seeds have no municipality boundaries.
- AI suggestions need `GEMINI_API_KEY` and `CMS_AI_CATEGORY_ID` in `.env`, set before `bin/setup` (the seeds create the AI prompts under that category).
- Zammad sync jobs fail without `TRIAGE_ZAMMAD_*`. Expected; they show up in `/admin/good_job`.
- Google and Facebook login need `GOOGLE_*` and `FACEBOOK_*`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `docker compose`: `permission denied` (Linux) | `sudo usermod -aG docker $USER`, then log out and in. |
| `role "ops" does not exist`, `password authentication failed for user "ops"`, `extension "postgis" is not available`, or port 5432 already allocated | Another PostgreSQL owns port 5432, so the app reaches it instead of Docker's. Stop it, or use it as your own server ([Prerequisites](#prerequisites), step 3). |
| `unrecognized configuration parameter "transaction_timeout"` | Your PostgreSQL is older than 17. Use Docker or upgrade ([Prerequisites](#prerequisites), step 3). |
| `failed to execute: psql` | Install the PostgreSQL client ([Prerequisites](#prerequisites), step 2). |
| `bin/dev`: `Address already in use` on port 5000 | Use `PORT=3000`; without it foreman picks 5000, which macOS AirPlay holds. |
| `bin/rails db:test:prepare` tries to drop the development database | Use `RAILS_ENV=test bin/rails db:prepare`. Without it, the task reads `.env` and targets the development database. |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Only maintainers can push here, so open pull requests from a fork.

## Connect new Backoffice instance

Tip: Use [CyberChef](https://gchq.github.io/CyberChef/#recipe=Pseudo-Random_Number_Generator(32,'Raw')To_Base62('0-9A-Za-z')) to generate secrets.

Example:

```ruby
new_backoffice_data = {
  name: "Malacky",
  url: "https://novy.odkazprestarostu.sk/connector/webhook",
  connector_zammad_url: "https://malacky.odkazprestarostu.sk/",
  receive_customer_activities: false,
  connector_zammad_api_token: "tokenvalue",
  connector_zammad_webhook_secret: "secretvalue"
}

def connect_backoffice(data)
  responsible_subject = ResponsibleSubject.find_by!(name: data[:name])

  raise "ResponsibleSubject already PRO" if responsible_subject.pro?

  responsible_subject.update_columns(
    subject_name: data[:name],
    active: true,
    pro: true
  )

  client = Client.find_or_create_by!(name: data[:name])
  tenant = Connector::Tenant.find_or_create_by!(name: data[:name])

  api_key = OpenSSL::PKey::EC.generate("prime256v1")
  webhook_key = OpenSSL::PKey::EC.generate("prime256v1")

  client.update_columns(
    api_token_public_key: api_key.public_to_pem,
    webhook_private_key: webhook_key.to_pem,
    url: data[:url],
    responsible_subject_id: responsible_subject.id
  )

  tenant.update_columns(
    backoffice_api_token: data[:connector_zammad_api_token],
    backoffice_webhook_secret: data[:connector_zammad_webhook_secret],
    ops_api_token_private_key: api_key.to_pem,
    ops_webhook_public_key: webhook_key.public_to_pem,
    ops_api_subject_identifier: client.id,
    backoffice_url: data[:connector_zammad_url],
    receive_customer_activities: data[:receive_customer_activities]
  )
end

connect_backoffice new_backoffice_data
```
