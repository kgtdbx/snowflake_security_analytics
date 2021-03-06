//===========================================================
// Create snowalert violation views
//===========================================================
USE ROLE SNOWALERT;
USE WAREHOUSE SNOWALERT;

// IAM Users without MFA Violation.
CREATE OR REPLACE VIEW 
  SNOWALERT.RULES.IAM_USER_WITHOUT_MFA_VIOLATION_QUERY 
  COPY GRANTS
  COMMENT='Any human IAM Users that do not have an MFA device
  @id 7FTYSEYDPVH'
AS
SELECT 
  'AWS' AS ENVIRONMENT,
  ARN AS OBJECT,
  'IAM USER WITHOUT MFA' AS TITLE,
  CURRENT_TIMESTAMP() AS ALERT_TIME,
  'This user does not have MFA configured in AWS' AS DESCRIPTION,
  RAW_DATA AS EVENT_DATA,
  'SNOWALERT' AS DETECTOR,
  'medium' AS SEVERITY,
  NULL AS OWNER,
  '7FTYSEYDPVH' AS QUERY_ID,
  'IAM_USER_WITHOUT_MFA' AS QUERY_NAME
FROM 
  SNOWALERT.BI.CURRENT_IAM_HUMAN_USERS
WHERE 
  NOT MFA_IS_ENABLED
;

// open security groups
CREATE OR REPLACE VIEW 
  SNOWALERT.RULES.WIDE_OPEN_SECURITY_GROUP_VIOLATION_QUERY 
  COPY GRANTS
  COMMENT='Security groups that allow ipv4 or ipv6 traffic from any ip range
  @id QM44DR0DWB'
AS
SELECT 
  'AWS' AS ENVIRONMENT,
  GROUP_ID AS OBJECT,
  'WIDE OPEN SECURITY GROUP' AS TITLE,
  CURRENT_TIMESTAMP() AS ALERT_TIME,
  'The "' || GROUP_NAME || '" (' || GROUP_ID || ') security group has a wide open ip range in the ' || REGION_NAME || ' region of account ' || ACCOUNT_ID AS DESCRIPTION,
  NULL AS EVENT_DATA,
  'SNOWALERT' AS DETECTOR,
  'low' AS SEVERITY,
  OWNER_ID AS OWNER,
  'QM44DR0DWB' AS QUERY_ID,
  'WIDE_OPEN_SECURITY_GROUP' AS QUERY_NAME
FROM (
  SELECT DISTINCT
    MONITORED_TIME,
    GROUP_ID,
    GROUP_NAME,
    OWNER_ID,
    REGION_NAME,
    ACCOUNT_ID
  FROM (
    SELECT 
      MONITORED_TIME,
      GROUP_ID,
      GROUP_NAME,
      OWNER_ID,
      REGION_NAME,
      ACCOUNT_ID,
      VALUE as IP_PERMISSIONS
    FROM 
      SNOWALERT.BI.CURRENT_SECURITY_GROUPS, TABLE(FLATTEN(INPUT => RAW_DATA:"IpPermissions"))
  ), TABLE(FLATTEN(INPUT => IP_PERMISSIONS:"Ipv6Ranges"))
  WHERE
    VALUE:"CidrIpv6" = '::/0'
  UNION ALL
  SELECT DISTINCT
    MONITORED_TIME,
    GROUP_ID,
    GROUP_NAME,
    OWNER_ID,
    REGION_NAME,
    ACCOUNT_ID
  FROM (
    SELECT 
      MONITORED_TIME,
      GROUP_ID,
      GROUP_NAME,
      OWNER_ID,
      REGION_NAME,
      ACCOUNT_ID,
      VALUE as IP_PERMISSIONS
    FROM 
      SNOWALERT.BI.CURRENT_SECURITY_GROUPS, TABLE(FLATTEN(INPUT => RAW_DATA:"IpPermissions"))
  ), TABLE(FLATTEN(INPUT => IP_PERMISSIONS:"IpRanges"))
  WHERE
    VALUE:"CidrIp" = '0.0.0.0/0'
);
//===========================================================