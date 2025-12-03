class Feedback {
  final int id;
  final int facultyId;
  final String facultyName;
  final String facultyDepartment;
  final int studentId;
  final String studentName;
  final String semester;
  final double teachingRating;
  final double communicationRating;
  final double punctualityRating;
  final double helpfulnessRating;
  final double overallRating;
  final String? comment;
  final String? courseName;
  final bool isAnonymous;
  final DateTime submittedAt;
  final DateTime updatedAt;

  Feedback({
    required this.id,
    required this.facultyId,
    required this.facultyName,
    required this.facultyDepartment,
    required this.studentId,
    required this.studentName,
    required this.semester,
    required this.teachingRating,
    required this.communicationRating,
    required this.punctualityRating,
    required this.helpfulnessRating,
    required this.overallRating,
    this.comment,
    this.courseName,
    required this.isAnonymous,
    required this.submittedAt,
    required this.updatedAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    print("=== PARSING FEEDBACK RESPONSE ===");
    print("Raw JSON: $json");
    
    // Helper function to safely get integer values
    int getInt(String key, {int defaultValue = 0}) {
      final value = json[key];
      if (value == null) {
        print("Warning: $key is null, using default: $defaultValue");
        return defaultValue;
      }
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
      print("Warning: $key could not be parsed as int, using default: $defaultValue");
      return defaultValue;
    }
    
    // Helper function to safely get string values
    String getString(String key, {String defaultValue = ''}) {
      final value = json[key];
      if (value == null) {
        print("Warning: $key is null, using default: '$defaultValue'");
        return defaultValue;
      }
      return value.toString();
    }
    
    // Helper function to safely get double values
    double getDouble(String key, {double defaultValue = 0.0}) {
      final value = json[key];
      if (value == null) {
        print("Warning: $key is null, using default: $defaultValue");
        return defaultValue;
      }
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
      print("Warning: $key could not be parsed as double, using default: $defaultValue");
      return defaultValue;
    }
    
    // Helper function to safely get boolean values
    bool getBool(String key, {bool defaultValue = false}) {
      final value = json[key];
      if (value == null) {
        print("Warning: $key is null, using default: $defaultValue");
        return defaultValue;
      }
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is int) return value != 0;
      print("Warning: $key could not be parsed as bool, using default: $defaultValue");
      return defaultValue;
    }
    
    // Helper function to safely get DateTime values
    DateTime getDateTime(String key) {
      final value = json[key];
      if (value == null) {
        print("Warning: $key is null, using current time");
        return DateTime.now();
      }
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print("Warning: $key could not be parsed as DateTime: $e");
          return DateTime.now();
        }
      }
      print("Warning: $key is not a string, using current time");
      return DateTime.now();
    }
    
    final feedback = Feedback(
      id: getInt('id'),
      facultyId: getInt('faculty_id'),
      facultyName: getString('faculty_name'),
      facultyDepartment: getString('faculty_department'),
      studentId: getInt('student_id'),
      studentName: getString('student_name'),
      semester: getString('semester'),
      teachingRating: getDouble('teaching_rating'),
      communicationRating: getDouble('communication_rating'),
      punctualityRating: getDouble('punctuality_rating'),
      helpfulnessRating: getDouble('helpfulness_rating'),
      overallRating: getDouble('overall_rating'),
      comment: json['comment'] as String?,
      courseName: json['course_name'] as String?,
      isAnonymous: getBool('is_anonymous'),
      submittedAt: getDateTime('submitted_at'),
      updatedAt: getDateTime('updated_at'),
    );
    
    print("=== PARSED FEEDBACK OBJECT ===");
    print("ID: ${feedback.id}");
    print("Faculty ID: ${feedback.facultyId}");
    print("Faculty Name: ${feedback.facultyName}");
    print("Semester: ${feedback.semester}");
    print("Teaching Rating: ${feedback.teachingRating}");
    print("Comment: ${feedback.comment}");
    print("Course Name: ${feedback.courseName}");
    
    return feedback;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'faculty_id': facultyId,
      'faculty_name': facultyName,
      'faculty_department': facultyDepartment,
      'student_id': studentId,
      'student_name': studentName,
      'semester': semester,
      'teaching_rating': teachingRating,
      'communication_rating': communicationRating,
      'punctuality_rating': punctualityRating,
      'helpfulness_rating': helpfulnessRating,
      'overall_rating': overallRating,
      'comment': comment,
      'course_name': courseName,
      'is_anonymous': isAnonymous,
      'submitted_at': submittedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get averageRating => (teachingRating + communicationRating + punctualityRating + helpfulnessRating) / 4;
}

class FeedbackCreateRequest {
  final int facultyId;
  final int semester;
  final int teachingRating;
  final int communicationRating;
  final int punctualityRating;
  final int subjectKnowledgeRating;
  final int helpfulnessRating;
  final String? comment;
  final bool isAnonymous;

  FeedbackCreateRequest({
    required this.facultyId,
    required this.semester,
    required this.teachingRating,
    required this.communicationRating,
    required this.punctualityRating,
    required this.subjectKnowledgeRating,
    required this.helpfulnessRating,
    this.comment,
    required this.isAnonymous,
  });

  factory FeedbackCreateRequest.fromJson(Map<String, dynamic> json) {
    return FeedbackCreateRequest(
      facultyId: json['faculty_id'] as int,
      semester: json['semester'] is int ? json['semester'] as int : int.tryParse(json['semester'].toString()) ?? 1,
      teachingRating: json['teaching_rating'] as int,
      communicationRating: json['communication_rating'] as int,
      punctualityRating: json['punctuality_rating'] as int,
      subjectKnowledgeRating: json['subject_knowledge_rating'] as int,
      helpfulnessRating: json['helpfulness_rating'] as int,
      comment: json['comment'] as String?,
      isAnonymous: json['is_anonymous'] as bool? ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'faculty_id': facultyId,
      'semester': semester,
      'teaching_rating': teachingRating,
      'communication_rating': communicationRating,
      'punctuality_rating': punctualityRating,
      'subject_knowledge_rating': subjectKnowledgeRating,
      'helpfulness_rating': helpfulnessRating,
      if (comment != null) 'comment': comment,
      'is_anonymous': isAnonymous,
    };
  }
}

class FacultyFeedbackSummary {
  final int facultyId;
  final String facultyName;
  final String facultyDepartment;
  final double averageOverallRating;
  final double averageTeachingRating;
  final double averageCommunicationRating;
  final double averagePunctualityRating;
  final double averageHelpfulnessRating;
  final int totalFeedbacks;
  final int semesterFeedbacks;
  final List<Feedback> recentFeedbacks;
  final Map<String, double> ratingsBySemester;

  FacultyFeedbackSummary({
    required this.facultyId,
    required this.facultyName,
    required this.facultyDepartment,
    required this.averageOverallRating,
    required this.averageTeachingRating,
    required this.averageCommunicationRating,
    required this.averagePunctualityRating,
    required this.averageHelpfulnessRating,
    required this.totalFeedbacks,
    required this.semesterFeedbacks,
    required this.recentFeedbacks,
    required this.ratingsBySemester,
  });

  factory FacultyFeedbackSummary.fromJson(Map<String, dynamic> json) {
    // Handle both backend serializer formats
    // Backend returns: avg_teaching_quality, avg_communication, avg_punctuality, avg_helpfulness, avg_overall_rating, total_feedback_count
    // Updated backend also returns: faculty_id, faculty_name, faculty_department, average_teaching_rating, etc.
    
    // Extract faculty info
    final facultyId = json['faculty_id'] ?? 
                      (json['faculty'] is Map ? json['faculty']['id'] : null) ??
                      (json['faculty'] is int ? json['faculty'] : null) ??
                      0;
    final facultyName = json['faculty_name'] ?? 
                        (json['faculty'] is Map ? json['faculty']['name'] : null) ??
                        (json['faculty'] is String ? json['faculty'] : null) ??
                        '';
    final facultyDepartment = json['faculty_department'] ?? 
                              (json['faculty'] is Map ? json['faculty']['department'] : null) ??
                              json['department'] ??
                              '';
    
    // Extract ratings - handle both old and new format
    final averageOverallRating = (json['avg_overall_rating'] ?? json['average_overall_rating'] ?? 0.0) as num;
    final averageTeachingRating = (json['avg_teaching_quality'] ?? json['average_teaching_rating'] ?? 0.0) as num;
    final averageCommunicationRating = (json['avg_communication'] ?? json['average_communication_rating'] ?? 0.0) as num;
    final averagePunctualityRating = (json['avg_punctuality'] ?? json['average_punctuality_rating'] ?? 0.0) as num;
    final averageHelpfulnessRating = (json['avg_helpfulness'] ?? json['average_helpfulness_rating'] ?? 0.0) as num;
    
    // Extract counts
    final totalFeedbacks = json['total_feedback_count'] ?? json['total_feedbacks'] ?? 0;
    final semesterFeedbacks = json['semester_feedbacks'] ?? json['semester_feedback_count'] ?? 0;
    
    // Extract recent feedbacks
    final recentFeedbacks = json['recent_feedbacks'] != null
        ? (json['recent_feedbacks'] as List)
            .map((item) {
              try {
                return Feedback.fromJson(item as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing feedback: $e');
                return null;
              }
            })
            .whereType<Feedback>()
            .toList()
        : <Feedback>[];
    
    // Extract ratings by semester
    final ratingsBySemester = json['ratings_by_semester'] != null
        ? Map<String, double>.from(
            (json['ratings_by_semester'] as Map).map(
              (key, value) => MapEntry(key.toString(), (value as num).toDouble())
            )
          )
        : <String, double>{};
    
    return FacultyFeedbackSummary(
      facultyId: facultyId is int ? facultyId : int.tryParse(facultyId.toString()) ?? 0,
      facultyName: facultyName.toString(),
      facultyDepartment: facultyDepartment.toString(),
      averageOverallRating: averageOverallRating.toDouble(),
      averageTeachingRating: averageTeachingRating.toDouble(),
      averageCommunicationRating: averageCommunicationRating.toDouble(),
      averagePunctualityRating: averagePunctualityRating.toDouble(),
      averageHelpfulnessRating: averageHelpfulnessRating.toDouble(),
      totalFeedbacks: totalFeedbacks is int ? totalFeedbacks : int.tryParse(totalFeedbacks.toString()) ?? 0,
      semesterFeedbacks: semesterFeedbacks is int ? semesterFeedbacks : int.tryParse(semesterFeedbacks.toString()) ?? 0,
      recentFeedbacks: recentFeedbacks,
      ratingsBySemester: ratingsBySemester,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'faculty_id': facultyId,
      'faculty_name': facultyName,
      'faculty_department': facultyDepartment,
      'average_overall_rating': averageOverallRating,
      'average_teaching_rating': averageTeachingRating,
      'average_communication_rating': averageCommunicationRating,
      'average_punctuality_rating': averagePunctualityRating,
      'average_helpfulness_rating': averageHelpfulnessRating,
      'total_feedbacks': totalFeedbacks,
      'semester_feedbacks': semesterFeedbacks,
      'recent_feedbacks': recentFeedbacks.map((feedback) => feedback.toJson()).toList(),
      'ratings_by_semester': ratingsBySemester,
    };
  }
}

class FeedbackStats {
  final int totalFeedbacks;
  final int semesterFeedbacks;
  final double averageOverallRating;
  final Map<String, int> feedbacksByFaculty;
  final Map<String, double> averageRatingsByCategory;
  final List<FacultyFeedbackSummary> topRatedFaculties;
  final List<FacultyFeedbackSummary> lowestRatedFaculties;

  FeedbackStats({
    required this.totalFeedbacks,
    required this.semesterFeedbacks,
    required this.averageOverallRating,
    required this.feedbacksByFaculty,
    required this.averageRatingsByCategory,
    required this.topRatedFaculties,
    required this.lowestRatedFaculties,
  });

  factory FeedbackStats.fromJson(Map<String, dynamic> json) {
    return FeedbackStats(
      totalFeedbacks: json['total_feedbacks'] as int,
      semesterFeedbacks: json['semester_feedbacks'] as int,
      averageOverallRating: (json['average_overall_rating'] as num).toDouble(),
      feedbacksByFaculty: Map<String, int>.from(json['feedbacks_by_faculty'] as Map),
      averageRatingsByCategory: Map<String, double>.from(json['average_ratings_by_category'] as Map),
      topRatedFaculties: (json['top_rated_faculties'] as List)
          .map((item) => FacultyFeedbackSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      lowestRatedFaculties: (json['lowest_rated_faculties'] as List)
          .map((item) => FacultyFeedbackSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'total_feedbacks': totalFeedbacks,
      'semester_feedbacks': semesterFeedbacks,
      'average_overall_rating': averageOverallRating,
      'feedbacks_by_faculty': feedbacksByFaculty,
      'average_ratings_by_category': averageRatingsByCategory,
      'top_rated_faculties': topRatedFaculties.map((faculty) => faculty.toJson()).toList(),
      'lowest_rated_faculties': lowestRatedFaculties.map((faculty) => faculty.toJson()).toList(),
    };
  }
}

class Faculty {
  final int id;
  final String name;
  final String department;
  final String designation;
  final String email;
  final String? profilePicture;
  final List<String> subjects;
  final double? averageRating;
  final int totalFeedbacks;

  Faculty({
    required this.id,
    required this.name,
    required this.department,
    required this.designation,
    required this.email,
    this.profilePicture,
    required this.subjects,
    this.averageRating,
    required this.totalFeedbacks,
  });

  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      id: json['id'] as int,
      name: json['name'] as String,
      department: json['department'] as String,
      designation: json['designation'] as String,
      email: json['email'] as String,
      profilePicture: json['profile_picture'] as String?,
      subjects: (json['subjects'] as List).cast<String>(),
      averageRating: json['average_rating'] != null ? (json['average_rating'] as num).toDouble() : null,
      totalFeedbacks: json['total_feedbacks'] as int,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'designation': designation,
      'email': email,
      'profile_picture': profilePicture,
      'subjects': subjects,
      'average_rating': averageRating,
      'total_feedbacks': totalFeedbacks,
    };
  }
}
