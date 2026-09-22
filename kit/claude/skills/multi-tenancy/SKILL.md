---
description: Tenant isolation rules for this multi-tenant app. Use when adding or changing a model, migration, controller, query, job, mailer or test that touches account-owned data.
paths: app/**, db/migrate/**, test/**
---
The tenant is `Current.account`. Leaking one account's data to another is the worst bug this app can have.

## If tenancy isn't built yet
Propose the approach before writing code: an `Account` model, a `Current` class
(`ActiveSupport::CurrentAttributes` with `account` and `user`), and how the account is chosen per request
(URL path prefix like `/:account_id/...`, subdomain, or session). 37signals' Fizzy uses a URL path prefix set
by middleware; see AGENTS.md in the Fizzy reference if it's configured.

## Models and migrations
- Every tenant-owned table has `account_id` (`t.references :account, null: false, foreign_key: true`)
  and indexes that start with `account_id` where you query by account.
- Tenant-owned models: `belongs_to :account, default: -> { Current.account }`.
  Child records copy the parent's account: `default: -> { project.account }`.
- Global records (identities, sessions, the accounts table itself) are the exception; say so in a comment.
- Uniqueness validations on tenant data are scoped: `validates :name, uniqueness: { scope: :account_id }`.

## Queries and controllers
- Always start from the tenant: `Current.account.projects.find(params[:id])`.
  Never `Project.find`, `Project.all`, `Project.where(...)` on tenant data outside the account scope.
- Loading from a parent that is already tenant-scoped is fine: `@project.tasks.find(params[:id])`.
- Raw SQL and `find_by_sql` must include `account_id`.

## Jobs, mailers, broadcasts
- Pass records, not ids; inside the job, set `Current.account = record.account` (or use
  `Current.with(account: record.account) { ... }`) before doing work.
- Turbo Stream channels are per-record (`broadcasts_refreshes`), so they're tenant-safe; never broadcast to a global stream.

## Tests
- Fixtures include at least two accounts.
- Every new controller gets a test proving a user from account B gets 404 for account A's record.
