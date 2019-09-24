#!/usr/bin/env bash

# This script must be executed with root token on VAULT
if ! [ "$VAULT_ADDR" ]; then (echo [`date`] ERROR: VAULT_ADDR must be set >&2) && exit 1; fi
if ! [ "$VAULT_TOKEN" ]; then (echo [`date`] ERROR: VAULT_TOKEN must be set to a root token for this test >&2) && exit 1; fi

set -e
cd "$(dirname "$0")"

USERPASS_ACCESSOR=$(vault auth list -format=json | jq -r '.["userpass/"].accessor')
if ! [ "$USERPASS_ACCESSOR" ]; then (echo [`date`] ERROR: USERPASS_ACCESSOR not found. please check userpass is enabled >&2) && exit 1; fi

# for each 'user' we need 1) entity.id and 2) token
# "2 users"
# "2 officers"

create_user() {
  local role=$1
  if ! [[ "$role" ]]; then (echo [`date`] ERROR: role parameter is missing >&2) && exit 1; fi
  local username=$2
  if ! [[ "$username" ]]; then (echo [`date`] ERROR: username parameter is missing >&2) && exit 1; fi
  local password=$3
  if ! [[ "$password" ]]; then (echo [`date`] ERROR: password parameter is missing >&2) && exit 1; fi
  local policies="$(cat ./roles/$role.txt)"

  echo
  echo "CREATING ENTITY for: \"$username\",\"password\":\"$password\",\"role\":\"$role\""
  # create password
  curl -s \
    -H"X-Vault-Token: $VAULT_TOKEN" \
    -H"Content-Type: application/json" \
    --data "{\"password\": \"$password\", \"policies\": \"$policies\"}" \
    "$VAULT_ADDR/v1/auth/userpass/users/$username"

  # create entity 
  local entity_id=$(curl -s \
    -H"X-Vault-Token: $VAULT_TOKEN" \
    -H"Content-Type: application/json" \
    --data "{\"name\": \"$username\", \"policies\": \"$policies\"}" \
    "$VAULT_ADDR/v1/identity/entity" | jq -r '.data.id')
  if ! [[ "$entity_id" ]]; then (echo [`date`] ERROR: could not create entity ID for $username. There was some error or this user exists) && exit 1; fi
  
  # create entity alias - to connect this entity 
  # to be accessible with user-password
  curl -s \
    -H"X-Vault-Token: $VAULT_TOKEN" \
    -H"Content-Type: application/json" \
    --data "{\"name\": \"$username\", \"mount_accessor\": \"$USERPASS_ACCESSOR\", \"canonical_id\": \"$entity_id\"}" \
    "$VAULT_ADDR/v1/identity/entity-alias" 

  echo "{\"username\":\"$username\",\"password\":\"$password\",\"role\":\"$role\",\"entity_id\":\"$entity_id\"}" > ./entities/$username.json
  cat "./entities/$username.json"
}

if [[ "$1" == "" ]]; then

  create_user users caterpilar caterpilar
else
  create_user $@
fi

# Use the following to check user:
# export VAULT_ADDR=http://localhost:8200
# vault login -method=userpass username=lesinge password=lesinge

