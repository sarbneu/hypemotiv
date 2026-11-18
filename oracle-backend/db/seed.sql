-- ============================================================================
-- HypeMotiv demo seed data for user_id = 'demo'
-- ============================================================================
-- Run as the HYPEMOTIV schema owner AFTER db/schema.sql:
--
--   sqlplus HYPEMOTIV/<password>@//host:1521/ORCL @db/seed.sql
--
-- Safe to re-run: existing 'demo' rows are deleted first. This makes the
-- alarm, checklist and streak screens show data as soon as Oracle is wired up.
-- ============================================================================

WHENEVER SQLERROR CONTINUE

DELETE FROM hypemotiv.alarm_settings   WHERE user_id = 'demo';
DELETE FROM hypemotiv.user_checklists  WHERE user_id = 'demo';
DELETE FROM hypemotiv.user_streaks     WHERE user_id = 'demo';

-- 1. One demo alarm
INSERT INTO hypemotiv.alarm_settings
  (alarm_id, user_id, title, scheduled_time, audio_url, enabled, created_at)
VALUES
  ('demo-alarm-1', 'demo', 'Rise and Grind',
   TO_TIMESTAMP('2026-11-19T07:00:00', 'YYYY-MM-DD"T"HH24:MI:SS'),
   'https://www.myinstants.com/media/sounds/bruh-sound-effect-2.mp3',
   1, SYSTIMESTAMP);

-- 2. Five demo checklist tasks
INSERT INTO hypemotiv.user_checklists
  (task_id, user_id, task_name, emoji, completed, completed_at)
VALUES ('demo-task-1', 'demo', 'Drink a glass of water', '💧', 1, SYSTIMESTAMP);

INSERT INTO hypemotiv.user_checklists
  (task_id, user_id, task_name, emoji, completed, completed_at)
VALUES ('demo-task-2', 'demo', 'Make the bed', '🛏️', 1, SYSTIMESTAMP);

INSERT INTO hypemotiv.user_checklists
  (task_id, user_id, task_name, emoji, completed, completed_at)
VALUES ('demo-task-3', 'demo', '10-minute stretch', '🧘', 0, NULL);

INSERT INTO hypemotiv.user_checklists
  (task_id, user_id, task_name, emoji, completed, completed_at)
VALUES ('demo-task-4', 'demo', 'Review today’s goals', '🎯', 0, NULL);

INSERT INTO hypemotiv.user_checklists
  (task_id, user_id, task_name, emoji, completed, completed_at)
VALUES ('demo-task-5', 'demo', 'Send an accountability email', '📧', 0, NULL);

-- 3. Demo streak
INSERT INTO hypemotiv.user_streaks
  (user_id, current_streak, longest_streak, last_active, created_at)
VALUES ('demo', 14, 21, SYSTIMESTAMP, SYSTIMESTAMP);

COMMIT;

PROMPT Seeded user_id='demo': 1 alarm, 5 checklist tasks, streak 14.

EXIT;
