#!/bin/bash
set -e

export OIDC_PROXY_CONFIG_PATH=${OIDC_PROXY_CONFIG_PATH:-/etc/httpd/conf.d/proxy.conf}

echo "Configuring OpenID Connect Proxy..."
mkdir -p /var/log/httpd

if [[ "x${OIDC_PROVIDER_ENDPOINTS_TOKEN_AUTH}" = "xprivate_key_jwt" ]]; then
    echo "Error: Private key authentication is not yet supported by this proxy." 1&>2
    echo "Note: This is support by mod_auth_oidc, it just needs to be implemented in the config." 1>&2
    exit 1
fi

if [[ -z $(env | grep OIDC_SECURE_PATHS) ]]; then
    echo "Error: Please specify at least one secure path and backend like:" 1>&2
    echo "OIDC_SECURE_PATHS_1_PATH=/" 1>&2
    echo "OIDC_SECURE_PATHS_1_BACKEND_URL=https://localhost" 1>&2
    exit 1
fi

j2tmpl /usr/share/oidc-proxy/templates/httpd.conf.jinja \
    -b /usr/share/oidc-proxy/templates -o "${OIDC_PROXY_CONFIG_PATH}"

if [[ "x${OIDC_PROXY_DUMP_CONFIG}" = "xtrue" || "${1}" = "dump-config" ]]; then
  cat /etc/httpd/conf.d/proxy.conf
fi

if [[ ! "${1}" = "dump-config" ]]; then
    ln -sf /dev/stderr /var/log/httpd/error_log
    rm -Rf /run/httpd/*
    exec httpd -DFOREGROUND
fi
