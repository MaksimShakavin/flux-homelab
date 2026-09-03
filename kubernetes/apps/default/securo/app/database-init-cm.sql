-- Runs once as the postgres superuser (Crunchy databaseInitSQL hook).
-- The `securo` database and owner are created by the postgress component's
-- users/databases spec; here we only pre-create the pgvector extension.
--
-- Securo migration 046_agents_foundation runs `CREATE EXTENSION vector` as the
-- non-superuser app user. `vector` is an UNTRUSTED extension, so the app user
-- cannot create it. Pre-creating it here (as superuser) satisfies the
-- migration's `pg_available_extensions` preflight and makes its
-- `CREATE EXTENSION IF NOT EXISTS vector` a no-op. pgvector ships in the stock
-- crunchy-postgres 5.8.x image, so no custom image is needed.
-- (`pgcrypto`, used by migration 052, is a TRUSTED extension and is created by
-- the app user itself, so it is intentionally not listed here.)
-- PostgreSQL 15+ revokes CREATE on the public schema from non-owners, so the
-- app user cannot create tables until granted. Give the securo user ownership.
\c securo
CREATE EXTENSION IF NOT EXISTS vector;
GRANT ALL ON SCHEMA public TO securo;
ALTER SCHEMA public OWNER TO securo;
