const multer = require('multer');
const path = require('path');

// Configure storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Determine destination based on field name or contentType query param
    if (file.fieldname === 'questionImage') {
      cb(null, 'uploads/question-images/');
    } else if (file.fieldname === 'file' && req.body.contentType) {
      // Course content files based on contentType
      const contentType = req.body.contentType.toLowerCase();
      if (contentType === 'image') {
        cb(null, 'uploads/courses/images/');
      } else if (contentType === 'audio') {
        cb(null, 'uploads/courses/audio/');
      } else if (contentType === 'video') {
        cb(null, 'uploads/courses/video/');
      } else {
        cb(null, 'uploads/courses/');
      }
    } else if (file.fieldname === 'image' && req.originalUrl && req.originalUrl.includes('/courses/upload-image')) {
      // Course image upload (from /api/courses/upload-image route)
      cb(null, 'uploads/courses/images/');
    } else {
      cb(null, 'uploads/');
    }
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    // Preserve original filename extension but add unique suffix
    const originalName = path.parse(file.originalname).name;
    const ext = path.extname(file.originalname);
    cb(null, originalName + '-' + uniqueSuffix + ext);
  }
});

// File filter
const fileFilter = (req, file, cb) => {
  console.log('📁 UPLOAD DEBUG: File received');
  console.log('   Original name:', file.originalname);
  console.log('   MIME type:', file.mimetype);
  console.log('   Field name:', file.fieldname);
  console.log('   Content type:', req.body.contentType);
  
  // Check if this is a course content file upload
  const isCourseContentFile = file.fieldname === 'file' && req.body.contentType;
  
  if (isCourseContentFile) {
    const contentType = req.body.contentType.toLowerCase();
    
    // Allow images for course content
    if (contentType === 'image' && file.mimetype.startsWith('image/')) {
      console.log('✅ UPLOAD DEBUG: Course content image file accepted');
      cb(null, true);
      return;
    }
    
    // Allow audio files for course content
    if (contentType === 'audio' && (
      file.mimetype.startsWith('audio/') ||
      file.mimetype === 'audio/mpeg' ||
      file.mimetype === 'audio/mp3' ||
      file.mimetype === 'audio/wav' ||
      file.mimetype === 'audio/ogg' ||
      file.mimetype === 'audio/m4a'
    )) {
      console.log('✅ UPLOAD DEBUG: Course content audio file accepted');
      cb(null, true);
      return;
    }
    
    // Allow video files for course content
    if (contentType === 'video' && (
      file.mimetype.startsWith('video/') ||
      file.mimetype === 'video/mp4' ||
      file.mimetype === 'video/avi' ||
      file.mimetype === 'video/quicktime' ||
      file.mimetype === 'video/webm'
    )) {
      console.log('✅ UPLOAD DEBUG: Course content video file accepted');
      cb(null, true);
      return;
    }
    
    console.log('❌ UPLOAD DEBUG: Course content file rejected - unsupported type');
    cb(new Error(`Invalid file type for contentType: ${contentType}`), false);
    return;
  }
  
  // Allow images
  if (file.mimetype.startsWith('image/')) {
    console.log('✅ UPLOAD DEBUG: Image file accepted');
    cb(null, true);
    return;
  }
  
  // Allow CSV files for bulk question upload
  if (file.mimetype === 'text/csv' || file.originalname.endsWith('.csv')) {
    console.log('✅ UPLOAD DEBUG: CSV file accepted');
    cb(null, true);
    return;
  }
  
  // Allow Excel files for bulk question upload
  if (file.mimetype === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' || 
      file.originalname.endsWith('.xlsx')) {
    console.log('✅ UPLOAD DEBUG: Excel file accepted');
    cb(null, true);
    return;
  }
  
  console.log('❌ UPLOAD DEBUG: File rejected - unsupported type');
  cb(new Error('Only image files, CSV, and Excel files are allowed!'), false);
};

// Configure multer with different limits based on file type
const getFileSizeLimit = (req) => {
  // For course content files, allow larger sizes (especially for video)
  if (req.body.contentType === 'video') {
    return 100 * 1024 * 1024; // 100MB for videos
  }
  if (req.body.contentType === 'audio') {
    return 50 * 1024 * 1024; // 50MB for audio
  }
  return 10 * 1024 * 1024; // 10MB default (for images and other files)
};

// Configure multer
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024 // 100MB limit (will be enforced per request in controller if needed)
  }
});

// Middleware for single file upload (images)
const uploadSingle = upload.single('image');

// Middleware for question image upload
const uploadQuestionImage = upload.single('questionImage');

// Middleware for course content file upload (images, audio, video)
const uploadCourseContentFile = upload.single('file');

// Middleware for course image upload
const uploadCourseImage = upload.single('image');

// Middleware for multiple files upload (bulk questions)
const uploadMultiple = upload.array('files', 5);

module.exports = {
  uploadSingle,
  uploadQuestionImage,
  uploadCourseContentFile,
  uploadCourseImage,
  uploadMultiple
};
