# Test CI AWS Profile Fix

This PR tests the fix for the AWS profile issue in CI workflows.

## Changes
- Provider configuration now uses variables instead of hardcoded profile
- CI workflows pass empty aws_profile for CI environments
- Should resolve the 'failed to get shared config profile, quanttrader-dev' error

## Expected Results
- Terraform fmt check should pass
- Terraform validate should pass  
- Terraform plan should run without AWS profile errors
- Security scans should execute successfully
- Plan output should be posted as PR comment

