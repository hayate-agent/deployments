# Hayate Agent Deployments

Deployment examples for [Hayate Agent](https://github.com/hayate-agent/core), an
AI assistant for the terminal and Matrix.

Use this repository to run a persistent assistant from a built Core checkout.
Keep your own agent configuration, credentials and persistent data outside Git.

## Requirements

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

## Contributing

Examples should be small, runnable and free of organization-specific identities,
hostnames and secrets. Document required configuration, persistent paths, health
checks and safe shutdown behavior. Open a pull request with validation instructions.

## License

The examples in this repository are [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/).
Core and Plugins have their own Apache-2.0 licenses.
