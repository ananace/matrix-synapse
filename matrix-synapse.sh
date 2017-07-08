#!/bin/bash -eu

function join_by { local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }

mkdir -p /kubeconf.d
mkdir -p /var/lib/matrix-synapse/signing

# This needs to exist, so don't allow empty vars
echo "server_name: ${MATRIX_SERVERNAME}" > /etc/matrix-synapse/conf.d/server_name.yaml
echo "${MATRIX_SIGNKEY}" > /var/lib/matrix-synapse/signing/signing.key

[ -n "${MATRIX_DATABASE-}" ] && (
  case ${MATRIX_DATABASE} in
    pg|postgres|postgresql)
      cat <<EOF > /etc/matrix-synapse/conf.d/database.yaml
database:
  name: psycopg2
  args:
    user: ${MATRIX_DB_USER:-synapse}
    password: ${MATRIX_DB_PASSWORD:-synapse}
    database: ${MATRIX_DB_DATABASE:-synapse}
    host: ${MATRIX_DB_HOST:-localhost}
    port: ${MATRIX_DB_PORT:-5432}
    cp_min: 5
    cp_max: 10
EOF
    ;;
    sqlite)
      cat <<EOF > /etc/matrix-synapse/conf.d/database.yaml
database:
  name: sqlite3
  args:
    database: "${MATRIX_DB_PATH:-/var/lib/matrix-synapse/homeserver.db}"
EOF
    ;;
  esac

)

[ -n "${MATRIX_LDAPURI-}" ] && [ -n "${MATRIX_LDAPBASE}" ] && cat <<EOF > /etc/matrix-synapse/conf.d/ldap.yaml
password_providers:
  - module: 'ldap_auth_provider.LdapAuthProvider'
    config:
      enabled: true
      uri: '${MATRIX_LDAPURI}'
      base: '${MATRIX_LDAPBASE}'
      attributes:
        uid: ${MATRIX_LDAPUIDATTR:-uid}
        mail: ${MATRIX_LDAPMAILATTR:-mail}
        name: ${MATRIX_LDAPNAMEATTR:-gecos}
EOF

[ -n "${MATRIX_TURNURIS-}" ] && [ -n "${MATRIX_TURNSECRET}" ] && cat <<EOF > /etc/matrix-synapse/conf.d/turn.yaml
turn_uris: [ "$(join_by '", "' "${MATRIX_TURNURIS[@]}")" ]
turn_shared_secret: ${MATRIX_TURNSECRET}
turn_user_lifetime: ${MATRIX_TURNLIFETIME:-86400000}
turn_allow_guests: ${MATRIX_TURNGUESTS:-False}
EOF

[ -n "${MATRIX_REPORTSTATS-}" ] && echo "report_stats: ${MATRIX_REPORTSTATS}" > /etc/matrix-synapse/conf.d/stats.yaml
[ -n "${MATRIX_PUBLICURL-}" ] && echo "public_baseurl: ${MATRIX_PUBLICURL}" > /etc/matrix-synapse/conf.d/publicurl.yaml
[ -n "${MATRIX_REGISTRATIONSECRET-}" ] \
    && echo "registration_shared_secret: ${MATRIX_REGISTRATIONSECRCET}" > /etc/matrix-synapse/conf.d/registration_shared_secret.yaml \
    || echo "registration_shared_secret: $(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 16 | head -1)" > /etc/matrix-synapse/conf.d/registration_shared_secret.yaml

[ -n "${MATRIX_INGRESS-}" ] && cat <<EOF > /etc/matrix-synapse/conf.d/listeners.yaml
listeners:
- port: 8448
  bind_address: ''
  type: http
  tls: true
  x_forwarded: true
  resources:
  - names:
    - client
    - webclient
    compress: true
  - names:
    - federation
    compress: false
- port: 8008
  bind_address: ''
  type: http
  tls: false
  x_forwarded: true
  resources:
  - names:
    - client
    - webclient
    compress: true
  - names:
    - federation
    copmress: false
EOF

echo 'media_store_path: "/var/lib/matrix-synapse/data"' > /etc/matrix-synapse/conf.d/media.yaml

cat <<EOF > /etc/matrix-synapse/conf.d/tls.yaml
tls_certificate_path: "/var/lib/matrix-synapse/tls/tls.crt"
tls_private_key_path: "/var/lib/matrix-synapse/tls/tls.key"
tls_dh_params_path:   "/var/lib/matrix-synapse/tls_dh/dhparams.pam"
signing_key_path:     "/var/lib/matrix-synapse/signing/signing.key"
EOF

touch /var/log/matrix-synapse/homserver.log
(tail -F /var/log/matrix-synapse/homeserver.log &)
python -m synapse.app.homeserver --config-path=/etc/matrix-synapse/homeserver.yaml --config-path=/etc/matrix-synapse/conf.d/ --config-path=/kubeconf.d/ "$@"
