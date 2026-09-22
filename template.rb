# Rails Claude Kit - application template
#
# New app:
#   rails new myapp -d postgresql -c tailwind -m ~/code/rails-claude-kit/template.rb
#
# Existing app (run inside the app):
#   bin/rails app:template LOCATION=~/code/rails-claude-kit/template.rb
#
# Answers can be preset with environment variables (useful for scripts):
#   MULTI_TENANT=1|0   include the multi-tenancy rules and skill
#   FIZZY=1|0          clone 37signals' Fizzy as a read-only reference
#   FIZZY_PATH=...     where to keep that reference (default ~/code/reference/fizzy)

require "json"
require "shellwords"
require "tmpdir"

FIZZY_REPO = "https://github.com/basecamp/fizzy.git"

# Make the kit's files available to `directory`, `template` and `copy_file`,
# whether the template is run from a local clone or from a raw GitHub URL.
def add_kit_to_source_paths
  if __FILE__ =~ %r{\Ahttps?://}
    match = __FILE__.match(%r{raw\.githubusercontent\.com/([^/]+)/([^/]+)/([^/]+)/})
    raise "Run this template from a local clone or a raw.githubusercontent.com URL" unless match

    user, repo, branch = match.captures
    tempdir = Dir.mktmpdir("rails-claude-kit-")
    at_exit { FileUtils.remove_entry(tempdir) }
    run "git clone --quiet --depth 1 --branch #{branch.shellescape} " \
        "https://github.com/#{user}/#{repo}.git #{tempdir.shellescape}"
    source_paths.unshift(tempdir)
  else
    source_paths.unshift(File.dirname(File.expand_path(__FILE__)))
  end
end

def answer(env_key, question)
  if ENV.key?(env_key)
    ENV[env_key] == "1"
  else
    yes?("#{question} [y/n]")
  end
end

def postgres?
  File.read(File.join(destination_root, "config/database.yml")).include?("adapter: postgresql")
rescue Errno::ENOENT
  false
end

add_kit_to_source_paths

@app_title     = File.basename(destination_root)
@multi_tenant  = answer("MULTI_TENANT", "Is this a multi-tenant app (accounts/organisations)?")
@use_fizzy     = answer("FIZZY", "Clone 37signals' Fizzy as a read-only reference for Claude?")
@fizzy_path    = File.expand_path(ENV.fetch("FIZZY_PATH", "~/code/reference/fizzy"))

unless postgres?
  say "Note: this app isn't using PostgreSQL. The kit still works, but CLAUDE.md assumes Postgres - edit it.", :yellow
end

# Tidewave: lets Claude run code, read logs and query the DB of the running dev app.
gem "tidewave", group: :development

after_bundle do
  # Claude Code project config: settings, hooks, skills, agents.
  directory "kit/claude", ".claude"
  chmod ".claude/hooks/rubocop.rb", 0o755
  remove_dir ".claude/skills/multi-tenancy" unless @multi_tenant

  copy_file "kit/mcp.json", ".mcp.json"
  template  "kit/CLAUDE.md.tt", "CLAUDE.md"

  # Machine-specific settings stay out of git.
  if File.exist?(File.join(destination_root, ".gitignore"))
    append_to_file ".gitignore", "\n# Claude Code personal settings\n/.claude/settings.local.json\n"
  end

  if @use_fizzy
    if Dir.exist?(@fizzy_path)
      say "Fizzy reference already at #{@fizzy_path} - run `git -C #{@fizzy_path} pull` now and then.", :green
    else
      run "git clone --quiet --depth 1 #{FIZZY_REPO} #{@fizzy_path.shellescape}"
    end

    local_settings = {
      "permissions" => {
        "additionalDirectories" => [ @fizzy_path ],
        # A leading "//" marks an absolute path in permission rules; Edit covers all file writes.
        "deny" => [ "Edit(/#{@fizzy_path}/**)" ]
      }
    }
    create_file ".claude/settings.local.json", JSON.pretty_generate(local_settings) + "\n"
  end

  say <<~MSG, :green

    Claude Code kit installed.
    Next:
      1. bin/setup && bin/dev          (Tidewave needs the app running on :3000)
      2. claude                        (approve the project MCP server when asked)
      3. /plugin install ruby-lsp@claude-plugins-official   (needs: gem install ruby-lsp)
      4. /run-skill-generator          (once, so /run and /verify know how to start the app)
  MSG
end
