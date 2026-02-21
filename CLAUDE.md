# FrankMega - Development Guide

## Project Overview

Security-hardened, self-hosted file sharing service. Users upload files, get time-limited shareable links with download counters. Deployed as a Docker container behind Cloudflare Tunnel at `frankmega.example.com`.

**Stack:** Ruby 3.4.8, Rails 8.1.2, SQLite3, Tailwind CSS v4, Propshaft, Importmap, Solid Queue/Cache/Cable, Puma + Thruster.

## Commands

```bash
# IMPORTANT: All bundle commands require this env var (read-only ~/.bundle workaround)
export BUNDLE_USER_HOME=/tmp/bundler_home

# Run tests
bundle exec rails test

# Run linters
bundle exec rubocop
bundle exec brakeman --no-pager --quiet
bundle exec bundler-audit check

# Start dev server
bin/dev

# Compile Tailwind manually
bundle exec rails tailwindcss:build

# Database
bundle exec rails db:migrate
bundle exec rails db:seed         # Seeds AllowedMimeType defaults
RAILS_ENV=test bundle exec rails db:migrate

# Docker
docker compose build
docker compose up
```

## Architecture

### Database

SQLite3 with separate databases in production for app, cache, queue, and cable (see `config/database.yml`). All databases live in `storage/`.

### Authentication

Built on Rails 8 built-in auth generator (`app/controllers/concerns/authentication.rb`). Every controller inherits `Authentication` through `ApplicationController`. Key methods:

- `current_user` - returns the logged-in User or nil
- `authenticated?` - helper method available in views
- `allow_unauthenticated_access` - class method to skip auth on specific actions
- `start_new_session_for(user)` - creates session record and sets signed cookie
- `require_admin` - redirects non-admin users

Auth flow: password login -> optional 2FA challenge -> session cookie. Banned users are rejected at `resume_session` level.

### Authorization

Two roles: `"admin"` and `"user"`. Check with `current_user.admin?`. Admin controllers inherit from `Admin::ApplicationController` which enforces `require_admin` as a `before_action`.

### File Storage

Active Storage with local disk backend. Production storage path configurable via `STORAGE_PATH` env var (defaults to `storage/uploads`). Max upload size: **1 GB**. Allowed MIME types managed via `AllowedMimeType` model (admin-configurable).

### Background Jobs

Solid Queue (no Redis). Recurring jobs configured in `config/recurring.yml`:
- `CleanupExpiredFilesJob` - every 15 minutes
- `CleanupExpiredBansJob` - every hour

All jobs use `queue_as :default`.

### Real-time

Turbo Streams via Action Cable (Solid Cable). Download notifications broadcast to user-specific channels: `"user_#{user_id}_notifications"`.

## Coding Conventions

### Models

Follow this ordering within model files:

```ruby
class ModelName < ApplicationRecord
  # 1. Associations
  belongs_to / has_many / has_one_attached

  # 2. Encryption
  encrypts :field_name

  # 3. Normalizations
  normalizes :field, with: -> ...

  # 4. Validations
  validates :field, presence: true, ...
  validate :custom_validation, on: :create

  # 5. Callbacks
  before_validation :method, on: :create

  # 6. Scopes
  scope :active, -> { where(...) }

  # 7. Public instance methods
  def active?
  end

  # 8. Private methods
  private
  def generate_something
  end
end
```

Key patterns:
- Use `SecureRandom.urlsafe_base64` for tokens/hashes (16 bytes for invitation codes, 24 bytes for download hashes)
- Use `Time.current` (never `Time.now`) for all time comparisons
- Define both scope and instance method for status checks (e.g., `scope :active` and `def active?`)
- Sensitive fields use `encrypts` (ActiveRecord Encryption) - currently `otp_secret` on User
- State-changing methods end with `!` when using `update!` (e.g., `ban!`, `redeem!`, `enable_otp!`)
- Boolean columns always have `default: false, null: false` in migrations
- Required string/integer columns use `null: false` in migrations
- Add database indexes for columns used in lookups (unique constraints, foreign keys, `expires_at`)

### Controllers

```ruby
class SomeController < ApplicationController
  # 1. Auth configuration
  allow_unauthenticated_access only: %i[show create]

  # 2. Before actions
  before_action :find_resource

  # 3. Actions (new, create, show, edit, update, destroy order)
  def show
  end

  # 4. Private methods
  private
  def find_resource
  end

  def resource_params
    params.require(:model).permit(:field1, :field2)
  end
end
```

Key patterns:
- Scope queries to `current_user` for data isolation: `current_user.shared_files.find(params[:id])`
- Use `if/elsif/else` blocks instead of early `return` + `render` (rubocop enforces no redundant returns)
- Public endpoints use `allow_unauthenticated_access`
- Admin controllers inherit `Admin::ApplicationController` (not `ApplicationController` directly)
- Admin namespace: `module Admin; class FooController < Admin::ApplicationController`
- Strong parameters: always use `params.require(:model).permit(...)` - never `params.permit` at top level
- Use `status: :unprocessable_entity` when re-rendering forms on validation failure
- Use `status: :see_other` on destroy redirects
- Background work goes in jobs, not inline in controllers

### Routes

- Public download URLs use short paths: `/d/:hash`
- Admin routes namespaced under `/admin`
- Setup route uses constraint: `constraints(-> { User.count.zero? })`
- Catch-all route at the bottom for 404s (excludes `/rails/` paths)
- Custom member actions use `post` (ban, unban, reset_password)

### Views

Tailwind CSS v4 with custom theme variables. All views use these conventions:

**Color tokens** (defined in `app/assets/tailwind/application.css`):
- `primary` / `primary-hover` - Bold red (hsl(0 85% 50%))
- `surface` - Light background
- `dark-bg` / `dark-surface` - Dark mode backgrounds
- `success`, `warning`, `danger` - Status colors

**Dark mode:** Uses `dark:` variant classes. Toggled via `dark` class on `<html>`. Persisted in `localStorage`.

**Layout patterns:**
- Full-page centered forms: `min-h-screen flex items-center justify-center` wrapper with `max-w-md` card
- Dashboard/content pages: `max-w-4xl mx-auto py-8`
- Cards: `bg-white dark:bg-dark-surface rounded-2xl shadow-xl p-8`
- Form inputs: `w-full px-4 py-3 rounded-lg border border-gray-300 dark:border-gray-600 dark:bg-gray-800 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent`
- Primary buttons: `py-3 px-4 bg-primary hover:bg-primary-hover text-white font-semibold rounded-lg transition-colors cursor-pointer`
- Status badges: `inline-flex items-center px-2 py-1 rounded-full text-xs font-medium` with color variants

**Partials:**
- `shared/_form_errors.html.erb` - Reusable error display, pass `resource:` local
- `shared/_navbar.html.erb` - Main nav, only rendered when `authenticated?`
- `shared/_download_toast.html.erb` - Turbo Stream toast notification
- `uploads/_shared_file.html.erb` - File card used in dashboard and Turbo Stream updates

**Flash messages:** Render inline in each page (not in layout). Use `flash[:alert]` for errors, `flash[:notice]` for success. Style with red/green backgrounds respectively.

**Turbo:** Dashboard subscribes to `turbo_stream_from "user_#{current_user.id}_notifications"`. Toast notifications append to `#toast_notifications` div.

### JavaScript (Stimulus)

Controllers live in `app/javascript/controllers/`. Naming: `*_controller.js` with snake_case filenames. Registered automatically via eager loading (`stimulus-loading.js`).

Existing controllers:
- `theme_controller.js` - Dark mode toggle, `localStorage` persistence
- `upload_controller.js` - Drag-and-drop zone, file preview, size formatting
- `clipboard_controller.js` - Copy text to clipboard
- `notification_controller.js` - Auto-dismissing toast notifications
- `webauthn_controller.js` - Passkey registration and authentication

Conventions:
- Use `static targets = [...]` and `static values = { ... }`
- Use `data-controller`, `data-action`, `data-*-target` attributes in HTML
- No external JS dependencies via npm - use importmap CDN pins or vendor JS
- Fetch API for async requests (not jQuery/axios)
- Always include CSRF token from `meta[name='csrf-token']` in fetch requests

### Tests

**Framework:** Minitest + FactoryBot + Shoulda Matchers + SimpleCov

**Directory structure:**
```
test/
  controllers/        # Integration tests (ActionDispatch::IntegrationTest)
    admin/            # Admin controller tests
  models/             # Unit tests (ActiveSupport::TestCase)
  jobs/               # Job tests (ActiveJob::TestCase)
  factories/          # FactoryBot factory definitions
  fixtures/files/     # Test file attachments
```

**Factory conventions:**
- One factory per model in `test/factories/model_name.rb` (pluralized)
- Use `Faker` for unique values (emails, IPs, user agents)
- Define traits for common states: `:admin`, `:banned`, `:expired`, `:exhausted`, `:with_otp`
- For ActiveStorage attachments, use `after(:build)` to attach `StringIO` content
- Use `association :user` (not inline `create(:user)`) for belongs_to

**Test conventions:**
- Use `build(:model)` for validation tests that don't need persistence
- Use `create(:model)` when database state is needed
- Controller tests: always log in first in `setup` block: `post session_path, params: { email_address: ..., password: ... }`
- Test descriptions: `test "descriptive behavior statement" do`
- Use `assert` / `assert_not` (not `refute`)
- Use `assert_response :success`, `assert_redirected_to`, `assert_difference`
- Test both happy paths and error paths (invalid params, unauthorized access, expired records)
- Tests run in parallel with processes (not threads)

**What every new feature must test:**
1. Model validations (presence, uniqueness, ranges)
2. Model scopes return correct records
3. Controller actions with valid and invalid params
4. Authorization (unauthenticated users redirected, non-admins blocked from admin)
5. Edge cases (expired records, exhausted limits, banned users)

### Migrations

- Always set `null: false` on required columns
- Always set `default:` on boolean columns
- Add `unique: true` indexes on lookup columns (codes, hashes, email)
- Add regular indexes on foreign keys and `expires_at` columns
- Use `bigint` for `file_size` (files can be > 2GB in metadata)
- Foreign keys referencing users: `foreign_key: { to_table: :users }` when column name differs from convention

### Jobs

```ruby
class SomeJob < ApplicationJob
  queue_as :default

  def perform(arg)
    # Guard clause for deleted records
    record = Model.find_by(id: arg)
    return unless record
    # ... work
  end
end
```

- Always use `find_by` with guard clause (records may be deleted between enqueue and perform)
- Read security settings from `Rails.application.config.x.security`
- Use `Rails.cache.increment` for counting/tracking (with `expires_in:`)

### Security

**Rate limiting:** Rack::Attack (see `config/initializers/rack_attack.rb`). Limits scale by `config.x.security.rate_limit_multiplier` (10x in dev, 1x in prod).

**IP banning:** `Ban` model with expiring records. Banning is disabled in development (`config.x.security.enable_banning = false`). Invalid hash access triggers `InvalidHashAccessJob` which counts attempts and auto-bans.

**Headers:** `secure_headers` gem configures CSP, HSTS, X-Frame-Options, etc. CSP allows `'self'` for scripts and `'unsafe-inline'` for styles (Tailwind requirement).

**Cookies:** Secure, HttpOnly, SameSite=Lax. Session cookie is signed and permanent.

**Cloudflare:** Trusted proxy IPs configured manually in `config/initializers/cloudflare.rb` (the `cloudflare-rails` gem is incompatible with Rails 8.1).

**Never do:**
- Expose internal IDs in public URLs (use `download_hash` instead)
- Allow user-supplied HTML rendering without sanitization
- Add `'unsafe-eval'` to CSP
- Skip CSRF protection
- Use `params` directly without strong parameters
- Store secrets in code (use ENV vars or Rails credentials)

### Environment Variables

Required in production:
```
SECRET_KEY_BASE
RAILS_MASTER_KEY
HOST                                        # e.g., frankmega.example.com
WEBAUTHN_ORIGIN                             # e.g., https://frankmega.example.com
WEBAUTHN_RP_ID                              # e.g., frankmega.example.com
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
STORAGE_PATH                                # Docker volume mount path
SMTP_ADDRESS, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD
```

## Pre-Commit Checklist

Before committing any code, verify:

1. `bundle exec rails test` - all tests pass, zero failures
2. `bundle exec rubocop` - zero offenses
3. `bundle exec brakeman --no-pager --quiet` - no new warnings (existing mass assignment warning in admin is intentional)
4. `bundle exec bundler-audit check` - no vulnerable gems
5. New models have factory + model tests
6. New controllers have integration tests covering auth, happy path, and error cases
7. New migrations set appropriate `null:`, `default:`, and indexes
8. Views use existing Tailwind tokens (`primary`, `dark-bg`, etc.) - not raw color values
9. Sensitive data uses `encrypts` or ENV vars - never hardcoded
