Environment variables;

- `MATRIX_SERVERNAME` - Sets the `server_name` variable. 
- `MATRIX_SIGNKEY` - Sets the signing key contents. Advisable to read from a secret in Kubernetes.
- `MATRIX_DATABASE` - Sets the database backend, currently supported are PostgreSQL and SQLite. `pg`/`postgres`/`postgresql` and `sqlite` respectively.
  - PostgreSQL:
    - `MATRIX_DB_USER` - The Postgres user to connect as, defaults to `synapse`
    - `MATRIX_DB_PASSWORD` - The password for the Postgres user, defaults to `synapse`
    - `MATRIX_DB_DATABASE` - The Postgres database to use, defaults to `synapse`
    - `MATRIX_DB_HOST` - The Postgres host to use, defaults to `localhost`
    - `MATRIX_DB_PORT` - The Postgres port to use, defaults to `5432`
  - SQLite:
    - `MATRIX_DB_PATH` - The path to the SQLite database, defaults to `/var/lib/matrix-synapse/data/homeserver.db`
- `MATRIX_LDAPURI`, `MATRIX_LDAPBASE` - Sets up LDAP authentication for the homeserver
  - `MATRIX_LDAPUIDATTR` - The UID attribute to use for users, defaults to `uid`
  - `MATRIX_LDAPMAILATTR` - The mail attribute to use, defaults to `mail`
  - `MATRIX_LDAPNAMEATTR` - The name attribute to use, defaults to `gecos`
- `MATRIX_TURNURIS`, `MATRIX_TURNSECRET` - Used to set up TURN connections
  - `MATRIX_TURNLIFETIME` - The user lifetime, defaults to `86400000`
  - `MATRIX_TURNGUESTS` - Allow guests access, defaults to `false`
- `MATRIX_REPORTSTATS` - Report homeserver stats
- `MATRIX_PUBLICURL` - Set the public homeserver URL (ex. https://matrix.example.com:8448/\_matrix)
- `MATRIX_REGISTRATIONSECRET` - Choose a registration secret, defaults to a 16-character random string
- `MATRIX_INGRESS` - Configures Synapse to assume a reverse proxy if set

