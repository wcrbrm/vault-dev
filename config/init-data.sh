#!/usr/bin/env bash

# This script must be executed with root token on VAULT
if ! [ "$VAULT_ADDR" ]; then (echo [`date`] ERROR: VAULT_ADDR must be set >&2) && exit 1; fi
if ! [ "$VAULT_TOKEN" ]; then (echo [`date`] ERROR: VAULT_TOKEN must be set to a root token for this test >&2) && exit 1; fi

set -e
cd "$(dirname "$0")"

put_sample_data() {
  local path=$1
  local rnd_value=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  local key=$(date -Iseconds)
  if [[ "$2" != "" ]]; then
    key=$2
  fi
  if [[ "$3" != "" ]]; then
    rnd_value=$3
  fi

  set -x
  curl --silent \
    -H"Content-Type: application/json" \
    -H"X-Vault-Token: $VAULT_TOKEN" \
    --data "{\"data\": {\"$key\": \"$rnd_value\"}}" \
    "$VAULT_ADDR/v1/secret/data/$path"

  { set +x; } 2>/dev/null
}

put_user_sample_data() {
  local USER_ID=$1
  local CHUNK_MD5="ef593e1899bd8f423f7e747439aa1d46"
  local CHUNK_DATA="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+P+/HgAFhAJ/wlseKgAAAABJRU5ErkJggg=="
  
  echo "USER: $USER_ID"

  put_sample_data "docs/$USER_ID/info"
  for officerID in $(cat entities/*.json | grep officers | jq -r .entity_id)
  do
    put_sample_data "docs/$USER_ID/residence/officers/$officerID"
  done;
}

if [[ "$1" == "" ]]; then
  put_sample_data "config"
  
  for userID in $(cat entities/*.json | grep users | jq -r .entity_id)
  do
    put_user_sample_data $userID
  done;
else
  put_sample_data $@
fi
