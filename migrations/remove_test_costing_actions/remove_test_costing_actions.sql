-- Test helpers for gas/fee capture. They now live in schema_addons_staging.sql only.
-- Run on production (and playground). Do NOT run on staging.
DROP ACTION IF EXISTS action_costing_gas;
DROP ACTION IF EXISTS action_costing_idos_token;
DROP ACTION IF EXISTS action_costing_fee;
