# Rails Claude Kit

A Rails application template that sets up a new or existing Rails app for Claude Code, in the
37signals "vanilla Rails" style, with PostgreSQL.

It adds:

| File | What it does |
| --- | --- |
| `CLAUDE.md` | Commands, stack, conventions and rules for Claude, with your app name filled in |
| `.claude/settings.json` | Pre-approved safe commands, blocked destructive ones, secrets unreadable |
| `.claude/hooks/rubocop.rb` | Runs RuboCop's safe fixes on every Ruby file Claude edits |
| `.claude/skills/vanilla-rails/` | Conventions and worked examples adapted from 37signals' Fizzy |
| `.claude/skills/hotwire/` | Turbo and Stimulus patterns (loads only for views, JS and controllers) |
| `.claude/skills/feature/` | `/feature <description>`: plan, tests first, build, verify, review |
| `.claude/skills/multi-tenancy/` | Tenant isolation rules (optional) |
| `.claude/agents/rails-reviewer.md` | A reviewer subagent that checks the diff with fresh eyes |
| `.mcp.json` | Tidewave MCP server, so Claude can use your running dev app |
| `Gemfile` | Adds `tidewave` to the development group |

Optionally it clones [Fizzy](https://github.com/basecamp/fizzy) to `~/code/reference/fizzy` and gives
Claude read-only access to it through `.claude/settings.local.json` (not committed).

For a full step-by-step example, see [USAGE.md](USAGE.md).

## One-time setup

```bash
git clone https://github.com/pmirvine/rails-claude-kit.git ~/code/rails-claude-kit
gem install ruby-lsp
```

## New app

```bash
rails new myapp -d postgresql -c tailwind -m ~/code/rails-claude-kit/template.rb
cd myapp
bin/setup
```

It asks two questions: is the app multi-tenant, and should it clone Fizzy as a reference. To skip the
prompts: `MULTI_TENANT=1 FIZZY=1 rails new ...`. Use `FIZZY_PATH=/some/dir` to put Fizzy elsewhere.

To make PostgreSQL and the kit the default for every `rails new`, add to `~/.railsrc`:

```text
--database=postgresql
--css=tailwind
--template=~/code/rails-claude-kit/template.rb
```

## Existing app

From inside the app:

```bash
bin/rails app:template LOCATION=~/code/rails-claude-kit/template.rb
```

If a file already exists (for example `CLAUDE.md`), you'll be asked whether to overwrite it. Answer
`d` to see the difference first.

## From GitHub without cloning

If the repository is public, you can run it straight from GitHub:

```bash
rails new myapp -d postgresql -m https://raw.githubusercontent.com/pmirvine/rails-claude-kit/main/template.rb
```

The template clones the kit to a temporary folder to get its files. This doesn't work for private
repositories; use a local clone for those.

## First session in the new app

1. `bin/dev`. Tidewave needs the app running on port 3000.
2. `claude`. Approve the `tidewave` MCP server when asked.
3. `/plugin install ruby-lsp@claude-plugins-official`
4. `/run-skill-generator`, once, so `/run` and `/verify` know how to start the app.
5. Fill in the app description at the top of `CLAUDE.md`.
6. Commit everything except `.claude/settings.local.json` (already git-ignored).

## Daily use

- Plan mode (Shift+Tab) for anything bigger than a small fix.
- `/feature invoice PDF export` for a full feature cycle.
- "Ask the rails-reviewer agent to review the diff" before committing.
- `git -C ~/code/reference/fizzy pull` now and then.

## Customising

Edit the files under `kit/` in this repository. Every app you create afterwards picks up the changes.
To update an existing app, re-run the `app:template` command and choose which files to overwrite.

## Licence

The kit is MIT licensed (see `LICENSE`). The `vanilla-rails` skill adapts conventions from Fizzy,
Copyright (c) 2025 37signals LLC, under the O'Saasy License (see `NOTICE`). Fizzy's licence allows
reuse but not running a hosted service that competes with Fizzy.

[![M8ven Score](https://m8ven.ai/badge/mcp/pmirvine-rails-claude-kit-lzxtz0?v=c02021f38b23abc55dbd45b021816909)](https://m8ven.ai/mcp/pmirvine-rails-claude-kit-lzxtz0)