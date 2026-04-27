---
paths:
  - "app/views/**/*.erb"
  - "app/presenters/**/*.rb"
---

# View & Presenter Conventions

- Use presenters (`app/presenters/`) with SimpleDelegator for formatting logic
- No business logic in views — use presenters for all display formatting
- Plain CSS with BEM naming and `@layer` for cascade control (no Tailwind, no inline styles)
- One CSS file per component/section, imported into `application.css`
- Turbo Frames for partial page updates; Turbo Streams for multi-target updates
- Stimulus controllers for client-side behavior (minimal JS, progressive enhancement)
- Always provide `format.html` fallback alongside `format.turbo_stream` responses
- Use `dom_id(@record)` for stable element IDs in Turbo targets
- Always include ARIA attributes for interactive elements (WCAG 2.1 AA)
- Run `bin/herb analyze app/views/` to catch ERB parse errors — the pre-commit hook does this automatically on any commit that includes staged ERB files
