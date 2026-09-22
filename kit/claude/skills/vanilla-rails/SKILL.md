---
description: 37signals-style "vanilla Rails" conventions for models, concerns, controllers, jobs and tests. Use when writing, refactoring or reviewing any Ruby code in app/ or test/.
paths: app/**, test/**, config/routes.rb
---
Conventions adapted from 37signals' Fizzy (github.com/basecamp/fizzy, STYLE.md and AGENTS.md),
Copyright (c) 2025 37signals LLC, O'Saasy License. Worked examples: [examples.md](examples.md).

## Before writing code
- Find similar code in this app and follow its shape. Consistency beats cleverness.

## Routes and controllers
- CRUD only. A state change that isn't create/update/destroy becomes a new singular resource:
  `resources :projects do resource :archival end`, not `post :archive`.
- Controllers stay thin: load the record, call one intention-revealing model method, respond.
  Plain Active Record calls (`@project.comments.create!(comment_params)`) are fine too.
- Shared loading lives in a controller concern (`ProjectScoped` with `before_action :set_project`).
- Respond with Turbo Streams for HTML and `head :no_content` for JSON where relevant.

## Models
- Rich domain models. No service layer by default; a plain object in app/models
  (`Signup.new(...).create_identity`) is fine when justified. Don't call it a service.
- One concern per behaviour, in a folder named after the model: `Project::Archivable` in
  app/models/project/archivable.rb. The model file is mostly `include` lines, associations and scopes.
- When who/when matters, store state as a record, not a boolean: `has_one :archival`
  (with `user` and `created_at`) and scopes `archived` (`joins(:archival)`) and
  `active` (`where.missing(:archival)`).
- State-changing methods are idempotent and transactional: `archive` does nothing if already archived.
- Default `creator` / `user` arguments from `Current.user`.
- Put reusable query fragments in named scopes; preload in a `preloaded` scope to avoid N+1s.

## Jobs
- Jobs are shallow: they call one model method.
- `thing_later` enqueues the job; `thing_now` does the work; the job calls `thing_now`.
- Enqueue from `after_create_commit` / `after_update_commit`, never plain `after_save`.

## Ruby style
- Prefer expanded `if/else` to guard clauses. Exception: a single early `return` at the very
  top of a non-trivial method.
- Order in a class: class methods, public methods (`initialize` first), then `private`.
- Order methods by invocation: a method appears just below the one that calls it.
- `private` is indented one level, with no blank line after it; the methods under it are indented again.
  In a module with only private methods, put `private` at the top, a blank line, and don't indent.
- Only use `!` when a non-bang twin exists. Don't use `!` just to mark something destructive.
- Name things for the domain (`gild`, `postpone`, `close`), not for the mechanics (`update_status`).

## Tests
- Minitest + fixtures. Model tests per concern (`test/models/project/archivable_test.rb`).
- Use `assert_difference` / `assert_changes` for side effects; set `Current` in `setup`.
- Controller/integration tests for every new resource, including the unauthorised case.
