#!/usr/bin/env bash
#
# inputs:
#   ZITI_BROWZER_OIDC_URL   OIDC issuer url
#   ZITI_BROWZER_CLIENT_ID  OIDC client id
#   BROWZER_EMAILS          space or comma separated list of emails to create with a role
#

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

# workaround: ext-jwt-signer cannot be updated, so dependency tree must be cleaned up first;
#   https://github.com/hanzozt/zt/issues/2459
function cleanup() {
    for EMAIL in "${EMAILS[@]}"
    do
        zt edge delete identity "${EMAIL}"
    done
    zt edge delete auth-policy "${AUTH_POLICY_NAME}"
    zt edge delete ext-jwt-signer "${EXT_JWT_SIGNER_NAME}"
}

: "${ZITI_BROWZER_FIELD:=email}"
: "${EXT_JWT_SIGNER_NAME:="browzer-auth0-ext-jwt-signer"}"
: "${AUTH_POLICY_NAME:="browzer-auth0-auth-policy"}"
: "${IDENTITY_ROLES:="browzer.enabled.identities"}"

BROWZER_EMAILS="${BROWZER_EMAILS//,/ }"
typeset -a EMAILS=(${BROWZER_EMAILS})

oidc_config="$(curl -sSf ${ZITI_BROWZER_OIDC_URL%/}/.well-known/openid-configuration)"
issuer="$(jq -r .issuer <<< "${oidc_config}")"
jwks="$(jq -r .jwks_uri <<< "${oidc_config}")"

if zt edge list ext-jwt-signers "name=\"$EXT_JWT_SIGNER_NAME\"" --csv \
| awk -F, "\$2==\"$EXT_JWT_SIGNER_NAME\"" | grep -q $EXT_JWT_SIGNER_NAME
then
    cleanup
fi
ext_jwt_signer=$(zt edge create ext-jwt-signer "${EXT_JWT_SIGNER_NAME}" "${issuer}" --jwks-endpoint "${jwks}" --audience "${ZITI_BROWZER_CLIENT_ID}" --claims-property ${ZITI_BROWZER_FIELD})

if zt edge list auth-policies "name=\"$AUTH_POLICY_NAME\"" | grep -q $AUTH_POLICY_NAME
then
    auth_policy=$(zt edge update auth-policy "${AUTH_POLICY_NAME}" --primary-ext-jwt-allowed --primary-ext-jwt-allowed-signers ${ext_jwt_signer})
else
    auth_policy=$(zt edge create auth-policy "${AUTH_POLICY_NAME}" --primary-ext-jwt-allowed --primary-ext-jwt-allowed-signers ${ext_jwt_signer})
fi

for EMAIL in "${EMAILS[@]}"
do
    if zt edge list identities "name=\"${EMAIL}\"" | grep -q "${EMAIL}"
    then
        zt edge update identity "${EMAIL}" --auth-policy ${auth_policy} --external-id "${EMAIL}" -a "${IDENTITY_ROLES}"
    else
        zt edge create identity "${EMAIL}" --auth-policy ${auth_policy} --external-id "${EMAIL}" -a "${IDENTITY_ROLES}"
    fi
done

echo -e "\nissuer:" "$issuer\n"\
        "jwks:" "$jwks\n"\
        "ext-jwt-signer:" "$ext_jwt_signer\n"\
        "auth-policy:" "$auth_policy\n"\
        "email(s):" "${EMAILS[@]}\n" \
| column -t
