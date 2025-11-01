-- ============================================================================
-- Wallet Application Database Tables
-- ============================================================================
-- Description: Tables for the Wallet application (unified banking solution)
--              that provide enhanced financial functionality including 
--              transaction tracking, budget management, and recurring payment 
--              automation. Consolidates functionality from Bank and Bankr apps.
--              Includes legacy banking table for backward compatibility.
-- Dependencies: phone_players (phone_number)
-- Created: 2025-11-01
-- Updated: 2025-11-01 (Renamed from phone_bankr_tables.sql to reflect Wallet app)
-- ============================================================================
-- 
-- Note: Table names remain as "phone_bankr_*" for backward compatibility with
--       existing data and code, but this file is named "phone_wallet_tables.sql"
--       to reflect the current unified Wallet application.
-- ============================================================================

-- ============================================================================
-- Table: phone_bankr_transactions
-- ============================================================================
-- Description: Enhanced wallet transaction log that tracks all financial
--              transactions with detailed categorization and metadata. Supports
--              both credit (incoming) and debit (outgoing) transactions with
--              optional recipient tracking for transfers.
-- Relationships: Foreign key to phone_players(phone_number) with CASCADE delete
--                to automatically remove transactions when a player is deleted.
-- Financial Precision: Uses DECIMAL(15, 2) for amounts, supporting values up to
--                      999,999,999,999.99 with 2 decimal places for cents.
-- Transaction Types: 
--   - credit: Money received (deposits, transfers in, income)
--   - debit: Money sent (withdrawals, transfers out, payments)
-- Categories: general, food, transport, entertainment, bills, shopping, etc.
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_bankr_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each transaction',
    owner_number VARCHAR(20) NOT NULL COMMENT 'Phone number of the account owner',
    account_id VARCHAR(50) NOT NULL COMMENT 'Wallet account identifier',
    transaction_type ENUM('credit', 'debit') NOT NULL COMMENT 'Type of transaction: credit (in) or debit (out)',
    amount DECIMAL(15, 2) NOT NULL COMMENT 'Transaction amount with 2 decimal precision',
    description VARCHAR(255) COMMENT 'Transaction description or memo',
    category VARCHAR(50) DEFAULT 'general' COMMENT 'Transaction category for budget tracking',
    recipient_number VARCHAR(20) COMMENT 'Phone number of recipient for transfers',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp when transaction occurred',
    
    -- Indexes for performance optimization
    INDEX idx_owner (owner_number),
    INDEX idx_account (account_id),
    INDEX idx_type (transaction_type),
    INDEX idx_category (category),
    INDEX idx_created (created_at DESC),
    
    -- Foreign key constraints
    FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Table: phone_bankr_budgets
-- ============================================================================
-- Description: Budget tracking system that allows users to set spending limits
--              for different expense categories over specific time periods.
--              Tracks current spending against monthly limits and supports
--              multiple budget periods per category.
-- Relationships: Foreign key to phone_players(phone_number) with CASCADE delete
--                to automatically remove budgets when a player is deleted.
-- Financial Precision: Uses DECIMAL(15, 2) for monetary amounts with 2 decimal
--                      places for cents.
-- Budget Periods: Defined by period_start and period_end dates, typically
--                 monthly but can be customized. The unique constraint ensures
--                 only one budget per category per period per user.
-- Categories: Must match transaction categories (food, transport, entertainment,
--             bills, shopping, etc.) for accurate spending tracking.
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_bankr_budgets (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each budget',
    owner_number VARCHAR(20) NOT NULL COMMENT 'Phone number of the budget owner',
    category VARCHAR(50) NOT NULL COMMENT 'Expense category for this budget',
    monthly_limit DECIMAL(15, 2) NOT NULL COMMENT 'Maximum spending limit for the period',
    current_spent DECIMAL(15, 2) DEFAULT 0 COMMENT 'Current amount spent in this period',
    period_start DATE NOT NULL COMMENT 'Start date of the budget period',
    period_end DATE NOT NULL COMMENT 'End date of the budget period',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp when budget was created',
    
    -- Indexes for performance optimization
    INDEX idx_owner (owner_number),
    INDEX idx_category (category),
    INDEX idx_period (period_start, period_end),
    
    -- Unique constraint to prevent duplicate budgets
    UNIQUE KEY unique_budget (owner_number, category, period_start),
    
    -- Foreign key constraints
    FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Table: phone_bankr_recurring
-- ============================================================================
-- Description: Automated recurring payment system that schedules and tracks
--              regular payments (subscriptions, bills, etc.). Supports weekly,
--              monthly, and quarterly payment frequencies with automatic
--              execution when next_payment date is reached.
-- Relationships: Foreign key to phone_players(phone_number) with CASCADE delete
--                to automatically remove recurring payments when a player is deleted.
-- Financial Precision: Uses DECIMAL(15, 2) for payment amounts with 2 decimal
--                      places for cents.
-- Payment Frequencies:
--   - weekly: Payment every 7 days
--   - monthly: Payment every 30 days (or calendar month)
--   - quarterly: Payment every 90 days (or 3 calendar months)
-- Automation: System checks for payments where next_payment <= NOW() and
--             is_active = TRUE, processes them, then updates next_payment
--             based on frequency.
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_bankr_recurring (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each recurring payment',
    owner_number VARCHAR(20) NOT NULL COMMENT 'Phone number of the payment owner',
    name VARCHAR(100) NOT NULL COMMENT 'Name or description of the recurring payment',
    amount DECIMAL(15, 2) NOT NULL COMMENT 'Payment amount with 2 decimal precision',
    frequency ENUM('weekly', 'monthly', 'quarterly') NOT NULL COMMENT 'Payment frequency schedule',
    recipient_number VARCHAR(20) NOT NULL COMMENT 'Phone number of the payment recipient',
    next_payment TIMESTAMP NOT NULL COMMENT 'Next scheduled payment date and time',
    is_active BOOLEAN DEFAULT TRUE COMMENT 'Whether this recurring payment is active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp when recurring payment was created',
    
    -- Indexes for performance optimization
    INDEX idx_owner (owner_number),
    INDEX idx_next_payment (next_payment),
    INDEX idx_active (is_active),
    
    -- Foreign key constraints
    FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Table: phone_bank_transactions (LEGACY)
-- ============================================================================
-- Description: Legacy banking transaction table maintained for backward
--              compatibility with older versions of the phone system. New
--              implementations should use phone_bankr_transactions instead.
--              This table uses a simpler schema with just sender, receiver,
--              and amount fields.
-- Relationships: No foreign key constraints for backward compatibility.
-- Financial Precision: Uses DECIMAL(10, 2) for amounts, supporting values up to
--                      99,999,999.99 with 2 decimal places.
-- Migration Note: Consider migrating data to phone_bankr_transactions for
--                 enhanced features like categorization and budget tracking.
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_bank_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each transaction',
    sender_number VARCHAR(20) NOT NULL COMMENT 'Phone number of the sender',
    receiver_number VARCHAR(20) NOT NULL COMMENT 'Phone number of the receiver',
    amount DECIMAL(10, 2) NOT NULL COMMENT 'Transaction amount with 2 decimal precision',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp when transaction occurred',
    
    -- Indexes for performance optimization
    INDEX idx_sender (sender_number),
    INDEX idx_receiver (receiver_number),
    INDEX idx_created (created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
