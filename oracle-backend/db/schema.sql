-- ============================================================================
-- HypeMotiv Oracle schema
-- ============================================================================
-- Run this as the HYPEMOTIV schema owner (the user named in ORACLE_USER):
--
--   sqlplus HYPEMOTIV/<password>@//host:1521/ORCL @db/schema.sql
--
-- or, from SQLcl / SQL Developer:
--
--   connect HYPEMOTIV/<password>@//host:1521/ORCL
--   @db/schema.sql
--
-- All objects are created unqualified in the connected schema. The Node
-- backend references them as hypemotiv.<table>, so either connect as the
-- HYPEMOTIV user, or (if using another user) create the HYPEMOTIV schema and
-- grant this user the required privileges. The script is safe to re-run:
-- each CREATE is guarded by a PL/SQL block that ignores "table exists".
-- ============================================================================

WHENEVER SQLERROR CONTINUE

-- 1. Alarm settings
BEGIN
  EXECUTE IMMEDIATE '
    CREATE TABLE alarm_settings (
      alarm_id       VARCHAR2(64) PRIMARY KEY,
      user_id        VARCHAR2(100) NOT NULL,
      title          VARCHAR2(200) NOT NULL,
      scheduled_time TIMESTAMP NOT NULL,
      audio_url      VARCHAR2(500),
      enabled        NUMBER(1) DEFAULT 1,
      created_at     TIMESTAMP DEFAULT SYSTIMESTAMP
    )';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

CREATE INDEX idx_alarms_user ON alarm_settings(user_id);

-- 2. User checklists
BEGIN
  EXECUTE IMMEDIATE '
    CREATE TABLE user_checklists (
      task_id      VARCHAR2(64) PRIMARY KEY,
      user_id      VARCHAR2(100) NOT NULL,
      task_name    VARCHAR2(200) NOT NULL,
      emoji        VARCHAR2(10),
      completed    NUMBER(1) DEFAULT 0,
      completed_at TIMESTAMP
    )';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

CREATE INDEX idx_checklists_user ON user_checklists(user_id);

-- 3. User streaks
BEGIN
  EXECUTE IMMEDIATE '
    CREATE TABLE user_streaks (
      user_id        VARCHAR2(100) PRIMARY KEY,
      current_streak NUMBER DEFAULT 0,
      longest_streak NUMBER DEFAULT 0,
      last_active    TIMESTAMP,
      created_at     TIMESTAMP DEFAULT SYSTIMESTAMP
    )';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

-- 4. User quotes
BEGIN
  EXECUTE IMMEDIATE '
    CREATE TABLE user_quotes (
      quote_id   VARCHAR2(64) PRIMARY KEY,
      user_id    VARCHAR2(100) NOT NULL,
      text       CLOB NOT NULL,
      author     VARCHAR2(200),
      created_at TIMESTAMP DEFAULT SYSTIMESTAMP
    )';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

CREATE INDEX idx_quotes_user ON user_quotes(user_id);

-- 5. Stored media files (uploads + ripped audio) ---------------------------
-- The backend stores bytes in the DATA BLOB. If Oracle is unreachable it
-- writes the same bytes to oracle-backend/uploads/<fileId> instead, so the
-- app continues to work without a database.
BEGIN
  EXECUTE IMMEDIATE '
    CREATE TABLE app_files (
      file_id    VARCHAR2(64) PRIMARY KEY,
      user_id    VARCHAR2(100) NOT NULL,
      file_name  VARCHAR2(300) NOT NULL,
      mime_type  VARCHAR2(100),
      file_size  NUMBER,
      kind       VARCHAR2(30),
      data       BLOB,
      created_at TIMESTAMP DEFAULT SYSTIMESTAMP
    )';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

CREATE INDEX idx_app_files_user ON app_files(user_id);

EXIT;
