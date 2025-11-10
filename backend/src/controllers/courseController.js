const Course = require('../models/Course');
const CourseContent = require('../models/CourseContent');
const CourseProgress = require('../models/CourseProgress');
const CourseContentProgress = require('../models/CourseContentProgress');
const AccessCode = require('../models/AccessCode');
const { validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const { Op } = require('sequelize');

class CourseController {
  /**
   * Get all courses (with filters)
   * Note: Access control is handled by the frontend based on global access period
   * Backend returns all courses; frontend determines which ones user can access
   */
  async getAllCourses(req, res) {
    try {
      const { category, difficulty, courseType, isActive, includeContents } = req.query;
      const userId = req.user?.userId;

      // Build where clause
      const whereClause = {};
      if (category) whereClause.category = category;
      if (difficulty) whereClause.difficulty = difficulty.toUpperCase();
      if (courseType) whereClause.courseType = courseType.toLowerCase();
      if (isActive !== undefined) whereClause.isActive = isActive === 'true';

      const courses = await Course.findAll({
        where: whereClause,
        order: [['createdAt', 'DESC']]
      });

      // Get content counts and format courses
      const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
      const coursesWithCounts = await Promise.all(
        courses.map(async (course) => {
          // Always get content count (even if contents are not included)
          const contentCount = await CourseContent.count({
            where: { courseId: course.id }
          });

          const courseData = course.toJSON();
          courseData.contentCount = contentCount;

          // Convert relative image URLs to full URLs
          if (courseData.courseImageUrl && !courseData.courseImageUrl.startsWith('http')) {
            if (courseData.courseImageUrl.startsWith('/uploads/')) {
              courseData.courseImageUrl = `${baseUrl}${courseData.courseImageUrl}`;
            } else if (courseData.courseImageUrl.startsWith('uploads/')) {
              courseData.courseImageUrl = `${baseUrl}/${courseData.courseImageUrl}`;
            } else if (!courseData.courseImageUrl.includes('/')) {
              // If it's just a filename, prepend the default upload path
              courseData.courseImageUrl = `${baseUrl}/uploads/course-images/${courseData.courseImageUrl}`;
            }
          }

          // Fetch contents if explicitly requested
          if (includeContents === 'true') {
            try {
              const contents = await CourseContent.findAll({
                where: { courseId: course.id },
                order: [['displayOrder', 'ASC']]
              });

              // Convert contents to JSON and process URLs
              courseData.contents = contents.map(content => {
                const contentData = content.toJSON();
                
                // Convert content URLs to full URLs for images, videos, and audio
                if (contentData.contentType !== 'text' && contentData.contentType !== 'link') {
                  if (contentData.content && !contentData.content.startsWith('http')) {
                    if (contentData.content.startsWith('/uploads/')) {
                      contentData.content = `${baseUrl}${contentData.content}`;
                    } else if (contentData.content.startsWith('uploads/')) {
                      contentData.content = `${baseUrl}/${contentData.content}`;
                    } else if (!contentData.content.includes('/')) {
                      // If it's just a filename, prepend the default upload path based on content type
                      const uploadPath = contentData.contentType === 'image' 
                        ? '/uploads/course-images/' 
                        : contentData.contentType === 'video' 
                          ? '/uploads/course-videos/' 
                          : '/uploads/course-audio/';
                      contentData.content = `${baseUrl}${uploadPath}${contentData.content}`;
                    }
                  }
                }
                return contentData;
              });
            } catch (contentError) {
              console.error(`Error fetching contents for course ${course.id}:`, contentError);
              courseData.contents = [];
            }
          } else {
            // If contents were not requested, set to empty array
            courseData.contents = [];
          }

          return courseData;
        })
      );

      res.json({
        success: true,
        message: 'Courses retrieved successfully',
        data: coursesWithCounts
      });
    } catch (error) {
      console.error('Get courses error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get course by ID (with contents if requested)
   * Note: Access control is handled by the frontend based on global access period
   * Backend returns course data; frontend determines if user can access it
   */
  async getCourseById(req, res) {
    try {
      const { id } = req.params;
      const { includeContents } = req.query;
      const userId = req.user?.userId;

      const course = await Course.findByPk(id);

      if (!course) {
        return res.status(404).json({
          success: false,
          message: 'Course not found'
        });
      }

      // Always get content count (even if contents are not included)
      const contentCount = await CourseContent.count({
        where: { courseId: course.id }
      });

      const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
      const courseData = course.toJSON();
      courseData.contentCount = contentCount;

      // Convert relative image URLs to full URLs
      if (courseData.courseImageUrl && !courseData.courseImageUrl.startsWith('http')) {
        if (courseData.courseImageUrl.startsWith('/uploads/')) {
          courseData.courseImageUrl = `${baseUrl}${courseData.courseImageUrl}`;
        } else if (courseData.courseImageUrl.startsWith('uploads/')) {
          courseData.courseImageUrl = `${baseUrl}/${courseData.courseImageUrl}`;
        } else if (!courseData.courseImageUrl.includes('/')) {
          // If it's just a filename, prepend the default upload path
          courseData.courseImageUrl = `${baseUrl}/uploads/course-images/${courseData.courseImageUrl}`;
        }
      }

      // Fetch contents if explicitly requested
      if (includeContents === 'true') {
        try {
          // Manually fetch contents to ensure they're always included
          const contents = await CourseContent.findAll({
            where: { courseId: course.id },
            order: [['displayOrder', 'ASC']]
          });

          // Convert contents to JSON and process URLs
          courseData.contents = contents.map(content => {
            const contentData = content.toJSON();
            
            // Convert content URLs to full URLs for images, videos, and audio
            if (contentData.contentType !== 'text' && contentData.contentType !== 'link') {
              if (contentData.content && !contentData.content.startsWith('http')) {
                if (contentData.content.startsWith('/uploads/')) {
                  contentData.content = `${baseUrl}${contentData.content}`;
                } else if (contentData.content.startsWith('uploads/')) {
                  contentData.content = `${baseUrl}/${contentData.content}`;
                } else if (!contentData.content.includes('/')) {
                  // If it's just a filename, prepend the default upload path based on content type
                  const uploadPath = contentData.contentType === 'image' 
                    ? '/uploads/course-images/' 
                    : contentData.contentType === 'video' 
                      ? '/uploads/course-videos/' 
                      : '/uploads/course-audio/';
                  contentData.content = `${baseUrl}${uploadPath}${contentData.content}`;
                }
              }
            }
            return contentData;
          });

          console.log(`✅ Fetched ${courseData.contents.length} contents for course ${id}`);
        } catch (contentError) {
          console.error('Error fetching course contents:', contentError);
          // If contents fetch fails, set to empty array but don't fail the request
          courseData.contents = [];
        }
      } else {
        // If contents were not requested, set to empty array
        courseData.contents = [];
      }

      // Get user progress if userId is available
      if (userId) {
        const progress = await CourseProgress.findOne({
          where: { userId, courseId: id }
        });
        if (progress) {
          courseData.progress = progress.toJSON();
        }
      }

      res.json({
        success: true,
        message: 'Course retrieved successfully',
        data: courseData
      });
    } catch (error) {
      console.error('Get course error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Create a new course (Admin only)
   */
  async createCourse(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { title, description, category, difficulty, courseType, courseImageUrl, isActive, contents } = req.body;

      // Validate that at least one text content exists
      if (contents && contents.length > 0) {
        const hasTextContent = contents.some(content => content.contentType === 'text');
        if (!hasTextContent) {
          return res.status(400).json({
            success: false,
            message: 'Course must have at least one text content item'
          });
        }
      }

      // Create course
      const course = await Course.create({
        id: uuidv4(),
        title,
        description: description || null,
        category: category || null,
        difficulty: difficulty || 'MEDIUM',
        courseType: courseType || 'free',
        courseImageUrl: courseImageUrl || null,
        isActive: isActive !== undefined ? isActive : true
      });

      // Create course contents if provided
      if (contents && contents.length > 0) {
        const courseContents = await Promise.all(
          contents.map((content, index) => {
            return CourseContent.create({
              id: uuidv4(),
              courseId: course.id,
              contentType: content.contentType || 'text',
              content: content.content,
              title: content.title || null,
              displayOrder: content.displayOrder !== undefined ? content.displayOrder : index
            });
          })
        );

        // Content count is calculated dynamically, no need to update
      }

      // Get course with contents
      const courseWithContents = await Course.findByPk(course.id, {
        include: [
          {
            model: CourseContent,
            as: 'contents',
            required: false,
            separate: true,
            order: [['displayOrder', 'ASC']]
          }
        ]
      });

      const contentCount = await CourseContent.count({
        where: { courseId: course.id }
      });

      const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
      const courseData = courseWithContents.toJSON();
      courseData.contentCount = contentCount;

      // Convert relative image URLs to full URLs
      if (courseData.courseImageUrl && !courseData.courseImageUrl.startsWith('http')) {
        if (courseData.courseImageUrl.startsWith('/uploads/')) {
          courseData.courseImageUrl = `${baseUrl}${courseData.courseImageUrl}`;
        } else if (courseData.courseImageUrl.startsWith('uploads/')) {
          courseData.courseImageUrl = `${baseUrl}/${courseData.courseImageUrl}`;
        } else if (!courseData.courseImageUrl.includes('/')) {
          courseData.courseImageUrl = `${baseUrl}/uploads/course-images/${courseData.courseImageUrl}`;
        }
      }

      // Sort contents and convert URLs
      if (courseData.contents) {
        courseData.contents.sort((a, b) => a.displayOrder - b.displayOrder);
        courseData.contents = courseData.contents.map(content => {
          if (content.contentType !== 'text' && content.contentType !== 'link') {
            if (content.content && !content.content.startsWith('http')) {
              if (content.content.startsWith('/uploads/')) {
                content.content = `${baseUrl}${content.content}`;
              } else if (content.content.startsWith('uploads/')) {
                content.content = `${baseUrl}/${content.content}`;
              } else if (!content.content.includes('/')) {
                const uploadPath = content.contentType === 'image' 
                  ? '/uploads/course-images/' 
                  : content.contentType === 'video' 
                    ? '/uploads/course-videos/' 
                    : '/uploads/course-audio/';
                content.content = `${baseUrl}${uploadPath}${content.content}`;
              }
            }
          }
          return content;
        });
      }

      res.status(201).json({
        success: true,
        message: 'Course created successfully',
        data: courseData
      });
    } catch (error) {
      console.error('Create course error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Update a course (Admin only)
   */
  async updateCourse(req, res) {
    try {
      const { id } = req.params;
      const { title, description, category, difficulty, courseType, courseImageUrl, isActive, contents } = req.body;

      const course = await Course.findByPk(id);
      if (!course) {
        return res.status(404).json({
          success: false,
          message: 'Course not found'
        });
      }

      // Update course fields
      const updateData = {};
      if (title !== undefined) updateData.title = title;
      if (description !== undefined) updateData.description = description;
      if (category !== undefined) updateData.category = category;
      if (difficulty !== undefined) updateData.difficulty = difficulty;
      if (courseType !== undefined) updateData.courseType = courseType;
      if (courseImageUrl !== undefined) updateData.courseImageUrl = courseImageUrl;
      if (isActive !== undefined) updateData.isActive = isActive;

      await Course.update(updateData, { where: { id } });

      // Update contents if provided
      if (contents !== undefined) {
        // Validate that at least one text content exists
        if (contents.length > 0) {
          const hasTextContent = contents.some(content => content.contentType === 'text');
          if (!hasTextContent) {
            return res.status(400).json({
              success: false,
              message: 'Course must have at least one text content item'
            });
          }
        }

        // Delete existing contents
        await CourseContent.destroy({ where: { courseId: id } });

        // Create new contents
        if (contents.length > 0) {
          await Promise.all(
            contents.map((content, index) => {
              return CourseContent.create({
                id: uuidv4(),
                courseId: id,
                contentType: content.contentType || 'text',
                content: content.content,
                title: content.title || null,
                displayOrder: content.displayOrder !== undefined ? content.displayOrder : index
              });
            })
          );
        }
      }

      // Get updated course with contents
      const updatedCourse = await Course.findByPk(id, {
        include: [
          {
            model: CourseContent,
            as: 'contents',
            required: false,
            separate: true,
            order: [['displayOrder', 'ASC']]
          }
        ]
      });

      const contentCount = await CourseContent.count({
        where: { courseId: id }
      });

      const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
      const courseData = updatedCourse.toJSON();
      courseData.contentCount = contentCount;

      // Convert relative image URLs to full URLs
      if (courseData.courseImageUrl && !courseData.courseImageUrl.startsWith('http')) {
        if (courseData.courseImageUrl.startsWith('/uploads/')) {
          courseData.courseImageUrl = `${baseUrl}${courseData.courseImageUrl}`;
        } else if (courseData.courseImageUrl.startsWith('uploads/')) {
          courseData.courseImageUrl = `${baseUrl}/${courseData.courseImageUrl}`;
        } else if (!courseData.courseImageUrl.includes('/')) {
          courseData.courseImageUrl = `${baseUrl}/uploads/course-images/${courseData.courseImageUrl}`;
        }
      }

      // Sort contents and convert URLs
      if (courseData.contents) {
        courseData.contents.sort((a, b) => a.displayOrder - b.displayOrder);
        courseData.contents = courseData.contents.map(content => {
          if (content.contentType !== 'text' && content.contentType !== 'link') {
            if (content.content && !content.content.startsWith('http')) {
              if (content.content.startsWith('/uploads/')) {
                content.content = `${baseUrl}${content.content}`;
              } else if (content.content.startsWith('uploads/')) {
                content.content = `${baseUrl}/${content.content}`;
              } else if (!content.content.includes('/')) {
                const uploadPath = content.contentType === 'image' 
                  ? '/uploads/course-images/' 
                  : content.contentType === 'video' 
                    ? '/uploads/course-videos/' 
                    : '/uploads/course-audio/';
                content.content = `${baseUrl}${uploadPath}${content.content}`;
              }
            }
          }
          return content;
        });
      }

      res.json({
        success: true,
        message: 'Course updated successfully',
        data: courseData
      });
    } catch (error) {
      console.error('Update course error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Delete a course (Admin only)
   */
  async deleteCourse(req, res) {
    try {
      const { id } = req.params;

      const course = await Course.findByPk(id);
      if (!course) {
        return res.status(404).json({
          success: false,
          message: 'Course not found'
        });
      }

      // Delete course (contents will be deleted via CASCADE)
      await Course.destroy({ where: { id } });

      res.json({
        success: true,
        message: 'Course deleted successfully'
      });
    } catch (error) {
      console.error('Delete course error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get user's courses (courses user is enrolled in)
   */
  async getUserCourses(req, res) {
    try {
      const userId = req.user.userId;

      // Get user's course progress
      const userProgress = await CourseProgress.findAll({
        where: { userId },
        include: [
          {
            model: Course,
            as: 'course',
            required: true,
            include: [
              {
                model: CourseContent,
                as: 'contents',
                required: false,
                separate: true,
                order: [['displayOrder', 'ASC']]
              }
            ]
          }
        ]
      });

      const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
      const courses = userProgress.map(progress => {
        const courseData = progress.course.toJSON();
        const progressData = progress.toJSON();

        // Convert relative image URLs to full URLs
        if (courseData.courseImageUrl && !courseData.courseImageUrl.startsWith('http')) {
          if (courseData.courseImageUrl.startsWith('/uploads/')) {
            courseData.courseImageUrl = `${baseUrl}${courseData.courseImageUrl}`;
          } else if (courseData.courseImageUrl.startsWith('uploads/')) {
            courseData.courseImageUrl = `${baseUrl}/${courseData.courseImageUrl}`;
          } else if (!courseData.courseImageUrl.includes('/')) {
            courseData.courseImageUrl = `${baseUrl}/uploads/course-images/${courseData.courseImageUrl}`;
          }
        }

        // Sort contents and convert URLs
        if (courseData.contents) {
          courseData.contents.sort((a, b) => a.displayOrder - b.displayOrder);
          courseData.contents = courseData.contents.map(content => {
            if (content.contentType !== 'text' && content.contentType !== 'link') {
              if (content.content && !content.content.startsWith('http')) {
                if (content.content.startsWith('/uploads/')) {
                  content.content = `${baseUrl}${content.content}`;
                } else if (content.content.startsWith('uploads/')) {
                  content.content = `${baseUrl}/${content.content}`;
                } else if (!content.content.includes('/')) {
                  const uploadPath = content.contentType === 'image' 
                    ? '/uploads/course-images/' 
                    : content.contentType === 'video' 
                      ? '/uploads/course-videos/' 
                      : '/uploads/course-audio/';
                  content.content = `${baseUrl}${uploadPath}${content.content}`;
                }
              }
            }
            return content;
          });
        }

        courseData.progress = progressData;
        return courseData;
      });

      res.json({
        success: true,
        message: 'User courses retrieved successfully',
        data: courses
      });
    } catch (error) {
      console.error('Get user courses error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get course progress for a user
   */
  async getCourseProgress(req, res) {
    try {
      const { courseId } = req.params;
      const userId = req.user.userId;

      const progress = await CourseProgress.findOne({
        where: { userId, courseId },
        include: [
          {
            model: Course,
            as: 'course',
            required: true
          }
        ]
      });

      if (!progress) {
        return res.status(404).json({
          success: false,
          message: 'Course progress not found'
        });
      }

      res.json({
        success: true,
        message: 'Course progress retrieved successfully',
        data: progress.toJSON()
      });
    } catch (error) {
      console.error('Get course progress error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Enroll in a course
   */
  async enrollInCourse(req, res) {
    try {
      const { courseId } = req.params;
      const userId = req.user.userId;

      // Check if course exists
      const course = await Course.findByPk(courseId);
      if (!course) {
        return res.status(404).json({
          success: false,
          message: 'Course not found'
        });
      }

      // Check if user has GLOBAL access (for paid courses)
      // Global access: If user has paid once, they get access to ALL paid courses
      if (course.courseType === 'paid') {
        // Check for active access code (not expired) - this provides global access to all paid courses
        const activeAccessCode = await AccessCode.findOne({
          where: {
            userId: userId,
            expiresAt: {
              [Op.gt]: new Date() // Access code must not be expired
            }
          },
          order: [['expiresAt', 'DESC']] // Get the most recent access code
        });

        if (!activeAccessCode) {
          return res.status(403).json({
            success: false,
            message: 'Access denied. Please purchase access to unlock all paid courses. Once you pay, you will have access to all paid courses.'
          });
        }
        
        // User has global access - they can enroll in any paid course
        console.log(`✅ GLOBAL ACCESS: User ${userId} has active access code, granting access to paid course ${courseId}`);
      }

      // Check if user is already enrolled
      let progress = await CourseProgress.findOne({
        where: { userId, courseId }
      });

      if (!progress) {
        // Get total content count
        const totalContentCount = await CourseContent.count({
          where: { courseId }
        });

        // Create progress record
        progress = await CourseProgress.create({
          id: uuidv4(),
          userId,
          courseId,
          completedContentCount: 0,
          totalContentCount,
          progressPercentage: 0.00,
          isCompleted: false,
          lastAccessedAt: new Date()
        });
      } else {
        // Update last accessed time
        progress.lastAccessedAt = new Date();
        await progress.save();
      }

      res.json({
        success: true,
        message: 'Successfully enrolled in course',
        data: progress.toJSON()
      });
    } catch (error) {
      console.error('Enroll in course error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Mark content as completed
   */
  async markContentComplete(req, res) {
    try {
      const { courseId, contentId } = req.params;
      const userId = req.user.userId;
      const { timeSpent } = req.body;

      // Check if content exists
      const content = await CourseContent.findOne({
        where: { id: contentId, courseId }
      });

      if (!content) {
        return res.status(404).json({
          success: false,
          message: 'Course content not found'
        });
      }

      // Get or create progress
      let progress = await CourseProgress.findOne({
        where: { userId, courseId }
      });

      if (!progress) {
        const totalContentCount = await CourseContent.count({
          where: { courseId }
        });

        progress = await CourseProgress.create({
          id: uuidv4(),
          userId,
          courseId,
          completedContentCount: 0,
          totalContentCount,
          progressPercentage: 0.00,
          isCompleted: false
        });
      }

      // Check if content is already completed
      let contentProgress = await CourseContentProgress.findOne({
        where: { userId, courseContentId: contentId }
      });

      if (!contentProgress) {
        // Mark content as completed
        contentProgress = await CourseContentProgress.create({
          id: uuidv4(),
          userId,
          courseId,
          courseContentId: contentId,
          isCompleted: true,
          completedAt: new Date(),
          timeSpent: timeSpent || 0
        });

        // Update course progress
        progress.completedContentCount += 1;
        progress.progressPercentage = progress.totalContentCount > 0 
          ? (progress.completedContentCount / progress.totalContentCount) * 100 
          : 0;
        progress.lastAccessedAt = new Date();

        // Check if course is completed
        if (progress.completedContentCount >= progress.totalContentCount) {
          progress.isCompleted = true;
          progress.completedAt = new Date();
        }

        await progress.save();
      }

      res.json({
        success: true,
        message: 'Content marked as completed',
        data: {
          contentProgress: contentProgress.toJSON(),
          courseProgress: progress.toJSON()
        }
      });
    } catch (error) {
      console.error('Mark content complete error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
}

module.exports = new CourseController();

