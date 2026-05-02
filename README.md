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

## Production

### Environment variables

Copy `.env.example` to `.env` and fill in the values before deploying.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SECRET_KEY_BASE` | yes | — | Rails secret key base |
| `RAILS_MASTER_KEY` | yes | — | Decrypts `config/credentials.yml.enc` |
| `DATABASE_PATH` | no | `/rails/storage/production.sqlite3` | Absolute path to SQLite DB |
| `OLLAMA_URL` | no | `http://ollama:11434` | Ollama API base URL |
| `OLLAMA_MODEL` | no | `qwen2.5:7b` | LLM model name |
| `KAMAL_REGISTRY_PASSWORD` | yes | — | Container registry password |
| `LITESTREAM_ACCESS_KEY_ID` | yes | — | S3-compatible storage key ID |
| `LITESTREAM_SECRET_ACCESS_KEY` | yes | — | S3-compatible storage secret |

### First deploy

```sh
# 1. Copy and fill in secrets
cp .env.example .env
# Edit .kamal/secrets to load values from .env or a password manager

# 2. Bootstrap the server (one-time)
bin/kamal setup

# 3. Deploy
bin/kamal deploy
```

### Disaster recovery (Litestream restore)

If the server is lost, restore the latest database backup before starting the app:

```sh
# On the new server, before starting the app container:
docker run --rm \
  -e LITESTREAM_ACCESS_KEY_ID=$LITESTREAM_ACCESS_KEY_ID \
  -e LITESTREAM_SECRET_ACCESS_KEY=$LITESTREAM_SECRET_ACCESS_KEY \
  -v readwise_storage:/rails/storage \
  litestream/litestream:latest \
  restore -config /etc/litestream.yml /rails/storage/production.sqlite3

# Then deploy normally:
bin/kamal deploy
```
