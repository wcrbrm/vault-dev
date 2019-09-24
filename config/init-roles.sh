#!/usr/bin/env bash

# This script must be executed with root token on VAULT
if ! [ "$VAULT_ADDR" ]; then (echo [`date`] ERROR: VAULT_ADDR must be set >&2) && exit 1; fi
if ! [ "$VAULT_TOKEN" ]; then (echo [`date`] ERROR: VAULT_TOKEN must be set to a root token for this test >&2) && exit 1; fi

set -e
cd "$(dirname "$0")"

verify_policies() {
  local name=$1
  IFS=$'\n' 
  local ALLOWED=" $(vault policy list) "
  unset IFS

  local FATAL=
  for policy in $(cat ./roles/$name.txt | sed 's/,/ /g'); do
    if ! [[ "${ALLOWED[@]}" =~ "$policy" ]]; then
      echo "FATAL ERROR: policy \"$policy\" not defined to be used in role \"$name\""
      FATAL="y"
    fi
  done
  if [[ "$FATAL" != "" ]]; then exit 1; fi
}

create_role() {
  local name=$1
  verify_policies $name

  vault write auth/token/roles/$name \
    allowed_policies="$(cat ./roles/$name.txt)" \
    period="24h"
  vault read auth/token/roles/$name
}

create_approle() {
  local name=$1
  vault write auth/approle/role/$name \
    policies="$(cat ./roles/$name.txt)" \
    period="24h"

  ROLE_ID=$(vault read auth/approle/role/$name/role-id | grep role_id)
  SECRET_ID=$(vault write -force auth/approle/role/$name/secret-id | grep secret_id | head -n1)
  TOKEN=$(curl -s --data \'{"role_id": "$ROLE_ID", "secret_id": "$SECRET_ID"}\' $VAULT_ADDR/v1/auth/approle/login)

  echo "role_id=$ROLE_ID"
  echo "secret_id=$SECRET_ID"
  echo "token=$TOKEN"
}

if [[ "$1" == "" ]]; then
  for role in $(ls ./roles/*.txt | sed 's/\.\/roles\///g' | sed 's/\.txt//g'); do
    create_role $role
  done
else
  create_role $@
fi

echo
echo 
echo "Current Roles:"
vault list auth/token/roles