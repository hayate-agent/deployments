# Hayate Agent Deployments

Deployment examples for [Hayate Agent](https://github.com/hayate-agent/core), an
AI assistant for the terminal and Matrix.

Run an assistant with Docker Compose, or use the native foreground launcher.
The examples include a standard agent profile, an OpenAI-compatible model provider
and an optional Matrix gateway. Keep your own credentials and data outside Git.

## Quick start with Docker Compose

Requires Docker Engine with Compose v2 (Docker Desktop on macOS/Windows) and Python 3
for local setup. Clone the repositories as siblings:

```sh
git clone https://github.com/hayate-agent/core.git
git clone https://github.com/hayate-agent/deployments.git
cd deployments
./init.sh
```

Set `MODEL_API_KEY` in the generated `.env`. The default model is
`openai-compatible/gpt-4.1-mini`; change `config/models.json` and
`config/hayate-agent.yaml` together to use another provider/model.

```sh
docker compose config --quiet
docker compose up --build -d
docker compose ps
docker compose logs --tail=50 hayate
```

The API is available only on **localhost:8642**. Its generated key is in `.env`.
The container's `/health` endpoint supplies Compose health status. The image is
built from the sibling public Core checkout and includes its exact vendored
plugins; no private registry or repository is needed. Configure
`HAYATE_CORE_PATH`/`HAYATE_DOCKERFILE` in `.env` for a different directory layout.

- **Configuration:** `config/` (mounted read-only); `init.sh` never overwrites it.
- **Workspace:** `workspace/`, mounted as `/workspace`; only place files there that
  the agent may access. The image runs as UID/GID 1000; grant that user workspace
  access if your host uses a different UID. Protect secrets from the agent's tools.
- **Persistent state:** the `agent-home` named volume holds conversations, queues
  and Matrix device/crypto state. Back it up before updates.
- **Secrets:** `.env` and generated configuration are ignored by Git. Do not publish them.
- **Stop:** `docker compose down` preserves data; **`down -v` deletes agent state**.
- **Update:** review the Core update, then `docker compose up --build -d`; graceful
  shutdown has a 90-second window. Reconcile interrupted external actions first.

For **rootless Podman**, retain private config permissions and your host UID with
the optional override (do not use this file with Docker Engine):

```sh
docker-compose -f compose.yaml -f compose.podman.yaml up --build -d
```

For Matrix, fill in the `MATRIX_*` values in `.env`, including the authenticated
bot device ID and your own allowed Matrix user ID, then recreate the container.
Do not start another process against its Matrix crypto store.

## Native foreground launcher

### Requirements

- A supported Linux, macOS or WSL2 host
- Node.js 22.19 or newer; Node 24 LTS is recommended
- A built [Hayate Core checkout](https://github.com/hayate-agent/core#readme)
- Access to a configured model provider

## Run locally

Build Core, then initialize a separate agent profile:

```sh
git clone https://github.com/hayate-agent/core.git
git clone https://github.com/hayate-agent/deployments.git
cd core
npm ci

export HAYATE_INSTALL="$PWD"
export HAYATE_AGENT_HOME="$HOME/.hayate-agent-service"
node "$HAYATE_INSTALL/dist/cli.js" init
```

Edit `$HAYATE_AGENT_HOME/hayate-agent.yaml` for your model and tools. Configure
provider credentials using the provider's supported credential storage. Then:

```sh
node "$HAYATE_INSTALL/dist/cli.js" doctor
cd ../deployments
./run.sh
```

The launcher checks that the build and agent configuration exist and starts
Hayate in the foreground. Stop with Ctrl-C. Starting it again with the same home
reuses its configuration, conversations and queue. Run only one process against
an agent home.

## Connect Matrix

Create a separate Matrix account for the assistant. Supply its homeserver, access
token and device identity through the environment or your secret manager. Set
allowed users and room policies before inviting it to shared rooms. Preserve the
agent home and Matrix crypto state across restarts.

See Core's [configuration guide](https://github.com/hayate-agent/core/blob/main/docs/configuration.md)
and [Matrix encryption guide](https://github.com/hayate-agent/core/blob/main/docs/matrix-e2ee.md).

## Operate a persistent service

Use systemd on Linux/WSL2 or launchd on macOS to supervise the foreground command.
Provide the same home, working directory, PATH and credential injection each time.
Allow graceful shutdown; do not run a second writer during an update.

Back up both the agent home and provider configuration. Review a new Core version,
run its tests, and restart the service to activate it. Do not delete persistent
volumes or crypto stores as part of a routine update.

For container builds and advanced deployment settings, see the
[Core installation guide](https://github.com/hayate-agent/core/blob/main/docs/installation.md).

## Public example updates

These examples are published as reviewed snapshots. Changes are validated against
the pinned public Core dependency before automatic integration. Unchanged example
files do not require another publication when unrelated deployment configuration
changes elsewhere. The product repositories retain their own release schedules.

## Contributing

Examples should be small, runnable and free of organization-specific identities,
hostnames and secrets. Document required configuration, persistent paths, health
checks and safe shutdown behavior. Open a pull request with validation instructions.

## Related projects

- [Core](https://github.com/hayate-agent/core) — agent runtime, terminal interface and APIs
- [Plugins](https://github.com/hayate-agent/plugins) — optional integrations and backend services
- [WebUI](https://github.com/hayate-agent/webui) — independent browser dashboard with its own Docker/Compose setup

These examples run Core. The WebUI is installed separately; a Core container alone
does not install or expose the standalone dashboard.

## License

The examples in this repository are [CC0-1.0](LICENSE), as declared previously.
Core, Plugins and WebUI have their own Apache-2.0 licenses. The example license
does not relicense those products or their third-party dependencies.
