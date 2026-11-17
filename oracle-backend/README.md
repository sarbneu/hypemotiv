# HypeMotiv Oracle Backend

REST API backend for the HypeMotiv mobile app that syncs data to Oracle Database.

## Overview

The HypeMotiv Flutter app uses local SQLite (Hive) for offline storage. When an Oracle connection is configured, the app syncs its data to Oracle via this REST API.

### Why a Backend?

- Flutter/Dart has no official Oracle database driver
- Oracle is accessed server-side via Node.js + oracledb
- The mobile app communicates with Oracle through HTTPS/REST

## Setup

### Prerequisites

- Node.js 18+ 
- Oracle Database (19c or later) with the HR sample schema or your own schema
- npm

### Installation

```bash
cd oracle-backend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your Oracle connection details
nano .env

# Start the server
npm start
```

### Oracle Connection Configuration

Create a `.env` file with:
```env
PORT=3000
ORACLE_USER=hr
ORACLE_PASSWORD=hr
ORACLE_HOST=localhost
ORACLE_PORT=1521
ORACLE_SERVICE=ORCL
ORACLE_CONNECTSTRING=localhost:1521/ORCL
```

## The Database Schema

You need to create these tables in Oracle:

```sql
-- Alarm settings
CREATE TABLE hypemotiv.alarm_settings (
  alarm_id   VARCHAR2(64) PRIMARY KEY,
  user_id    VARCHAR2(100) NOT NULL,
  title      VARCHAR2(200) NOT NULL,
  scheduled_time TIMESTAMP NOT NULL,
  audio_url  VARCHAR2(500),
  enabled    NUMBER(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- User checklists
CREATE TABLE hypemotiv.user_checklists (
  task_id     VARCHAR2(64) PRIMARY KEY,
  user_id     VARCHAR2(100) NOT NULL,
  task_name   VARCHAR2(200) NOT NULL,
  emoji       VARCHAR2(10),
  completed   NUMBER(1) DEFAULT 0,
  completed_at TIMESTAMP
);

-- User streaks  
CREATE TABLE hypemotiv.user_streaks (
  user_id       VARCHAR2(100) PRIMARY KEY,
  current_streak NUMBER DEFAULT 0,
  longest_streak NUMBER DEFAULT 0,
  last_active   TIMESTAMP,
  created_at    TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- User quotes
CREATE TABLE hypemotiv.user_quotes (
  quote_id   VARCHAR2(64) PRIMARY KEY,
  user_id    VARCHAR2(100) NOT NULL,
  text       CLOB NOT NULL,
  author     VARCHAR2(200),
  created_at TIMESTAMP DEFAULT SYSTIMESTAMP
);
```

## REST API Endpoints

### GET /api/health
- Health check endpoint

### GET /api/alarms?userId=
- Get alarms for a user

### POST /api/alarms
- Save alarms for a user
- Body: `{ "userId": "...", "alarms": [...] }`

### GET /api/checklists?userId=
- Get checklists for a user

### POST /api/checklists
- Save checklists for a user
- Body: `{ "userId": "...", "checklists": [...] }`

### GET /api/streaks?userId=
- Get streak for a user

### POST /api/streaks
- Save/update streak for a user
- Body: `{ "userId": "...", "currentStreak": 5, "longestStreak": 12, "lastActive": "..." }`

### GET /api/quotes?count=1
- Get random motivational quotes

### POST /api/quotes
- Save quotes for a user
- Body: `{ "userId": "...", "quotes": [...] }`

## Usage in Flutter

The `OracleService` in `lib/services/oracle_service.dart` communicates with these endpoints:

```dart
// Fetch user settings from Oracle
final result = await OracleService.fetchSettings(userId);

// Push alarm settings to Oracle
await OracleService.saveAlarms(userId, alarms);
```

## Troubleshooting

### Connection refused (ECONNREFUSED)
- Check Oracle is running
- Verify the connectString in .env
- Test with: `tnsping ORCL`

### Authentication failed
- Verify username and password
- Ensure user has access to required tables

### SSL/TLS errors
- For local dev, use non-TLS connection (localhost)
- For production, configure proper TLS certificates

## License

MIT
