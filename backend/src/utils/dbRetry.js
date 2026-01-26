/**
 * Database retry utility for handling lock timeouts and transient errors
 */

/**
 * Check if error is a lock timeout error
 */
function isLockTimeoutError(error) {
  return error.code === 'ER_LOCK_WAIT_TIMEOUT' ||
         error.errno === 1205 ||
         error.message?.includes('Lock wait timeout') ||
         error.message?.includes('ER_LOCK_WAIT_TIMEOUT');
}

/**
 * Check if error is a duplicate entry error (can retry with new values)
 */
function isDuplicateEntryError(error) {
  return error.code === 'ER_DUP_ENTRY' ||
         error.errno === 1062 ||
         error.message?.includes('Duplicate entry');
}

/**
 * Retry database operation with exponential backoff
 * @param {Function} operation - Async function to retry
 * @param {Object} options - Retry options
 * @param {number} options.maxRetries - Maximum number of retries (default: 3)
 * @param {number} options.retryDelay - Initial retry delay in ms (default: 100)
 * @param {boolean} options.retryOnLockTimeout - Retry on lock timeout (default: true)
 * @param {boolean} options.retryOnDuplicate - Retry on duplicate entry (default: false)
 * @param {Function} options.onRetry - Callback called before each retry
 * @returns {Promise} Result of the operation
 */
async function retryDbOperation(operation, options = {}) {
  const {
    maxRetries = 3,
    retryDelay = 100,
    retryOnLockTimeout = true,
    retryOnDuplicate = false,
    onRetry = null
  } = options;

  let lastError;
  
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error;
      
      const isLockTimeout = isLockTimeoutError(error);
      const isDuplicate = isDuplicateEntryError(error);
      
      // Check if we should retry
      const shouldRetry = 
        (isLockTimeout && retryOnLockTimeout && attempt < maxRetries) ||
        (isDuplicate && retryOnDuplicate && attempt < maxRetries);
      
      if (!shouldRetry) {
        // Don't retry - throw immediately
        throw error;
      }
      
      // Calculate delay with exponential backoff
      const delay = retryDelay * Math.pow(2, attempt - 1);
      
      // Call retry callback if provided
      if (onRetry) {
        onRetry(attempt, maxRetries, delay, error);
      } else {
        console.warn(`⚠️ Database operation failed (attempt ${attempt}/${maxRetries}), retrying in ${delay}ms:`, 
          isLockTimeout ? 'Lock timeout' : isDuplicate ? 'Duplicate entry' : error.message);
      }
      
      // Wait before retrying
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  
  // All retries exhausted
  throw lastError;
}

module.exports = {
  retryDbOperation,
  isLockTimeoutError,
  isDuplicateEntryError
};

