---
description: Build a feature end to end, the Rails way, with tests first and a review at the end.
disable-model-invocation: true
argument-hint: [what to build]
---
Build: $ARGUMENTS

1. Read CLAUDE.md and the vanilla-rails skill. Find the most similar existing code and follow it.
2. Propose the plan: routes (resources only), models and concerns, migrations, views/streams, jobs.
   List open questions. Stop and wait for my OK.
3. Write failing tests first: model tests per concern, then controller/integration tests
   (include the not-allowed case), then a system test for any interactive UI.
4. Generate migrations with `bin/rails generate migration`, run `bin/rails db:migrate`.
5. Implement models and concerns, then controllers, then views and Stimulus.
6. Run `bin/rails test` (and `bin/rails test:system` if you added system tests) and `bin/rubocop`
   until both are clean.
7. Check the feature in the running app with Tidewave (query the data, call the new model methods).
8. Ask the rails-reviewer agent to review the diff; fix anything it finds that I'd agree with.
9. Summarise: what changed, files touched, anything I should look at, and a suggested commit message.
