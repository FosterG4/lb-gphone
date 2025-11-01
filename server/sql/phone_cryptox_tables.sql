-- ============================================================================
-- CryptoX Application Database Tables
-- ============================================================================
-- Description: Tables for the CryptoX cryptocurrency trading application
-- Dependencies: phone_players (phone_number)
-- Created: 2025-11-01
-- ============================================================================
-- 
-- This file contains all tables related to cryptocurrency trading functionality:
-- - phone_cryptox_holdings: Current cryptocurrency holdings for each user
-- - phone_cryptox_transactions: Transaction history for buy/sell operations
-- - phone_cryptox_alerts: Price alert notifications
-- - phone_crypto: Legacy crypto holdings table (backward compatibility)
--
-- Decimal Precision:
-- - Crypto amounts use DECIMAL(20, 8) to support up to 8 decimal places
-- - Prices use DECIMAL(20, 2) for standard currency precision
-- - Fees use DECIMAL(20, 2) for transaction cost tracking
--
-- Order Types:
-- - market: Execute immediately at current market price
-- - limit: Execute when price reaches specified target
--
-- Alert Logic:
-- - 'above': Trigger when price rises above target_price
-- - 'below': Trigger when price falls below target_price
-- - Alerts remain active until triggered or manually disabled
-- ============================================================================

-- Table: phone_cryptox_holdings
-- Description: Stores current cryptocurrency holdings for each user
-- Relationships: References phone_players(phone_number)
CREATE TABLE IF NOT EXISTS phone_cryptox_holdings (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique holding record ID',
    owner_number VARCHAR(20) NOT NULL COMMENT 'Phone number of the holder',
    crypto_symbol VARCHAR(20) NOT NULL COMMENT 'Cryptocurrency symbol (e.g., BTC, ETH)',
    amount DECIMAL(20, 8) NOT NULL COMMENT 'Amount of cryptocurrency held (8 decimal precision)',
    avg_buy_price DECIMAL(20, 2) NOT NULL COMMENT 'Average purchase price per unit',
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',
    
    -- Indexes for performance
    INDEX idx_owner (owner_number),
    INDEX idx_symbol (crypto_symbol),
    
    -- Constraints
    UNIQUE KEY unique_holding (owner_number, crypto_symbol),
    FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Cryptocurrency holdings for CryptoX app';

-- Table: phone_cryptox_transactions
-- Description: Records all cryptocurrency buy and sell transactions
-- Relationships: References phone_players(phone_number)
CREATE TABLE IF NOT EXISTS phone_cryptox_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique transaction ID',
    owner_number VARCHAR(20) NOT NULL COMMENT 'Phone number of the trader',
    crypto_symbol VARCHAR(20) NOT NULL COMMENT 'Cryptocurrency symbol traded',
    transaction_type ENUM('buy', 'sell') NOT NULL COMMENT 'Transaction type: buy or sell',
    amount DECIMAL(20, 8) NOT NULL COMMENT 'Amount of cryptocurrency traded',
    price_per_unit DECIMAL(20, 2) NOT NULL COMMENT 'Price per unit at time of transaction',
    total_value DECIMAL(20, 2) NOT NULL COMMENT 'Total transaction value (amount * price)',
    order_type ENUM('market', 'limit') DEFAULT 'market' COMMENT 'Order type: market (immediate) or limit (target price)',
    fee DECIMAL(20, 2) DEFAULT 0 COMMENT 'Transaction fee charged',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Transaction timestamp',
    
    -- Indexes for performance
    INDEX idx_owner (owner_number),
    INDEX idx_symbol (crypto_symbol),
    INDEX idx_type (transaction_type),
    INDEX idx_created (created_at DESC),
    
    -- Constraints
    FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Transaction history for CryptoX app';

-- Table: phone_cryptox_alerts
-- Description: Price alert notifications for cryptocurrency price movements
-- Relationships: References phone_players(phone_number)
CREATE TABLE IF NOT EXISTS phone_cryptox_alerts (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique alert ID',
    owner_number VARCHAR(20) NOT NULL COMMENT 'Phone number of the alert owner',
    crypto_symbol VARCHAR(20) NOT NULL COMMENT 'Cryptocurrency symbol to monitor',
    alert_type ENUM('above', 'below') NOT NULL COMMENT 'Alert trigger: above (price rises) or below (price falls)',
    target_price DECIMAL(20, 2) NOT NULL COMMENT 'Target price that triggers the alert',
    is_active BOOLEAN DEFAULT TRUE COMMENT 'Whether alert is currently active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Alert creation timestamp',
    
    -- Indexes for performance
    INDEX idx_owner (owner_number),
    INDEX idx_symbol (crypto_symbol),
    INDEX idx_active (is_active),
    
    -- Constraints
    FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Price alerts for CryptoX app';

-- Table: phone_crypto (LEGACY)
-- Description: Legacy cryptocurrency holdings table for backward compatibility
-- Note: This table is maintained for backward compatibility with older versions.
--       New implementations should use phone_cryptox_holdings instead.
-- Relationships: No foreign key constraints (legacy design)
CREATE TABLE IF NOT EXISTS phone_crypto (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique holding record ID',
    owner_number VARCHAR(20) NOT NULL COMMENT 'Phone number of the holder',
    crypto_type VARCHAR(20) NOT NULL COMMENT 'Cryptocurrency type identifier',
    amount DECIMAL(20, 8) NOT NULL COMMENT 'Amount of cryptocurrency held',
    
    -- Indexes for performance
    INDEX idx_owner (owner_number),
    
    -- Constraints
    UNIQUE KEY unique_holding (owner_number, crypto_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Legacy crypto holdings table (use phone_cryptox_holdings for new implementations)';

-- ============================================================================
-- Common Queries
-- ============================================================================
--
-- Get all holdings for a user:
-- SELECT * FROM phone_cryptox_holdings WHERE owner_number = '555-0100';
--
-- Get transaction history for a user:
-- SELECT * FROM phone_cryptox_transactions 
-- WHERE owner_number = '555-0100' 
-- ORDER BY created_at DESC 
-- LIMIT 50;
--
-- Get active price alerts:
-- SELECT * FROM phone_cryptox_alerts 
-- WHERE owner_number = '555-0100' AND is_active = TRUE;
--
-- Calculate total portfolio value (requires current prices):
-- SELECT crypto_symbol, amount, avg_buy_price, 
--        (amount * avg_buy_price) as invested_value
-- FROM phone_cryptox_holdings 
-- WHERE owner_number = '555-0100';
--
-- Get buy/sell summary:
-- SELECT transaction_type, crypto_symbol, 
--        SUM(amount) as total_amount, 
--        SUM(total_value) as total_value,
--        SUM(fee) as total_fees
-- FROM phone_cryptox_transactions 
-- WHERE owner_number = '555-0100'
-- GROUP BY transaction_type, crypto_symbol;
-- ============================================================================
