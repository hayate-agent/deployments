#!/bin/sh
# Generic manual foreground launcher; never discovers a private installation.
set -eu
: "${HAYATE_INSTALL:?Set HAYATE_INSTALL to the built public Core checkout}"
: "${HAYATE_AGENT_HOME:?Set HAYATE_AGENT_HOME to a new example home}"
case "$HAYATE_INSTALL" in /*) ;; *) echo 'HAYATE_INSTALL must be absolute' >&2; exit 1;; esac
case "$HAYATE_AGENT_HOME" in /*) ;; *) echo 'HAYATE_AGENT_HOME must be absolute' >&2; exit 1;; esac
test -f "$HAYATE_INSTALL/dist/cli.js" || { echo 'Build the selected public Core first' >&2; exit 1; }
test -f "$HAYATE_AGENT_HOME/hayate-agent.yaml" || { echo 'Initialize the example home first' >&2; exit 1; }
exec node "$HAYATE_INSTALL/dist/cli.js" run
