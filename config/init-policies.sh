#!/usr/bin/env bash

# This script must be executed with root token on VAULT
if ! [ "$VAULT_ADDR" ]; then (echo [`date`] ERROR: VAULT_ADDR must be set >&2) && exit 1; fi
if ! [ "$VAULT_TOKEN" ]; then (echo [`date`] ERROR: VAULT_TOKEN must be set to a root token for this test >&2) && exit 1; fi

set -e
cd "$(dirname "$0")"

POLICIES=$(find ./policies/*.hcl | sed s/\.hcl//g | sed s/\\.\\/policies\\///g | sort)
set -x
for P in $POLICIES; do vault policy write $P ./policies/$P.hcl; vault policy read $P; done
vault policy list
