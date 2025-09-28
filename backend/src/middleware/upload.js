const multer = require('multer');
const path = require('path');

// Configure storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Determine destination based on field name
    if (file.fieldname === 'questionImage') {
      cb(null, 'uploads/question-images/');
    } else {
      cb(null, 'uploads/');
    }
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

// File filter
const fileFilter = (req, file, cb) => {
  console.log('📁 UPLOAD DEBUG: File received');
  console.log('   Original name:', file.originalname);
  console.log('   MIME type:', file.mimetype);
  console.log('   Field name:', file.fieldname);
  
  // Allow images
  if (file.mimetype.startsWith('image/')) {
    console.log('✅ UPLOAD DEBUG: Image file accepted');
    cb(null, true);
  }
  // Allow CSV files for bulk question upload
  else if (file.mimetype === 'text/csv' || file.originalname.endsWith('.csv')) {
    console.log('✅ UPLOAD DEBUG: CSV file accepted');
    cb(null, true);
  }
  // Allow Excel files for bulk question upload
  else if (file.mimetype === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' || 
           file.originalname.endsWith('.xlsx')) {
    console.log('✅ UPLOAD DEBUG: Excel file accepted');
    cb(null, true);
  }
  else {
    console.log('❌ UPLOAD DEBUG: File rejected - unsupported type');
    cb(new Error('Only image files, CSV, and Excel files are allowed!'), false);
  }
};

// Configure multer
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  }
});

// Middleware for single file upload (images)
const uploadSingle = upload.single('image');

// Middleware for question image upload
const uploadQuestionImage = upload.single('questionImage');

// Middleware for multiple files upload (bulk questions)
const uploadMultiple = upload.array('files', 5);

module.exports = {
  uploadSingle,
  uploadQuestionImage,
  uploadMultiple
};
