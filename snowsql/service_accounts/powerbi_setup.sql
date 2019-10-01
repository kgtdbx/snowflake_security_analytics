//===========================================================
// Create service account, warehouse, and role structure
// for a PowerBI BI connection
//===========================================================
// create a BI service account user
USE ROLE SECURITYADMIN;
CREATE USER IF NOT EXISTS
  POWERBI_SNOWALERT_SERVICE_ACCOUNT
  PASSWORD = 'my cool password here' // use your own password, dummy 
  MUST_CHANGE_PASSWORD = FALSE;

// create roles
USE ROLE SECURITYADMIN;
CREATE ROLE IF NOT EXISTS POWERBI_ADMIN_ROLE;
CREATE ROLE IF NOT EXISTS POWERBI_SNOWALERT_USER_ROLE;
GRANT ROLE POWERBI_ADMIN_ROLE          TO ROLE SYSADMIN;
GRANT ROLE POWERBI_SNOWALERT_USER_ROLE TO ROLE SYSADMIN;
GRANT ROLE POWERBI_SNOWALERT_USER_ROLE TO ROLE POWERBI_ADMIN_ROLE;
GRANT ROLE POWERBI_SNOWALERT_USER_ROLE TO USER POWERBI_SNOWALERT_SERVICE_ACCOUNT;

// create warehouse
USE ROLE SYSADMIN;
CREATE WAREHOUSE IF NOT EXISTS
  POWERBI_SNOWALERT_WH
  COMMENT='Warehouse for snowalert dashboard development in PowerBI'
  WAREHOUSE_SIZE=XSMALL
  AUTO_SUSPEND=60
  INITIALLY_SUSPENDED=TRUE;
GRANT OWNERSHIP ON WAREHOUSE POWERBI_SNOWALERT_WH TO ROLE POWERBI_ADMIN_ROLE;

// permission the role
USE ROLE SECURITYADMIN;
GRANT USAGE ON WAREHOUSE POWERBI_SNOWALERT_WH TO ROLE POWERBI_SNOWALERT_USER_ROLE;
GRANT ROLE SNOWALERT_BI_READ_ROLE             TO ROLE POWERBI_SNOWALERT_USER_ROLE;

// set service account default values
ALTER USER 
  POWERBI_SNOWALERT_SERVICE_ACCOUNT
SET
  DEFAULT_WAREHOUSE = POWERBI_SNOWALERT_WH
  DEFAULT_ROLE = POWERBI_SNOWALERT_USER_ROLE;
//===========================================================