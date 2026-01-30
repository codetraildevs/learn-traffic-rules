/**
 * Simple in-memory cache utility for frequently accessed, rarely changing data
 * Used to cache question counts per exam to avoid N+1 query patterns
 */

class SimpleCache {
  /**
   * Create a new cache instance
   * @param {number} ttlMs - Time to live in milliseconds (default: 5 minutes)
   */
  constructor(ttlMs = 300000) {
    this.cache = new Map();
    this.ttl = ttlMs;
  }

  /**
   * Get a value from the cache
   * @param {string} key - Cache key
   * @returns {*} Cached value or null if not found/expired
   */
  get(key) {
    const entry = this.cache.get(key);
    if (!entry) return null;
    
    // Check if entry has expired
    if (Date.now() > entry.expires) {
      this.cache.delete(key);
      return null;
    }
    
    return entry.value;
  }

  /**
   * Set a value in the cache
   * @param {string} key - Cache key
   * @param {*} value - Value to cache
   * @param {number} customTtl - Optional custom TTL for this entry
   */
  set(key, value, customTtl = null) {
    const ttl = customTtl || this.ttl;
    this.cache.set(key, {
      value,
      expires: Date.now() + ttl
    });
  }

  /**
   * Check if a key exists and is not expired
   * @param {string} key - Cache key
   * @returns {boolean}
   */
  has(key) {
    return this.get(key) !== null;
  }

  /**
   * Delete a specific key from the cache
   * @param {string} key - Cache key
   */
  delete(key) {
    this.cache.delete(key);
  }

  /**
   * Invalidate all cache entries that match a pattern
   * @param {string} pattern - Pattern to match (substring match)
   */
  invalidate(pattern) {
    for (const key of this.cache.keys()) {
      if (key.includes(pattern)) {
        this.cache.delete(key);
      }
    }
  }

  /**
   * Clear the entire cache
   */
  clear() {
    this.cache.clear();
  }

  /**
   * Get the number of items in the cache
   * @returns {number}
   */
  size() {
    return this.cache.size;
  }

  /**
   * Clean up expired entries (can be called periodically)
   */
  cleanup() {
    const now = Date.now();
    for (const [key, entry] of this.cache.entries()) {
      if (now > entry.expires) {
        this.cache.delete(key);
      }
    }
  }
}

// Cache for question counts per exam (5 minute TTL)
const questionCountCache = new SimpleCache(300000);

// Cache for all question counts map (5 minute TTL)
const allQuestionCountsCache = new SimpleCache(300000);

// Cache keys
const CACHE_KEYS = {
  ALL_QUESTION_COUNTS: 'all_question_counts',
  EXAM_QUESTION_COUNT: (examId) => `question_count_${examId}`
};

module.exports = {
  SimpleCache,
  questionCountCache,
  allQuestionCountsCache,
  CACHE_KEYS
};
