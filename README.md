# OpenID Connect Proxy in Docker

Use apache with [mod_auth_openidc](https://oasis.rancher.localhost/probe) as a proxy for
single sign on.

Features:

- Configured entirely with environment variables.
- Support for templates for common providers. Azure included.
- Uses jinja2 templates for configuration allowing new providers
  in containers that use this as a base to be added easily.
- Container tags track `mod_auth_openidc` version.

## Usage Example:

```
docker run -ti --rm \
    -e OIDC_PROVIDER_TEMAPLATE=azure \
    -e OIDC_PROVIDER_AZURE_TENANTID=${YOUR_AZURE_TENANT} \
    -e OIDC_CLIENT_ID=${YOUR_CLIENT_ID} \
    -e OIDC_CLIENT_SECRET_FILE=/var/run/secrets/azure-client-secret \
    -e OIDC_SECURE_PATHS_1_PATH=/ \
    -e OIDC_SECURE_PATHS_1_BACKEND_URL=http://app:8080/ \
    -e OIDC_CRYPTO_PASSPHRASE_FILE=/var/run/oidc-crypto-passphrase \
    -v ${PATH_TO_CLIENT_SECRET_FILE}:/var/run/secrets/azure-client-secret:r \
    -v ${PATH_TO_CRYPTO_PASSPHRASE_FILE}:/var/un/secrets/oidc-crypto-passphrase:r
```

Note that currently the container is designed to read secrets from files. Secrets from
environment variables may be a future enhancement if it becomes necessary.

## Environment Variables

Many of the values documented in [mod_auth_openidc](https://github.com/zmartzone/mod_auth_openidc/blob/master/auth_openidc.conf)
are supported. Check the [config template](tempaltes/httpd.conf.jinja) for details. Here are some highlights:

**OIDC_PROXY_CONFIG_PATH**: Location where the configuration file will be placed. Shouldn't be changed unless
you're doing something interested. Default: `/etc/httpd/conf.d/proxy.conf`.

**OIDC_PROXY_LOGFILE**: Log all access to this file.

**OIDC_FRONTEND_SSL_ENABLE**: Enable SSL on the frontend. Note that port 443 is always open but may not be properly
configured unless this is on. Don't set this, it's mostly for development. Use some kind of other proxy in front
of this container.

**OIDC_FRONTEND_HOSTNAME**: Only used for SSL, to support SNI properly.

**OIDC_FRONTEND_DISABLE_CACHING**: Send various no-cache headers, useful for development.

**OIDC_PROVIDER_TEMPLATE**: Use a specific template to configure httpd rather than the generic options. Some
Configuration options will not longer be avaialble (mostly those that control how the proxy will interact with
a provider). Templates are included from `templates/httpd.${OIDC_PROVIDER_TEMPLATE}.conf.jinja`.

**OIDC_CRYPTO_PASSPHRASE_FILE** and **OIDC_CLIENT_SECRET_FILE**: This container expects secrets to be supplied
as files (ala Kubernetes/Swarm secrets).

**OIDC_SECURE_PATHS**: List of all paths and their required access. If none of these are set, the proxy
will not require authentication for any URLs. This value is a set of several environment variables:

| Variable | Default | Mapping |
|----------|---------|---------|
| OIDC_SECURE_PATHS_#_PATH | | URL path for which this rule applies. |
| OIDC_SECURE_PATHS_#_SCOPE| | Optional. Define scopes specific to this path. |
| OIDC_SECURE_PATHS_#_AUTH_PARAMS | | Optional. Add parameters to send to the authorization endpoint of the provider. |
| OIDC_SECURE_PATHS_#_HEADERS_USERNAME | `X-Remote-User` | Header in which to send the user's username |
| OIDC_SECURE_PATHS_#_ACTIONS_NOTLOGGEDIN | `auth` | Action to take when a request it not authenticated. Can be `auth` or `401`, authenticate or issue a 401. |
| OIDC_SECURE_PATHS_#_ACTIONS_UNAUTHORIZED | `401` | Action to take when a user is authenticated but does not pass authorization checks. |
| OIDC_SECURE_PATHS_#_REFRESHTOKEN_PASS | False | Corresponds to `OIDCPassRefreshToken`. |
| OIDC_SECURE_PATHS_#_BACKEND_URL | | Required. URL of the backend for this frontend url. |
| OIDC_SECURE_PATHS_#_BACKEND_FLAGS | Any proxy flags for this backend. See [the `ProxyPass` docs](https://httpd.apache.org/docs/2.4/mod/mod_proxy.html#proxypass) |
| OIDC_SECURE_PATHS_#_REQUIRE | `valid-user` | Rule for this location. |

## Provider Templates

Provider templates may be added by containers that inherit from this one by copying a single
jinja2 template into `/usr/share/oidc-proxy/templates`. The file should be named `httpd.${PROVIDER}.conf.jinja`.

### Azure

The Azure template pre-configures the various provider URLs, the scope, and the remote user claim for use with
Azure. The following variables are available:

| Variable | Default | Notes |
|----------|---------|-------|
| OIDC_PROVIDER_AZURE_TENANTID | | ID of your Azure AD Tenant (available on the app registration overview in the portal) |
| OIDC_PROVIDER_DISCOVERY_URL | Based on Tenant ID | |
| OIDC_PROVIDER_JWKSURI | Based on Tenant ID | |
| OIDC_SCOPE | `openid email` | |
| OIDC_CLAIMS_USERNAME | `email` | Use the user's e-mail as the value to populate the `X-Remote-User` header. |

