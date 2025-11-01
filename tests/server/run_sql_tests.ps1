# ============================================================================
# SQL Schema Testing Script for Windows
# ============================================================================
# This PowerShell script runs all SQL schema tests
# Usage: .\tests\server\run_sql_tests.ps1
# ============================================================================

param(
    [string]$DBUser = "root",
    [string]$DBPassword = "",
    [string]$DBHost = "localhost",
    [string]$DBPort = "3306"
)

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "SQL Schema Testing Suite" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if MySQL client is available
$mysqlPath = Get-Command mysql -ErrorAction SilentlyContinue
if (-not $mysqlPath) {
    Write-Host "ERROR: MySQL client not found in PATH" -ForegroundColor Red
    Write-Host "Please install MySQL client or add it to your PATH" -ForegroundColor Yellow
    exit 1
}

Write-Host "MySQL client found: $($mysqlPath.Source)" -ForegroundColor Green
Write-Host ""

# Prompt for password if not provided
if ([string]::IsNullOrEmpty($DBPassword)) {
    $securePassword = Read-Host "Enter MySQL password for user '$DBUser'" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $DBPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

# Test database connection
Write-Host "Testing database connection..." -ForegroundColor Yellow
$testConnection = "SELECT 1;" | mysql -h $DBHost -P $DBPort -u $DBUser -p$DBPassword 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Cannot connect to database" -ForegroundColor Red
    Write-Host $testConnection -ForegroundColor Red
    exit 1
}
Write-Host "Database connection successful!" -ForegroundColor Green
Write-Host ""

# Test 1: Individual SQL Files
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "Test 1: Individual SQL File Validation" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

$test1Output = Get-Content "tests\server\validate_sql_files.sql" | mysql -h $DBHost -P $DBPort -u $DBUser -p$DBPassword 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Test 1 PASSED: Individual SQL files validated successfully" -ForegroundColor Green
    Write-Host $test1Output
} else {
    Write-Host "✗ Test 1 FAILED: Individual SQL file validation failed" -ForegroundColor Red
    Write-Host $test1Output -ForegroundColor Red
}
Write-Host ""

# Test 2: Master Installation Script
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "Test 2: Master Installation Script" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

$test2Output = Get-Content "tests\server\test_master_install.sql" | mysql -h $DBHost -P $DBPort -u $DBUser -p$DBPassword 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Test 2 PASSED: Master installation script executed successfully" -ForegroundColor Green
    Write-Host $test2Output
} else {
    Write-Host "✗ Test 2 FAILED: Master installation script failed" -ForegroundColor Red
    Write-Host $test2Output -ForegroundColor Red
}
Write-Host ""

# Test 3: Existing Database Compatibility
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "Test 3: Existing Database Compatibility" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

$test3Output = Get-Content "tests\server\test_existing_database.sql" | mysql -h $DBHost -P $DBPort -u $DBUser -p$DBPassword 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Test 3 PASSED: Existing database compatibility verified" -ForegroundColor Green
    Write-Host $test3Output
} else {
    Write-Host "✗ Test 3 FAILED: Existing database compatibility test failed" -ForegroundColor Red
    Write-Host $test3Output -ForegroundColor Red
}
Write-Host ""

# Cleanup
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "Cleanup" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Cleaning up test databases..." -ForegroundColor Yellow
$cleanup = @"
DROP DATABASE IF EXISTS phone_test_validation;
DROP DATABASE IF EXISTS phone_test_master;
DROP DATABASE IF EXISTS phone_test_existing;
"@ | mysql -h $DBHost -P $DBPort -u $DBUser -p$DBPassword 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Test databases cleaned up successfully" -ForegroundColor Green
} else {
    Write-Host "⚠ Warning: Could not clean up all test databases" -ForegroundColor Yellow
    Write-Host $cleanup -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All SQL schema tests completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Test databases have been cleaned up." -ForegroundColor Gray
Write-Host "Review the output above for detailed results." -ForegroundColor Gray
Write-Host ""
