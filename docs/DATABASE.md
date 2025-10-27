# Database Schema Documentation

This document provides detailed information about the database schema used by the FiveM Smartphone NUI resource.

## Overview

The resource uses MySQL via oxmysql for data persistence. All tables are automatically created on resource start if they don't exist.

## Database Tables

### Table Relationships

```
phone_players (1) ──< (N) phone_contacts
      │
      ├──< (N) phone_messages (sender)
      │
      ├──< (N) phone_messages (receiver)
      │
      ├──< (N) phone_call_history (caller)
      │
      ├──< (N) phone_call_history (receiver)
      │
      ├──< (N) phone_tweets
      │
      └──< (N) phone_crypto
```

## Table Definitions

### phone_players

Stores player identifiers and their assigned phone numbers.

```sql
CREATE TABLE IF NOT EXISTS phone_players (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(50) UNIQUE NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_identifier (identifier),
    INDEX idx_phone_number (phone_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Columns:**
- `id` - Auto-incrementing primary key
- `identifier` - Unique player identifier (license, steam, etc.)
- `phone_number` - Unique phone number assigned to player
- `created_at` - Timestamp when player first joined

**Indexes:**
- `idx_identifier` - Fast lookup by player identifier
- `idx_phone_number` - Fast lookup by phone number

**Usage:**
- Created when a player joins the server for the first time
- Used to map player identifiers to phone numbers
- Referenced by all other tables via phone_number

---

### phone_contacts

Stores player contact lists.

```sql
CREATE TABLE IF NOT EXISTS phone_contacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_number VARCHAR(20) NOT NULL,
    contact_name VARCHAR(100) NOT NULL,
    contact_number VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_owner (owner_number),
    FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Columns:**
- `id` - Auto-incrementing primary key
- `owner_number` - Phone number of the contact list owner
- `contact_name` - Display name for the contact
- `contact_number` - Phone number of the contact
- `created_at` - Timestamp when contact was added

**Indexes:**
- `idx_owner` - Fast lookup of all contacts for a player

**Foreign Keys:**
- `owner_number` references `phone_players(phone_number)` with CASCADE delete

**Usage:**
- Created when a player adds a contact
- Updated when a player edits a contact name
- Deleted when a player removes a contact or when the owner is deleted

---

### phone_messages

Stores all text messages between players.

```sql
CREATE TABLE IF NOT EXISTS phone_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_number VARCHAR(20) NOT NULL,
    receiver_number VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_conversation (sender_number, receiver_number),
    INDEX idx_receiver (receiver_number, is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Columns:**
- `id` - Auto-incrementing primary key
- `sender_number` - Phone number of message sender
- `receiver_number` - Phone number of message receiver
- `message` - Message content (max 500 characters by default)
- `is_read` - Whether the receiver has read the message
- `created_at` - Timestamp when message was sent

**Indexes:**
- `idx_conversation` - Fast lookup of messages between two players
- `idx_receiver` - Fast lookup of unread messages for a player

**Usage:**
- Created when a player sends a message
- Updated when a player reads a message (is_read = TRUE)
- Queried to display conversation threads
- Used for offline message delivery

---

### phone_call_history

Stores call logs for all players.

```sql
CREATE TABLE IF NOT EXISTS phone_call_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    caller_number VARCHAR(20) NOT NULL,
    receiver_number VARCHAR(20) NOT NULL,
    duration INT DEFAULT 0,
    call_type ENUM('incoming', 'outgoing', 'missed') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_caller (caller_number),
    INDEX idx_receiver (receiver_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Columns:**
- `id` - Auto-incrementing primary key
- `caller_number` - Phone number of call initiator
- `receiver_number` - Phone number of call receiver
- `duration` - Call duration in seconds (0 for missed calls)
- `call_type` - Type of call from receiver's perspective
  - `incoming` - Answered incoming call
  - `outgoing` - Outgoing call that was answered
  - `missed` - Unanswered incoming call
- `created_at` - Timestamp when call was initiated

**Indexes:**
- `idx_caller` - Fast lookup of calls made by a player
- `idx_receiver` - Fast lookup of calls received by a player

**Usage:**
- Created when a call is initiated
- Updated with duration when call ends
- Queried to display call history

---

### phone_tweets

Stores social media posts for the Twitter app.

```sql
CREATE TABLE IF NOT EXISTS phone_tweets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    author_number VARCHAR(20) NOT NULL,
    author_name VARCHAR(100) NOT NULL,
    content VARCHAR(280) NOT NULL,
    likes INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_created (created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Columns:**
- `id` - Auto-incrementing primary key
- `author_number` - Phone number of tweet author
- `author_name` - Display name of author
- `content` - Tweet content (max 280 characters)
- `likes` - Number of likes the tweet has received
- `created_at` - Timestamp when tweet was posted

**Indexes:**
- `idx_created` - Fast lookup of recent tweets (DESC order)

**Usage:**
- Created when a player posts a tweet
- Updated when a player likes a tweet (likes incremented)
- Queried to display the public feed

---

### phone_crypto

Stores cryptocurrency holdings for players.

```sql
CREATE TABLE IF NOT EXISTS phone_crypto (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_number VARCHAR(20) NOT NULL,
    crypto_type VARCHAR(20) NOT NULL,
    amount DECIMAL(20, 8) NOT NULL,
    INDEX idx_owner (owner_number),
    UNIQUE KEY unique_holding (owner_number, crypto_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Columns:**
- `id` - Auto-incrementing primary key
- `owner_number` - Phone number of crypto holder
- `crypto_type` - Cryptocurrency symbol (BTC, ETH, DOGE, etc.)
- `amount` - Amount of crypto held (up to 8 decimal places)

**Indexes:**
- `idx_owner` - Fast lookup of all crypto holdings for a player

**Unique Constraints:**
- `unique_holding` - Ensures one row per player per crypto type

**Usage:**
- Created when a player first buys a cryptocurrency
- Updated when a player buys or sells crypto
- Deleted when amount reaches zero (optional)
- Queried to display portfolio

## Data Types

### VARCHAR Lengths

- `identifier` (50) - Accommodates various identifier types (license, steam, etc.)
- `phone_number` (20) - Supports various phone number formats with separators
- `contact_name` (100) - Reasonable length for contact names
- `author_name` (100) - Matches contact name length
- `crypto_type` (20) - Supports cryptocurrency symbols and names

### TEXT vs VARCHAR

- `message` - TEXT type allows for longer messages without fixed limit
- `content` - VARCHAR(280) enforces Twitter-style character limit

### DECIMAL Precision

- `amount` DECIMAL(20, 8) - Supports large crypto amounts with 8 decimal precision (Bitcoin standard)

## Maintenance

### Cleanup Queries

**Delete old messages (older than 30 days):**
```sql
DELETE FROM phone_messages 
WHERE created_at < DATE_SUB(NOW(), INTERVAL 30 DAY);
```

**Delete old call history (older than 90 days):**
```sql
DELETE FROM phone_call_history 
WHERE created_at < DATE_SUB(NOW(), INTERVAL 90 DAY);
```

**Delete old tweets (older than 7 days):**
```sql
DELETE FROM phone_tweets 
WHERE created_at < DATE_SUB(NOW(), INTERVAL 7 DAY);
```

### Optimization

**Analyze tables for query optimization:**
```sql
ANALYZE TABLE phone_players, phone_contacts, phone_messages, 
             phone_call_history, phone_tweets, phone_crypto;
```

**Check table sizes:**
```sql
SELECT 
    table_name AS 'Table',
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.TABLES
WHERE table_schema = 'your_database_name'
    AND table_name LIKE 'phone_%'
ORDER BY (data_length + index_length) DESC;
```

## Backup

### Export all phone data:
```bash
mysqldump -u username -p database_name phone_players phone_contacts phone_messages phone_call_history phone_tweets phone_crypto > phone_backup.sql
```

### Import backup:
```bash
mysql -u username -p database_name < phone_backup.sql
```

## Migration

If you need to modify the schema after deployment, create migration scripts:

**Example: Add a new column to phone_contacts**
```sql
ALTER TABLE phone_contacts 
ADD COLUMN favorite BOOLEAN DEFAULT FALSE AFTER contact_number;

ALTER TABLE phone_contacts 
ADD INDEX idx_favorites (owner_number, favorite);
```

Always test migrations on a backup database first!

## Performance Considerations

### Index Usage

All tables have appropriate indexes for common queries:
- Lookups by phone number
- Conversation queries (sender + receiver)
- Recent items (created_at DESC)

### Query Optimization Tips

1. **Use prepared statements** - oxmysql handles this automatically
2. **Limit result sets** - Use LIMIT for feeds and history
3. **Cache frequently accessed data** - Player phone numbers, contact lists
4. **Batch operations** - Group multiple inserts when possible
5. **Avoid SELECT *** - Only query needed columns

### Monitoring

Monitor slow queries in MySQL:
```sql
-- Enable slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1; -- Log queries taking > 1 second

-- View slow queries
SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;
```

## Security

### SQL Injection Prevention

- Always use parameterized queries via oxmysql
- Never concatenate user input into SQL strings
- Validate and sanitize all inputs before database operations

### Data Privacy

- Phone numbers and identifiers are sensitive data
- Consider implementing data retention policies
- Comply with applicable privacy regulations (GDPR, etc.)

### Access Control

- Database user should have minimal required permissions
- Use separate database user for this resource
- Restrict access to production database

## Troubleshooting

### Tables not created

Check server console for errors. Common issues:
- Database user lacks CREATE TABLE permission
- Database connection failed
- oxmysql not installed or started

### Foreign key errors

If you see foreign key constraint errors:
- Ensure parent records exist before creating child records
- Check that phone_number values match between tables
- Verify CASCADE delete is working correctly

### Character encoding issues

If you see garbled text:
- Ensure database uses utf8mb4 charset
- Check that tables use utf8mb4_unicode_ci collation
- Verify client connection uses utf8mb4

### Performance issues

If queries are slow:
- Check that indexes exist (SHOW INDEX FROM table_name)
- Analyze query execution plans (EXPLAIN SELECT ...)
- Consider adding composite indexes for common query patterns
- Monitor table sizes and implement cleanup policies
