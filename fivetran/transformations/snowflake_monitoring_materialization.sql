//===========================================================
// initial schema setup
//===========================================================
// schema
CREATE SCHEMA IF NOT EXISTS FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE;

// warehouse metering history
CREATE TABLE IF NOT EXISTS 
  FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE.WAREHOUSE_METERING_HISTORY
AS (
  SELECT
    *,
    CURRENT_TIMESTAMP AS INGESTION_TIME
  FROM
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
);

// snowpipe history
CREATE TABLE IF NOT EXISTS 
  FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE.SNOWPIPES
AS (
  SELECT
    *,
    CURRENT_TIMESTAMP AS INGESTION_TIME
  FROM
    SNOWFLAKE.ACCOUNT_USAGE.PIPES
);

// snowpipe usage history
CREATE TABLE IF NOT EXISTS 
  FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE.SNOWPIPE_USAGE_HISTORY
AS (
  SELECT
    *,
    CURRENT_TIMESTAMP AS INGESTION_TIME
  FROM
    SNOWFLAKE.ACCOUNT_USAGE.PIPE_USAGE_HISTORY
);

// query history
CREATE TABLE IF NOT EXISTS 
  FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE.QUERY_HISTORY
AS (
  SELECT
    *,
    CURRENT_TIMESTAMP AS INGESTION_TIME
  FROM
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
);

// Tasks history
CREATE TABLE IF NOT EXISTS 
  FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE.TASKS (
    CREATED_ON TIMESTAMP_LTZ,
    NAME STRING,
    DATABASE_NAME STRING,
    SCHEMA_NAME STRING,
    OWNER STRING,
    COMMENT STRING,
    WAREHOUSE STRING,
    SCHEDULE STRING,
    PREDECESSOR STRING,
    STATE STRING,
    DEFINITION STRING,
    CONDITION STRING,
    INGESTION_TIME TIMESTAMP_LTZ
);

// Task usage history
CREATE TABLE IF NOT EXISTS
  FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE.TASK_USAGE_HISTORY(
    QUERY_ID STRING,
    NAME STRING,
    DATABASE_NAME STRING,
    SCHEMA_NAME STRING,
    QUERY_TEXT STRING,
    CONDITION_TEXT STRING,
    STATE STRING,
    ERROR_CODE STRING,
    ERROR_MESSAGE STRING,
    SCHEDULED_TIME TIMESTAMP_LTZ,
    COMPLETED_TIME TIMESTAMP_LTZ,
    RETURN_CODE STRING,
    INGESTION_TIME TIMESTAMP_LTZ
  );

//===========================================================



//===========================================================
// account_usage cdc and snapshotting
//===========================================================
// warehouse metering history
SET CURSOR = (SELECT COALESCE(MAX(START_TIME), 0::TIMESTAMP_LTZ) FROM FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE.WAREHOUSE_METERING_HISTORY);

INSERT INTO  
  FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE.WAREHOUSE_METERING_HISTORY
SELECT
  *,
  CURRENT_TIMESTAMP AS INGESTION_TIME
FROM
  SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE
  START_TIME > $CURSOR;

// snowpipe history
INSERT INTO  
  FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE.SNOWPIPES
SELECT
    *,
    CURRENT_TIMESTAMP AS INGESTION_TIME
  FROM
    SNOWFLAKE.ACCOUNT_USAGE.PIPES;

// snowpipe usage history
SET CURSOR = (SELECT COALESCE(MAX(END_TIME), 0::TIMESTAMP_LTZ) FROM FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE.SNOWPIPE_USAGE_HISTORY);

INSERT INTO  
  FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE.SNOWPIPE_USAGE_HISTORY
SELECT
  *,
  CURRENT_TIMESTAMP AS INGESTION_TIME
FROM
  SNOWFLAKE.ACCOUNT_USAGE.PIPE_USAGE_HISTORY
WHERE
  END_TIME > $CURSOR;

// query history
SET CURSOR = (SELECT COALESCE(MAX(END_TIME), 0::TIMESTAMP_LTZ) FROM FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE.QUERY_HISTORY);

INSERT INTO  
  FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE.QUERY_HISTORY
SELECT
  *,
  CURRENT_TIMESTAMP AS INGESTION_TIME
FROM
  SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE
  END_TIME > $CURSOR;

//===========================================================



//===========================================================
// tasks cdc and snapshotting with SYSADMIN
//===========================================================
// needed to monitor tasks as snowflake somehow does not have a MONITOR permission for tasks.
USE ROLE SYSADMIN; 

// Snapshot tasks for task_history
// no task inventory table exists, so this is called for a subsequent RESULT_SCAN call
SHOW TASKS IN ACCOUNT;

INSERT INTO  
  FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE.TASKS 
SELECT 
  "created_on" AS CREATED_ON,
  "name" AS NAME,
  "database_name" AS DATABASE_NAME,
  "schema_name" AS SCHEMA_NAME,
  "owner" AS OWNER,
  "comment" AS COMMENT,
  "warehouse" AS WAREHOUSE,
  "schedule" AS SCHEDULE,
  "predecessor" AS PREDECESSOR,
  "state" AS STATE,
  "definition" AS DEFINITION,
  "condition" AS CONDITION,
  CURRENT_TIMESTAMP AS INGESTION_TIME
FROM // RESULT_SCAN presents the results of the previous SHOW TASKS query as a table
  TABLE(RESULT_SCAN(LAST_QUERY_ID())); 

// Task usage history
SET CURSOR = (SELECT COALESCE(MAX(COMPLETED_TIME), 0::TIMESTAMP_LTZ) FROM FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE.TASK_USAGE_HISTORY);

INSERT INTO  
  FIVETRAN_DB.HASHMAP_SNOWFLAKE_USAGE.TASK_USAGE_HISTORY
SELECT
  *,
  CURRENT_TIMESTAMP AS INGESTION_TIME
FROM
  TABLE(SNOWFLAKE.INFORMATION_SCHEMA.TASK_HISTORY())
WHERE
  COMPLETED_TIME > $CURSOR;

//===========================================================
