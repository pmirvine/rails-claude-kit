#!/usr/bin/env ruby
# PostToolUse hook: after Claude writes or edits a Ruby file, apply RuboCop's
# safe autocorrections to that file. Never blocks Claude; failures are ignored.
require "json"

input = begin
  JSON.parse($stdin.read)
rescue JSON::ParserError
  {}
end

path = input.dig("tool_input", "file_path").to_s
exit 0 unless path.end_with?(".rb", ".rake") && File.exist?(path)

project = ENV.fetch("CLAUDE_PROJECT_DIR", Dir.pwd)
binstub = File.join(project, "bin/rubocop")
rubocop = File.executable?(binstub) ? [ binstub ] : %w[bundle exec rubocop]

Dir.chdir(project) do
  system(*rubocop, "-a", "--format", "quiet", path, out: File::NULL, err: File::NULL)
end
exit 0
