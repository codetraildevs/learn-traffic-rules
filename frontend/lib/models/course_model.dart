// Removed json_annotation import - using manual JSON serialization

enum CourseContentType {
  text,
  image,
  audio,
  video,
  link;

  String get displayName {
    switch (this) {
      case CourseContentType.text:
        return 'Text';
      case CourseContentType.image:
        return 'Image';
      case CourseContentType.audio:
        return 'Audio';
      case CourseContentType.video:
        return 'Video';
      case CourseContentType.link:
        return 'Link';
    }
  }

  static CourseContentType? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'text':
        return CourseContentType.text;
      case 'image':
        return CourseContentType.image;
      case 'audio':
        return CourseContentType.audio;
      case 'video':
        return CourseContentType.video;
      case 'link':
        return CourseContentType.link;
      default:
        return null;
    }
  }

  String toJson() => name;
}

enum CourseType {
  free,
  paid;

  String get displayName {
    switch (this) {
      case CourseType.free:
        return 'Free';
      case CourseType.paid:
        return 'Paid';
    }
  }

  static CourseType? fromString(String? value) {
    if (value == null) return CourseType.free;
    switch (value.toLowerCase()) {
      case 'free':
        return CourseType.free;
      case 'paid':
        return CourseType.paid;
      default:
        return CourseType.free;
    }
  }

  String toJson() => name;
}

class CourseContent {
  final String id;
  final String courseId;
  final CourseContentType contentType;
  final String
  content; // Text content, image URL, audio URL, video URL, or link URL
  final String? title; // Optional title for the content
  final int displayOrder; // Order in which content appears
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CourseContent({
    required this.id,
    required this.courseId,
    required this.contentType,
    required this.content,
    this.title,
    required this.displayOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory CourseContent.fromJson(Map<String, dynamic> json) {
    return CourseContent(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      contentType:
          CourseContentType.fromString(json['contentType'] as String) ??
          CourseContentType.text,
      content: json['content'] as String,
      title: json['title'] as String?,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'contentType': contentType.name,
      'content': content,
      'title': title,
      'displayOrder': displayOrder,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  CourseContent copyWith({
    String? id,
    String? courseId,
    CourseContentType? contentType,
    String? content,
    String? title,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseContent(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      contentType: contentType ?? this.contentType,
      content: content ?? this.content,
      title: title ?? this.title,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Course {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final String difficulty;
  final CourseType courseType; // free or paid
  final bool isActive;
  final String? courseImageUrl;
  final int? contentCount; // Number of content items
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<CourseContent>? contents; // Optional: loaded with course details

  const Course({
    required this.id,
    required this.title,
    this.description,
    this.category,
    required this.difficulty,
    required this.courseType,
    required this.isActive,
    this.courseImageUrl,
    this.contentCount,
    this.createdAt,
    this.updatedAt,
    this.contents,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String? ?? 'medium',
      courseType:
          CourseType.fromString(json['courseType'] as String?) ??
          CourseType.free,
      isActive: json['isActive'] as bool? ?? true,
      courseImageUrl: json['courseImageUrl'] as String?,
      contentCount: (json['contentCount'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      contents: json['contents'] != null
          ? (json['contents'] as List)
                .map((e) => CourseContent.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'courseType': courseType.name,
      'isActive': isActive,
      'courseImageUrl': courseImageUrl,
      'contentCount': contentCount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'contents': contents?.map((e) => e.toJson()).toList(),
    };
  }

  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? difficulty,
    CourseType? courseType,
    bool? isActive,
    String? courseImageUrl,
    int? contentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CourseContent>? contents,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      courseType: courseType ?? this.courseType,
      isActive: isActive ?? this.isActive,
      courseImageUrl: courseImageUrl ?? this.courseImageUrl,
      contentCount: contentCount ?? this.contentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contents: contents ?? this.contents,
    );
  }

  String get difficultyDisplay {
    switch (difficulty.toUpperCase()) {
      case 'EASY':
        return 'Easy';
      case 'MEDIUM':
        return 'Medium';
      case 'HARD':
        return 'Hard';
      default:
        return difficulty;
    }
  }

  String get statusDisplay => isActive ? 'Active' : 'Inactive';

  bool get isFree => courseType == CourseType.free;
  bool get isPaid => courseType == CourseType.paid;
}

class CreateCourseRequest {
  final String title;
  final String? description;
  final String? category;
  final String difficulty;
  final CourseType courseType;
  final bool isActive;
  final String? courseImageUrl;
  final List<CreateCourseContentRequest>? contents;

  const CreateCourseRequest({
    required this.title,
    this.description,
    this.category,
    required this.difficulty,
    required this.courseType,
    required this.isActive,
    this.courseImageUrl,
    this.contents,
  });

  factory CreateCourseRequest.fromJson(Map<String, dynamic> json) {
    return CreateCourseRequest(
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String,
      courseType:
          CourseType.fromString(json['courseType'] as String?) ??
          CourseType.free,
      isActive: json['isActive'] as bool? ?? true,
      courseImageUrl: json['courseImageUrl'] as String?,
      contents: json['contents'] != null
          ? (json['contents'] as List)
                .map(
                  (e) => CreateCourseContentRequest.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'courseType': courseType.name,
      'isActive': isActive,
      'courseImageUrl': courseImageUrl,
      'contents': contents?.map((e) => e.toJson()).toList(),
    };
  }
}

class CreateCourseContentRequest {
  final CourseContentType contentType;
  final String content; // Required: text content, or URL for media/link
  final String? title; // Optional title
  final int displayOrder;

  const CreateCourseContentRequest({
    required this.contentType,
    required this.content,
    this.title,
    required this.displayOrder,
  });

  factory CreateCourseContentRequest.fromJson(Map<String, dynamic> json) {
    return CreateCourseContentRequest(
      contentType:
          CourseContentType.fromString(json['contentType'] as String) ??
          CourseContentType.text,
      content: json['content'] as String,
      title: json['title'] as String?,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'contentType': contentType.name,
      'content': content,
      'title': title,
      'displayOrder': displayOrder,
    };
  }
}

class UpdateCourseRequest {
  final String? title;
  final String? description;
  final String? category;
  final String? difficulty;
  final CourseType? courseType;
  final bool? isActive;
  final String? courseImageUrl;
  final List<CreateCourseContentRequest>? contents;

  const UpdateCourseRequest({
    this.title,
    this.description,
    this.category,
    this.difficulty,
    this.courseType,
    this.isActive,
    this.courseImageUrl,
    this.contents,
  });

  factory UpdateCourseRequest.fromJson(Map<String, dynamic> json) {
    return UpdateCourseRequest(
      title: json['title'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String?,
      courseType: json['courseType'] != null
          ? CourseType.fromString(json['courseType'] as String)
          : null,
      isActive: json['isActive'] as bool?,
      courseImageUrl: json['courseImageUrl'] as String?,
      contents: json['contents'] != null
          ? (json['contents'] as List)
                .map(
                  (e) => CreateCourseContentRequest.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (category != null) map['category'] = category;
    if (difficulty != null) map['difficulty'] = difficulty;
    if (courseType != null) map['courseType'] = courseType!.name;
    if (isActive != null) map['isActive'] = isActive;
    if (courseImageUrl != null) map['courseImageUrl'] = courseImageUrl;
    if (contents != null)
      map['contents'] = contents!.map((e) => e.toJson()).toList();
    return map;
  }
}

class CourseResponse {
  final bool success;
  final String? message;
  final Course? data;

  const CourseResponse({required this.success, this.message, this.data});

  factory CourseResponse.fromJson(Map<String, dynamic> json) {
    return CourseResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null
          ? Course.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data?.toJson()};
  }
}

class CourseListResponse {
  final bool success;
  final String? message;
  final List<Course>? data;

  const CourseListResponse({required this.success, this.message, this.data});

  factory CourseListResponse.fromJson(Map<String, dynamic> json) {
    return CourseListResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List)
                .map((e) => Course.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.map((e) => e.toJson()).toList(),
    };
  }
}

class CourseProgress {
  final String id;
  final String userId;
  final String courseId;
  final double progressPercentage;
  final int completedContentCount;
  final int totalContentCount;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime startedAt;
  final DateTime? updatedAt;

  const CourseProgress({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.progressPercentage,
    required this.completedContentCount,
    required this.totalContentCount,
    required this.isCompleted,
    this.completedAt,
    required this.startedAt,
    this.updatedAt,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      id: json['id'] as String,
      userId: json['userId'] as String,
      courseId: json['courseId'] as String,
      progressPercentage:
          (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      completedContentCount:
          (json['completedContentCount'] as num?)?.toInt() ?? 0,
      totalContentCount: (json['totalContentCount'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      startedAt: DateTime.parse(json['startedAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'courseId': courseId,
      'progressPercentage': progressPercentage,
      'completedContentCount': completedContentCount,
      'totalContentCount': totalContentCount,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'startedAt': startedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class CourseProgressResponse {
  final bool success;
  final String? message;
  final CourseProgress? data;

  const CourseProgressResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory CourseProgressResponse.fromJson(Map<String, dynamic> json) {
    return CourseProgressResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null
          ? CourseProgress.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data?.toJson()};
  }
}
