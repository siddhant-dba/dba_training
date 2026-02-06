# 1-MONTH POSTGRESQL MASTERY FOR SQL SERVER DBAs
## Fast-Track Syllabus for Entry-Level PostgreSQL Positions

*Designed for DBAs with 2 years SQL Server experience*
*Target: PostgreSQL DBA role readiness in 30 days*

---

## WEEK 1: POSTGRESQL FUNDAMENTALS & ARCHITECTURE MAPPING

MODULE 1: POSTGRESQL ARCHITECTURE & SQL SERVER COMPARISON ═══════════════════
│
├── 1️⃣ ARCHITECTURE ROOT (vs SQL Server)
│   ├── Client → libpq Protocol → PostgreSQL Server (vs TDS → Database Engine)
│   ├── Query Processing: Parser → Rewriter → Planner → Executor (vs Relational Engine)
│   ├── Storage: Heap/Toast → Buffer Manager → WAL Writer (vs Storage Engine)
│   └── Process Model: Postmaster + Backend Processes (vs SQLOS Threading)
│
├── 2️⃣ CORE DIFFERENCES FROM SQL SERVER
│   ├── Multi-Process vs Multi-Thread: Each connection = OS process (not thread)
│   ├── MVCC Always On: No read/write blocking (vs SQL Server locking)
│   ├── No Instance Concept: Cluster = multiple databases, One port per cluster
│   ├── Schemas Work Differently: search_path (vs default schema per user)
│   └── VACUUM Required: Dead tuple cleanup (vs auto-cleanup in SQL Server)
│
├── 3️⃣ POSTGRESQL CLUSTER STRUCTURE
│   ├── Cluster (like SQL Server Instance): Contains multiple databases
│   ├── System Databases: postgres, template0, template1 (vs master, model, tempdb)
│   ├── User Databases: Independent, Cannot query across databases easily
│   └── Tablespaces: Like filegroups, Control physical file location
│
├── 4️⃣ PHYSICAL STORAGE LAYOUT
│   ├── Data Directory: $PGDATA (vs SQL Server data files)
│   │   ├── base/: Database files (subdirectories by OID)
│   │   ├── pg_wal/: Write-Ahead Log (vs .ldf transaction log)
│   │   ├── pg_xact/: Transaction status (commit/abort info)
│   │   └── postgresql.conf, pg_hba.conf: Configuration files
│   │
│   ├── File Organization: 1GB segment files (vs 8KB pages → Extents)
│   ├── Page Structure: 8KB pages (same as SQL Server)
│   ├── TOAST: The Oversized-Attribute Storage Technique (vs LOB storage)
│   └── No Filegroups: Use tablespaces instead
│
├── 5️⃣ MEMORY ARCHITECTURE
│   ├── Shared Buffers: Like SQL Server Buffer Pool (data/index cache)
│   ├── work_mem: Per-operation memory (sorts, hash joins) - per query/session
│   ├── maintenance_work_mem: For VACUUM, CREATE INDEX, etc.
│   ├── effective_cache_size: Hint to planner (not actual allocation)
│   └── No Plan Cache Concept: Prepared statements per session only
│
├── 6️⃣ PROCESS ARCHITECTURE (Critical Difference)
│   ├── Postmaster: Master process (like SQL Server service)
│   ├── Backend Processes: One per client connection (NOT threads!)
│   ├── Background Processes:
│   │   ├── WAL Writer: Writes WAL to disk
│   │   ├── Background Writer: Flushes dirty buffers
│   │   ├── Checkpointer: Checkpoint operations
│   │   ├── Autovacuum Launcher/Workers: Automatic VACUUM
│   │   ├── Stats Collector: Collects statistics (like DMVs)
│   │   └── Logical Replication Workers: For replication
│   │
│   └── Connection Overhead: Higher than SQL Server (process vs thread)
│
├── 7️⃣ TRANSACTION & CONCURRENCY (MVCC Focus)
│   ├── MVCC (Multi-Version Concurrency Control): Always enabled
│   │   ├── Readers NEVER block writers (vs SQL Server locks)
│   │   ├── Writers NEVER block readers
│   │   ├── Row Versioning: Creates new tuple version (vs tempdb version store)
│   │   └── Dead Tuples: Requires VACUUM cleanup
│   │
│   ├── Isolation Levels: Read Committed (default), Repeatable Read, Serializable
│   │   └── NO Read Uncommitted: Maps to Read Committed
│   │
│   ├── Locking: Row-level, Table-level (simpler than SQL Server)
│   ├── Write-Ahead Log (WAL): Like transaction log, Crash recovery
│   └── No Snapshot Isolation: Repeatable Read uses MVCC instead
│
├── 8️⃣ SQL SERVER TO POSTGRESQL MAPPING
│   
│   **CONCEPT MAPPING:**
│   ```
│   SQL Server              →  PostgreSQL
│   ────────────────────────────────────────────────────────
│   Instance                →  Cluster (pg_ctl/systemctl)
│   Database                →  Database (similar)
│   Schema                  →  Schema (different behavior)
│   Login                   →  Role (unified concept)
│   Database User           →  Role with LOGIN attribute
│   Server Role             →  Role with special privileges
│   master database         →  postgres database
│   model database          →  template1 database
│   tempdb database         →  Temporary tablespace (auto)
│   msdb database           →  No equivalent (use extensions)
│   
│   SQL Agent               →  pg_cron extension / cron jobs
│   Linked Server           →  Foreign Data Wrapper (FDW)
│   Database Mail           →  External scripts (no built-in)
│   SSMS                    →  pgAdmin, DBeaver, psql
│   T-SQL                   →  PL/pgSQL (different syntax)
│   
│   .mdf file               →  base/[oid]/files
│   .ldf file               →  pg_wal/
│   Filegroup               →  Tablespace
│   
│   sys.dm_* (DMVs)         →  pg_stat_*, pg_catalog.*
│   sp_who2                 →  pg_stat_activity
│   DBCC CHECKDB            →  No direct equivalent (rare corruption)
│   
│   Buffer Cache Hit Ratio  →  blks_hit / (blks_hit + blks_read)
│   Page Life Expectancy    →  No direct metric
│   Wait Statistics         →  pg_stat_activity (wait_event)
│   ```
│   
│   **DATA TYPE MAPPING:**
│   ```
│   INT, BIGINT             →  INTEGER, BIGINT
│   VARCHAR(n)              →  VARCHAR(n) or TEXT
│   NVARCHAR(n)             →  VARCHAR (PostgreSQL is UTF-8 by default!)
│   CHAR(n)                 →  CHAR(n) (avoid, use VARCHAR)
│   DATETIME                →  TIMESTAMP (no time zone)
│   DATETIME2               →  TIMESTAMP (same)
│   DATETIMEOFFSET          →  TIMESTAMPTZ (with time zone)
│   DATE                    →  DATE
│   TIME                    →  TIME
│   UNIQUEIDENTIFIER        →  UUID
│   VARBINARY(MAX)          →  BYTEA
│   XML                     →  XML
│   JSON                    →  JSON or JSONB (binary, faster)
│   BIT                     →  BOOLEAN
│   MONEY                   →  NUMERIC(19,4) or MONEY type
│   IDENTITY(1,1)           →  SERIAL or GENERATED ALWAYS AS IDENTITY
│   ```
│
└── 9️⃣ INITIAL HANDS-ON SETUP
    ├── Install PostgreSQL 15/16 on Linux (Ubuntu/RHEL)
    ├── Install pgAdmin 4 (GUI tool)
    ├── Install psql (command-line client)
    ├── Locate postgresql.conf and pg_hba.conf
    ├── Practice: Start/stop PostgreSQL service
    └── Connect using psql: `psql -U postgres -d postgres`

---

MODULE 2: INSTALLATION, CONFIGURATION & BASIC ADMINISTRATION ══════════════
│
├── Pre-Installation Planning
│   ├── OS Choice: Linux (recommended), Windows (supported)
│   ├── PostgreSQL Version: 15, 16 (latest stable)
│   ├── Hardware: CPU, RAM, Disk (SSD recommended for pg_wal)
│   ├── Port: 5432 (default)
│   └── User Account: postgres (system user created during install)
│
├── Installation Methods
│   ├── Linux Package Managers
│   │   ├── Ubuntu/Debian: apt install postgresql
│   │   ├── RHEL/CentOS: yum install postgresql-server
│   │   └── PostgreSQL Official Repository (recommended for latest)
│   │
│   ├── Windows: EDB Installer or zip distribution
│   ├── Docker: Official PostgreSQL images
│   └── Cloud: AWS RDS, Azure Database for PostgreSQL, Google Cloud SQL
│
├── Post-Installation Configuration
│   ├── Initialize Cluster: initdb -D /var/lib/postgresql/data (if needed)
│   ├── postgresql.conf: Main configuration file
│   │   ├── listen_addresses: '*' or specific IPs
│   │   ├── port: 5432
│   │   ├── max_connections: 100 (default), Adjust based on workload
│   │   ├── shared_buffers: 25% of RAM (start)
│   │   ├── effective_cache_size: 50-75% of RAM (planner hint)
│   │   ├── work_mem: 4MB default (increase for complex queries)
│   │   ├── maintenance_work_mem: 64MB (for VACUUM, indexes)
│   │   ├── wal_level: replica (for replication/PITR)
│   │   └── log_destination: 'stderr' or 'csvlog'
│   │
│   ├── pg_hba.conf: Client authentication (CRITICAL for security)
│   │   ├── Format: TYPE DATABASE USER ADDRESS METHOD
│   │   ├── local: Unix socket connections
│   │   ├── host: TCP/IP connections
│   │   ├── Methods: trust, md5, scram-sha-256, peer, ident
│   │   └── Example: host all all 0.0.0.0/0 scram-sha-256
│   │
│   ├── Reload Configuration: pg_ctl reload or SELECT pg_reload_conf();
│   ├── Restart Required: For some parameters (shared_buffers, max_connections)
│   └── Service Management
│       ├── systemctl start postgresql (Linux)
│       ├── systemctl enable postgresql (auto-start)
│       └── pg_ctl start -D $PGDATA (manual)
│
├── Essential psql Commands (vs SSMS)
│   ```
│   \l                  List databases (like sp_databases)
│   \c dbname           Connect to database (like USE)
│   \dt                 List tables in current schema
│   \dt schema.*        List tables in specific schema
│   \d tablename        Describe table (like sp_help)
│   \du                 List roles (users)
│   \dn                 List schemas
│   \df                 List functions
│   \dv                 List views
│   \di                 List indexes
│   \dx                 List extensions
│   \timing on          Show query execution time
│   \x                  Expanded display (toggle)
│   \q                  Quit
│   \?                  Help
│   \h SELECT           Help on SQL command
│   \! ls               Execute shell command
│   ```
│
├── Connection Management (vs SQL Server)
│   ├── Connection Pooling: Use PgBouncer or pgpool-II (REQUIRED for scale)
│   │   └── Why: Process-per-connection overhead (not thread like SQL Server)
│   │
│   ├── Check Active Connections:
│   │   └── SELECT * FROM pg_stat_activity;  (vs sp_who2)
│   │
│   ├── Kill Connection:
│   │   └── SELECT pg_terminate_backend(pid);  (vs KILL SPID)
│   │
│   └── Connection Limits:
│       ├── max_connections (postgresql.conf)
│       ├── Per-database: ALTER DATABASE mydb CONNECTION LIMIT 50;
│       └── Per-role: ALTER ROLE myuser CONNECTION LIMIT 10;
│
├── Database Creation & Management
│   ├── CREATE DATABASE mydb
│   │       OWNER = myuser
│   │       ENCODING = 'UTF8'
│   │       LC_COLLATE = 'en_US.UTF-8'
│   │       LC_CTYPE = 'en_US.UTF-8'
│   │       TEMPLATE = template0
│   │       TABLESPACE = pg_default;
│   │
│   ├── ALTER DATABASE: Change owner, rename, set parameters
│   ├── DROP DATABASE: Cannot be connected to database being dropped
│   ├── Database Properties: System catalogs (pg_database)
│   └── Template Databases:
│       ├── template0: Pristine template (never modify)
│       ├── template1: Default template (can customize)
│       └── Custom templates: For standardized new databases
│
├── Schema Management (Different from SQL Server!)
│   ├── search_path: Like default schema, but ordered list
│   │   └── SHOW search_path;  -- Default: "$user", public
│   │
│   ├── CREATE SCHEMA sales AUTHORIZATION myuser;
│   ├── SET search_path TO sales, public;  -- Per session
│   ├── ALTER DATABASE mydb SET search_path TO sales, public;  -- Persistent
│   └── Best Practice: Create schema per application, Don't use public
│
├── Tablespaces (Like Filegroups)
│   ├── CREATE TABLESPACE fast_ssd LOCATION '/mnt/ssd/pgdata';
│   ├── CREATE TABLE orders (...) TABLESPACE fast_ssd;
│   ├── ALTER DATABASE mydb SET TABLESPACE fast_ssd;
│   └── Default Tablespaces: pg_default (data), pg_global (system catalogs)
│
└── Configuration Best Practices
    ├── shared_buffers: Start with 25% RAM (max ~8-16GB on Linux)
    ├── effective_cache_size: 50-75% RAM (not allocated, just hint)
    ├── work_mem: 4MB → 16-64MB (multiply by max_connections!)
    ├── maintenance_work_mem: 256MB - 1GB (VACUUM, CREATE INDEX)
    ├── checkpoint_completion_target: 0.9 (spread I/O over 90% of interval)
    ├── wal_buffers: 16MB (usually auto-tuned)
    ├── max_wal_size: 1-4GB (controls checkpoint frequency)
    ├── random_page_cost: 1.1 (for SSD), 4.0 (for HDD)
    └── effective_io_concurrency: 200 (for SSD), 2 (for HDD)

---

## WEEK 2: SECURITY, BACKUP & RECOVERY

MODULE 3: SECURITY & AUTHENTICATION ═════════════════════════════════════════
│
├── Authentication Methods (pg_hba.conf)
│   ├── trust: No password (DANGEROUS - dev only!)
│   ├── md5: MD5 password hash (legacy)
│   ├── scram-sha-256: Modern password auth (RECOMMENDED)
│   ├── peer: OS user must match PostgreSQL user (local connections)
│   ├── ident: Query OS for username (local or remote)
│   ├── cert: SSL certificate authentication
│   └── LDAP/RADIUS/PAM: Enterprise authentication
│
├── Roles (Unified Login/User Concept - Different from SQL Server!)
│   ├── No Separate Login/User: Role = both
│   ├── CREATE ROLE john WITH LOGIN PASSWORD 'secure_password';
│   ├── CREATE ROLE developers;  -- Group role (no LOGIN)
│   ├── GRANT developers TO john;  -- Add john to group
│   │
│   ├── Role Attributes (vs SQL Server Server Roles):
│   │   ├── SUPERUSER: Like sysadmin (full control)
│   │   ├── CREATEDB: Can create databases
│   │   ├── CREATEROLE: Can create other roles
│   │   ├── LOGIN: Can connect (without this = group role)
│   │   ├── REPLICATION: For replication connections
│   │   ├── BYPASSRLS: Bypass Row-Level Security
│   │   └── CONNECTION LIMIT: Max connections for this role
│   │
│   └── Default Roles (PostgreSQL 14+):
│       ├── pg_read_all_data: Read all tables/views
│       ├── pg_write_all_data: Modify all tables
│       ├── pg_monitor: Read monitoring views
│       └── pg_signal_backend: Send signals to backends
│
├── Permissions (GRANT/REVOKE)
│   ├── Database Level:
│   │   ├── GRANT CONNECT ON DATABASE mydb TO john;
│   │   ├── GRANT CREATE ON DATABASE mydb TO developers;
│   │   └── REVOKE ALL ON DATABASE mydb FROM PUBLIC;
│   │
│   ├── Schema Level:
│   │   ├── GRANT USAGE ON SCHEMA sales TO john;
│   │   ├── GRANT CREATE ON SCHEMA sales TO developers;
│   │   └── REVOKE ALL ON SCHEMA public FROM PUBLIC; -- Security!
│   │
│   ├── Table Level:
│   │   ├── GRANT SELECT, INSERT ON sales.orders TO john;
│   │   ├── GRANT ALL ON sales.customers TO developers;
│   │   └── GRANT SELECT (id, name) ON customers TO readonly;  -- Column level!
│   │
│   ├── Sequence Level (for SERIAL/IDENTITY):
│   │   └── GRANT USAGE ON SEQUENCE orders_id_seq TO john;
│   │
│   ├── Function Level:
│   │   └── GRANT EXECUTE ON FUNCTION calculate_total() TO developers;
│   │
│   └── Default Privileges (vs SQL Server ALTER DEFAULT):
│       └── ALTER DEFAULT PRIVILEGES IN SCHEMA sales
│               GRANT SELECT ON TABLES TO readonly;
│
├── Row-Level Security (RLS)
│   ├── ENABLE: ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
│   ├── CREATE POLICY: Filter rows per user
│   │   └── CREATE POLICY emp_policy ON employees
│   │           FOR SELECT TO regular_users
│   │           USING (department = current_user);
│   │
│   ├── Policies: FOR SELECT, INSERT, UPDATE, DELETE, ALL
│   ├── USING: Which rows visible (SELECT, UPDATE, DELETE)
│   ├── WITH CHECK: Which rows can be added/modified (INSERT, UPDATE)
│   └── Bypass: BYPASSRLS role attribute or table owner
│
├── SSL/TLS Encryption
│   ├── Generate Certificates: openssl commands
│   ├── postgresql.conf:
│   │   ├── ssl = on
│   │   ├── ssl_cert_file = 'server.crt'
│   │   ├── ssl_key_file = 'server.key'
│   │   └── ssl_ca_file = 'root.crt' (for client verification)
│   │
│   ├── pg_hba.conf: hostssl (require SSL)
│   └── Client Connection: sslmode=require, sslmode=verify-full
│
├── Security Best Practices
│   ├── Never use 'trust' method in production
│   ├── Use scram-sha-256 authentication
│   ├── REVOKE ALL ON SCHEMA public FROM PUBLIC;
│   ├── Create application-specific schemas
│   ├── Disable postgres superuser remote login
│   ├── Enable SSL for all connections
│   ├── Audit with pgaudit extension
│   └── Regular role/permission reviews
│
└── Security Monitoring
    ├── pg_stat_activity: Active connections and queries
    ├── pg_stat_ssl: SSL connection info
    ├── Log failed authentication: log_connections, log_disconnections
    ├── pgaudit Extension: Detailed audit logging
    └── Fail2ban: Block brute force attempts

---

MODULE 4: BACKUP & RECOVERY STRATEGIES ══════════════════════════════════════
│
├── Backup Types (Different from SQL Server!)
│   ├── Logical Backups (pg_dump/pg_dumpall)
│   │   ├── Like SQL Server BACKUP DATABASE (but generates SQL/archive)
│   │   ├── Consistent snapshot, Database online during backup
│   │   ├── Cannot do point-in-time recovery alone
│   │   └── Slower for large databases
│   │
│   ├── Physical Backups (pg_basebackup)
│   │   ├── Like SQL Server native backup (file-level copy)
│   │   ├── Requires WAL archiving for PITR
│   │   ├── Faster for large databases
│   │   └── Foundation for replication and PITR
│   │
│   └── Continuous Archiving (WAL archiving)
│       ├── Like SQL Server transaction log backups
│       ├── Enables point-in-time recovery
│       └── Required for streaming replication
│
├── pg_dump (Logical Backup)
│   ├── Single Database:
│   │   ├── pg_dump -U postgres -d mydb -F c -f mydb.backup
│   │   │   └── -F c: Custom format (compressed, selective restore)
│   │   │
│   │   ├── pg_dump -U postgres -d mydb -F p -f mydb.sql
│   │   │   └── -F p: Plain SQL (portable, human-readable)
│   │   │
│   │   └── pg_dump -U postgres -d mydb -F d -j 4 -f mydb_dir/
│   │       └── -F d: Directory format (parallel dump)
│   │
│   ├── Schema Only: pg_dump -s (vs BACKUP DATABASE with COPY_ONLY)
│   ├── Data Only: pg_dump -a
│   ├── Specific Tables: pg_dump -t sales.orders -t sales.customers
│   ├── Specific Schema: pg_dump -n sales
│   ├── Exclude Tables: pg_dump -T audit_log
│   │
│   └── Best Practices:
│       ├── Use -F c (custom format) for flexibility
│       ├── Use -F d -j N for large databases (parallel)
│       └── Include --verbose for progress monitoring
│
├── pg_dumpall (All Databases + Globals)
│   ├── Dumps all databases plus roles and tablespaces
│   ├── pg_dumpall -U postgres -f all_databases.sql
│   ├── pg_dumpall --globals-only -f globals.sql (roles, tablespaces only)
│   └── Use Case: Cluster-wide backup, Migration scenarios
│
├── pg_restore (Logical Restore)
│   ├── Restore Custom Format:
│   │   └── pg_restore -U postgres -d mydb -F c mydb.backup
│   │
│   ├── Create Database and Restore:
│   │   ├── createdb -U postgres mydb
│   │   └── pg_restore -U postgres -d mydb mydb.backup
│   │
│   ├── Parallel Restore: pg_restore -j 4 -d mydb mydb.backup
│   ├── Selective Restore:
│   │   ├── List contents: pg_restore -l mydb.backup
│   │   ├── Restore specific table: pg_restore -t orders -d mydb mydb.backup
│   │   └── Restore specific schema: pg_restore -n sales -d mydb mydb.backup
│   │
│   └── From SQL Dump: psql -U postgres -d mydb -f mydb.sql
│
├── Physical Backup & PITR (Point-in-Time Recovery)
│   ├── WAL Archiving Setup (postgresql.conf):
│   │   ├── wal_level = replica
│   │   ├── archive_mode = on
│   │   ├── archive_command = 'test ! -f /archive/%f && cp %p /archive/%f'
│   │   │   └── %p = full path, %f = filename
│   │   │
│   │   ├── archive_timeout = 300 (force archive every 5 min)
│   │   └── Restart required after changing wal_level
│   │
│   ├── Base Backup (pg_basebackup):
│   │   ├── pg_basebackup -U replication -D /backup/base -P -R
│   │   │   ├── -U: Replication user
│   │   │   ├── -D: Destination directory
│   │   │   ├── -P: Progress reporting
│   │   │   └── -R: Create standby.signal and replication config
│   │   │
│   │   ├── Alternatively (manual):
│   │   │   ├── SELECT pg_start_backup('daily_backup');
│   │   │   ├── rsync -av $PGDATA/ /backup/base/
│   │   │   └── SELECT pg_stop_backup();
│   │   │
│   │   └── Schedule: Daily/weekly base backups
│   │
│   ├── Point-in-Time Recovery Process:
│   │   ├── 1. Stop PostgreSQL: systemctl stop postgresql
│   │   ├── 2. Clear data directory: rm -rf $PGDATA/*
│   │   ├── 3. Restore base backup: cp -r /backup/base/* $PGDATA/
│   │   ├── 4. Create recovery.signal: touch $PGDATA/recovery.signal
│   │   ├── 5. Configure recovery (postgresql.conf or postgresql.auto.conf):
│   │   │   ├── restore_command = 'cp /archive/%f %p'
│   │   │   ├── recovery_target_time = '2024-01-28 14:30:00'
│   │   │   └── recovery_target_action = 'promote'
│   │   │
│   │   ├── 6. Start PostgreSQL: systemctl start postgresql
│   │   ├── 7. Verify recovery: Check logs, Connect and test
│   │   └── 8. Remove recovery.signal (happens automatically on promotion)
│   │
│   └── Recovery Targets:
│       ├── recovery_target_time: '2024-01-28 14:30:00'
│       ├── recovery_target_xid: '123456' (transaction ID)
│       ├── recovery_target_name: 'before_bad_update' (restore point)
│       ├── recovery_target_lsn: '0/3000000' (LSN position)
│       └── recovery_target = 'immediate' (end of base backup)
│
├── Backup Automation Scripts
│   ```bash
│   #!/bin/bash
│   # daily_backup.sh
│   
│   BACKUP_DIR="/backup/postgresql"
│   DATE=$(date +%Y%m%d_%H%M%S)
│   PGUSER="postgres"
│   DATABASES="mydb production analytics"
│   
│   # Logical backups
│   for DB in $DATABASES; do
│       pg_dump -U $PGUSER -d $DB -F c -f "$BACKUP_DIR/${DB}_$DATE.backup"
│       
│       # Compress old backups
│       find $BACKUP_DIR -name "${DB}_*.backup" -mtime +7 -exec gzip {} \;
│       
│       # Delete old backups
│       find $BACKUP_DIR -name "${DB}_*.backup.gz" -mtime +30 -delete
│   done
│   
│   # Global objects
│   pg_dumpall -U $PGUSER --globals-only -f "$BACKUP_DIR/globals_$DATE.sql"
│   
│   # Weekly base backup (physical)
│   if [ $(date +%u) -eq 7 ]; then
│       pg_basebackup -U replication -D "$BACKUP_DIR/base_$DATE" -P -Ft -z
│   fi
│   ```
│
├── Backup Monitoring & Validation
│   ├── Test Restores: Regularly restore to test server
│   ├── Verify Backups: pg_restore -l (list contents)
│   ├── WAL Archive Monitoring:
│   │   └── SELECT * FROM pg_stat_archiver;
│   │
│   ├── Backup Age Check:
│   │   └── SELECT name, last_modified FROM backups ORDER BY last_modified DESC;
│   │
│   └── Automate Alerts: Failed backups, Missing WAL archives
│
└── Backup Best Practices
    ├── Use pg_basebackup + WAL archiving for PITR
    ├── Logical backups for schema-only, selective restores
    ├── Store backups on separate storage/server
    ├── Test recovery procedures quarterly
    ├── Document RPO/RTO requirements
    ├── Encrypt backups (pgBackRest, WAL-G support)
    └── Consider third-party tools: pgBackRest, Barman, WAL-G

---

MODULE 5: HIGH AVAILABILITY & REPLICATION ═══════════════════════════════════
│
├── Replication Types (vs SQL Server AG/Mirroring)
│   ├── Streaming Replication (Physical)
│   │   ├── Like SQL Server Availability Groups (but simpler)
│   │   ├── Byte-for-byte copy of entire cluster
│   │   ├── Standby can be read-only (Hot Standby)
│   │   └── Asynchronous or Synchronous
│   │
│   ├── Logical Replication
│   │   ├── Like SQL Server Transactional Replication
│   │   ├── Table-level replication
│   │   ├── Selective: Choose which tables to replicate
│   │   └── Bi-directional possible (with conflicts)
│   │
│   └── Cascading Replication: Standby → Standby chains
│
├── Streaming Replication Setup
│   ├── Primary Server Configuration (postgresql.conf):
│   │   ├── listen_addresses = '*'
│   │   ├── wal_level = replica
│   │   ├── max_wal_senders = 5
│   │   ├── wal_keep_size = 1GB (or use replication slots)
│   │   └── hot_standby = on (allow queries on standby)
│   │
│   ├── Create Replication User:
│   │   └── CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'secure_pass';
│   │
│   ├── pg_hba.conf on Primary:
│   │   └── host replication replicator standby_ip/32 scram-sha-256
│   │
│   ├── Standby Server Setup:
│   │   ├── Stop PostgreSQL on standby
│   │   ├── Remove data directory: rm -rf $PGDATA/*
│   │   ├── Base backup:
│   │   │   └── pg_basebackup -h primary_ip -U replicator \
│   │   │                      -D $PGDATA -P -R --wal-method=stream
│   │   │       └── -R: Creates standby.signal automatically
│   │   │
│   │   ├── Standby Configuration (postgresql.auto.conf):
│   │   │   └── primary_conninfo = 'host=primary_ip port=5432 user=replicator password=xxx'
│   │   │       (created by pg_basebackup -R)
│   │   │
│   │   └── Start standby: systemctl start postgresql
│   │
│   └── Synchronous Replication (optional):
│       ├── Primary: synchronous_standby_names = 'standby1'
│       └── Ensures zero data loss (like SQL Server sync AG)
│
├── Monitoring Replication
│   ├── On Primary:
│   │   ├── SELECT * FROM pg_stat_replication;
│   │   │   └── Shows connected standbys, lag, sync state
│   │   │
│   │   └── Check WAL sender processes: SELECT * FROM pg_stat_activity WHERE backend_type = 'walsender';
│   │
│   ├── On Standby:
│   │   ├── SELECT pg_is_in_recovery();  -- Should be 't' (true)
│   │   ├── SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();
│   │   └── Replication Lag:
│   │       └── SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp())) AS lag_seconds;
│   │
│   └── Key Metrics:
│       ├── write_lag, flush_lag, replay_lag (pg_stat_replication)
│       ├── sent_lsn vs replay_lsn (bytes behind)
│       └── sync_state: async, potential, sync, quorum
│
├── Failover Operations
│   ├── Manual Failover (Planned):
│   │   ├── 1. Stop writes on primary (application-level)
│   │   ├── 2. Verify standby caught up:
│   │   │   └── SELECT pg_last_wal_receive_lsn() = pg_last_wal_replay_lsn();
│   │   │
│   │   ├── 3. Promote standby:
│   │   │   └── pg_ctl promote -D $PGDATA
│   │   │       OR: SELECT pg_promote();
│   │   │
│   │   ├── 4. Verify promotion:
│   │   │   └── SELECT pg_is_in_recovery();  -- Should be 'f' (false)
│   │   │
│   │   └── 5. Reconfigure applications to new primary
│   │
│   ├── Automatic Failover:
│   │   ├── Use repmgr or Patroni (community tools)
│   │   ├── No built-in auto-failover (unlike SQL Server AG)
│   │   └── Patroni: HA solution with etcd/ZooKeeper/Consul
│   │
│   └── Switchback (Failback):
│       ├── Old primary becomes new standby
│       └── Use pg_rewind (if WAL available) or fresh pg_basebackup
│
├── Logical Replication (PostgreSQL 10+)
│   ├── Publisher Configuration:
│   │   ├── wal_level = logical
│   │   ├── CREATE PUBLICATION mypub FOR TABLE orders, customers;
│   │   └── CREATE PUBLICATION allpub FOR ALL TABLES;
│   │
│   ├── Subscriber Configuration:
│   │   ├── CREATE SUBSCRIPTION mysub
│   │   │       CONNECTION 'host=publisher dbname=mydb user=repuser password=xxx'
│   │   │       PUBLICATION mypub;
│   │   │
│   │   └── Tables must exist on subscriber (same schema)
│   │
│   ├── Monitoring:
│   │   ├── SELECT * FROM pg_stat_subscription;
│   │   ├── SELECT * FROM pg_publication_tables;
│   │   └── Lag: pg_stat_subscription.latest_end_lsn vs sent_lsn
│   │
│   └── Use Cases:
│       ├── Cross-version replication (14 → 15 upgrade)
│       ├── Selective table replication
│       ├── Data consolidation from multiple sources
│       └── Zero-downtime major version upgrades
│
├── Connection Pooling (CRITICAL for PostgreSQL!)
│   ├── Why Needed: Process-per-connection overhead
│   ├── PgBouncer (Recommended):
│   │   ├── Lightweight connection pooler
│   │   ├── Modes: session, transaction, statement pooling
│   │   ├── Install: apt install pgbouncer
│   │   ├── Config: /etc/pgbouncer/pgbouncer.ini
│   │   └── Usage: psql -h localhost -p 6432 (pgbouncer port)
│   │
│   ├── Pgpool-II:
│   │   ├── Connection pooling + load balancing
│   │   ├── Can distribute reads to standby servers
│   │   └── More complex than PgBouncer
│   │
│   └── Best Practice: Always use connection pooling in production
│
└── HA Best Practices
    ├── Use replication slots (prevent WAL deletion before replay)
    ├── Monitor replication lag (alert if >1 minute)
    ├── Test failover procedures quarterly
    ├── Use Patroni for automatic failover
    ├── Configure synchronous replication for zero data loss
    ├── Implement PgBouncer for connection pooling
    └── Document failover runbooks

---

## WEEK 3: PERFORMANCE TUNING & MONITORING

MODULE 6: QUERY PERFORMANCE & OPTIMIZATION ══════════════════════════════════
│
├── EXPLAIN & Query Plans (vs SQL Server Execution Plans)
│   ├── EXPLAIN SELECT * FROM orders WHERE customer_id = 123;
│   │   └── Shows estimated plan (like SQL Server estimated plan)
│   │
│   ├── EXPLAIN ANALYZE SELECT ...;
│   │   └── Executes query and shows actual plan (like SQL Server actual plan)
│   │
│   ├── EXPLAIN (ANALYZE, BUFFERS) SELECT ...;
│   │   └── Includes buffer usage (shared blocks read/hit)
│   │
│   ├── Plan Operators (Common):
│   │   ├── Seq Scan: Full table scan (like Table Scan)
│   │   ├── Index Scan: Use index to find rows (like Index Seek)
│   │   ├── Index Only Scan: Covering index (no heap access)
│   │   ├── Bitmap Index Scan: Combines multiple indexes
│   │   ├── Nested Loop: Join method (like Nested Loop Join)
│   │   ├── Hash Join: Build hash table, probe (like Hash Match)
│   │   ├── Merge Join: Pre-sorted inputs
│   │   └── Sort: Explicit sort operation
│   │
│   └── Reading Plans:
│       ├── cost=0.00..100.00: Startup cost..Total cost
│       ├── rows=1000: Estimated rows (cardinality)
│       ├── width=50: Average row width in bytes
│       ├── actual time=0.5..10.2: Actual startup..total time (ms)
│       └── buffers: shared hit=100 read=50 (cache hits vs disk reads)
│
├── Indexes (vs SQL Server Indexes)
│   ├── B-tree Index (default, like SQL Server nonclustered):
│   │   ├── CREATE INDEX idx_orders_customer ON orders(customer_id);
│   │   ├── Multicolumn: CREATE INDEX idx ON orders(customer_id, order_date);
│   │   ├── Unique: CREATE UNIQUE INDEX idx ON orders(order_id);
│   │   └── WHERE clause (filtered): CREATE INDEX idx ON orders(status) WHERE status = 'pending';
│   │
│   ├── Hash Index (for equality only):
│   │   └── CREATE INDEX idx_hash ON orders USING HASH (order_id);
│   │
│   ├── GiST Index (spatial, full-text):
│   │   └── CREATE INDEX idx_gist ON documents USING GIST (tsv_column);
│   │
│   ├── GIN Index (arrays, JSONB, full-text):
│   │   ├── CREATE INDEX idx_gin ON products USING GIN (tags);  -- array column
│   │   └── CREATE INDEX idx_jsonb ON orders USING GIN (metadata);  -- JSONB
│   │
│   ├── BRIN Index (large tables, sequential data):
│   │   └── CREATE INDEX idx_brin ON logs USING BRIN (timestamp);
│   │
│   └── Partial Index (filtered):
│       └── CREATE INDEX idx_active ON orders(customer_id) WHERE status = 'active';
│
├── Index Maintenance (Different from SQL Server!)
│   ├── No Fragmentation Concept: MVCC handles updates differently
│   ├── Bloat: Dead tuples in indexes (VACUUM cleanup)
│   ├── REINDEX:
│   │   ├── REINDEX INDEX idx_orders_customer;
│   │   ├── REINDEX TABLE orders;  -- All indexes on table
│   │   └── REINDEX DATABASE mydb;  -- All indexes in database
│   │
│   ├── CONCURRENTLY (online rebuild):
│   │   └── REINDEX INDEX CONCURRENTLY idx_orders_customer;
│   │       └── Does not lock table (like ONLINE in SQL Server)
│   │
│   └── When to REINDEX:
│       ├── After bulk data loads
│       ├── Significant bloat detected
│       └── Performance degradation
│
├── Statistics (vs SQL Server Statistics)
│   ├── Auto-Update: Enabled by default (autovacuum also updates stats)
│   ├── Manual Update:
│   │   ├── ANALYZE orders;  -- Single table
│   │   ├── ANALYZE;  -- All tables in database
│   │   └── VACUUM ANALYZE orders;  -- Cleanup + stats
│   │
│   ├── View Statistics:
│   │   ├── SELECT * FROM pg_stats WHERE tablename = 'orders';
│   │   └── Shows histogram, most common values, null fraction
│   │
│   ├── Statistics Target:
│   │   ├── ALTER TABLE orders ALTER COLUMN customer_id SET STATISTICS 1000;
│   │   │   └── Default 100, Increase for skewed data
│   │   │
│   │   └── SET default_statistics_target = 100;  -- Cluster-wide
│   │
│   └── Extended Statistics (PostgreSQL 10+):
│       └── CREATE STATISTICS s1 (dependencies) ON customer_id, order_date FROM orders;
│           └── For correlated columns
│
├── Query Optimization Techniques
│   ├── Avoid SELECT *: Specify only needed columns
│   ├── Use Indexes: WHERE, JOIN, ORDER BY columns
│   ├── Avoid Functions on Indexed Columns:
│   │   └── WHERE EXTRACT(YEAR FROM order_date) = 2024  -- Bad
│   │       vs WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01'  -- Good
│   │
│   ├── Use EXISTS vs IN:
│   │   └── WHERE EXISTS (SELECT 1 FROM ...)  -- Often faster than IN
│   │
│   ├── CTEs vs Subqueries:
│   │   ├── WITH (CTE) is optimization fence (pre-12)
│   │   └── PostgreSQL 12+: CTEs can be inlined automatically
│   │
│   ├── LIMIT Pushdown:
│   │   └── Use LIMIT when only need few rows
│   │
│   └── Avoid OFFSET for Pagination:
│       ├── Bad: SELECT * FROM orders OFFSET 1000000 LIMIT 10;  -- Still scans 1M rows!
│       └── Good: SELECT * FROM orders WHERE id > last_id LIMIT 10;  -- Keyset pagination
│
├── Parallel Query (PostgreSQL 9.6+)
│   ├── Configuration:
│   │   ├── max_parallel_workers_per_gather = 2 (default)
│   │   ├── max_parallel_workers = 8 (cluster-wide)
│   │   ├── min_parallel_table_scan_size = 8MB
│   │   └── parallel_tuple_cost, parallel_setup_cost (planner costs)
│   │
│   ├── When Used: Large table scans, Aggregations
│   ├── Force Parallel: SET max_parallel_workers_per_gather = 4;
│   ├── Disable Parallel: SET max_parallel_workers_per_gather = 0;
│   └── EXPLAIN shows: Gather, Parallel Seq Scan, etc.
│
├── Query Hints (Limited vs SQL Server)
│   ├── No Query Hints: PostgreSQL philosophy is "fix the planner"
│   ├── Workarounds:
│   │   ├── Set planner costs: SET random_page_cost = 1.1;
│   │   ├── Disable features: SET enable_seqscan = off;  -- Force index usage
│   │   ├── CTE Materialization: WITH ... AS MATERIALIZED (SELECT ...)
│   │   └── pg_hint_plan Extension: Third-party hint system
│   │
│   └── Planner Controls (per session):
│       ├── SET enable_seqscan = off;
│       ├── SET enable_indexscan = off;
│       ├── SET enable_nestloop = off;
│       └── SET enable_hashjoin = off;
│
└── Query Performance Monitoring
    ├── pg_stat_statements Extension (MUST INSTALL):
    │   ├── CREATE EXTENSION pg_stat_statements;
    │   ├── View: SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC;
    │   ├── Columns: query, calls, total_exec_time, mean_exec_time, rows
    │   └── Reset: SELECT pg_stat_statements_reset();
    │
    ├── Slow Query Log:
    │   ├── log_min_duration_statement = 1000  -- Log queries >1s
    │   ├── log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
    │   └── Analyze logs: pgBadger (log analyzer tool)
    │
    └── Active Queries:
        └── SELECT pid, usename, query_start, state, query
                FROM pg_stat_activity
                WHERE state = 'active' AND query NOT LIKE '%pg_stat_activity%';

---

MODULE 7: VACUUM, BLOAT & MAINTENANCE ═══════════════════════════════════════
│
├── Understanding VACUUM (Critical Difference from SQL Server!)
│   ├── Why Needed: MVCC creates dead tuples (old row versions)
│   ├── Dead Tuples: Updated/deleted rows not immediately removed
│   ├── VACUUM: Reclaims space, Updates statistics, Prevents XID wraparound
│   └── Not Like SQL Server: No auto-cleanup of old row versions
│
├── VACUUM Types
│   ├── VACUUM (Standard):
│   │   ├── Marks dead tuples as reusable
│   │   ├── Does NOT return space to OS
│   │   ├── Updates statistics (like ANALYZE)
│   │   └── Usage: VACUUM orders; or VACUUM;
│   │
│   ├── VACUUM FULL:
│   │   ├── Reclaims space and returns to OS
│   │   ├── Rewrites entire table (locks table - AVOID in production!)
│   │   ├── Rebuilds indexes
│   │   └── Usage: VACUUM FULL orders;  -- Use only during maintenance window
│   │
│   ├── VACUUM FREEZE:
│   │   ├── Prevents transaction ID wraparound
│   │   ├── Automatically happens at autovacuum_freeze_max_age
│   │   └── Critical for database health
│   │
│   └── VACUUM ANALYZE:
│       └── Combines VACUUM + statistics update
│
├── Autovacuum (Auto-Maintenance)
│   ├── Enabled by Default: autovacuum = on
│   ├── Configuration (postgresql.conf):
│   │   ├── autovacuum_max_workers = 3
│   │   ├── autovacuum_naptime = 60s  -- Check interval
│   │   ├── autovacuum_vacuum_threshold = 50  -- Min dead tuples
│   │   ├── autovacuum_vacuum_scale_factor = 0.2  -- 20% of table
│   │   │   └── Trigger: threshold + (scale_factor * tuples)
│   │   │
│   │   ├── autovacuum_analyze_threshold = 50
│   │   ├── autovacuum_analyze_scale_factor = 0.1
│   │   └── autovacuum_vacuum_cost_delay = 2ms  -- Throttle I/O
│   │
│   ├── Per-Table Tuning:
│   │   └── ALTER TABLE large_table SET (autovacuum_vacuum_scale_factor = 0.01);
│   │       └── Smaller scale for large tables (trigger more frequently)
│   │
│   └── Monitoring Autovacuum:
│       ├── SELECT * FROM pg_stat_progress_vacuum;  -- Currently running
│       ├── SELECT * FROM pg_stat_all_tables WHERE schemaname = 'public';
│       │   └── Columns: n_dead_tup, last_vacuum, last_autovacuum
│       │
│       └── pg_stat_activity: WHERE query LIKE '%autovacuum%'
│
├── Bloat Detection & Management
│   ├── Table Bloat:
│   │   ├── Caused by: Many UPDATEs/DELETEs, Infrequent VACUUM
│   │   ├── Detection Query:
│   │   │   └── SELECT schemaname, tablename, 
│   │   │              pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
│   │   │              pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS bloat
│   │   │       FROM pg_tables WHERE schemaname = 'public';
│   │   │
│   │   └── Fix: VACUUM FULL (locks table) or pg_repack extension (online)
│   │
│   ├── Index Bloat:
│   │   ├── Detection: pgstattuple extension
│   │   │   └── SELECT * FROM pgstatindex('idx_orders_customer');
│   │   │
│   │   └── Fix: REINDEX or REINDEX CONCURRENTLY
│   │
│   └── Preventing Bloat:
│       ├── Tune autovacuum aggressively for high-churn tables
│       ├── Increase autovacuum_max_workers
│       ├── Partition large tables
│       └── Consider pg_repack for bloated tables
│
├── Transaction ID Wraparound Protection
│   ├── Problem: 32-bit transaction IDs wrap around at 2 billion
│   ├── VACUUM FREEZE: Marks old rows as "frozen" (permanent)
│   ├── Monitoring:
│   │   └── SELECT datname, age(datfrozenxid), 
│   │              datfrozenxid 
│   │       FROM pg_database
│   │       ORDER BY age(datfrozenxid) DESC;
│   │       └── Alert if age > 1.5 billion
│   │
│   ├── Configuration:
│   │   ├── autovacuum_freeze_max_age = 200000000 (200M transactions)
│   │   ├── vacuum_freeze_table_age = 150000000
│   │   └── Autovacuum forces FREEZE before wraparound
│   │
│   └── Emergency: Immediate VACUUM FREEZE if age close to 2B
│
├── Routine Maintenance Tasks
│   ├── Daily:
│   │   ├── Check autovacuum activity
│   │   ├── Monitor bloat on high-churn tables
│   │   └── Review slow query log
│   │
│   ├── Weekly:
│   │   ├── ANALYZE on critical tables
│   │   ├── Check transaction ID age
│   │   └── Review index usage (drop unused)
│   │
│   ├── Monthly:
│   │   ├── REINDEX high-bloat indexes
│   │   ├── pg_repack bloated tables (if needed)
│   │   └── Review autovacuum settings
│   │
│   └── Quarterly:
│       ├── Full database ANALYZE
│       ├── Review and drop unused indexes
│       └── Capacity planning review
│
└── Maintenance Tools & Extensions
    ├── pg_repack: Online table/index rebuild (no locks)
    ├── pgstattuple: Bloat detection
    ├── pg_stat_statements: Query performance tracking
    ├── pg_cron: Schedule jobs inside PostgreSQL
    └── pgBadger: Log analysis and reporting

---

MODULE 8: MONITORING & TROUBLESHOOTING ══════════════════════════════════════
│
├── System Catalogs & Statistics Views
│   ├── pg_stat_activity: Active connections (like sp_who2)
│   │   └── SELECT pid, usename, application_name, state, query, wait_event
│   │       FROM pg_stat_activity WHERE state != 'idle';
│   │
│   ├── pg_stat_database: Database-level stats
│   │   └── Columns: numbackends, xact_commit, xact_rollback, blks_read, blks_hit
│   │
│   ├── pg_stat_all_tables: Table access statistics
│   │   └── Columns: seq_scan, seq_tup_read, idx_scan, n_tup_ins, n_tup_upd, n_tup_del, n_dead_tup
│   │
│   ├── pg_stat_all_indexes: Index usage
│   │   └── Columns: idx_scan, idx_tup_read, idx_tup_fetch
│   │
│   ├── pg_statio_all_tables: I/O statistics
│   │   └── Columns: heap_blks_read, heap_blks_hit, idx_blks_read, idx_blks_hit
│   │
│   └── pg_stat_bgwriter: Background writer stats
│
├── Performance Monitoring Queries
│   ├── Cache Hit Ratio:
│   │   └── SELECT sum(blks_hit) * 100.0 / sum(blks_hit + blks_read) AS cache_hit_ratio
│   │       FROM pg_stat_database;
│   │       └── Target: >99% (like SQL Server Buffer Cache Hit Ratio)
│   │
│   ├── Index Usage:
│   │   └── SELECT schemaname, tablename, indexname, idx_scan
│   │       FROM pg_stat_user_indexes
│   │       WHERE idx_scan = 0
│   │       ORDER BY pg_relation_size(indexrelid) DESC;
│   │       └── Find unused indexes
│   │
│   ├── Table Bloat:
│   │   └── SELECT schemaname, tablename, n_dead_tup, n_live_tup,
│   │              round(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_ratio
│   │       FROM pg_stat_user_tables
│   │       WHERE n_dead_tup > 1000
│   │       ORDER BY n_dead_tup DESC;
│   │
│   ├── Long-Running Queries:
│   │   └── SELECT pid, now() - query_start AS duration, query
│   │       FROM pg_stat_activity
│   │       WHERE state = 'active' AND (now() - query_start) > interval '5 minutes'
│   │       ORDER BY duration DESC;
│   │
│   └── Database Size:
│       └── SELECT datname, pg_size_pretty(pg_database_size(datname))
│           FROM pg_database
│           ORDER BY pg_database_size(datname) DESC;
│
├── Locking & Blocking (vs SQL Server)
│   ├── View Locks:
│   │   └── SELECT locktype, database, relation::regclass, mode, granted, pid
│   │       FROM pg_locks
│   │       WHERE NOT granted;  -- Blocked queries
│   │
│   ├── Blocking Queries:
│   │   └── SELECT blocked_locks.pid AS blocked_pid,
│   │              blocked_activity.usename AS blocked_user,
│   │              blocking_locks.pid AS blocking_pid,
│   │              blocking_activity.usename AS blocking_user,
│   │              blocked_activity.query AS blocked_statement,
│   │              blocking_activity.query AS current_statement_in_blocking_process
│   │       FROM pg_catalog.pg_locks blocked_locks
│   │       JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
│   │       JOIN pg_catalog.pg_locks blocking_locks 
│   │           ON blocking_locks.locktype = blocked_locks.locktype
│   │           AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
│   │           AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
│   │           AND blocking_locks.pid != blocked_locks.pid
│   │       JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
│   │       WHERE NOT blocked_locks.granted;
│   │
│   ├── Kill Query/Connection:
│   │   ├── pg_cancel_backend(pid): Cancel query only
│   │   └── pg_terminate_backend(pid): Kill connection (like KILL SPID)
│   │
│   └── Lock Modes:
│       ├── AccessShareLock (SELECT)
│       ├── RowShareLock (SELECT FOR UPDATE)
│       ├── RowExclusiveLock (UPDATE, DELETE, INSERT)
│       ├── ShareUpdateExclusiveLock (VACUUM, ANALYZE, CREATE INDEX CONCURRENTLY)
│       └── AccessExclusiveLock (DROP TABLE, TRUNCATE, VACUUM FULL, LOCK TABLE)
│
├── Wait Events (PostgreSQL 9.6+)
│   ├── View Wait Events:
│   │   └── SELECT wait_event_type, wait_event, count(*)
│   │       FROM pg_stat_activity
│   │       WHERE wait_event IS NOT NULL
│   │       GROUP BY wait_event_type, wait_event
│   │       ORDER BY count(*) DESC;
│   │
│   ├── Common Wait Events:
│   │   ├── Client: ClientRead (waiting for client)
│   │   ├── IO: DataFileRead, WALWrite
│   │   ├── Lock: relation, tuple, transactionid
│   │   ├── LWLock: BufferMapping, WALInsert
│   │   └── IPC: BgWorkerShutdown, ReplicationSlotSync
│   │
│   └── Like SQL Server Wait Stats, but per-session only
│
├── Logging Configuration
│   ├── postgresql.conf Logging Settings:
│   │   ├── logging_collector = on
│   │   ├── log_directory = 'pg_log'
│   │   ├── log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
│   │   ├── log_rotation_age = 1d
│   │   ├── log_rotation_size = 100MB
│   │   ├── log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
│   │   ├── log_min_duration_statement = 1000  -- Log slow queries (ms)
│   │   ├── log_checkpoints = on
│   │   ├── log_connections = on
│   │   ├── log_disconnections = on
│   │   ├── log_lock_waits = on
│   │   ├── deadlock_timeout = 1s
│   │   └── log_statement = 'ddl'  -- or 'all', 'mod', 'none'
│   │
│   └── Log Analysis: pgBadger (generates HTML reports)
│
├── Connection Monitoring
│   ├── Active Connections:
│   │   └── SELECT count(*) FROM pg_stat_activity;
│   │
│   ├── Connection Limit Check:
│   │   └── SELECT count(*), max_conn, max_conn - count(*) AS remaining
│   │       FROM pg_stat_activity, (SELECT setting::int AS max_conn FROM pg_settings WHERE name='max_connections') mc
│   │       GROUP BY max_conn;
│   │
│   └── Idle Connections:
│       └── SELECT count(*) FROM pg_stat_activity WHERE state = 'idle';
│           └── Consider pg_terminate_backend if too many
│
├── Disk Space Monitoring
│   ├── Database Sizes:
│   │   └── SELECT datname, pg_size_pretty(pg_database_size(datname))
│   │       FROM pg_database
│   │       ORDER BY pg_database_size(datname) DESC;
│   │
│   ├── Table Sizes:
│   │   └── SELECT schemaname, tablename,
│   │              pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
│   │              pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
│   │              pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS indexes_size
│   │       FROM pg_tables
│   │       WHERE schemaname = 'public'
│   │       ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
│   │       LIMIT 20;
│   │
│   └── WAL Directory Size:
│       └── SELECT pg_size_pretty(sum(size)) FROM pg_ls_waldir();
│
└── Troubleshooting Common Issues
    ├── High CPU:
    │   ├── Find expensive queries: pg_stat_statements ORDER BY total_exec_time
    │   ├── Check parallel workers: max_parallel_workers_per_gather
    │   └── Review vacuum/autovacuum activity
    │
    ├── High I/O:
    │   ├── Check cache hit ratio: Should be >99%
    │   ├── Missing indexes: pg_stat_user_tables (seq_scan high)
    │   ├── Bloat: Run VACUUM, check dead tuples
    │   └── Increase shared_buffers if RAM available
    │
    ├── Connection Exhaustion:
    │   ├── Implement PgBouncer (connection pooling)
    │   ├── Increase max_connections (with caution)
    │   ├── Kill idle connections
    │   └── Fix application connection leaks
    │
    └── Slow Queries:
        ├── EXPLAIN ANALYZE: Understand query plan
        ├── Missing indexes: Check seq_scan counts
        ├── Outdated statistics: Run ANALYZE
        ├── Bloat: VACUUM or REINDEX
        └── Configuration: Increase work_mem for sorts/hashes

---

## WEEK 4: ADVANCED TOPICS & INTERVIEW PREPARATION

MODULE 9: ADVANCED POSTGRESQL FEATURES ══════════════════════════════════════
│
├── JSONB (vs SQL Server JSON)
│   ├── JSON vs JSONB:
│   │   ├── JSON: Text storage, Slower
│   │   └── JSONB: Binary storage, Faster, Indexable (RECOMMENDED)
│   │
│   ├── JSONB Operations:
│   │   ├── Store: INSERT INTO products (data) VALUES ('{"name":"Widget","price":19.99}'::jsonb);
│   │   ├── Query: SELECT data->>'name' FROM products WHERE data->>'price' = '19.99';
│   │   ├── Containment: WHERE data @> '{"category":"electronics"}';
│   │   ├── Path Extraction: data#>'{address,city}'
│   │   └── Array Elements: data->'tags'->0
│   │
│   └── JSONB Indexing:
│       ├── GIN Index: CREATE INDEX idx_data ON products USING GIN (data);
│       └── Expression Index: CREATE INDEX idx_price ON products ((data->>'price'));
│
├── Full-Text Search
│   ├── tsvector and tsquery:
│   │   ├── CREATE INDEX idx_fts ON documents USING GIN (to_tsvector('english', content));
│   │   └── SELECT * FROM documents WHERE to_tsvector('english', content) @@ to_tsquery('postgresql & performance');
│   │
│   ├── Generated Columns (PostgreSQL 12+):
│   │   └── ALTER TABLE documents ADD COLUMN tsv tsvector GENERATED ALWAYS AS (to_tsvector('english', content)) STORED;
│   │       CREATE INDEX idx_fts ON documents USING GIN (tsv);
│   │
│   └── Ranking: ts_rank, ts_rank_cd
│
├── Partitioning (vs SQL Server Partitioning)
│   ├── Declarative Partitioning (PostgreSQL 10+):
│   │   ├── CREATE TABLE orders (
│   │   │       order_id SERIAL,
│   │   │       order_date DATE NOT NULL,
│   │   │       ...
│   │   │   ) PARTITION BY RANGE (order_date);
│   │   │
│   │   ├── Create Partitions:
│   │   │   ├── CREATE TABLE orders_2023 PARTITION OF orders
│   │   │   │       FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
│   │   │   │
│   │   │   └── CREATE TABLE orders_2024 PARTITION OF orders
│   │   │           FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
│   │   │
│   │   └── Partition Types: RANGE, LIST, HASH
│   │
│   ├── Partition Pruning: Automatically skips irrelevant partitions
│   ├── Attach/Detach: ALTER TABLE orders ATTACH/DETACH PARTITION orders_2023;
│   └── Benefits: Faster queries, Easier archival, Parallel execution
│
├── Foreign Data Wrappers (FDW) (vs SQL Server Linked Servers)
│   ├── Connect to External Data Sources
│   ├── Postgres FDW (connect to other PostgreSQL):
│   │   ├── CREATE EXTENSION postgres_fdw;
│   │   ├── CREATE SERVER remote_pg FOREIGN DATA WRAPPER postgres_fdw
│   │   │       OPTIONS (host 'remote_host', dbname 'remote_db', port '5432');
│   │   │
│   │   ├── CREATE USER MAPPING FOR myuser SERVER remote_pg
│   │   │       OPTIONS (user 'remote_user', password 'remote_pass');
│   │   │
│   │   └── IMPORT FOREIGN SCHEMA public FROM SERVER remote_pg INTO local_schema;
│   │
│   ├── Other FDWs: MySQL, Oracle, SQL Server (tds_fdw), MongoDB, CSV, etc.
│   └── Use Cases: Cross-database queries, Data federation, Migration
│
├── Extensions (Powerful Ecosystem!)
│   ├── Install Extension: CREATE EXTENSION extension_name;
│   ├── Essential Extensions:
│   │   ├── pg_stat_statements: Query performance tracking
│   │   ├── pgcrypto: Cryptographic functions
│   │   ├── uuid-ossp: UUID generation
│   │   ├── pg_trgm: Fuzzy text matching (trigrams)
│   │   ├── hstore: Key-value store in column
│   │   ├── PostGIS: Geospatial data
│   │   ├── pg_cron: Job scheduling
│   │   └── timescaledb: Time-series data
│   │
│   └── List Extensions: \dx or SELECT * FROM pg_available_extensions;
│
├── Stored Procedures & Functions
│   ├── PL/pgSQL (vs T-SQL):
│   │   ```sql
│   │   CREATE OR REPLACE FUNCTION calculate_total(p_order_id INT)
│   │   RETURNS NUMERIC AS $$
│   │   DECLARE
│   │       v_total NUMERIC;
│   │   BEGIN
│   │       SELECT SUM(quantity * price) INTO v_total
│   │       FROM order_items
│   │       WHERE order_id = p_order_id;
│   │       
│   │       RETURN COALESCE(v_total, 0);
│   │   END;
│   │   $$ LANGUAGE plpgsql;
│   │   ```
│   │
│   ├── Differences from T-SQL:
│   │   ├── DECLARE section separate from BEGIN
│   │   ├── := for assignment (or =)
│   │   ├── RAISE for errors (vs RAISERROR)
│   │   ├── No OUTPUT parameters (use OUT or INOUT)
│   │   └── RETURNS TABLE for table functions
│   │
│   └── Other Languages: PL/Python, PL/Perl, PL/Java, PL/V8 (JavaScript)
│
├── Triggers (vs SQL Server Triggers)
│   ├── Create Trigger Function:
│   │   ```sql
│   │   CREATE OR REPLACE FUNCTION audit_trigger()
│   │   RETURNS TRIGGER AS $$
│   │   BEGIN
│   │       INSERT INTO audit_log (table_name, action, old_data, new_data, changed_at)
│   │       VALUES (TG_TABLE_NAME, TG_OP, row_to_json(OLD), row_to_json(NEW), now());
│   │       
│   │       RETURN NEW;
│   │   END;
│   │   $$ LANGUAGE plpgsql;
│   │   ```
│   │
│   ├── Create Trigger:
│   │   └── CREATE TRIGGER audit_orders_trigger
│   │       AFTER INSERT OR UPDATE OR DELETE ON orders
│   │       FOR EACH ROW EXECUTE FUNCTION audit_trigger();
│   │
│   ├── Trigger Timing: BEFORE, AFTER, INSTEAD OF
│   ├── Trigger Level: FOR EACH ROW, FOR EACH STATEMENT
│   └── Special Variables: NEW, OLD, TG_OP, TG_TABLE_NAME, TG_WHEN
│
└── Materialized Views
    ├── CREATE MATERIALIZED VIEW sales_summary AS
    │       SELECT product_id, SUM(quantity) AS total_qty, SUM(revenue) AS total_revenue
    │       FROM sales
    │       GROUP BY product_id;
    │
    ├── Refresh: REFRESH MATERIALIZED VIEW sales_summary;
    ├── CONCURRENTLY: REFRESH MATERIALIZED VIEW CONCURRENTLY sales_summary;
    │   └── Requires UNIQUE INDEX on materialized view
    │
    └── Use Cases: Expensive aggregations, Dashboard queries, Reporting

---

MODULE 10: MIGRATION FROM SQL SERVER & INTERVIEW PREP ═══════════════════════
│
├── SQL Server to PostgreSQL Migration Strategy
│   ├── Assessment Phase:
│   │   ├── Inventory: Databases, tables, indexes, stored procedures, jobs
│   │   ├── Dependencies: Applications, ETL, reports, linked servers
│   │   ├── Data Types: Map SQL Server types to PostgreSQL
│   │   ├── T-SQL Code: Identify incompatible syntax
│   │   └── Features: Identify SQL Server-specific features
│   │
│   ├── Schema Migration:
│   │   ├── Tools: ora2pg (works for SQL Server too), pgloader
│   │   ├── Manual: DDL script conversion
│   │   ├── IDENTITY → SERIAL or GENERATED ALWAYS AS IDENTITY
│   │   ├── NVARCHAR → VARCHAR (PostgreSQL is UTF-8 by default)
│   │   └── Constraints, Indexes, Foreign Keys
│   │
│   ├── Data Migration:
│   │   ├── pgloader: Direct SQL Server → PostgreSQL migration
│   │   ├── bcp + COPY: Export from SQL Server, Import to PostgreSQL
│   │   ├── ETL Tools: Pentaho, Talend, SSIS (with PostgreSQL connector)
│   │   └── Logical Replication: For minimal downtime (complex)
│   │
│   ├── Code Migration (T-SQL → PL/pgSQL):
│   │   ├── Stored Procedures: Rewrite syntax
│   │   ├── Functions: RETURNS TABLE vs Table-Valued Functions
│   │   ├── Triggers: Different structure, Trigger functions separate
│   │   └── Cursors: Prefer set-based, or use PL/pgSQL cursors
│   │
│   ├── Application Changes:
│   │   ├── Connection Strings: Change provider/driver
│   │   ├── SQL Syntax: TOP → LIMIT, GETDATE() → NOW(), etc.
│   │   ├── Error Handling: Different error codes
│   │   └── Testing: Comprehensive regression testing
│   │
│   └── Post-Migration:
│       ├── Performance Tuning: Indexes, statistics, configuration
│       ├── Monitoring Setup: pg_stat_statements, logging
│       ├── Backup Strategy: pg_basebackup, WAL archiving
│       └── Training: DBA and developer training on PostgreSQL
│
├── Common T-SQL to PostgreSQL Syntax Differences
│   ```sql
│   -- SQL Server                       PostgreSQL
│   ─────────────────────────────────────────────────────────────
│   SELECT TOP 10 *                     SELECT * FROM orders LIMIT 10;
│   FROM orders;
│   
│   SELECT GETDATE();                   SELECT NOW() or CURRENT_TIMESTAMP;
│   
│   IF EXISTS (SELECT 1 FROM ...)      IF EXISTS (SELECT 1 FROM ...) THEN
│       BEGIN ... END                      ... 
│                                        END IF;
│   
│   SET @var = value                    var := value  or  var = value
│   
│   IDENTITY(1,1)                       SERIAL or GENERATED ALWAYS AS IDENTITY
│   
│   ISNULL(col, 0)                      COALESCE(col, 0)
│   
│   LEN(str)                            LENGTH(str)  or  CHAR_LENGTH(str)
│   
│   CHARINDEX('sub', str)               POSITION('sub' IN str)  or  STRPOS(str, 'sub')
│   
│   STUFF(str, start, len, new)         OVERLAY(str PLACING new FROM start FOR len)
│   
│   DATEADD(day, 7, date)               date + INTERVAL '7 days'
│   
│   DATEDIFF(day, start, end)           (end::date - start::date)
│   
│   CAST(value AS type)                 CAST(value AS type)  or  value::type
│   
│   NEWID()                              gen_random_uuid()  (pgcrypto extension)
│   
│   @@ROWCOUNT                           GET DIAGNOSTICS var = ROW_COUNT;
│   
│   @@ERROR                              (use EXCEPTION handling instead)
│   
│   GO                                   (use ; between statements, psql: \g)
│   
│   USE database;                        \c database  (psql) or reconnect
│   ```
│
├── Interview Preparation Topics
│   ├── Architecture Questions:
│   │   ├── Explain PostgreSQL process model vs SQL Server threading
│   │   ├── What is MVCC and how does it differ from SQL Server?
│   │   ├── Describe PostgreSQL storage structure
│   │   ├── Explain WAL (Write-Ahead Logging)
│   │   └── What are the key differences between PostgreSQL and SQL Server?
│   │
│   ├── Administration Questions:
│   │   ├── How do you configure PostgreSQL after installation?
│   │   ├── Explain pg_hba.conf and authentication methods
│   │   ├── How do you monitor active connections?
│   │   ├── What is the purpose of VACUUM?
│   │   ├── How do you handle transaction ID wraparound?
│   │   └── Describe backup strategies in PostgreSQL
│   │
│   ├── Performance Questions:
│   │   ├── How do you identify slow queries?
│   │   ├── Explain EXPLAIN ANALYZE output
│   │   ├── What is the purpose of shared_buffers?
│   │   ├── How do you detect and fix bloat?
│   │   ├── When would you use different index types (B-tree, GIN, GIST)?
│   │   └── How does connection pooling work? (PgBouncer)
│   │
│   ├── Security Questions:
│   │   ├── How do roles differ from SQL Server logins/users?
│   │   ├── Explain Row-Level Security
│   │   ├── How do you configure SSL connections?
│   │   ├── What are the different authentication methods?
│   │   └── How do you audit database activity?
│   │
│   ├── Backup & Recovery Questions:
│   │   ├── Difference between pg_dump and pg_basebackup?
│   │   ├── How do you perform point-in-time recovery?
│   │   ├── Explain WAL archiving
│   │   ├── How do you verify backup integrity?
│   │   └── What is the difference between VACUUM and VACUUM FULL?
│   │
│   └── High Availability Questions:
│       ├── How does streaming replication work?
│       ├── Synchronous vs asynchronous replication?
│       ├── How do you monitor replication lag?
│       ├── Explain failover procedures
│       └── What is Patroni and when would you use it?
│
├── Hands-On Practice Scenarios
│   ├── Week 1-2:
│   │   ├── Install PostgreSQL on Linux
│   │   ├── Configure postgresql.conf and pg_hba.conf
│   │   ├── Create databases, schemas, tables
│   │   ├── Create roles with various permissions
│   │   ├── Practice pg_dump and pg_restore
│   │   └── Setup WAL archiving and perform PITR
│   │
│   ├── Week 3:
│   │   ├── Setup streaming replication (primary + standby)
│   │   ├── Monitor replication with pg_stat_replication
│   │   ├── Install and configure PgBouncer
│   │   ├── Use EXPLAIN ANALYZE on sample queries
│   │   ├── Create indexes (B-tree, GIN for JSONB)
│   │   └── Monitor with pg_stat_statements
│   │
│   └── Week 4:
│       ├── Practice VACUUM, ANALYZE, REINDEX
│       ├── Detect and fix bloat
│       ├── Write PL/pgSQL functions and triggers
│       ├── Create partitioned tables
│       ├── Setup pg_cron for scheduled jobs
│       └── Perform complete backup and restore drill
│
├── Common Pitfalls & Gotchas
│   ├── Case Sensitivity: Unquoted identifiers are lowercase (vs SQL Server insensitive)
│   ├── search_path: Different from SQL Server default schema
│   ├── No Cross-Database Queries: Use schemas or FDW instead
│   ├── VACUUM Required: Not automatic like SQL Server
│   ├── Connection Overhead: Always use pooling (PgBouncer)
│   ├── Transaction ID Wraparound: Monitor and prevent
│   ├── Autovacuum Tuning: Critical for write-heavy workloads
│   └── No SQL Agent: Use pg_cron or external schedulers
│
└── Resources for Continued Learning
    ├── Official Documentation: https://www.postgresql.org/docs/
    ├── PostgreSQL Wiki: https://wiki.postgresql.org/
    ├── Books:
    │   ├── "PostgreSQL: Up and Running" (O'Reilly)
    │   ├── "The Art of PostgreSQL" (Dimitri Fontaine)
    │   └── "PostgreSQL 14 Administration Cookbook"
    │
    ├── Communities:
    │   ├── Reddit: r/PostgreSQL
    │   ├── Stack Overflow: postgresql tag
    │   ├── PostgreSQL Slack/Discord
    │   └── pgsql-general mailing list
    │
    └── Tools to Master:
        ├── psql: Command-line client
        ├── pgAdmin 4: GUI administration
        ├── DBeaver: Universal database tool
        ├── PgBouncer: Connection pooling
        ├── pgBackRest/Barman: Backup management
        └── Patroni: HA automation

---

## APPENDIX: QUICK REFERENCE GUIDES

SQL SERVER TO POSTGRESQL COMMAND MAPPING ═══════════════════════════════════
```
SQL Server Command                 PostgreSQL Equivalent
────────────────────────────────────────────────────────────────────────
sp_who / sp_who2                   SELECT * FROM pg_stat_activity;

sp_databases                       \l  or  SELECT datname FROM pg_database;

sp_tables                          \dt  or  SELECT * FROM pg_tables;

sp_help tablename                  \d tablename

sp_helptext procname               \df+ procname

sp_helpindex tablename             \di  or  SELECT * FROM pg_indexes WHERE tablename='orders';

sp_spaceused                       SELECT pg_size_pretty(pg_database_size('dbname'));

sp_lock                            SELECT * FROM pg_locks;

sp_configure                       SHOW all;  or  SELECT * FROM pg_settings;

DBCC CHECKDB                       (Rarely needed, PostgreSQL very stable)

BACKUP DATABASE                    pg_dump or pg_basebackup

RESTORE DATABASE                   pg_restore or restore $PGDATA

KILL SPID                          SELECT pg_terminate_backend(pid);

USE database                       \c database

CREATE LOGIN                       CREATE ROLE ... WITH LOGIN PASSWORD '...';

CREATE USER                        (Same as CREATE ROLE in PostgreSQL)

GRANT serverrole TO login          GRANT role TO user;  (roles unified)

sys.dm_exec_query_stats            pg_stat_statements

sys.dm_os_wait_stats               pg_stat_activity (wait_event column)

sys.databases                      pg_database

sys.tables                         pg_tables, information_schema.tables

sys.indexes                        pg_indexes, pg_stat_user_indexes

PRINT                              RAISE NOTICE (in functions)

BEGIN TRANSACTION                  BEGIN;  or  START TRANSACTION;

COMMIT                             COMMIT;

ROLLBACK                           ROLLBACK;

SAVE TRANSACTION savepoint         SAVEPOINT savepoint_name;

SET NOCOUNT ON                     (Not needed in PostgreSQL)

@@IDENTITY                         RETURNING clause or currval('sequence_name')

SCOPE_IDENTITY()                   RETURNING id  or  lastval()

RAISERROR                          RAISE EXCEPTION

TRY...CATCH                        BEGIN ... EXCEPTION WHEN ... THEN ... END;
```

KEY CONFIGURATION PARAMETERS ═══════════════════════════════════════════════
```
Parameter                          Recommended Value                   Notes
────────────────────────────────────────────────────────────────────────────
max_connections                    100-400                            Use PgBouncer for more

shared_buffers                     25% of RAM (max 8-16GB)            Start conservative

effective_cache_size               50-75% of RAM                      Planner hint only

work_mem                           4MB (default) to 64MB              Per operation, multiply by connections!

maintenance_work_mem               256MB to 2GB                       For VACUUM, CREATE INDEX

wal_level                          replica                            For replication/PITR

max_wal_senders                    5-10                               For replication

checkpoint_completion_target       0.9                                Spread checkpoint I/O

random_page_cost                   1.1 (SSD), 4.0 (HDD)               Planner cost

effective_io_concurrency           200 (SSD), 2 (HDD)                 Parallel I/O

autovacuum                         on                                 Always enabled!

log_min_duration_statement         1000 (1 second)                    Log slow queries

log_line_prefix                    '%t [%p]: user=%u,db=%d,app=%a '   Structured logging
```

---

## END OF 1-MONTH POSTGRESQL SYLLABUS FOR SQL SERVER DBAs

**Next Steps After Completing This Syllabus:**
1. Complete all hands-on exercises in each module
2. Set up a practice environment (PostgreSQL + PgBouncer + pgAdmin)
3. Migrate a small SQL Server database to PostgreSQL
4. Take practice interviews using the interview prep questions
5. Contribute to PostgreSQL community forums (solidifies knowledge)
6. Consider PostgreSQL certification (if available in your region)
7. Build a portfolio project showcasing PostgreSQL skills

**Job-Ready Checklist:**
- [ ] Can install and configure PostgreSQL from scratch
- [ ] Understand MVCC and how it differs from SQL Server
- [ ] Can setup and monitor streaming replication
- [ ] Know how to backup and perform PITR
- [ ] Comfortable with psql and pgAdmin
- [ ] Can write PL/pgSQL functions
- [ ] Understand VACUUM and bloat management
- [ ] Can troubleshoot performance issues
- [ ] Know how to secure PostgreSQL (roles, SSL, pg_hba.conf)
- [ ] Familiar with key extensions (pg_stat_statements, etc.)

Good luck with your PostgreSQL journey! 🐘