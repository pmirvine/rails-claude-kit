# Example: creating a new app with the kit

This walks through creating a new Rails app called `my-app` in `~/dev/rails`. Swap in your own
folder and app name. Step 1 is done once per machine; steps 2 to 6 are repeated for every new app.

## 1. One-time setup

Check the prerequisites: Ruby 3.2 or later, Rails 8, a running PostgreSQL and Claude Code.

```bash
ruby -v
rails -v                 # if missing or older: gem install rails
psql -l                  # should list databases; on a Mac, if not: brew services start postgresql@17
claude --version
gem install ruby-lsp
```

Clone the kit next to your apps:

```bash
cd ~/dev/rails
git clone https://github.com/pmirvine/rails-claude-kit.git
```

## 2. Create the app

```bash
cd ~/dev/rails
rails new my-app -d postgresql -c tailwind -m ~/dev/rails/rails-claude-kit/template.rb
```

Rails generates the app and installs its gems, then the kit asks two questions:

- **Is this a multi-tenant app?** Answer `y` if records will belong to accounts, teams or
  organisations. This adds tenancy rules to `CLAUDE.md` and the `multi-tenancy` skill.
- **Clone 37signals' Fizzy as a read-only reference?** Answer `y` to give Claude a large, well-written
  Rails app to copy patterns from. Fizzy is cloned to `~/code/reference/fizzy` the first time and
  reused for later apps.

To keep Fizzy under `~/dev/rails` as well, put this in front of `rails new`:

```bash
FIZZY_PATH=~/dev/rails/reference/fizzy rails new my-app ...
```

To answer the questions in advance, e.g. in a script: `MULTI_TENANT=1 FIZZY=1 rails new my-app ...`
(`0` for no).

## 3. Set up and start the app

```bash
cd my-app
bin/setup
```

`bin/setup` creates the Postgres databases and starts the server. If it didn't start the server,
run `bin/dev`. Leave the server running in that terminal: Tidewave only works while the app is up on
port 3000. Check that http://localhost:3000 loads.

## 4. Commit the starting point

```bash
git add -A
git commit -m "New Rails app with Claude Code kit"
```

`.claude/settings.local.json`, which holds the path to your Fizzy copy, is git-ignored and stays out.

## 5. First Claude Code session

Open a second terminal:

```bash
cd ~/dev/rails/my-app
claude
```

Inside Claude Code:

1. Trust the folder and approve the `tidewave` MCP server when asked.
2. Run `/mcp` and check that `tidewave` shows as connected.
3. Run `/plugin install ruby-lsp@claude-plugins-official`.
4. Run `/run-skill-generator` once, so `/run` and `/verify` know how to start and check the app.
5. Ask Claude to fill in the description at the top of `CLAUDE.md` from a sentence or two about
   what the app does and who it's for.
6. Commit again.

## 6. Build features

- Switch to plan mode (Shift+Tab) for anything bigger than a small fix.
- `/feature <what to build>` runs the whole cycle: plan, tests first, build, check in the running
  app, review. It stops after the plan and waits for your OK. For example:
  `/feature projects with tasks that can be archived`.
- Before committing, ask Claude to "use the rails-reviewer agent to review the diff".
- Now and then, update the Fizzy reference: `git -C ~/code/reference/fizzy pull`.

## Adding the kit to an existing app

From inside the app:

```bash
bin/rails app:template LOCATION=~/dev/rails/rails-claude-kit/template.rb
```

If a file such as `CLAUDE.md` already exists, you'll be asked whether to overwrite it. Answer `d`
to see the difference first. Then carry on from step 3.

## Updating the kit

Edit the files under `kit/`, commit and push. On each machine, pull the changes:

```bash
git -C ~/dev/rails/rails-claude-kit pull
```

New apps pick up the changes automatically. To update an existing app, re-run the `app:template`
command above and choose which files to overwrite.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `rails new` fails creating the database | PostgreSQL isn't running. On a Mac: `brew services start postgresql@17`, then `bin/setup` |
| `/mcp` shows tidewave as failed | The app isn't running. Start `bin/dev`, then reconnect from `/mcp` |
| The kit's questions didn't appear | You ran `rails new` without `-m`. Apply it afterwards with the existing-app command |
| RuboCop isn't fixing files | Check `bin/rubocop` exists and runs; the hook calls it after each Ruby edit |

## A note on Fizzy's licence

The `vanilla-rails` skill borrows Fizzy's coding conventions, which the licence doesn't restrict.
If you copy Fizzy's actual code into an app, keep the 37signals copyright notice with it. Don't use
Fizzy's code to run a hosted service that competes with Fizzy, such as a public kanban product. See
`NOTICE` for the full licence text.
