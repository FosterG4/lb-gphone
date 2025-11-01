-- ============================================================================
-- Marketplace App Database Tables
-- ============================================================================
-- Description: Tables for the Marketplace app, which allows users to buy and
--              sell items, manage listings, process transactions, leave reviews,
--              and save favorite listings
-- Dependencies: phone_players (for foreign key relationships)
-- Created: 2024
-- ============================================================================

-- ============================================================================
-- Table: phone_marketplace_listings
-- ============================================================================
-- Description: Marketplace listings created by sellers. Each listing represents
--              an item for sale with title, description, price, photos, and status.
-- Relationships: 
--   - seller_number references phone_players(phone_number) with CASCADE delete
-- Listing Status Documentation:
--   - active: Listing is currently available for purchase
--   - sold: Item has been sold and listing is no longer available
--   - deleted: Seller has removed the listing
-- Category Examples:
--   - vehicles: Cars, motorcycles, boats
--   - electronics: Phones, computers, gaming
--   - furniture: Home and office furniture
--   - clothing: Apparel and accessories
--   - real_estate: Properties and land
--   - services: Professional services offered
--   - other: Miscellaneous items
-- Photos Storage:
--   - photos_json stores JSON array of photo URLs
--   - Format: ["url1", "url2", "url3"]
--   - First photo typically used as thumbnail
--   - Supports multiple photos per listing
-- Use Cases:
--   - Users can browse and search listings by category
--   - Sellers can manage their active listings
--   - Buyers can view listing details and contact sellers
--   - Listings can be filtered by price, category, and status
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_marketplace_listings (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique listing identifier',
    seller_number VARCHAR(20) NOT NULL COMMENT 'Phone number of seller',
    title VARCHAR(200) NOT NULL COMMENT 'Listing title/name',
    description TEXT COMMENT 'Detailed description of item',
    price DECIMAL(10, 2) NOT NULL COMMENT 'Item price (supports up to 99,999,999.99)',
    category VARCHAR(50) COMMENT 'Item category for filtering',
    photos_json TEXT COMMENT 'JSON array of photo URLs',
    status ENUM('active', 'sold', 'deleted') DEFAULT 'active' COMMENT 'Current listing status',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When listing was created',
    
    -- Indexes for performance
    INDEX idx_seller (seller_number) COMMENT 'Quick lookup of listings by seller',
    INDEX idx_category (category) COMMENT 'Filter listings by category',
    INDEX idx_status (status) COMMENT 'Filter active/sold/deleted listings',
    
    -- Foreign key relationships
    FOREIGN KEY (seller_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Marketplace item listings';

-- ============================================================================
-- Table: phone_marketplace_transactions
-- ============================================================================
-- Description: Records of marketplace transactions between buyers and sellers.
--              Tracks payment, status, fees, and completion timestamps.
-- Relationships:
--   - listing_id references phone_marketplace_listings(id) with CASCADE delete
--   - buyer_number references phone_players(phone_number) with CASCADE delete
--   - seller_number references phone_players(phone_number) with CASCADE delete
-- Transaction Status Documentation:
--   - pending: Transaction initiated but not yet completed
--   - completed: Transaction successfully completed, item delivered
--   - cancelled: Transaction was cancelled by buyer or seller
--   - disputed: Transaction is under dispute resolution
-- Transaction Flow:
--   1. Buyer initiates purchase (status: pending)
--   2. Payment is processed
--   3. Item is delivered/transferred
--   4. Transaction marked as completed (completed_at timestamp set)
--   5. Both parties can leave reviews
-- Payment Method Examples:
--   - cash: Cash payment in-game
--   - bank_transfer: Bank account transfer
--   - crypto: Cryptocurrency payment
--   - trade: Item trade/barter
-- Transaction Fee Logic:
--   - transaction_fee is the marketplace commission
--   - Typically a percentage of the transaction amount
--   - Fee is deducted from seller's payment
--   - Example: 5% fee on $1000 = $50 fee, seller receives $950
--   - Fee supports marketplace operations and moderation
-- Decimal Precision:
--   - amount: DECIMAL(15, 2) supports up to 9,999,999,999,999.99
--   - transaction_fee: DECIMAL(15, 2) for consistency
--   - Precision of 2 decimal places for currency accuracy
-- Use Cases:
--   - Track all marketplace transactions
--   - Calculate seller earnings and marketplace revenue
--   - Dispute resolution and transaction history
--   - Generate transaction reports and analytics
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_marketplace_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique transaction identifier',
    listing_id INT NOT NULL COMMENT 'Reference to the listing being purchased',
    buyer_number VARCHAR(20) NOT NULL COMMENT 'Phone number of buyer',
    seller_number VARCHAR(20) NOT NULL COMMENT 'Phone number of seller',
    amount DECIMAL(15, 2) NOT NULL COMMENT 'Transaction amount (item price)',
    status ENUM('pending', 'completed', 'cancelled', 'disputed') DEFAULT 'pending' COMMENT 'Transaction status',
    payment_method VARCHAR(50) DEFAULT 'cash' COMMENT 'Payment method used',
    transaction_fee DECIMAL(15, 2) DEFAULT 0 COMMENT 'Marketplace commission fee',
    notes TEXT COMMENT 'Additional transaction notes or details',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When transaction was initiated',
    completed_at TIMESTAMP NULL COMMENT 'When transaction was completed',
    
    -- Indexes for performance
    INDEX idx_listing (listing_id) COMMENT 'Quick lookup of transactions by listing',
    INDEX idx_buyer (buyer_number) COMMENT 'Quick lookup of buyer purchase history',
    INDEX idx_seller (seller_number) COMMENT 'Quick lookup of seller sales history',
    INDEX idx_status (status) COMMENT 'Filter transactions by status',
    INDEX idx_created (created_at DESC) COMMENT 'Sort transactions by recency',
    
    -- Foreign key relationships
    FOREIGN KEY (listing_id) REFERENCES phone_marketplace_listings(id) ON DELETE CASCADE,
    FOREIGN KEY (buyer_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (seller_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Marketplace transaction records';

-- ============================================================================
-- Table: phone_marketplace_reviews
-- ============================================================================
-- Description: Reviews and ratings left by buyers and sellers after completing
--              a marketplace transaction. Supports mutual review system.
-- Relationships:
--   - transaction_id references phone_marketplace_transactions(id) with CASCADE delete
--   - reviewer_number references phone_players(phone_number) with CASCADE delete
--   - reviewed_number references phone_players(phone_number) with CASCADE delete
-- Review Type Documentation:
--   - buyer: Review left by buyer about the seller
--   - seller: Review left by seller about the buyer
-- Rating System:
--   - rating: Integer from 1 to 5 (enforced by CHECK constraint)
--   - 1 star: Very poor experience
--   - 2 stars: Poor experience
--   - 3 stars: Average experience
--   - 4 stars: Good experience
--   - 5 stars: Excellent experience
-- Rating Calculation Methods:
--   - User's average rating = SUM(rating) / COUNT(rating)
--   - Calculate separately for buyer and seller ratings
--   - Example query for seller rating:
--     SELECT AVG(rating) FROM phone_marketplace_reviews 
--     WHERE reviewed_number = ? AND review_type = 'seller'
--   - Example query for buyer rating:
--     SELECT AVG(rating) FROM phone_marketplace_reviews 
--     WHERE reviewed_number = ? AND review_type = 'buyer'
--   - Round to 2 decimal places for display (e.g., 4.67 stars)
-- Mutual Review System:
--   - Each transaction can have up to 2 reviews (one from buyer, one from seller)
--   - UNIQUE constraint on (transaction_id, reviewer_number) prevents duplicate reviews
--   - Both parties can review each other independently
--   - Reviews are optional but encouraged for trust building
-- Use Cases:
--   - Build user reputation and trust scores
--   - Help buyers/sellers make informed decisions
--   - Identify problematic users for moderation
--   - Display user ratings on profiles and listings
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_marketplace_reviews (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique review identifier',
    transaction_id INT NOT NULL COMMENT 'Reference to the transaction being reviewed',
    reviewer_number VARCHAR(20) NOT NULL COMMENT 'Phone number of person leaving review',
    reviewed_number VARCHAR(20) NOT NULL COMMENT 'Phone number of person being reviewed',
    rating INT NOT NULL COMMENT 'Rating from 1 to 5 stars',
    review_text TEXT COMMENT 'Written review content (optional)',
    review_type ENUM('buyer', 'seller') NOT NULL COMMENT 'Whether reviewing as buyer or seller',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When review was submitted',
    
    -- Indexes for performance
    INDEX idx_transaction (transaction_id) COMMENT 'Quick lookup of reviews by transaction',
    INDEX idx_reviewer (reviewer_number) COMMENT 'Quick lookup of reviews written by user',
    INDEX idx_reviewed (reviewed_number) COMMENT 'Quick lookup of reviews received by user',
    INDEX idx_rating (rating) COMMENT 'Filter reviews by rating',
    INDEX idx_type (review_type) COMMENT 'Filter reviews by buyer/seller type',
    INDEX idx_created (created_at DESC) COMMENT 'Sort reviews by recency',
    
    -- Unique constraint to prevent duplicate reviews
    UNIQUE KEY unique_review (transaction_id, reviewer_number) COMMENT 'One review per user per transaction',
    
    -- Foreign key relationships
    FOREIGN KEY (transaction_id) REFERENCES phone_marketplace_transactions(id) ON DELETE CASCADE,
    FOREIGN KEY (reviewer_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (reviewed_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Marketplace transaction reviews and ratings';

-- ============================================================================
-- Table: phone_marketplace_favorites
-- ============================================================================
-- Description: User's saved/favorited marketplace listings for quick access.
--              Allows users to bookmark items they're interested in.
-- Relationships:
--   - listing_id references phone_marketplace_listings(id) with CASCADE delete
--   - user_number references phone_players(phone_number) with CASCADE delete
-- Favorite System:
--   - Users can favorite any active listing
--   - UNIQUE constraint prevents duplicate favorites
--   - Favorites are automatically removed if listing is deleted
--   - Users can view all their favorited items in one place
-- Use Cases:
--   - Save items for later consideration
--   - Create a wishlist of desired items
--   - Track price changes on favorited items
--   - Quick access to interesting listings
--   - Receive notifications when favorited items go on sale
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_marketplace_favorites (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique favorite identifier',
    listing_id INT NOT NULL COMMENT 'Reference to the favorited listing',
    user_number VARCHAR(20) NOT NULL COMMENT 'Phone number of user who favorited',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When listing was favorited',
    
    -- Indexes for performance
    INDEX idx_listing (listing_id) COMMENT 'Quick lookup of favorites by listing',
    INDEX idx_user (user_number) COMMENT 'Quick lookup of user favorites',
    INDEX idx_created (created_at DESC) COMMENT 'Sort favorites by recency',
    
    -- Unique constraint to prevent duplicate favorites
    UNIQUE KEY unique_favorite (listing_id, user_number) COMMENT 'One favorite per user per listing',
    
    -- Foreign key relationships
    FOREIGN KEY (listing_id) REFERENCES phone_marketplace_listings(id) ON DELETE CASCADE,
    FOREIGN KEY (user_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='User favorited marketplace listings';

-- ============================================================================
-- Common Queries for Marketplace Tables
-- ============================================================================
-- Get all active listings:
--   SELECT * FROM phone_marketplace_listings 
--   WHERE status = 'active' 
--   ORDER BY created_at DESC;
--
-- Get listings by category:
--   SELECT * FROM phone_marketplace_listings 
--   WHERE status = 'active' AND category = ? 
--   ORDER BY created_at DESC;
--
-- Get seller's listings:
--   SELECT * FROM phone_marketplace_listings 
--   WHERE seller_number = ? 
--   ORDER BY created_at DESC;
--
-- Get user's purchase history:
--   SELECT t.*, l.title, l.seller_number 
--   FROM phone_marketplace_transactions t
--   JOIN phone_marketplace_listings l ON t.listing_id = l.id
--   WHERE t.buyer_number = ? 
--   ORDER BY t.created_at DESC;
--
-- Get user's sales history:
--   SELECT t.*, l.title 
--   FROM phone_marketplace_transactions t
--   JOIN phone_marketplace_listings l ON t.listing_id = l.id
--   WHERE t.seller_number = ? 
--   ORDER BY t.created_at DESC;
--
-- Calculate user's seller rating:
--   SELECT AVG(rating) as avg_rating, COUNT(*) as review_count
--   FROM phone_marketplace_reviews 
--   WHERE reviewed_number = ? AND review_type = 'seller';
--
-- Calculate user's buyer rating:
--   SELECT AVG(rating) as avg_rating, COUNT(*) as review_count
--   FROM phone_marketplace_reviews 
--   WHERE reviewed_number = ? AND review_type = 'buyer';
--
-- Get user's favorited listings:
--   SELECT l.* 
--   FROM phone_marketplace_favorites f
--   JOIN phone_marketplace_listings l ON f.listing_id = l.id
--   WHERE f.user_number = ? AND l.status = 'active'
--   ORDER BY f.created_at DESC;
--
-- Check if user favorited a listing:
--   SELECT COUNT(*) as is_favorited
--   FROM phone_marketplace_favorites 
--   WHERE listing_id = ? AND user_number = ?;
--
-- Get transaction with reviews:
--   SELECT t.*, 
--          r1.rating as buyer_rating, r1.review_text as buyer_review,
--          r2.rating as seller_rating, r2.review_text as seller_review
--   FROM phone_marketplace_transactions t
--   LEFT JOIN phone_marketplace_reviews r1 ON t.id = r1.transaction_id AND r1.review_type = 'buyer'
--   LEFT JOIN phone_marketplace_reviews r2 ON t.id = r2.transaction_id AND r2.review_type = 'seller'
--   WHERE t.id = ?;
--
-- Calculate marketplace revenue (total fees):
--   SELECT SUM(transaction_fee) as total_revenue, COUNT(*) as completed_transactions
--   FROM phone_marketplace_transactions 
--   WHERE status = 'completed';
--
-- Get top-rated sellers:
--   SELECT reviewed_number, AVG(rating) as avg_rating, COUNT(*) as review_count
--   FROM phone_marketplace_reviews 
--   WHERE review_type = 'seller'
--   GROUP BY reviewed_number
--   HAVING review_count >= 5
--   ORDER BY avg_rating DESC, review_count DESC
--   LIMIT 10;
--
-- Search listings by title or description:
--   SELECT * FROM phone_marketplace_listings 
--   WHERE status = 'active' 
--   AND (title LIKE ? OR description LIKE ?)
--   ORDER BY created_at DESC;
-- ============================================================================
