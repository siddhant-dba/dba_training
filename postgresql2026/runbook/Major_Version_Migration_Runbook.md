# PostgreSQL 17 to PostgreSQL 18 Migration Runbook

**Version:** 1.0  
**Date:** 2026-06-08  
**Environment Scope:** HA Clusters & Standalone Servers  
**Target Outcome:** Minimum Downtime, Zero Data Loss, Verified Rollback Path  

---

## Table of Contents

1. [Overview & Scope](#overview--scope)
2. [Pre-Migration Phase (Discovery & Validation)](#pre-migration-phase-discovery--validation)
3. [HA Cluster Migration Runbook](#ha-cluster-migration-runbook)
4. [Standalone Server Migration Runbook](#standalone-server-migration-runbook)
5. [Multi-Wave Execution for Standalone Fleet](#multi-wave-execution-for-standalone-fleet)
6. [Rollback Procedures](#rollback-procedures)
7. [Post-Migration Validation](#post-migration-validation)
8. [Communication & Escalation](#communication--escalation)

---

## Overview & Scope

### Migration Objective

Upgrade PostgreSQL 17 production environments to PostgreSQL 18 with:
- **Minimum downtime:** 5-30 minutes depending on method
- **Zero data loss:** Enforced through backup validation and replication checks
- **Verified rollback path:** All procedures tested in non-production before production execution
- **Comprehensive validation:** Pre- and post-migration checklist enforcement

### Environments in Scope

| Environment Type | Count | Method | Expected Downtime |
|------------------|-------|--------|-------------------|
| HA Clusters (Primary + Standby) | Multiple | Blue-Green + Logical Replication | 5-15 minutes |
| Standalone Servers | 10+ | pg_upgrade --link | 15-30 minutes |

### Document Usage

This runbook is organized in two parallel tracks:
- **HA Cluster Track:** Sections 3-5 address HA cluster migration
- **Standalone Track:** Sections 4-5 address standalone server migration
- **Common Sections:** 2, 6, 7, 8 apply to both tracks

---

## Pre-Migration Phase (Discovery & Validation)

### Duration: 5-10 Business Days

This phase must be completed entirely before any production migration window is scheduled.

### Checkpoint: Discovery & Pre-Migration (Sign-off Required)

**Responsible Party:** Database Architect or Senior DBA  
**Sign-off Authority:** Database Operations Lead

Before proceeding to any production work, all items below must be confirmed:

#### Inventory Completion

- [ ] PostgreSQL version and minor version documented for every instance
- [ ] Operating system version and distribution documented for every instance
- [ ] Kernel version and glibc version confirmed for every instance
- [ ] Hardware specifications recorded (CPU, RAM, storage type, disk space used)
- [ ] All tablespace locations identified and documented
- [ ] Connection pooler software and versions identified (PgBouncer, Pgpool-II, etc.)
- [ ] pgBackRest version and stanza configuration documented
- [ ] For HA clusters: streaming replication configuration documented including slot names and synchronous settings

#### Extension Compatibility Validation

For every extension currently installed:

- [ ] Extension name and current version recorded
- [ ] PostgreSQL 18 compatible version confirmed to exist in intended package repository
- [ ] Compatibility verified in non-production PostgreSQL 18 test environment
- [ ] Any custom C functions or language handlers documented and tested
- [ ] Critical extensions tested: PostGIS, pg_partman, pgvector, pg_stat_statements, others as applicable

**Blocking Issue:** If any extension lacks a PostgreSQL 18 compatible package, that environment is blocked from migration until the package is available. Document the blocker and exclude from wave planning.

#### Application Dependency Assessment

- [ ] All application database drivers identified and versions documented
- [ ] Driver vendor confirmed to support PostgreSQL 18 without behavior changes
- [ ] Connection string configuration method identified (hostname, virtual IP, DNS alias, load balancer)
- [ ] Peak transaction periods and blackout windows documented
- [ ] Long-running transaction or batch job patterns documented
- [ ] Application team lead identified and contact information confirmed

#### Performance Baseline Collection

Collect baseline metrics from the production PostgreSQL 17 environment under normal operating conditions:

- [ ] Top 20 queries by execution time and call frequency documented
- [ ] Index usage statistics for major tables recorded
- [ ] Table bloat estimates calculated
- [ ] Autovacuum activity and lag patterns documented
- [ ] Checkpoint frequency and duration patterns documented
- [ ] Connection count patterns and peak counts recorded
- [ ] Wait event statistics collected for busy periods
- [ ] Slow query patterns identified

**Deliverable:** Baseline metrics saved to shared location accessible to migration team.

#### Backup Validation

For every environment in scope:

- [ ] Full pgBackRest backup taken and backup log verified for completion without errors
- [ ] Backup verified restored to non-production server successfully
- [ ] Restored database confirmed accessible and queryable
- [ ] Row counts in restored database match production source
- [ ] pgBackRest version confirmed compatible with PostgreSQL 18 via vendor documentation
- [ ] Backup repository storage capacity confirmed sufficient for retention of pre- and post-upgrade backups
- [ ] Backup completion time and restore time documented for rollback planning

**Critical Requirement:** A backup that has not been tested for restore validity is not considered a valid backup.

#### Operating System & Infrastructure Validation

- [ ] Kernel parameters (shared memory, open files, etc.) reviewed for PostgreSQL 18 compatibility
- [ ] Locale settings documented and consistency confirmed across cluster members if applicable
- [ ] Disk free space confirmed sufficient for PostgreSQL 18 binary installation alongside PostgreSQL 17
- [ ] For pg_upgrade non-link approach: disk free space confirmed sufficient for database copy (100% of data directory size)
- [ ] For blue-green HA: target servers confirmed available with equivalent or superior hardware

#### Replication Validation (HA Clusters Only)

- [ ] Streaming replication health confirmed via `SELECT * FROM pg_stat_replication`
- [ ] Replication lag measurement under production load documented
- [ ] No replication slots confirmed held by disconnected or stuck processes
- [ ] Synchronous standby configuration, if in use, documented and verified
- [ ] Monitoring thresholds for replication lag documented

#### Monitoring & Alerting Readiness

- [ ] Prometheus scrape configuration or equivalent monitoring confirmed working on PostgreSQL 17
- [ ] postgres_exporter or equivalent confirmed compatible with PostgreSQL 18
- [ ] Alerting rules reviewed for PostgreSQL 18 compatibility
- [ ] Grafana dashboards reviewed for PostgreSQL 18 compatibility
- [ ] New PostgreSQL 18 hosts pre-configured in monitoring agent if applicable

#### Security & Access Review

- [ ] pg_hba.conf entries reviewed for PostgreSQL 18 compatibility
- [ ] SSL certificate and postgresql.conf SSL parameters reviewed
- [ ] Role definitions and privilege configuration reviewed
- [ ] Row-level security policies (if in use) reviewed for PostgreSQL 18 compatibility
- [ ] For HA clusters: replication role credentials confirmed available

#### PostgreSQL 18 Non-Production Environment Build

- [ ] PostgreSQL 18 installed on non-production test environment
- [ ] PostgreSQL 18 version confirmed matching intended production deployment
- [ ] All extensions installed and tested on non-production PostgreSQL 18
- [ ] Dump and restore from PostgreSQL 17 test database completed successfully on PostgreSQL 18
- [ ] Non-production environment baseline performance baseline collected for comparison

#### UAT Coordination

- [ ] Application teams briefed on migration approach and timeline
- [ ] UAT schedule coordinated with application teams
- [ ] UAT test cases defined by application teams
- [ ] UAT environment confirmed ready for PostgreSQL 18 testing
- [ ] Application team lead assigned as go/no-go decision authority

### Sign-Off Document

**Prepared By:** [Name], [Title]  
**Date:** [Date]  
**Reviewed By:** [Name], [Title]  
**Approved By:** [Name], [Title]  

All items above confirmed complete:

```
Signature: ________________________     Date: __________

```

---

## HA Cluster Migration Runbook

### Migration Method: Blue-Green Deployment with Logical Replication

**Expected Total Duration:** 3-7 days (zero downtime until cutover)  
**Cutover Window Downtime:** 5-15 minutes  
**Rollback Window:** 24-72 hours

### High-Level Architecture

```
BEFORE MIGRATION:

Applications → PG17 Primary ⟷ PG17 Standby
                     ↓
                pgBackRest

DURING MIGRATION:

Applications → PG17 Primary ⟷ PG17 Standby
                     │ (Logical Replication)
                     ↓
                PG18 Primary ⟷ PG18 Standby
                     ↓
                pgBackRest

AFTER CUTOVER:

Applications → PG18 Primary ⟷ PG18 Standby
                     ↓
                pgBackRest

PG17 Primary ⟷ PG17 Standby (Standby - for rollback)
```

### Phase 1: Build New PostgreSQL 18 HA Cluster

**Duration:** 2-4 hours  
**Downtime:** None  

#### Step 1.1: Provision New Cluster Servers

- [ ] Two new servers allocated matching or exceeding existing hardware specs
- [ ] Server hostnames documented: `pg18-pri01` and `pg18-std01` (or per naming convention)
- [ ] Server IP addresses documented
- [ ] Network connectivity between new servers confirmed
- [ ] Network connectivity to pgBackRest repository confirmed
- [ ] NTP synchronization confirmed on both servers
- [ ] SSH key-based access confirmed for DBA team

#### Step 1.2: Install PostgreSQL 18 Binaries

On both `pg18-pri01` and `pg18-std01`:

- [ ] PostgreSQL 18 binaries installed from official repository or validated source
- [ ] PostgreSQL 18 version confirmed: `psql --version` returns PostgreSQL 18.x
- [ ] PostgreSQL 18 system libraries confirmed installed
- [ ] pgBackRest version matching PostgreSQL 18 requirement installed
- [ ] All required extensions available in PostgreSQL 18 package repository

#### Step 1.3: Initialize PostgreSQL 18 Primary

On `pg18-pri01`:

- [ ] `postgres` operating system user created with appropriate UID/GID
- [ ] Data directory created with appropriate permissions (700)
- [ ] Tablespace directories created to match existing PG17 topology
- [ ] `initdb` executed to initialize PostgreSQL 18 cluster
- [ ] PostgreSQL 18 configuration file (`postgresql.conf`) created based on PG17 template
- [ ] Replication configuration added: `max_wal_senders`, `wal_keep_segments`, `hot_standby = on`
- [ ] pgBackRest stanza configuration created for PG18 primary
- [ ] PostgreSQL 18 service started successfully
- [ ] `SELECT version();` confirms PostgreSQL 18.x running

#### Step 1.4: Initialize PostgreSQL 18 Standby

On `pg18-std01`:

- [ ] `postgres` operating system user created with appropriate UID/GID
- [ ] Data directory created with appropriate permissions
- [ ] PostgreSQL 18 binary installation confirmed
- [ ] Do not initialize cluster yet—standby will be built from primary backup

#### Step 1.5: Create Base Backup from PG18 Primary

On `pg18-pri01`:

- [ ] Create replication slot for standby: `SELECT * FROM pg_create_physical_replication_slot('pg18_standby_slot');`
- [ ] Create base backup: `pg_basebackup -D /path/to/standby_backup -R -S pg18_standby_slot`
- [ ] Backup completion confirmed in logs
- [ ] `backup_label` file present in backup directory

#### Step 1.6: Transfer Base Backup to Standby

- [ ] Backup transferred to `pg18-std01` via secure method (scp, rsync, etc.)
- [ ] Backup file integrity verified via checksum comparison if applicable
- [ ] Backup placed in standby data directory

#### Step 1.7: Start PostgreSQL 18 Standby

On `pg18-std01`:

- [ ] PostgreSQL 18 service started
- [ ] Standby begins receiving WAL from primary
- [ ] Standby status confirmed via `SELECT * FROM pg_stat_replication` on primary
- [ ] Replication lag confirmed near zero: `SELECT now() - pg_last_xact_replay_time();`

#### Step 1.8: Configure pgBackRest for PG18 Cluster

- [ ] pgBackRest stanza configuration created for new PG18 cluster
- [ ] Stanza references new primary and standby hostnames
- [ ] Backup repository storage location confirmed
- [ ] `pgbackrest info` command confirms stanza connectivity
- [ ] Configuration backed up to version control or documented location

**Checkpoint 1: New PG18 HA Cluster Ready**

Confirm the following before proceeding:

- [ ] PG18 Primary and Standby both running PostgreSQL 18
- [ ] Streaming replication active and lag near zero
- [ ] pgBackRest stanza functional
- [ ] All extensions installed and accessible on PG18

---

### Phase 2: Configure Logical Replication

**Duration:** 30 minutes to 2 hours  
**Downtime:** None  

#### Step 2.1: Create Publication on PostgreSQL 17 Primary

On `pg17-pri01`:

- [ ] Create publication to replicate all tables:
  ```
  CREATE PUBLICATION pg17_to_pg18 FOR ALL TABLES;
  ```

- [ ] Verify publication:
  ```
  SELECT * FROM pg_publication;
  SELECT * FROM pg_publication_tables;
  ```

- [ ] Create replication slot for logical replication:
  ```
  SELECT * FROM pg_create_logical_replication_slot(
    'pg17_to_pg18_slot', 'pgoutput'
  );
  ```

- [ ] Verify slot created:
  ```
  SELECT * FROM pg_replication_slots WHERE slot_name = 'pg17_to_pg18_slot';
  ```

#### Step 2.2: Prepare PostgreSQL 18 Primary for Subscription

On `pg18-pri01`:

- [ ] Create schema objects and structure manually or via pg_dump schema-only:
  ```
  pg_dump -s -h pg17-pri01 dbname > schema.sql
  psql -h pg18-pri01 -d dbname -f schema.sql
  ```

- [ ] Verify all schemas, tables, and indexes present on PG18:
  ```
  SELECT count(*) FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog', 'information_schema');
  ```

- [ ] Note: Do not populate with data yet—subscription will do this

- [ ] Verify publication from PG17 is accessible from PG18:
  ```
  -- From PG18, test connection to PG17:
  SELECT * FROM dblink_connect('pg17_conn', 'host=pg17-pri01 user=replication password=xxx dbname=dbname');
  ```

#### Step 2.3: Create Subscription on PostgreSQL 18 Primary

On `pg18-pri01`:

- [ ] Create subscription to replicate data from PG17:
  ```
  CREATE SUBSCRIPTION pg17_to_pg18_sub
    CONNECTION 'host=pg17-pri01 user=replication password=xxx dbname=dbname'
    PUBLICATION pg17_to_pg18
    WITH (create_slot = false, slot_name = 'pg17_to_pg18_slot', copy_data = true);
  ```

- [ ] Initial data copy begins automatically
- [ ] Monitor copy progress via `SELECT * FROM pg_subscription_rel;`

#### Step 2.4: Monitor Initial Data Synchronization

**Expected Duration:**
- 100 GB database: 30 minutes to 2 hours
- 500 GB database: 2 to 8 hours
- 1 TB database: 4 to 15 hours
- 5 TB+: Several hours to days

On `pg18-pri01`, monitor progress:

- [ ] Query subscription status frequently:
  ```
  SELECT srsubid, srrelid, srsubstate FROM pg_subscription_rel;
  -- States: i=initializing, d=data copy in progress, s=synchronized, r=ready
  ```

- [ ] Monitor PG17 replication slot to ensure it is not held back:
  ```
  SELECT slot_name, restart_lsn, confirmed_flush_lsn FROM pg_replication_slots WHERE slot_name = 'pg17_to_pg18_slot';
  ```

- [ ] Monitor PG18 subscription lag:
  ```
  SELECT now() - pg_last_xact_replay_time();
  ```

- [ ] Once `srsubstate` shows 's' (synchronized) for all tables, initial copy is complete

#### Step 2.5: Verify Data Completeness

Once synchronization completes:

On both PG17 and PG18:

- [ ] Count rows in each major table and compare:
  ```
  SELECT schemaname, tablename, n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC LIMIT 10;
  ```

- [ ] Verify row counts match between PG17 and PG18 for all major tables
- [ ] Compare checksums or row counts for critical tables
- [ ] Document any discrepancies

**Checkpoint 2: Logical Replication Synchronized**

Confirm before proceeding:

- [ ] All tables in subscription showing state 's' or 'r' (synchronized/ready)
- [ ] Row counts match between PG17 and PG18
- [ ] Subscription slot exists and is healthy on PG17
- [ ] Replication lag on PG18 near zero and stable

---

### Phase 3: Validation & Testing

**Duration:** 1-2 business days  
**Downtime:** None  

#### Step 3.1: Extension Validation

On `pg18-pri01`:

- [ ] For each extension, verify it is installed:
  ```
  SELECT * FROM pg_extension WHERE extname = 'extension_name';
  ```

- [ ] Test extension functionality by executing a representative query or function
- [ ] Document results for each extension

#### Step 3.2: Application Smoke Test

- [ ] Coordinate with application team to run functional smoke tests against PG18
- [ ] Application team tests against `pg18-pri01` read-only initially
- [ ] Document test results and any issues found
- [ ] Issues are categorized as blockers or non-blockers

#### Step 3.3: Backup Validation

On `pg18-pri01`:

- [ ] Trigger pgBackRest full backup:
  ```
  pgbackrest backup
  ```

- [ ] Monitor backup progress and completion
- [ ] Verify backup completed without errors:
  ```
  pgbackrest info
  ```

- [ ] Test restore of backup to separate location (if time permits)

#### Step 3.4: Performance Baseline Collection

- [ ] Run production workload queries against `pg18-pri01`
- [ ] Collect execution time and plan output
- [ ] Compare against PG17 baseline
- [ ] Identify any query regressions
- [ ] Document results

#### Step 3.5: UAT Sign-Off

- [ ] Application team completes UAT against PG18
- [ ] UAT test results documented
- [ ] Application team lead provides written sign-off: "PG18 environment acceptable for production cutover"
- [ ] Any identified issues documented with severity and remediation plan

**Checkpoint 3: Validation Complete**

Confirm before proceeding:

- [ ] All extensions verified and functional
- [ ] Application smoke tests passed
- [ ] pgBackRest backup successful and verified
- [ ] Performance regression analysis completed
- [ ] UAT signed off by application team lead
- [ ] No blocking issues outstanding

---

### Phase 4: Cutover Preparation

**Duration:** 2-4 hours before cutover window  
**Downtime:** None  

#### Step 4.1: Assemble On-Call Team

- [ ] DBA team lead: [Name], [Phone], [Email]
- [ ] Database Architect: [Name], [Phone], [Email]
- [ ] Application Team Lead: [Name], [Phone], [Email]
- [ ] Infrastructure/Network Support: [Name], [Phone], [Email]
- [ ] Rollback Decision Authority (named individual): [Name], [Phone], [Email]

#### Step 4.2: Confirm Cutover Window

- [ ] Cutover start time confirmed: [Date/Time]
- [ ] Cutover end time estimated: [Date/Time] + 30 minutes
- [ ] Maintenance window approved in change management system
- [ ] Stakeholders notified of maintenance window
- [ ] All team members confirmed available during cutover window

#### Step 4.3: Final Replication Lag Check

On `pg18-pri01`:

- [ ] Check replication lag on PG18 standby:
  ```
  SELECT now() - pg_last_xact_replay_time();
  ```

- [ ] Lag must be less than 1 second. If not, investigate and resolve before cutover.
- [ ] Confirm subscription status all tables synchronized:
  ```
  SELECT * FROM pg_subscription_rel;
  ```

#### Step 4.4: Pre-Cutover Dry Run

1. Simulate application quiesce (notify application teams to prepare):
   - [ ] Application teams notified to prepare for controlled shutdown
   - [ ] Batch jobs stopped
   - [ ] Long-running transactions monitored

2. Monitor PG17 for remaining writes:
   - [ ] Run on `pg17-pri01`:
     ```
     SELECT count(*) FROM pg_stat_statements WHERE query NOT LIKE '%pg_stat_statements%' ORDER BY rows DESC LIMIT 5;
     ```
   - [ ] Confirm no active transactions beyond monitoring queries

3. Check PG18 replication lag again:
   - [ ] Lag must be near-zero
   - [ ] If lag > 5 seconds, do not proceed—investigate

4. Confirm sequence synchronization plan documented:
   - [ ] List all sequences:
     ```
     SELECT * FROM information_schema.sequences;
     ```
   - [ ] For each sequence, plan to manually sync values before cutover

#### Step 4.5: Monitoring Dashboards & Alerts

- [ ] Grafana or monitoring dashboard active and visible on team console
- [ ] Critical alerts configured and tested
- [ ] Team briefed on alert escalation procedures
- [ ] On-call rotation updated to include new hostnames

**Checkpoint 4: Cutover Ready**

Confirm:

- [ ] All team members present and briefed
- [ ] Cutover start time confirmed with stakeholders
- [ ] Replication lag verified < 1 second
- [ ] Sequence synchronization plan documented
- [ ] Monitoring dashboards active
- [ ] Rollback decision authority confirmed on standby

---

### Phase 5: Cutover Execution

**Duration: 5-15 minutes downtime**

#### Step 5.1: T-0 Minutes - Start Cutover Window

- [ ] Cutover start time logged in team chat or shared document
- [ ] All team members confirm ready
- [ ] Stakeholder notification sent: "Maintenance window starting now"

#### Step 5.2: T+1 Minute - Quiesce Application Writes

On application servers or via load balancer:

- [ ] Stop application writes to PostgreSQL 17
- [ ] Method depends on application architecture:
  - For connection pooler: drain connection pool, close new connections
  - For load balancer: remove PG17 from pool
  - For application: stop accepting writes

- [ ] Monitor PG17 for remaining connections:
  ```
  SELECT count(*) FROM pg_stat_activity WHERE state != 'idle';
  ```

- [ ] Wait until only idle connections remain (max 3 minutes)

#### Step 5.3: T+4 Minutes - Verify Replication Lag = Zero

On `pg18-pri01`:

- [ ] Check replication lag on logical subscription:
  ```
  SELECT now() - pg_last_xact_replay_time();
  ```

- [ ] Lag must be 0 (or < 1 second). If not, stop and investigate.
- [ ] Confirm subscription synchronized:
  ```
  SELECT * FROM pg_subscription_rel WHERE srsubstate != 's' AND srsubstate != 'r';
  ```

- [ ] No rows returned. If rows returned, subscription not ready—investigate.

#### Step 5.4: T+7 Minutes - Synchronize Sequences

On `pg18-pri01`:

Sequences are not replicated by logical replication. Manual synchronization required.

For each sequence identified in pre-cutover planning:

```
-- On PG17, check current sequence value:
SELECT last_value, is_called FROM sequence_name;

-- On PG18, set sequence to same value:
SELECT setval('sequence_name', last_value, is_called);
```

- [ ] Execute for each critical sequence
- [ ] Document sequence sync completion

#### Step 5.5: T+10 Minutes - Final Validation

On `pg18-pri01`:

- [ ] Verify database is accessible:
  ```
  SELECT count(*) FROM pg_class;
  ```

- [ ] Check replication status:
  ```
  SELECT * FROM pg_stat_replication;
  ```

- [ ] Verify standby is receiving WAL:
  ```
  SELECT slot_name, restart_lsn FROM pg_replication_slots;
  ```

- [ ] Run critical application query that was part of baseline:
  ```
  SELECT count(*) FROM critical_application_table;
  ```

#### Step 5.6: T+12 Minutes - Redirect Application Traffic

Update application connection strings or load balancer:

- [ ] If using hostname: update DNS or `/etc/hosts` to point to `pg18-pri01`
- [ ] If using virtual IP: update IP address mapping
- [ ] If using load balancer: remove `pg17-pri01`, add `pg18-pri01`
- [ ] If using application config: update connection strings and restart application

- [ ] Monitor for connection errors (should be none or minimal)
- [ ] Confirm first queries execute successfully on PG18

#### Step 5.7: T+15 Minutes - Post-Cutover Status

- [ ] Log cutover completion time
- [ ] Notify stakeholders: "Migration cutover completed successfully"
- [ ] Team reviews logs for any errors or warnings
- [ ] No rollback decision made—proceed to validation phase

**Checkpoint 5: Cutover Complete**

Record:

- [ ] Actual cutover start time: _______________
- [ ] Actual cutover end time: _______________
- [ ] Total downtime: _______________
- [ ] Any issues encountered: _______________
- [ ] Team sign-off: _______________

---

### Phase 6: Post-Cutover Validation

**Duration:** 30 minutes to 1 hour  
**Downtime:** None (application now on PG18)

#### Step 6.1: Functional Validation

- [ ] Application reports no connectivity errors
- [ ] Critical business queries execute successfully
- [ ] Application team confirms basic functionality working:
  - [ ] User login/authentication
  - [ ] Data retrieval for top 5 use cases
  - [ ] Data modification capability
  - [ ] Reporting functionality

#### Step 6.2: Replication Validation

On `pg18-pri01`:

- [ ] Check replication status:
  ```
  SELECT * FROM pg_stat_replication;
  ```

- [ ] Standby WAL receiver active and healthy
- [ ] No replication slot lag:
  ```
  SELECT slot_name, restart_lsn, confirmed_flush_lsn, write_lag, flush_lag, replay_lag FROM pg_replication_slots;
  ```

#### Step 6.3: Extension Validation

- [ ] For each extension, verify still installed and functional:
  ```
  SELECT * FROM pg_extension;
  ```

- [ ] Test extension-specific functionality if applicable

#### Step 6.4: Backup Validation

On `pg18-pri01`:

- [ ] Trigger pgBackRest backup immediately:
  ```
  pgbackrest backup
  ```

- [ ] Backup completes successfully:
  ```
  pgbackrest info
  ```

- [ ] First backup of PG18 environment successful—this is critical first recovery point

#### Step 6.5: Performance Validation

- [ ] Compare performance metrics against baseline collected pre-migration
- [ ] Key metrics to compare:
  - Top 10 query execution times
  - Wait events (should be similar distribution)
  - Checkpoint frequency
  - Connection count
  - Cache hit ratio

- [ ] Any metric deviating > 20% from baseline should be investigated
- [ ] Document any regressions found

#### Step 6.6: Monitoring Validation

- [ ] All alerts firing correctly on PG18
- [ ] Prometheus scraping all metrics
- [ ] Grafana dashboards displaying data
- [ ] On-call team confirmed using new hostnames in rotation

#### Step 6.7: Application Sign-Off

- [ ] Application team lead confirms acceptance: "PG18 environment performing acceptably"
- [ ] Sign-off documented with timestamp
- [ ] Any identified post-migration issues logged as separate tickets

**Checkpoint 6: Post-Cutover Validation Complete**

- [ ] All validation items passed
- [ ] No blocking issues
- [ ] Application team sign-off obtained
- [ ] Rollback window begins (24-72 hours)

---

### Phase 7: Rollback Window Management

**Duration:** 24-72 hours post-cutover  
**Action:** Maintain PG17 cluster in standby state for rapid rollback if needed

#### Step 7.1: During Rollback Window (24-72 hours)

- [ ] PG17 cluster remains running but not serving production traffic
- [ ] PG17 primary and standby retained with data intact
- [ ] Team monitors PG18 production for any issues
- [ ] Any critical issues trigger rollback decision by rollback authority
- [ ] Team on high alert for first 4-8 hours post-cutover

#### Step 7.2: Rollback Decision Criteria

Rollback is initiated if any of the following occur:

- [ ] Data corruption detected on PG18
- [ ] Critical query plan regression causing significant performance degradation
- [ ] Application-level functionality broken and cannot be resolved within 30 minutes
- [ ] Unrecoverable replication failure on PG18 cluster
- [ ] Security issue or authentication failure affecting multiple users

**If any of the above occur:**

1. Rollback decision authority makes go/no-go decision
2. Execution team initiates rollback procedure (see Section 6)
3. Application redirected back to PG17
4. Post-rollback investigation begins

#### Step 7.3: Closing Rollback Window

After 72 hours with no issues:

- [ ] Rollback decision authority declares rollback window closed
- [ ] PG17 cluster scheduled for decommissioning
- [ ] pgBackRest backup retention policy adjusted to remove PG17 backups
- [ ] PG17 credentials and access removed
- [ ] Documentation updated with completed migration record

---

### Phase 8: Post-Migration Cleanup

**Duration:** 1-2 business days after rollback window closes

#### Step 8.1: Decommission PG17 Cluster

- [ ] Final backup of PG17 taken and retained for archival
- [ ] PostgreSQL 17 service stopped on both primary and standby
- [ ] PostgreSQL 17 data directory backed up to archival storage (if required by policy)
- [ ] PostgreSQL 17 binaries removed
- [ ] PostgreSQL 17 system user removed

#### Step 8.2: Clean Up Logical Replication

- [ ] Drop subscription on PG18:
  ```
  DROP SUBSCRIPTION pg17_to_pg18_sub;
  ```

- [ ] Drop publication on PG17 (if PG17 still accessible):
  ```
  DROP PUBLICATION pg17_to_pg18;
  ```

- [ ] Drop replication slots on PG17 (if still running):
  ```
  SELECT pg_drop_replication_slot('pg17_to_pg18_slot');
  ```

#### Step 8.3: pgBackRest Maintenance

- [ ] Update pgBackRest retention policy to keep only PG18 backups
- [ ] Delete old PG17 backups:
  ```
  pgbackrest expire --repo-retention-full=3 --repo-retention-diff=7
  ```

- [ ] Verify backup policy now only references PG18

#### Step 8.4: Documentation Update

- [ ] Update runbooks to reference PG18 as current version
- [ ] Archive PG17-specific documentation with migration record
- [ ] Update operational procedures manuals
- [ ] Update disaster recovery documentation with new cluster details
- [ ] Update capacity planning and hardware baseline documentation

#### Step 8.5: Team Debrief

Schedule post-migration team debrief:

- [ ] Discuss what went well
- [ ] Discuss what could be improved
- [ ] Document lessons learned
- [ ] Update procedures for future migrations
- [ ] Recognize team contributions

---

## Standalone Server Migration Runbook

### Migration Method: pg_upgrade with --link Option

**Expected Total Duration:** 1-2 business days (including preparation, backup, upgrade)  
**Upgrade Window Downtime:** 15-30 minutes  
**Rollback Window:** 24-72 hours (via pgBackRest restore if needed)

### High-Level Architecture

```
BEFORE MIGRATION:

Applications → PostgreSQL 17 (pg17-standalone01)
                    ↓
              pgBackRest Repository

DURING UPGRADE (15-30 min downtime):

Applications
     X
     │
PostgreSQL 17 → STOPPED
                 │
                 pg_upgrade --link
                 │
PostgreSQL 18 → STARTED
                 │
              Validation (5-15 mins)
                 │
Applications → PostgreSQL 18 (pg17-standalone01)
                    ↓
              pgBackRest Repository
```

### Prerequisites Checklist (From Discovery Phase)

Before scheduling any standalone server migration:

- [ ] Pre-migration checklist from Discovery Phase completed and signed off
- [ ] PostgreSQL 18 binaries prepared and version confirmed
- [ ] All extensions confirmed compatible with PostgreSQL 18
- [ ] Performance baseline collected from PG17 environment
- [ ] pgBackRest version confirmed compatible with PostgreSQL 18
- [ ] Application team briefed and on standby for post-migration validation
- [ ] Maintenance window approved and communicated
- [ ] Rollback decision authority identified

---

### Phase 1: Pre-Upgrade Preparation

**Duration:** 2-8 hours (can run during business hours before scheduled window)  
**Downtime:** None

#### Step 1.1: Install PostgreSQL 18 Binaries

On standalone server:

- [ ] PostgreSQL 18 binaries downloaded from official repository or validated source
- [ ] Binaries installed to standard location (e.g., `/usr/lib/postgresql/18`)
- [ ] PostgreSQL 18 version confirmed:
  ```
  /usr/lib/postgresql/18/bin/postgres --version
  ```

- [ ] PostgreSQL 17 binaries remain in place (e.g., `/usr/lib/postgresql/17`)
- [ ] Both versions can coexist without conflict

#### Step 1.2: Install Required Extensions for PostgreSQL 18

- [ ] For each extension installed on PG17, install PostgreSQL 18 compatible version:
  ```
  apt-get install postgresql-18-extension-name  # Debian/Ubuntu
  yum install postgresql18-extension-name        # RHEL/CentOS
  ```

- [ ] Verify each extension installed:
  ```
  /usr/lib/postgresql/18/bin/pg_config --sharedir
  ls /usr/share/postgresql/18/extension/
  ```

#### Step 1.3: Prepare pgBackRest Configuration

- [ ] Review current pgBackRest configuration (usually `/etc/pgbackrest.conf`)
- [ ] Prepare updated stanza configuration that references PostgreSQL 18 paths
- [ ] Note current settings (backup repository, retention policy, etc.)
- [ ] Configuration will be updated post-upgrade

#### Step 1.4: Create Pre-Upgrade Backup

**Timing:** Schedule this immediately before the upgrade window opens (last 1-2 hours of business)

- [ ] Stop any batch jobs or long-running maintenance
- [ ] Trigger pgBackRest full backup:
  ```
  pgbackrest backup
  ```

- [ ] Monitor backup progress:
  ```
  pgbackrest info
  ```

- [ ] Verify backup completed successfully without errors
- [ ] Document backup completion time and size
- [ ] **Critical:** Do not proceed with upgrade until backup is verified complete

#### Step 1.5: Coordinate with Application Teams

- [ ] Application team lead confirmed available for post-upgrade validation
- [ ] Notify application team of exact maintenance window (start and estimated end time)
- [ ] Confirm application is in a state where it can be gracefully shut down (no critical batch jobs running)

**Checkpoint 1: Pre-Upgrade Preparation Complete**

- [ ] PostgreSQL 18 binaries installed and verified
- [ ] All extensions installed for PostgreSQL 18
- [ ] pgBackRest pre-upgrade full backup completed and verified
- [ ] Application team ready
- [ ] Maintenance window about to begin

---

### Phase 2: Upgrade Window Execution

**Duration: 15-30 minutes downtime**

#### Step 2.1: T-0 Minutes - Window Start

- [ ] Log upgrade window start time
- [ ] Notify stakeholders: "Maintenance window starting - PostgreSQL upgrade in progress"
- [ ] All team members confirmed present and ready
- [ ] Monitoring dashboards active (no traffic expected during downtime)

#### Step 2.2: T+1 Minute - Stop Application Writes

- [ ] Application teams notified to stop writing to database
- [ ] Method depends on application architecture:
  - For PgBouncer: drain pool, close new connections
  - For application: gracefully shut down write requests
  - For load balancer: remove from pool if applicable

- [ ] Monitor remaining connections to ensure they drain:
  ```
  sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity WHERE state != 'idle';"
  ```

- [ ] Wait for active connections to complete or time out (max 3 minutes)

#### Step 2.3: T+4 Minutes - Stop PostgreSQL 17

- [ ] Stop PostgreSQL 17 service:
  ```
  sudo systemctl stop postgresql@17-main  # or service postgresql-17 stop
  ```

- [ ] Verify PostgreSQL 17 stopped:
  ```
  ps aux | grep postgres
  ```

- [ ] Should see no `postgres:` processes running

#### Step 2.4: T+5 Minutes - Run pg_upgrade Check

Before performing the actual upgrade, validate that pg_upgrade can succeed:

- [ ] Change to postgres user:
  ```
  sudo -u postgres bash
  ```

- [ ] Run pg_upgrade --check:
  ```
  /usr/lib/postgresql/18/bin/pg_upgrade \
    --old-bindir /usr/lib/postgresql/17/bin \
    --new-bindir /usr/lib/postgresql/18/bin \
    --old-datadir /var/lib/postgresql/17/main \
    --new-datadir /var/lib/postgresql/18/main \
    --check
  ```

- [ ] Review output for any FATAL errors. Examples of expected output:
  - Warnings about deprecated features (okay to proceed)
  - Information about missing pg_stat_statements data (okay to proceed)
  - FATAL errors (do not proceed—investigate and resolve)

- [ ] If FATAL errors found, stop and contact Database Architect before proceeding

- [ ] If check passes, proceed to actual upgrade

#### Step 2.5: T+10 Minutes - Execute pg_upgrade with --link Option

Run the actual upgrade using hard links (fastest method):

- [ ] As postgres user, execute pg_upgrade with --link:
  ```
  /usr/lib/postgresql/18/bin/pg_upgrade \
    --old-bindir /usr/lib/postgresql/17/bin \
    --new-bindir /usr/lib/postgresql/18/bin \
    --old-datadir /var/lib/postgresql/17/main \
    --new-datadir /var/lib/postgresql/18/main \
    --link
  ```

- [ ] Monitor progress. Output will show:
  - Cluster compatibility check
  - System catalog upgrade
  - Data directory sync
  - Completion message

- [ ] Expected duration: 5-20 minutes depending on database size
  - Small databases (< 100 GB): 5-10 minutes
  - Medium databases (100-500 GB): 10-15 minutes
  - Large databases (> 500 GB): 15-20+ minutes

- [ ] Verify completion—output should end with:
  ```
  Upgrade complete
  Report has been written to upgrade_server.log
  ```

- [ ] Check for any WARNING or ERROR messages in output
- [ ] Review `upgrade_server.log` in the data directory for any issues

#### Step 2.6: T+20 Minutes - Start PostgreSQL 18

- [ ] Start PostgreSQL 18 service:
  ```
  sudo systemctl start postgresql@18-main  # or service postgresql-18 start
  ```

- [ ] Verify PostgreSQL 18 started successfully:
  ```
  ps aux | grep postgres
  ```

- [ ] Should see `postgres: logger`, `postgres: startup`, and other processes

- [ ] Verify database is accepting connections:
  ```
  sudo -u postgres psql -c "SELECT version();"
  ```

- [ ] Output should confirm PostgreSQL 18.x running

#### Step 2.7: T+22 Minutes - Run Post-Upgrade Script (if applicable)

- [ ] If pg_upgrade generated `analyze_new_cluster.sh`:
  ```
  cd /var/lib/postgresql/18/main
  sudo -u postgres ./analyze_new_cluster.sh
  ```

- [ ] This updates statistics for the query planner
- [ ] Expected duration: 5-15 minutes depending on database size

#### Step 2.8: T+30-35 Minutes - Post-Upgrade Validation

#### Application Connectivity Test

- [ ] Verify database is accepting connections:
  ```
  sudo -u postgres psql -d appdbname -c "SELECT count(*) FROM pg_tables WHERE schemaname NOT IN ('pg_catalog', 'information_schema');"
  ```

- [ ] This confirms basic connectivity and catalog integrity

#### Extension Validation

- [ ] Verify all extensions are installed and functional:
  ```
  sudo -u postgres psql -c "SELECT * FROM pg_extension;"
  ```

- [ ] For each extension, test basic functionality:
  ```
  -- Example: PostGIS
  sudo -u postgres psql -c "SELECT PostGIS_version();"
  ```

#### Critical Table Validation

- [ ] Verify row counts in major application tables:
  ```
  sudo -u postgres psql -d appdbname -c "SELECT schemaname, tablename, n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC LIMIT 10;"
  ```

- [ ] Compare against pre-upgrade row counts documented in baseline

#### Application Smoke Test

- [ ] Notify application team: "PostgreSQL 18 upgrade complete - beginning validation"
- [ ] Application team executes smoke test:
  - [ ] Application can connect to database
  - [ ] Retrieve critical data (e.g., user list, recent records)
  - [ ] Insert test record if possible
  - [ ] Delete test record
  - [ ] Run report query

- [ ] Application team confirms basic functionality working

#### Final Status

- [ ] All validation items passed
- [ ] No critical errors in logs
- [ ] Database accepting connections and serving queries
- [ ] Application reporting successful smoke test

**Checkpoint 2: Upgrade Window Complete**

Record:

- [ ] Upgrade start time: _______________
- [ ] Upgrade completion time: _______________
- [ ] Total downtime: _______________
- [ ] pg_upgrade status: [PASS/FAIL]
- [ ] Post-upgrade validation: [PASS/FAIL]
- [ ] Application smoke test: [PASS/FAIL]
- [ ] Any issues encountered: _______________

---

### Phase 3: Post-Upgrade Stabilization

**Duration:** 1-2 hours post-upgrade  
**Downtime:** None (application on PostgreSQL 18)

#### Step 3.1: Update pgBackRest Configuration

- [ ] Update `/etc/pgbackrest.conf` to reference PostgreSQL 18 paths:
  ```
  [global]
  repo1-path=/path/to/pgbackrest/repo
  
  [stanzaname]
  db-path=/var/lib/postgresql/18/main
  pg1-path=/usr/lib/postgresql/18/bin
  ```

- [ ] Reload pgBackRest configuration
- [ ] Verify stanza connectivity:
  ```
  pgbackrest info
  ```

#### Step 3.2: Trigger First PostgreSQL 18 Backup

**Critical:** The first backup of PostgreSQL 18 becomes the recovery baseline:

- [ ] Trigger pgBackRest backup:
  ```
  pgbackrest backup
  ```

- [ ] Monitor progress:
  ```
  pgbackrest info
  ```

- [ ] Verify backup completed successfully without errors
- [ ] This is the first recovery point for PostgreSQL 18

#### Step 3.3: Performance Baseline Comparison

Within 1-2 hours of opening traffic:

- [ ] Collect initial performance metrics from PostgreSQL 18:
  ```
  sudo -u postgres psql -c "SELECT query, calls, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
  ```

- [ ] Compare against PG17 baseline collected pre-migration
- [ ] Document any significant deviations:
  - Queries taking > 20% longer
  - Query plans significantly different
  - Index usage changes

- [ ] If regressions found, document for post-migration analysis

#### Step 3.4: Monitoring Configuration Update

- [ ] Update any hardcoded hostnames in monitoring configuration if hostname changed
- [ ] Confirm Prometheus scraping PostgreSQL 18 metrics
- [ ] Verify all alerts firing correctly
- [ ] Update on-call runbooks with new PostgreSQL version

#### Step 3.5: Open Traffic

- [ ] Notify application team: "PostgreSQL 18 ready to accept full traffic"
- [ ] Redirect full application traffic to PostgreSQL 18:
  - Update connection strings if hostname changed
  - Update load balancer if applicable
  - Restart application services if connection pooler needs refresh

- [ ] Monitor for any connection errors or application issues
- [ ] Team stands by for 30 minutes to catch any immediate issues

**Checkpoint 3: Post-Upgrade Stabilization Complete**

- [ ] pgBackRest configuration updated and first PG18 backup successful
- [ ] Performance metrics within acceptable range
- [ ] Monitoring updated and alerts functional
- [ ] Full traffic redirected to PostgreSQL 18
- [ ] No critical issues

---

### Phase 4: Rollback Window (24-72 hours)

**Duration:** 24-72 hours  
**Action:** Monitor for issues; maintain rollback capability

#### Step 4.1: Rollback Readiness

During rollback window:

- [ ] pgBackRest full backup from before upgrade remains available
- [ ] PostgreSQL 17 binaries remain installed (can be used for restore if needed)
- [ ] pgBackRest configuration can be quickly reverted to PG17 paths
- [ ] Team remains on high alert for first 4-8 hours

#### Step 4.2: Rollback Decision Criteria

Initiate rollback if any of the following occur:

- [ ] Persistent data corruption detected
- [ ] Critical query plan regressions causing application failure
- [ ] Unrecoverable replication failure (if this is part of HA)
- [ ] Security or authentication issues affecting multiple users
- [ ] Application-level failures that cannot be resolved in < 30 minutes

**If rollback required:**

See Section 6: Rollback Procedures for detailed steps.

#### Step 4.3: Closing Rollback Window

After 72 hours with no issues:

- [ ] Rollback decision authority declares rollback window closed
- [ ] PostgreSQL 17 binaries can be removed:
  ```
  apt-get remove postgresql-17 postgresql-17-contrib  # Debian/Ubuntu
  yum remove postgresql17-server                       # RHEL/CentOS
  ```

- [ ] PostgreSQL 17 data directory can be safely deleted (after confirming backup exists):
  ```
  rm -rf /var/lib/postgresql/17/main
  ```

- [ ] pgBackRest configuration permanently updated to PostgreSQL 18
- [ ] Old pgBackRest backups can begin to be expired per retention policy

---

## Multi-Wave Execution for Standalone Fleet

### Wave Strategy Overview

Given that 10+ standalone servers require migration, a sequential wave-based approach minimizes fleet-wide risk and allows incorporation of lessons learned from each wave.

### Wave Scheduling

**Wave 1:** Weeks 9-10 (2 low-risk servers)  
**Wave 2:** Weeks 12-14 (4-6 medium-risk servers)  
**Wave 3+:** Weeks 15+ (remaining servers including most critical)

Each wave has a 1-2 week observation period before the next wave begins.

### Wave 1: Low-Risk Pilot

#### Server Selection Criteria

- [ ] Database size: < 200 GB if possible
- [ ] Business criticality: Low (not customer-facing if possible)
- [ ] Complexity: Fewest extensions and simplest workload
- [ ] Availability: Application team available for post-migration validation
- [ ] Examples: Reporting server, development support server, archive server

#### Servers Selected for Wave 1

- [ ] Server 1: __________________ (Size: _____ GB, Criticality: _______)
- [ ] Server 2: __________________ (Size: _____ GB, Criticality: _______)

#### Wave 1 Execution

- [ ] Follow standalone runbook (Section 4) exactly as documented
- [ ] Document every step taken and actual time consumed
- [ ] Record any deviations from plan and why they were necessary
- [ ] Document any issues encountered and how they were resolved
- [ ] Collect detailed post-upgrade logs and metrics

#### Wave 1 Observation Period (1 week minimum)

- [ ] Monitor both servers daily for any PostgreSQL 18 specific issues
- [ ] Application teams report any functional or performance issues
- [ ] Backup validation: Confirm pgBackRest can back up and restore successfully
- [ ] Replication validation (if applicable): Confirm replication healthy
- [ ] Performance: Compare metrics against baseline - any regressions?
- [ ] Monitoring: Confirm all alerts and dashboards working correctly

#### Wave 1 Sign-Off Criteria (Required Before Wave 2)

- [ ] Both wave 1 servers running PostgreSQL 18 stably for minimum 7 days
- [ ] No PostgreSQL 18 specific incidents reported
- [ ] Application team has confirmed functional acceptance
- [ ] Post-migration validation checklist completed for both servers
- [ ] pgBackRest backups confirmed working
- [ ] Performance regression analysis completed - no blockers found
- [ ] Lessons learned documented and incorporated into wave 2 plan

**If Wave 1 meets all criteria:** Proceed to Wave 2

**If Wave 1 has issues:**

- [ ] Investigate root cause
- [ ] Determine if issue affects other servers
- [ ] Develop remediation plan
- [ ] Test remediation on wave 1 servers if possible
- [ ] Update wave 2 plan to prevent issue recurrence
- [ ] Do not begin wave 2 until issues are resolved and plan updated

### Wave 2: Medium-Risk Expansion

#### Server Selection Criteria

- [ ] Database size: 200-500 GB
- [ ] Business criticality: Medium (non-critical but important)
- [ ] Complexity: Moderate (some extensions, moderate workload)
- [ ] Availability: Application teams available
- [ ] Lessons from Wave 1 incorporated into planning

#### Servers Selected for Wave 2

- [ ] Server 1: __________________ (Size: _____ GB, Criticality: _______)
- [ ] Server 2: __________________ (Size: _____ GB, Criticality: _______)
- [ ] Server 3: __________________ (Size: _____ GB, Criticality: _______)
- [ ] Server 4: __________________ (Size: _____ GB, Criticality: _______)
- [ ] [Add more rows as needed]

#### Wave 2 Procedure Updates

Based on Wave 1 lessons learned:

- [ ] Update runbook step [X] because: _____________________________
- [ ] Add validation checkpoint for: _____________________________
- [ ] Modify timing estimate from _____ to _____
- [ ] Add extension-specific procedure for: _____________________________
- [ ] [Document other modifications]

#### Wave 2 Execution

- [ ] Follow updated standalone runbook
- [ ] Continue to document all steps, timing, and deviations
- [ ] Team now more experienced - execution should be smoother

#### Wave 2 Observation Period (1 week minimum)

- [ ] Same monitoring and validation as Wave 1
- [ ] Lessons learned from Wave 2 documented

#### Wave 2 Sign-Off Criteria

- [ ] All wave 2 servers stable on PostgreSQL 18 for minimum 7 days
- [ ] No new issues compared to Wave 1 (or issues quickly resolved)
- [ ] Application teams confirmed functional acceptance
- [ ] Lessons learned from Wave 2 documented
- [ ] Update to runbook finalized based on Wave 2 experience

**If Wave 2 successful:** Proceed to Wave 3

### Wave 3+: Critical Production Servers

#### Server Selection Criteria

- [ ] Includes the most critical production servers
- [ ] Largest databases (> 500 GB)
- [ ] Most complex extension sets
- [ ] Highest availability requirements
- [ ] Procedure now proven by two prior waves

#### Servers Selected for Wave 3+

List all remaining servers with criticality ranking from highest to lowest.

#### Wave 3+ Execution

- [ ] Follow proven runbook with only necessary modifications
- [ ] Can execute more servers in parallel if infrastructure allows (but one at a time per migration team)
- [ ] For very large or critical servers, consider additional pre-migration dry run

#### Wave 3+ Timeline

- [ ] Can accelerate timeline as team becomes more experienced
- [ ] Estimate 1-2 servers per week at this point

### Multi-Wave Success Criteria (Fleet Completion)

All servers migrated successfully when:

- [ ] 100% of in-scope servers running PostgreSQL 18
- [ ] Zero servers rolled back to PostgreSQL 17
- [ ] All post-migration validation checklists completed and signed off
- [ ] All critical applications confirmed functional
- [ ] All pgBackRest backups confirmed working
- [ ] All monitoring alerts confirmed active and functional
- [ ] Post-migration documentation updated and final

---

## Rollback Procedures

### Rollback Decision Authority

**Named Individual:** ________________________  
**Backup Authority:** ________________________  
**Contact Method:** ________________________  

### Rollback Trigger Criteria

Rollback is initiated immediately upon occurrence of any of:

1. **Data Integrity Issue**
   - Database corruption detected and confirmed
   - Row count mismatch with pre-migration baseline
   - Application reports missing or corrupted data

2. **Critical Functionality Failure**
   - Application cannot connect to database
   - Critical business queries fail or return incorrect results
   - Authentication or authorization system broken

3. **Performance Degradation**
   - Query execution time > 100% of baseline (doubled)
   - System load significantly higher under normal workload
   - Cannot be attributed to statistics updates and cannot be resolved in < 30 minutes

4. **Replication Failure** (HA clusters only)
   - Streaming replication fails to establish or maintain synchronization
   - Standby unable to catch up with primary
   - Cannot be resolved in < 15 minutes

5. **Security/Availability Issue**
   - Multiple users unable to authenticate
   - Unpatched security vulnerability discovered in PostgreSQL 18
   - System stability failure

### HA Cluster Rollback Procedure

**Duration:** 5-15 minutes  
**Downtime:** Application offline during rollback

#### HA Cluster Rollback Steps

1. **Rollback Decision**
   - [ ] Named rollback decision authority confirms rollback needed
   - [ ] Rollback decision logged with timestamp and justification
   - [ ] Stakeholders notified immediately

2. **Stop Application Traffic to PG18**
   - [ ] Application writes directed away from PostgreSQL 18
   - [ ] All connections to PG18 drained if possible
   - [ ] No new connections accepted to PG18

3. **Redirect to PG17**
   - [ ] Application connection strings/load balancer updated to point to pg17-pri01
   - [ ] Application traffic begins flowing to PostgreSQL 17 primary
   - [ ] Application team confirms connectivity successful

4. **Verify PG17 Data Integrity**
   - [ ] Execute verification query:
     ```
     SELECT count(*) FROM critical_application_table;
     ```
   - [ ] Confirm row counts match known good value from just before cutover

5. **Drop PG18 Subscription** (to prevent automatic sync)
   - [ ] Connect to PG18 and execute:
     ```
     DROP SUBSCRIPTION IF EXISTS pg17_to_pg18_sub;
     ```
   - [ ] This stops logical replication from consuming resources

6. **Archive PG18 Environment**
   - [ ] PG18 cluster stopped or isolated from network
   - [ ] PG18 data directory preserved for post-rollback investigation
   - [ ] Do not delete PG18 data directory

7. **Post-Rollback Status**
   - [ ] Application confirmed operational on PG17
   - [ ] Stakeholders notified of rollback completion
   - [ ] Team scheduled for root cause analysis meeting

#### HA Cluster Rollback Success Criteria

- [ ] Application connectivity to PG17 confirmed
- [ ] No data loss detected
- [ ] Application functionality restored
- [ ] Replication between PG17 primary and standby healthy (if they are still in use)

### Standalone Server Rollback Procedure

**Duration:** 30 minutes to several hours (depending on database size and restore speed)  
**Method:** Restore from pre-upgrade pgBackRest backup

#### Standalone Server Rollback Steps

**Option A: If pg_upgrade Used WITHOUT --link**

Hard-linked files were not used, so rollback is simple:

1. **Stop PostgreSQL 18**
   ```
   sudo systemctl stop postgresql@18-main
   ```

2. **Start PostgreSQL 17**
   ```
   sudo systemctl start postgresql@17-main
   ```

3. **Verify Connectivity**
   ```
   sudo -u postgres psql -c "SELECT version();"
   ```
   Should show PostgreSQL 17.x

4. **Redirect Application Traffic**
   - [ ] Update application connection strings or load balancer
   - [ ] Verify application connectivity

5. **Rollback Complete**
   - Original data directory preserved, data intact
   - No restore needed
   - Minimal downtime (just service restart)

**Option B: If pg_upgrade Used WITH --link (Recommended)**

Hard-linked files may have been modified by PG18, so recovery from backup is required:

1. **Stop PostgreSQL 18**
   ```
   sudo systemctl stop postgresql@18-main
   ```

2. **Preserve PG18 Data Directory** (for investigation)
   ```
   sudo mv /var/lib/postgresql/18/main /var/lib/postgresql/18/main.backup
   ```

3. **Restore PG17 Data from pgBackRest Backup**
   ```
   pgbackrest restore --stanza=stanzaname
   ```

   Expected duration:
   - 100 GB database: 30 minutes - 1 hour
   - 500 GB database: 1 - 4 hours
   - 1 TB+ database: 4+ hours

   Monitor progress:
   ```
   # In another terminal, watch backup process:
   tail -f /var/log/pgbackrest/[stanza].log
   ```

4. **Start PostgreSQL 17**
   ```
   sudo systemctl start postgresql@17-main
   ```

5. **Verify Restored Data**
   ```
   sudo -u postgres psql -c "SELECT version();"
   sudo -u postgres psql -d appdbname -c "SELECT count(*) FROM critical_table;"
   ```

6. **Redirect Application Traffic**
   - [ ] Update connection strings or load balancer
   - [ ] Verify application connectivity

7. **Rollback Complete**

#### Standalone Server Rollback Success Criteria

- [ ] PostgreSQL 17 running and accepting connections
- [ ] Data restored successfully and row counts verified
- [ ] Application connectivity confirmed
- [ ] Application functionality validated

### Post-Rollback Investigation

After rollback completes, schedule investigation:

#### Investigation Steps

1. **Collect Logs**
   - [ ] Collect PostgreSQL error logs from attempted PG18 migration
   - [ ] Collect system logs from time of issue
   - [ ] Collect application error logs if relevant

2. **Root Cause Analysis**
   - [ ] Analyze logs to identify root cause
   - [ ] Determine if issue is environment-specific or systemic
   - [ ] Document findings

3. **Remediation Plan**
   - [ ] If blocking issue found: develop fix
   - [ ] Test fix in non-production environment
   - [ ] Plan re-attempt after fix validation

4. **Stakeholder Communication**
   - [ ] Notify stakeholders of root cause
   - [ ] Explain impact and remediation plan
   - [ ] Set expectation for re-attempt if needed

---

## Post-Migration Validation

### Validation Checklist

This checklist must be completed for every migrated environment within 24 hours of cutover/upgrade.

#### Functional Validation

- [ ] Database starts successfully: `SELECT version();`
- [ ] All databases in cluster are accessible and queryable
- [ ] Schema objects present: `SELECT count(*) FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog', 'information_schema');`
- [ ] Row counts verified for major tables match pre-migration counts
- [ ] Sequences functional and values appropriate: `SELECT schemaname, sequencename, last_value FROM information_schema.sequences;`
- [ ] Foreign keys intact and validated: Run `ALTER TABLE table_name VALIDATE CONSTRAINT constraint_name;` for samples
- [ ] Views functional: `SELECT count(*) FROM information_schema.views WHERE table_schema NOT IN ('pg_catalog', 'information_schema');`

#### Extension Validation

- [ ] All extensions present: `SELECT * FROM pg_extension;`
- [ ] Each extension tested for basic functionality
- [ ] PostGIS (if installed): `SELECT PostGIS_full_version();`
- [ ] pg_stat_statements (if installed): `SELECT count(*) FROM pg_stat_statements;`
- [ ] pgvector (if installed): Test vector operations
- [ ] Custom extensions: Test with representative queries

#### Replication Validation (HA Clusters Only)

- [ ] Streaming replication established: `SELECT * FROM pg_stat_replication;` on primary
- [ ] Standby WAL receiver active: Check `state` column shows 'streaming'
- [ ] Replication lag minimal: `SELECT now() - pg_last_xact_replay_time();` on standby (should be < 1 second)
- [ ] No replication slots stuck: `SELECT * FROM pg_replication_slots WHERE NOT active;`
- [ ] Synchronous standby configured as intended (if applicable)

#### Backup Validation

- [ ] First pgBackRest backup of new cluster triggered: `pgbackrest backup`
- [ ] Backup completed without errors: `pgbackrest info`
- [ ] Backup size reasonable (similar to pre-migration size)
- [ ] Backup repository storage available for future backups

#### Performance Validation

Collect metrics at 1 hour, 4 hours, and 24 hours post-migration:

- [ ] Top 10 queries by execution time (compare to baseline)
- [ ] Query plan comparison (identify plan regressions)
- [ ] Checkpoint frequency and duration (should be similar to baseline)
- [ ] Cache hit ratio: `SELECT 100 * sum(blks_hit) / (sum(blks_hit) + sum(blks_read)) AS hit_ratio FROM pg_stat_database;`
- [ ] Connection count and active transaction count (should match workload pattern)
- [ ] Wait events (should be similar distribution to baseline)

**Action if regression found:**

- [ ] Investigate cause (new planner behavior, statistics, configuration)
- [ ] Attempt to resolve with `ANALYZE;` or configuration adjustment
- [ ] If cannot resolve within 1 hour, escalate to Database Architect
- [ ] Document regression and resolution for migration record

#### Security & Access Validation

- [ ] Authentication works for application roles: `psql -U appuser -d appdb -c "SELECT 1;"`
- [ ] Row-level security policies (if in use) enforced correctly
- [ ] SSL connections functional if configured
- [ ] Superuser roles limited and documented
- [ ] Backup user role has correct permissions

#### Monitoring Validation

- [ ] Prometheus scraping all metrics from PostgreSQL 18: `curl http://localhost:9090/api/v1/query?query=pg_up`
- [ ] Grafana dashboards displaying data (no "no data" panels)
- [ ] Alerting rules firing correctly for configured thresholds
- [ ] On-call escalation procedures updated to reference new environment
- [ ] Backup monitoring alerts functional

#### Application Validation

**Responsible Party:** Application Team Lead  
**Sign-Off Required:** Yes

- [ ] Application connects successfully to PostgreSQL 18
- [ ] Authentication works for application users
- [ ] Critical business workflows execute successfully
- [ ] Data retrieval (SELECT) works correctly
- [ ] Data modification (INSERT/UPDATE/DELETE) works correctly
- [ ] Reporting/analytics queries execute successfully
- [ ] No unexpected errors in application logs
- [ ] Performance acceptable (no user complaints)

**Application Team Sign-Off:**

```
Application Team Lead: ________________  Date: __________

Confirmation: PostgreSQL 18 environment is acceptable for 
continued production use.

Issues Identified: _________________________________
```

#### Documentation Validation

- [ ] Runbooks updated to reference PostgreSQL 18
- [ ] Operational procedures manual updated
- [ ] Disaster recovery plan updated
- [ ] Capacity planning updated with new environment specs
- [ ] Hardware and software inventory updated
- [ ] Migration record documented for future reference

---

## Communication & Escalation

### Pre-Migration Communication

**One Week Before Window:**

- [ ] Email to all stakeholders with:
  - Maintenance window date and time
  - Estimated duration (downtime and total window)
  - Expected applications affected
  - Rollback plan overview
  - Contact information for questions

**24 Hours Before Window:**

- [ ] Reminder email with final details
- [ ] Confirm application team availability
- [ ] Confirm DBA team on standby

**1 Hour Before Window:**

- [ ] Team chat message: "Migration window beginning in 1 hour"
- [ ] All team members acknowledge readiness
- [ ] Monitoring dashboards confirmed active

### During-Migration Communication

**Every 5-10 minutes:**

- [ ] Team lead posts status update in chat:
  - Current phase
  - Status (on track, delayed, issues)
  - Estimated time to completion

**Upon Issue Detection:**

- [ ] Immediate escalation message to team and stakeholders
- [ ] Root cause and workaround (if available) communicated
- [ ] Updated ETA provided

**Upon Completion or Rollback:**

- [ ] Team lead announces completion or rollback decision
- [ ] Stakeholders notified with final status
- [ ] Expected business operations resumption time provided

### Post-Migration Communication

**Within 1 Hour:**

- [ ] Status email to stakeholders: "Migration [successful/rolled back]"
- [ ] If successful: "System operational, validation in progress"
- [ ] If rolled back: "System rolled back to PostgreSQL 17, [root cause], investigation underway"

**Within 4 Hours:**

- [ ] Email with validation results summary
- [ ] Any issues identified and remediation plan
- [ ] Formal go-live approval (if all validation passed)

**Within 24 Hours:**

- [ ] Email with full migration metrics (timing, resource usage, issues)
- [ ] Link to migration record documentation
- [ ] Lessons learned (if available)

### Escalation Matrix

| Issue | Escalate To | Method | Timeline |
|-------|-------------|--------|----------|
| Extension not loading | Database Architect | Immediate call | < 5 mins |
| Performance regression | Database Architect | Immediate call | < 5 mins |
| Data mismatch | Database Architect + Manager | Immediate call | < 5 mins |
| Replication failure | Database Architect | Immediate call | < 5 mins |
| Rollback decision | Director of Operations | Phone + Chat | < 10 mins |
| Unplanned downtime extension | Infrastructure Lead | Chat + Email | < 15 mins |

---

## Post-Migration Decommissioning (After Rollback Window)

### Timeline: 24-72 hours after rollback window closes

#### PostgreSQL 17 Decommissioning

- [ ] Final pgBackRest backup of PG17 taken if desired for archival
- [ ] PostgreSQL 17 service stopped
- [ ] PostgreSQL 17 binaries removed (or archived)
- [ ] PostgreSQL 17 system user removed
- [ ] pgBackRest configuration for PG17 removed
- [ ] Old pgBackRest backups expired

#### Configuration & Documentation Cleanup

- [ ] All runbooks updated to remove PG17 references
- [ ] Disaster recovery procedures updated for PG18
- [ ] On-call runbooks updated
- [ ] Hardware inventory updated
- [ ] Monitoring dashboards for PG17 removed
- [ ] Alerting rules for PG17 removed

#### Final Sign-Off

- [ ] Database Operations Lead confirms decommissioning complete
- [ ] Migration record finalized and archived
- [ ] Post-migration meeting scheduled to discuss lessons learned
- [ ] Team recognized for successful execution

---

## Appendices

### Appendix A: Useful pg_upgrade Commands

```bash
# Pre-upgrade check
/usr/lib/postgresql/18/bin/pg_upgrade \
  --old-bindir /usr/lib/postgresql/17/bin \
  --new-bindir /usr/lib/postgresql/18/bin \
  --old-datadir /var/lib/postgresql/17/main \
  --new-datadir /var/lib/postgresql/18/main \
  --check

# Actual upgrade with hard links (fastest)
/usr/lib/postgresql/18/bin/pg_upgrade \
  --old-bindir /usr/lib/postgresql/17/bin \
  --new-bindir /usr/lib/postgresql/18/bin \
  --old-datadir /var/lib/postgresql/17/main \
  --new-datadir /var/lib/postgresql/18/main \
  --link

# Upgrade without hard links (slower but safer)
/usr/lib/postgresql/18/bin/pg_upgrade \
  --old-bindir /usr/lib/postgresql/17/bin \
  --new-bindir /usr/lib/postgresql/18/bin \
  --old-datadir /var/lib/postgresql/17/main \
  --new-datadir /var/lib/postgresql/18/main
```

### Appendix B: Useful PostgreSQL Validation Queries

```sql
-- Check version
SELECT version();

-- Count tables
SELECT count(*) FROM information_schema.tables 
WHERE table_schema NOT IN ('pg_catalog', 'information_schema');

-- List extensions
SELECT * FROM pg_extension;

-- Check replication status
SELECT * FROM pg_stat_replication;

-- Check replication lag
SELECT now() - pg_last_xact_replay_time();

-- Table sizes
SELECT schemaname, tablename, 
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables 
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC 
LIMIT 20;

-- Extension versions
SELECT extname, extversion FROM pg_extension;

-- Table row counts
SELECT schemaname, tablename, n_live_tup 
FROM pg_stat_user_tables 
ORDER BY n_live_tup DESC 
LIMIT 20;
```

### Appendix C: Monitoring Commands

```bash
# Monitor pg_upgrade progress
tail -f upgrade_server.log

# Monitor pgBackRest backup
pgbackrest info
tail -f /var/log/pgbackrest/stanzaname.log

# Monitor active connections
watch -n 1 "sudo -u postgres psql -c \"SELECT count(*) FROM pg_stat_activity WHERE state != 'idle';\""

# Monitor replication lag
watch -n 5 "sudo -u postgres psql -c \"SELECT now() - pg_last_xact_replay_time();\""

# Check disk usage
watch -n 5 "df -h /var/lib/postgresql"
```

---

**Document Prepared By:** Database Architecture Team  
**Date:** 2026-06-08  
**Version:** 1.0  
**Next Review Date:** Upon first production execution or quarterly

**Approval Sign-Off:**

DBA Operations Lead: ________________  Date: __________

Database Architect: ________________  Date: __________

Director of Operations: ________________  Date: __________
