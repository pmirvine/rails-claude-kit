---
description: Turbo Frames, Turbo Streams and Stimulus patterns. Use when building or changing interactive UI, views, partials or JavaScript controllers.
paths: app/views/**, app/javascript/**, app/controllers/**
---
## Turbo
- Default to plain links and forms; Turbo Drive handles them. Add Frames or Streams only when needed.
- Turbo Frames for in-place edits and lazy-loaded sections (`turbo_frame_tag dom_id(@record)`).
- Turbo Streams for updating several parts of a page from one action (`create.turbo_stream.erb`).
- Prefer page refreshes with morphing (`turbo_refreshes_with method: :morph, scroll: :preserve`) and
  `broadcasts_refreshes` on the model over hand-written stream broadcasts.
- Use `dom_id` for every frame and stream target. Never hand-write ids.
- Forms that fail validation re-render with `status: :unprocessable_entity`.

## Stimulus
- One behaviour per controller, named for the behaviour (`clipboard_controller.js`, `autosave_controller.js`).
- Use `static targets` and `static values`, not `querySelector` or data attributes read by hand.
- Keep controllers generic and reusable; business logic stays on the server.
- Register via importmap (`bin/importmap pin ...`); no bundler, no npm build step.

## Views
- Small partials named after the record (`projects/_project.html.erb`); render collections with `render @projects`.
- Helpers for view logic; no queries in views (preload in the controller or a `preloaded` scope).

## Tests
- Every new frame or stream interaction gets a system test in test/system/.
- Verify in the running app with Tidewave before finishing.
