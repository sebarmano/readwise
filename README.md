# book-recommender
Personal book library &amp; recommender — Rails 8, Hotwire, Ollama, Kamal

## Dev toolchain

No build step — the app uses importmaps and Propshaft.

| Tool | Purpose | Install |
|------|---------|---------|
| StandardRB | Ruby formatter/linter | `bundle install` |
| Herb | ERB formatter | `brew install herb` |
| Biome | JS formatter/linter | `brew install biome` |

### Pre-commit hook

Activate the versioned hook on a fresh clone:

```sh
git config core.hooksPath .githooks
```

The hook auto-formats staged `.rb`, `.html.erb`, and `.js` files before each commit. Herb and Biome are skipped gracefully if not installed.

### Running formatters manually

```sh
bin/standardrb --fix          # Ruby
herb fmt app/views/**/*.erb   # ERB
bin/biome format --write .    # JavaScript
```
