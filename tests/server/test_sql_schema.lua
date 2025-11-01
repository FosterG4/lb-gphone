-- ============================================================================
-- SQL Schema Validation Test Script
-- ============================================================================
-- This script tests all SQL files to ensure they create tables correctly
-- and that all foreign keys and indexes are properly defined.
-- ============================================================================

local MySQL = exports.oxmysql

-- Test configuration
local TEST_DB_NAME = "phone_test_" .. os.time()
local SQL_FILES = {
    -- Core tables (no dependencies)
    "server/sql/phone_core_tables.sql",
    
    -- Media tables (depends on core)
    "server/sql/phone_media_tables.sql",
    
    -- Social media tables
    "server/sql/phone_chirper_tables.sql",
    "server/sql/phone_shotz_additional_tables.sql",
    "server/sql/phone_modish_tables.sql",
    "server/sql/phone_flicker_tables.sql",
    "server/sql/phone_contact_sharing_tables.sql",
    "server/sql/phone_social_media_multi_attachments.sql",
    
    -- Financial tables
    "server/sql/phone_wallet_tables.sql",
    "server/sql/phone_cryptox_tables.sql",
    
    -- Entertainment tables
    "server/sql/phone_musicly_tables.sql",
    
    -- Location and safety tables
    "server/sql/phone_finder_tables.sql",
    "server/sql/phone_safezone_tables.sql",
    
    -- Commerce tables
    "server/sql/phone_marketplace_tables.sql",
    "server/sql/phone_business_tables.sql",
    
    -- Utility tables
    "server/sql/phone_utilities_tables.sql",
    
    -- Asset tables
    "server/sql/phone_assets_tables.sql",
}

-- Test results tracking
local testResults = {
    passed = 0,
    failed = 0,
    errors = {}
}

-- Helper function to read SQL file
local function readSQLFile(filepath)
    local file = io.open(filepath, "r")
    if not file then
        return nil, "Could not open file: " .. filepath
    end
    
    local content = file:read("*all")
    file:close()
    return content
end

-- Helper function to execute SQL
local function executeSQL(sql)
    local success, result = pcall(function()
        return MySQL.query.await(sql)
    end)
    
    if not success then
        return false, result
    end
    
    return true, result
end

-- Test 1: Verify SQL file syntax
local function testSQLFileSyntax(filepath)
    print("Testing SQL file: " .. filepath)
    
    local content, err = readSQLFile(filepath)
    if not content then
        testResults.failed = testResults.failed + 1
        table.insert(testResults.errors, {
            file = filepath,
            test = "File Read",
            error = err
        })
        return false
    end
    
    -- Check for basic SQL syntax elements
    if not content:match("CREATE%s+TABLE") then
        testResults.failed = testResults.failed + 1
        table.insert(testResults.errors, {
            file = filepath,
            test = "SQL Syntax",
            error = "No CREATE TABLE statements found"
        })
        return false
    end
    
    -- Check for IF NOT EXISTS clause
    if not content:match("IF%s+NOT%s+EXISTS") then
        testResults.failed = testResults.failed + 1
        table.insert(testResults.errors, {
            file = filepath,
            test = "IF NOT EXISTS",
            error = "Missing IF NOT EXISTS clause"
        })
        return false
    end
    
    testResults.passed = testResults.passed + 1
    return true
end

-- Test 2: Execute SQL file and verify tables are created
local function testSQLFileExecution(filepath)
    print("Executing SQL file: " .. filepath)
    
    local content, err = readSQLFile(filepath)
    if not content then
        testResults.failed = testResults.failed + 1
        table.insert(testResults.errors, {
            file = filepath,
            test = "Execution",
            error = err
        })
        return false
    end
    
    -- Split by semicolons and execute each statement
    local statements = {}
    for statement in content:gmatch("([^;]+)") do
        local trimmed = statement:match("^%s*(.-)%s*$")
        if trimmed ~= "" and not trimmed:match("^%-%-") then
            table.insert(statements, trimmed)
        end
    end
    
    for _, statement in ipairs(statements) do
        local success, result = executeSQL(statement)
        if not success then
            testResults.failed = testResults.failed + 1
            table.insert(testResults.errors, {
                file = filepath,
                test = "Statement Execution",
                error = tostring(result),
                statement = statement:sub(1, 100) .. "..."
            })
            return false
        end
    end
    
    testResults.passed = testResults.passed + 1
    return true
end

-- Test 3: Verify foreign key constraints
local function testForeignKeyConstraints()
    print("Testing foreign key constraints...")
    
    local query = [[
        SELECT 
            TABLE_NAME,
            CONSTRAINT_NAME,
            REFERENCED_TABLE_NAME
        FROM information_schema.KEY_COLUMN_USAGE
        WHERE TABLE_SCHEMA = DATABASE()
        AND REFERENCED_TABLE_NAME IS NOT NULL
        AND TABLE_NAME LIKE 'phone_%'
    ]]
    
    local success, result = executeSQL(query)
    if not success then
        testResults.failed = testResults.failed + 1
        table.insert(testResults.errors, {
            file = "N/A",
            test = "Foreign Keys",
            error = tostring(result)
        })
        return false
    end
    
    if #result == 0 then
        testResults.failed = testResults.failed + 1
        table.insert(testResults.errors, {
            file = "N/A",
            test = "Foreign Keys",
            error = "No foreign key constraints found"
        })
        return false
    end
    
    print("Found " .. #result .. " foreign key constraints")
    testResults.passed = testResults.passed + 1
    return true
end

-- Test 4: Verify indexes are created
local function testIndexes()
    print("Testing indexes...")
    
    local query = [[
        SELECT 
            TABLE_NAME,
            INDEX_NAME,
            COLUMN_NAME
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME LIKE 'phone_%'
        AND INDEX_NAME != 'PRIMARY'
    ]]
    
    local success, result = executeSQL(query)
    if not success then
        testResults.failed = testResults.failed + 1
        table.insert(testResults.errors, {
            file = "N/A",
            test = "Indexes",
            error = tostring(result)
        })
        return false
    end
    
    if #result == 0 then
        testResults.failed = testResults.failed + 1
        table.insert(testResults.errors, {
            file = "N/A",
            test = "Indexes",
            error = "No indexes found"
        })
        return false
    end
    
    print("Found " .. #result .. " indexes")
    testResults.passed = testResults.passed + 1
    return true
end

-- Test 5: Count tables created
local function testTableCount()
    print("Counting tables...")
    
    local query = [[
        SELECT COUNT(*) as count
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME LIKE 'phone_%'
    ]]
    
    local success, result = executeSQL(query)
    if not success then
        testResults.failed = testResults.failed + 1
        table.insert(testResults.errors, {
            file = "N/A",
            test = "Table Count",
            error = tostring(result)
        })
        return false
    end
    
    local count = result[1].count
    print("Found " .. count .. " tables")
    
    if count < 50 then
        testResults.failed = testResults.failed + 1
        table.insert(testResults.errors, {
            file = "N/A",
            test = "Table Count",
            error = "Expected 50+ tables, found " .. count
        })
        return false
    end
    
    testResults.passed = testResults.passed + 1
    return true
end

-- Main test execution
local function runTests()
    print("============================================================================")
    print("SQL Schema Validation Tests")
    print("============================================================================")
    
    -- Test individual SQL files
    print("\n--- Testing Individual SQL Files ---")
    for _, filepath in ipairs(SQL_FILES) do
        testSQLFileSyntax(filepath)
    end
    
    print("\n--- Executing SQL Files ---")
    for _, filepath in ipairs(SQL_FILES) do
        testSQLFileExecution(filepath)
    end
    
    -- Test database structure
    print("\n--- Testing Database Structure ---")
    testForeignKeyConstraints()
    testIndexes()
    testTableCount()
    
    -- Print results
    print("\n============================================================================")
    print("Test Results")
    print("============================================================================")
    print("Passed: " .. testResults.passed)
    print("Failed: " .. testResults.failed)
    
    if #testResults.errors > 0 then
        print("\nErrors:")
        for _, error in ipairs(testResults.errors) do
            print("  File: " .. error.file)
            print("  Test: " .. error.test)
            print("  Error: " .. error.error)
            if error.statement then
                print("  Statement: " .. error.statement)
            end
            print("")
        end
    end
    
    print("============================================================================")
    
    return testResults.failed == 0
end

-- Export for use in other scripts
return {
    runTests = runTests
}
