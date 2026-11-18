-- ============================================================================
-- Create the HYPEMOTIV schema owner (standard / on-prem Oracle 19c+)
-- ============================================================================
-- Run as a DBA (as SYSDBA) BEFORE db/schema.sql:
--
--   sqlplus / as sysdba @db/create-user.sql
--
-- The backend's .env must then use ORACLE_USER=hypemotiv and
-- ORACLE_CONNECTSTRING=host:1521/ORCL (matching this schema name).
-- Replace the placeholder password below with a strong one and keep it in sync
-- with ORACLE_PASSWORD in .env.
-- ============================================================================

WHENEVER SQLERROR CONTINUE

CREATE USER hypemotiv IDENTIFIED BY "ChangeMe_Strong_Password";

GRANT CONNECT, RESOURCE, UNLIMITED TABLESPACE TO hypemotiv;

-- Needed for node-oracledb thin-mode metadata / DBMS_LOB operations.
GRANT CREATE SESSION TO hypemotiv;

-- Optional: allow the app user to be queried by monitoring tools.
-- GRANT SELECT_CATALOG_ROLE TO hypemotiv;

PROMPT
PROMPT Next: connect as the new owner and run db/schema.sql, then db/seed.sql
PROMPT   sqlplus hypemotiv@//host:1521/ORCL @db/schema.sql
PROMPT   sqlplus hypemotiv@//host:1521/ORCL @db/seed.sql
PROMPT
PROMPT For Oracle Autonomous Database (ATP/ADW) the schema user is created in
PROMPT the OCI console (Database Actions > Users), NOT with CREATE USER here.
PROMPT Set that user's name as ORACLE_USER and use the wallet connect string.

EXIT;
