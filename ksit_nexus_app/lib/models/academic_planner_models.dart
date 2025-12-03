class Course {
  final int? id;
  final String courseCode;
  final String courseName;
  final String courseType;
  final int credits;
  final int semester;
  final String academicYear;
  final String? description;
  final String? syllabus;
  final int? instructor;
  final String? instructorName;
  final Map<String, dynamic>? schedule;
  final bool isActive;
  final String color;
  final int? enrollmentCount;

  Course({
    this.id,
    required this.courseCode,
    required this.courseName,
    required this.courseType,
    required this.credits,
    required this.semester,
    required this.academicYear,
    this.description,
    this.syllabus,
    this.instructor,
    this.instructorName,
    this.schedule,
    required this.isActive,
    required this.color,
    this.enrollmentCount,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      courseCode: json['course_code'],
      courseName: json['course_name'],
      courseType: json['course_type'],
      credits: json['credits'],
      semester: json['semester'],
      academicYear: json['academic_year'],
      description: json['description'],
      syllabus: json['syllabus'],
      instructor: json['instructor'],
      instructorName: json['instructor_name'],
      schedule: json['schedule'],
      isActive: json['is_active'],
      color: json['color'] ?? '#3b82f6',
      enrollmentCount: json['enrollment_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_code': courseCode,
      'course_name': courseName,
      'course_type': courseType,
      'credits': credits,
      'semester': semester,
      'academic_year': academicYear,
      'description': description,
      'syllabus': syllabus,
      'instructor': instructor,
      'schedule': schedule,
      'is_active': isActive,
      'color': color,
    };
  }
}

class CourseEnrollment {
  final int? id;
  final int student;
  final String? studentName;
  final Course course;
  final String status;
  final DateTime enrollmentDate;
  final DateTime? completionDate;
  final String? finalGrade;
  final double? gradePoints;

  CourseEnrollment({
    this.id,
    required this.student,
    this.studentName,
    required this.course,
    required this.status,
    required this.enrollmentDate,
    this.completionDate,
    this.finalGrade,
    this.gradePoints,
  });

  // Helper method to safely parse numeric values from JSON
  static double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  factory CourseEnrollment.fromJson(Map<String, dynamic> json) {
    return CourseEnrollment(
      id: json['id'],
      student: json['student'],
      studentName: json['student_name'],
      course: Course.fromJson(json['course']),
      status: json['status'],
      enrollmentDate: DateTime.parse(json['enrollment_date']),
      completionDate: json['completion_date'] != null
          ? DateTime.parse(json['completion_date'])
          : null,
      finalGrade: json['final_grade'],
      gradePoints: _parseDoubleNullable(json['grade_points']),
    );
  }
}

class Assignment {
  final int? id;
  final String title;
  final String? description;
  final String assignmentType;
  final Course course;
  final int? student;
  final String? studentName;
  final DateTime assignedDate;
  final DateTime dueDate;
  final bool lateSubmissionAllowed;
  final double latePenaltyPercentage;
  final String status;
  final DateTime? submittedAt;
  final String? submissionLink;
  final String? submissionFile;
  final double maxScore;
  final double? score;
  final double weight;
  final String? feedback;
  final int? gradedBy;
  final DateTime? gradedAt;
  final bool reminderSent;
  final bool isOverdue;
  final int daysUntilDue;
  final double? percentageScore;

  Assignment({
    this.id,
    required this.title,
    this.description,
    required this.assignmentType,
    required this.course,
    this.student,
    this.studentName,
    required this.assignedDate,
    required this.dueDate,
    required this.lateSubmissionAllowed,
    required this.latePenaltyPercentage,
    required this.status,
    this.submittedAt,
    this.submissionLink,
    this.submissionFile,
    required this.maxScore,
    this.score,
    required this.weight,
    this.feedback,
    this.gradedBy,
    this.gradedAt,
    required this.reminderSent,
    required this.isOverdue,
    required this.daysUntilDue,
    this.percentageScore,
  });

  // Helper method to safely parse numeric values from JSON
  static double _parseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      title: json['title'] as String,
      description: json['description'] as String?,
      assignmentType: json['assignment_type'] as String,
      course: Course.fromJson(json['course'] as Map<String, dynamic>),
      student: json['student'] as int?,
      studentName: json['student_name'] as String?,
      assignedDate: DateTime.parse(json['assigned_date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      lateSubmissionAllowed: json['late_submission_allowed'] as bool? ?? false,
      latePenaltyPercentage: _parseDouble(json['late_penalty_percentage'], 0.0),
      status: json['status'] as String,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      submissionLink: json['submission_link'] as String?,
      submissionFile: json['submission_file'] as String?,
      maxScore: _parseDouble(json['max_score'], 100.0),
      score: json['score'] != null ? _parseDouble(json['score'], 0.0) : null,
      weight: _parseDouble(json['weight'], 0.0),
      feedback: json['feedback'] as String?,
      gradedBy: json['graded_by'] as int?,
      gradedAt: json['graded_at'] != null
          ? DateTime.parse(json['graded_at'] as String)
          : null,
      reminderSent: json['reminder_sent'] as bool? ?? false,
      isOverdue: json['is_overdue'] as bool? ?? false,
      daysUntilDue: _parseInt(json['days_until_due'], 0),
      percentageScore: json['percentage_score'] != null
          ? _parseDouble(json['percentage_score'], 0.0)
          : null,
    );
  }
}

class Grade {
  final int? id;
  final int student;
  final String? studentName;
  final Course course;
  final String? grade;
  final double? gradePoints;
  final double? percentage;
  final Map<String, dynamic>? assignmentScores;
  final int? semester;
  final String? academicYear;
  final String? notes;
  final bool isFinal;
  final DateTime calculatedAt;

  Grade({
    this.id,
    required this.student,
    this.studentName,
    required this.course,
    this.grade,
    this.gradePoints,
    this.percentage,
    this.assignmentScores,
    this.semester,
    this.academicYear,
    this.notes,
    required this.isFinal,
    required this.calculatedAt,
  });

  // Helper method to safely parse numeric values from JSON
  static double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'],
      student: json['student'],
      studentName: json['student_name'],
      course: Course.fromJson(json['course']),
      grade: json['grade'],
      gradePoints: _parseDoubleNullable(json['grade_points']),
      percentage: _parseDoubleNullable(json['percentage']),
      assignmentScores: json['assignment_scores'],
      semester: json['semester'],
      academicYear: json['academic_year'],
      notes: json['notes'],
      isFinal: json['is_final'],
      calculatedAt: DateTime.parse(json['calculated_at']),
    );
  }
}

class AcademicReminder {
  final int? id;
  final String title;
  final String? description;
  final String reminderType;
  final int user;
  final Course? course;
  final Assignment? assignment;
  final DateTime reminderDate;
  final bool isRecurring;
  final String? recurrencePattern;
  final bool isCompleted;
  final DateTime? completedAt;
  final String priority;
  final bool notificationSent;
  final DateTime? notificationSentAt;
  final bool isOverdue;
  final int daysUntilReminder;

  AcademicReminder({
    this.id,
    required this.title,
    this.description,
    required this.reminderType,
    required this.user,
    this.course,
    this.assignment,
    required this.reminderDate,
    required this.isRecurring,
    this.recurrencePattern,
    required this.isCompleted,
    this.completedAt,
    required this.priority,
    required this.notificationSent,
    this.notificationSentAt,
    required this.isOverdue,
    required this.daysUntilReminder,
  });

  factory AcademicReminder.fromJson(Map<String, dynamic> json) {
    return AcademicReminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      reminderType: json['reminder_type'],
      user: json['user'],
      course: json['course'] != null ? Course.fromJson(json['course']) : null,
      assignment: json['assignment'] != null
          ? Assignment.fromJson(json['assignment'])
          : null,
      reminderDate: DateTime.parse(json['reminder_date']),
      isRecurring: json['is_recurring'],
      recurrencePattern: json['recurrence_pattern'],
      isCompleted: json['is_completed'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      priority: json['priority'],
      notificationSent: json['notification_sent'],
      notificationSentAt: json['notification_sent_at'] != null
          ? DateTime.parse(json['notification_sent_at'])
          : null,
      isOverdue: json['is_overdue'],
      daysUntilReminder: json['days_until_reminder'],
    );
  }
}

class AcademicDashboard {
  final int enrolledCourses;
  final int activeAssignments;
  final int overdueAssignments;
  final int upcomingDeadlines;
  final double? currentGpa;
  final int totalCredits;
  final int completedCredits;

  AcademicDashboard({
    required this.enrolledCourses,
    required this.activeAssignments,
    required this.overdueAssignments,
    required this.upcomingDeadlines,
    this.currentGpa,
    required this.totalCredits,
    required this.completedCredits,
  });

  factory AcademicDashboard.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is List) return value.length; // If it's a list, return its length
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }
    
    // Helper function to safely convert to double (nullable)
    double? safeDoubleNullable(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value);
      }
      return null;
    }
    
    return AcademicDashboard(
      enrolledCourses: safeInt(json['enrolled_courses']),
      activeAssignments: safeInt(json['active_assignments']),
      overdueAssignments: safeInt(json['overdue_assignments']),
      upcomingDeadlines: safeInt(json['upcoming_deadlines']),
      currentGpa: safeDoubleNullable(json['current_gpa']),
      totalCredits: safeInt(json['total_credits']),
      completedCredits: safeInt(json['completed_credits']),
    );
  }

  AcademicDashboard copyWith({
    int? enrolledCourses,
    int? activeAssignments,
    int? overdueAssignments,
    int? upcomingDeadlines,
    double? currentGpa,
    int? totalCredits,
    int? completedCredits,
  }) {
    return AcademicDashboard(
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      activeAssignments: activeAssignments ?? this.activeAssignments,
      overdueAssignments: overdueAssignments ?? this.overdueAssignments,
      upcomingDeadlines: upcomingDeadlines ?? this.upcomingDeadlines,
      currentGpa: currentGpa ?? this.currentGpa,
      totalCredits: totalCredits ?? this.totalCredits,
      completedCredits: completedCredits ?? this.completedCredits,
    );
  }
}


