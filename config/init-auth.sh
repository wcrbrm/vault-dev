#!/usr/bin/env bash

# This script must be executed with root token on VAULT
if ! [ "$VAULT_ADDR" ]; then (echo [`date`] ERROR: VAULT_ADDR must be set >&2) && exit 1; fi
if ! [ "$VAULT_TOKEN" ]; then (echo [`date`] ERROR: VAULT_TOKEN must be set to a root token for this test >&2) && exit 1; fi

set -e
cd "$(dirname "$0")"

auth_enable() {
  if [[ "$(vault auth list | grep $1)" == "" ]]; then
    vault auth enable $1
  fi
}

auth_enable userpass
# auth_enable approle
# auth_enable github
