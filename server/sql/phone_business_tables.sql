-- ============================================================================
-- Business Pages App Database Tables
-- ============================================================================
-- Description: Tables for the Business Pages app, which allows users to create
--              and manage business pages, track followers, collect reviews and
--              ratings, and monitor page views for analytics
-- Dependencies: phone_players (for foreign key relationships)
-- Created: 2024
-- ============================================================================

-- ============================================================================
-- Table: phone_business_pages
-- ============================================================================
-- Description: Business pages created by users to promote their businesses,
--              services, or organizations. Each page includes business info,
--              location, photos, services, and aggregated metrics.
-- Relationships: 
--   - owner_number references phone_players(phone_number) with CASCADE delete
-- Business Status Documentation:
--   - active: Page is publicly visible and accepting interactions
--   - inactive: Page is temporarily hidden by owner
--   - suspended: Page has been suspended by moderation (policy violation)
-- Category Examples:
--   - restaurant: Restaurants, cafes, food trucks
--   - retail: Shops, stores, boutiques
--   - automotive: Car dealerships, repair shops, detailing
--   - real_estate: Real estate agencies, property management
--   - professional: Law firms, accounting, consulting
--   - entertainment: Clubs, venues, event spaces
--   - healthcare: Clinics, pharmacies, wellness centers
--   - services: General services and contractors
--   - other: Miscellaneous business types
-- Location Storage:
--   - location_x, location_y: Game world coordinates (FLOAT)
--   - Used for map markers and proximity searches
--   - Allows users to find nearby businesses
--   - Can be used for "businesses near me" features
-- Photos and Services Storage:
--   - photos: TEXT field storing JSON array of photo URLs
--   - services: TEXT field storing JSON array of service descriptions
--   - Format: ["url1", "url2", "url3"] or ["service1", "service2"]
--   - First photo typically used as page banner/cover
--   - Services list helps users understand offerings
-- Aggregated Metrics:
--   - followers_count: Total number of followers (updated via triggers or app logic)
--   - rating: Average rating from all reviews (DECIMAL 3,2 = X.XX format, 0.00-5.00)
--   - reviews_count: Total number of reviews received
--   - These are denormalized for performance (avoid COUNT queries on every page load)
-- Rating Calculation Logic:
--   - rating = SUM(all review ratings) / COUNT(reviews)
--   - Stored as DECIMAL(3,2) for precision (e.g., 4.67)
--   - Updated when new reviews are added or removed
--   - Display as stars in UI (e.g., 4.5 stars = 4.5/5.0)
--   - Default 0.00 for pages with no reviews
-- Use Cases:
--   - Business owners create pages to promote their services
--   - Users can discover and follow local businesses
--   - Businesses can showcase photos, services, and contact info
--   - Users can leave reviews and ratings
--   - Analytics via view tracking and follower counts
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_business_pages (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique business page identifier',
    owner_number VARCHAR(20) NOT NULL COMMENT 'Phone number of page owner',
    name VARCHAR(200) NOT NULL COMMENT 'Business name',
    description TEXT COMMENT 'Business description and details',
    category VARCHAR(50) COMMENT 'Business category for filtering',
    contact_number VARCHAR(20) COMMENT 'Business contact phone number',
    location_x FLOAT COMMENT 'Business location X coordinate',
    location_y FLOAT COMMENT 'Business location Y coordinate',
    photos TEXT COMMENT 'JSON array of business photo URLs',
    services TEXT COMMENT 'JSON array of services offered',
    followers_count INT DEFAULT 0 COMMENT 'Total number of followers (denormalized)',
    rating DECIMAL(3,2) DEFAULT 0.00 COMMENT 'Average rating from reviews (0.00-5.00)',
    reviews_count INT DEFAULT 0 COMMENT 'Total number of reviews (denormalized)',
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active' COMMENT 'Page visibility status',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When page was created',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',
    
    -- Indexes for performance
    INDEX idx_owner (owner_number) COMMENT 'Quick lookup of pages by owner',
    INDEX idx_category (category) COMMENT 'Filter pages by business category',
    INDEX idx_status (status) COMMENT 'Filter active/inactive/suspended pages',
    INDEX idx_rating (rating) COMMENT 'Sort pages by rating (highest rated)',
    
    -- Foreign key relationships
    FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Business pages for promoting businesses and services';

-- ============================================================================
-- Table: phone_page_followers
-- ============================================================================
-- Description: Tracks follower relationships between users and business pages.
--              Users can follow pages to receive updates and show support.
-- Relationships:
--   - page_id references phone_business_pages(id) with CASCADE delete
--   - follower_number references phone_players(phone_number) with CASCADE delete
-- Follower System Logic:
--   - Users can follow any active business page
--   - UNIQUE constraint prevents duplicate follows
--   - Following is automatically removed if page or user is deleted
--   - Followers can unfollow at any time
--   - Page owner can see list of all followers
-- Follower Count Updates:
--   - When a user follows: INCREMENT phone_business_pages.followers_count
--   - When a user unfollows: DECREMENT phone_business_pages.followers_count
--   - Can be implemented via triggers or application logic
--   - Example update query:
--     UPDATE phone_business_pages 
--     SET followers_count = (SELECT COUNT(*) FROM phone_page_followers WHERE page_id = ?)
--     WHERE id = ?
-- Use Cases:
--   - Users follow businesses they're interested in
--   - Businesses can notify followers of updates, promotions, events
--   - Display follower count as social proof
--   - Show "You follow this page" indicator in UI
--   - Generate follower lists for business owners
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_page_followers (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique follower relationship identifier',
    page_id INT NOT NULL COMMENT 'Reference to the business page',
    follower_number VARCHAR(20) NOT NULL COMMENT 'Phone number of follower',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When user followed the page',
    
    -- Indexes for performance
    INDEX idx_page (page_id) COMMENT 'Quick lookup of followers by page',
    INDEX idx_follower (follower_number) COMMENT 'Quick lookup of pages followed by user',
    
    -- Unique constraint to prevent duplicate follows
    UNIQUE KEY unique_follow (page_id, follower_number) COMMENT 'One follow per user per page',
    
    -- Foreign key relationships
    FOREIGN KEY (page_id) REFERENCES phone_business_pages(id) ON DELETE CASCADE,
    FOREIGN KEY (follower_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Business page follower relationships';

-- ============================================================================
-- Table: phone_page_reviews
-- ============================================================================
-- Description: Reviews and ratings left by users for business pages. Each user
--              can leave one review per page with a 1-5 star rating and text.
-- Relationships:
--   - page_id references phone_business_pages(id) with CASCADE delete
--   - reviewer_number references phone_players(phone_number) with CASCADE delete
-- Rating System:
--   - rating: Integer from 1 to 5 (enforced by CHECK constraint)
--   - 1 star: Very poor experience
--   - 2 stars: Poor experience
--   - 3 stars: Average experience
--   - 4 stars: Good experience
--   - 5 stars: Excellent experience
-- Rating Calculation Methods:
--   - Page average rating = SUM(rating) / COUNT(rating)
--   - Store result in phone_business_pages.rating (DECIMAL 3,2)
--   - Update when reviews are added, modified, or deleted
--   - Example calculation query:
--     SELECT AVG(rating) as avg_rating, COUNT(*) as review_count
--     FROM phone_page_reviews 
--     WHERE page_id = ?
--   - Round to 2 decimal places for display (e.g., 4.67 stars)
--   - Display as "4.7 out of 5 stars (123 reviews)"
-- Review Validation Rules:
--   - UNIQUE constraint: One review per user per page
--   - Users cannot review their own business pages (enforced in app logic)
--   - Rating must be between 1 and 5 (CHECK constraint)
--   - Review text is optional but encouraged
--   - Reviews can be edited by the reviewer
--   - Page owners can respond to reviews (stored separately or in app logic)
-- Review Moderation:
--   - Reviews can be flagged for inappropriate content
--   - Moderation handled at application level
--   - Flagged reviews may be hidden or removed
--   - Review history maintained for dispute resolution
-- Use Cases:
--   - Users share experiences with businesses
--   - Build business reputation and trust
--   - Help other users make informed decisions
--   - Provide feedback to business owners
--   - Identify high-quality businesses (sort by rating)
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_page_reviews (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique review identifier',
    page_id INT NOT NULL COMMENT 'Reference to the business page',
    reviewer_number VARCHAR(20) NOT NULL COMMENT 'Phone number of reviewer',
    rating INT NOT NULL COMMENT 'Rating from 1 to 5 stars',
    review_text TEXT COMMENT 'Written review content (optional)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When review was submitted',
    
    -- Indexes for performance
    INDEX idx_page (page_id) COMMENT 'Quick lookup of reviews by page',
    INDEX idx_reviewer (reviewer_number) COMMENT 'Quick lookup of reviews by user',
    INDEX idx_rating (rating) COMMENT 'Filter reviews by rating',
    INDEX idx_created (created_at DESC) COMMENT 'Sort reviews by recency',
    
    -- Unique constraint to prevent duplicate reviews
    UNIQUE KEY unique_review (page_id, reviewer_number) COMMENT 'One review per user per page',
    
    -- Foreign key relationships
    FOREIGN KEY (page_id) REFERENCES phone_business_pages(id) ON DELETE CASCADE,
    FOREIGN KEY (reviewer_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Business page reviews and ratings';

-- ============================================================================
-- Table: phone_page_views
-- ============================================================================
-- Description: Tracks page views for analytics. Records each time a user views
--              a business page, enabling view count metrics and analytics.
-- Relationships:
--   - page_id references phone_business_pages(id) with CASCADE delete
--   - viewer_number references phone_players(phone_number) with CASCADE delete
-- View Tracking Logic:
--   - Record a view each time a user opens a business page
--   - Multiple views by same user are tracked separately
--   - Allows calculation of total views, unique viewers, and view trends
--   - Can be used for "trending" or "popular" page rankings
-- Analytics Use Cases:
--   - Total page views: COUNT(*) WHERE page_id = ?
--   - Unique viewers: COUNT(DISTINCT viewer_number) WHERE page_id = ?
--   - Views in last 7 days: COUNT(*) WHERE page_id = ? AND viewed_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
--   - Most viewed pages: SELECT page_id, COUNT(*) as views FROM phone_page_views GROUP BY page_id ORDER BY views DESC
--   - View trends over time: GROUP BY DATE(viewed_at) for daily view counts
-- Privacy Considerations:
--   - View tracking is anonymous to page viewers
--   - Only page owners can see view analytics
--   - Individual viewer identities may be shown to page owners
--   - Consider data retention policies (e.g., delete views older than 1 year)
-- Performance Considerations:
--   - This table can grow large with high traffic
--   - Consider partitioning by date for better performance
--   - May want to aggregate old data and archive
--   - Index on viewed_at DESC for recent views queries
-- Use Cases:
--   - Business owners track page performance
--   - Identify popular pages and trending businesses
--   - Measure marketing campaign effectiveness
--   - Understand user engagement patterns
--   - Generate analytics dashboards for page owners
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_page_views (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique view record identifier',
    page_id INT NOT NULL COMMENT 'Reference to the business page',
    viewer_number VARCHAR(20) NOT NULL COMMENT 'Phone number of viewer',
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When page was viewed',
    
    -- Indexes for performance
    INDEX idx_page (page_id) COMMENT 'Quick lookup of views by page',
    INDEX idx_viewer (viewer_number) COMMENT 'Quick lookup of pages viewed by user',
    INDEX idx_viewed (viewed_at DESC) COMMENT 'Sort views by recency',
    
    -- Foreign key relationships
    FOREIGN KEY (page_id) REFERENCES phone_business_pages(id) ON DELETE CASCADE,
    FOREIGN KEY (viewer_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Business page view tracking for analytics';

-- ============================================================================
-- Common Queries for Business Pages Tables
-- ============================================================================
-- Get all active business pages:
--   SELECT * FROM phone_business_pages 
--   WHERE status = 'active' 
--   ORDER BY created_at DESC;
--
-- Get pages by category:
--   SELECT * FROM phone_business_pages 
--   WHERE status = 'active' AND category = ? 
--   ORDER BY rating DESC, followers_count DESC;
--
-- Get user's business pages:
--   SELECT * FROM phone_business_pages 
--   WHERE owner_number = ? 
--   ORDER BY created_at DESC;
--
-- Get top-rated businesses:
--   SELECT * FROM phone_business_pages 
--   WHERE status = 'active' AND reviews_count >= 5
--   ORDER BY rating DESC, reviews_count DESC
--   LIMIT 10;
--
-- Get most followed businesses:
--   SELECT * FROM phone_business_pages 
--   WHERE status = 'active'
--   ORDER BY followers_count DESC
--   LIMIT 10;
--
-- Get pages followed by user:
--   SELECT p.* 
--   FROM phone_page_followers f
--   JOIN phone_business_pages p ON f.page_id = p.id
--   WHERE f.follower_number = ? AND p.status = 'active'
--   ORDER BY f.created_at DESC;
--
-- Check if user follows a page:
--   SELECT COUNT(*) as is_following
--   FROM phone_page_followers 
--   WHERE page_id = ? AND follower_number = ?;
--
-- Get page followers list:
--   SELECT f.follower_number, f.created_at, p.phone_number
--   FROM phone_page_followers f
--   JOIN phone_players p ON f.follower_number = p.phone_number
--   WHERE f.page_id = ?
--   ORDER BY f.created_at DESC;
--
-- Get page reviews:
--   SELECT r.*, p.phone_number as reviewer_name
--   FROM phone_page_reviews r
--   JOIN phone_players p ON r.reviewer_number = p.phone_number
--   WHERE r.page_id = ?
--   ORDER BY r.created_at DESC;
--
-- Calculate page rating:
--   SELECT AVG(rating) as avg_rating, COUNT(*) as review_count
--   FROM phone_page_reviews 
--   WHERE page_id = ?;
--
-- Update page rating and review count:
--   UPDATE phone_business_pages p
--   SET rating = (SELECT COALESCE(AVG(rating), 0) FROM phone_page_reviews WHERE page_id = p.id),
--       reviews_count = (SELECT COUNT(*) FROM phone_page_reviews WHERE page_id = p.id)
--   WHERE id = ?;
--
-- Get page view count:
--   SELECT COUNT(*) as total_views, COUNT(DISTINCT viewer_number) as unique_viewers
--   FROM phone_page_views 
--   WHERE page_id = ?;
--
-- Get page views in last 7 days:
--   SELECT COUNT(*) as recent_views
--   FROM phone_page_views 
--   WHERE page_id = ? 
--   AND viewed_at >= DATE_SUB(NOW(), INTERVAL 7 DAY);
--
-- Get daily view counts for a page:
--   SELECT DATE(viewed_at) as view_date, COUNT(*) as views
--   FROM phone_page_views 
--   WHERE page_id = ?
--   GROUP BY DATE(viewed_at)
--   ORDER BY view_date DESC
--   LIMIT 30;
--
-- Get trending pages (most views in last 7 days):
--   SELECT p.*, COUNT(v.id) as recent_views
--   FROM phone_business_pages p
--   LEFT JOIN phone_page_views v ON p.id = v.page_id 
--     AND v.viewed_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
--   WHERE p.status = 'active'
--   GROUP BY p.id
--   ORDER BY recent_views DESC
--   LIMIT 10;
--
-- Search pages by name or description:
--   SELECT * FROM phone_business_pages 
--   WHERE status = 'active' 
--   AND (name LIKE ? OR description LIKE ?)
--   ORDER BY rating DESC, followers_count DESC;
--
-- Find nearby businesses (within radius):
--   SELECT *, 
--          SQRT(POW(location_x - ?, 2) + POW(location_y - ?, 2)) as distance
--   FROM phone_business_pages 
--   WHERE status = 'active'
--   HAVING distance <= ?
--   ORDER BY distance ASC;
--
-- Get user's review for a page:
--   SELECT * FROM phone_page_reviews 
--   WHERE page_id = ? AND reviewer_number = ?;
--
-- Get pages with no reviews:
--   SELECT * FROM phone_business_pages 
--   WHERE status = 'active' AND reviews_count = 0
--   ORDER BY created_at DESC;
--
-- Get pages by rating range:
--   SELECT * FROM phone_business_pages 
--   WHERE status = 'active' 
--   AND rating >= ? AND rating <= ?
--   ORDER BY rating DESC;
-- ============================================================================
