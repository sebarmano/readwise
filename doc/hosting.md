# Hosting Options Analysis

Parked 2026-05-04. Revisit when the app is ready for production deployment.

## Context

- Rails 8 app deployed via Kamal 2
- Ollama runs as a Kamal accessory (model: `qwen2.5:7b`, requires ~5–6 GB RAM)
- Primary user is based in Australia

## Options Considered

| Provider | Region | Specs | Price/month | Notes |
|---|---|---|---|---|
| **Hetzner** | US West (Oregon) | CX32 — 4 vCPU, 8 GB RAM | ~€8 | Best value; no AU region; ~150–200 ms from AU |
| Vultr | Sydney | High Performance 8 GB | ~$48 | AU-local latency; 6× Hetzner cost |
| DigitalOcean | Sydney | 8 GB Droplet | ~$48 | AU-local latency; 6× Hetzner cost |
| Oracle Cloud | Sydney | Ampere A1 — 4 CPU, 24 GB | Free | Requires ARM multi-arch image build |

## Recommendation

**Start with Hetzner CX32 (US West).** The app's LLM response times (seconds) dwarf the ~150 ms AU–Oregon latency. At €8/month it's the most practical starting point for a side project.

**Revisit Oracle Cloud Free Tier (Sydney)** if cost becomes a concern. Requires adding `arm64` to `builder.arch` in `config/deploy.yml` and rebuilding — straightforward but an extra step.

## When Ready to Deploy

1. Replace `192.168.0.1` in `config/deploy.yml` with the server's IP
2. Ensure `.env` is populated (see `.env.example`)
3. `bin/kamal setup` — bootstraps Docker on the server (one-time)
4. `bin/kamal deploy` — builds, pushes, and starts all containers
