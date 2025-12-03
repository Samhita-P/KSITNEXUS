/// Models for Lifecycle Extensions

class OnboardingStep {
  final int id;
  final String name;
  final String stepType;
  final String title;
  final String? description;
  final Map<String, dynamic> content;
  final int order;
  final bool isRequired;
  final bool isActive;
  final List<String> targetUserTypes;
  final DateTime createdAt;
  final DateTime updatedAt;

  OnboardingStep({
    required this.id,
    required this.name,
    required this.stepType,
    required this.title,
    this.description,
    required this.content,
    required this.order,
    required this.isRequired,
    required this.isActive,
    required this.targetUserTypes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OnboardingStep.fromJson(Map<String, dynamic> json) {
    return OnboardingStep(
      id: json['id'],
      name: json['name'],
      stepType: json['step_type'],
      title: json['title'],
      description: json['description'],
      content: Map<String, dynamic>.from(json['content'] ?? {}),
      order: json['order'],
      isRequired: json['is_required'],
      isActive: json['is_active'],
      targetUserTypes: List<String>.from(json['target_user_types'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class UserOnboardingProgress {
  final int id;
  final int userId;
  final String? userName;
  final int? currentStepId;
  final OnboardingStep? currentStepData;
  final List<int> completedSteps;
  final List<int> skippedSteps;
  final Map<String, dynamic> progressData;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserOnboardingProgress({
    required this.id,
    required this.userId,
    this.userName,
    this.currentStepId,
    this.currentStepData,
    required this.completedSteps,
    required this.skippedSteps,
    required this.progressData,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserOnboardingProgress.fromJson(Map<String, dynamic> json) {
    return UserOnboardingProgress(
      id: json['id'],
      userId: json['user'],
      userName: json['user_name'],
      currentStepId: json['current_step'],
      currentStepData: json['current_step_data'] != null
          ? OnboardingStep.fromJson(json['current_step_data'])
          : null,
      completedSteps: List<int>.from(json['completed_steps'] ?? []),
      skippedSteps: List<int>.from(json['skipped_steps'] ?? []),
      progressData: Map<String, dynamic>.from(json['progress_data'] ?? {}),
      isCompleted: json['is_completed'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class AlumniProfile {
  final int id;
  final int userId;
  final String? userName;
  final String? userEmail;
  final int graduationYear;
  final String degree;
  final String? major;
  final String? currentPosition;
  final String? currentCompany;
  final String? industry;
  final String? location;
  final String? bio;
  final String? linkedinUrl;
  final String? websiteUrl;
  final bool isMentor;
  final bool isAvailableForMentorship;
  final List<String> mentorshipAreas;
  final bool isVerified;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AlumniProfile({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    required this.graduationYear,
    required this.degree,
    this.major,
    this.currentPosition,
    this.currentCompany,
    this.industry,
    this.location,
    this.bio,
    this.linkedinUrl,
    this.websiteUrl,
    required this.isMentor,
    required this.isAvailableForMentorship,
    required this.mentorshipAreas,
    required this.isVerified,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AlumniProfile.fromJson(Map<String, dynamic> json) {
    return AlumniProfile(
      id: json['id'],
      userId: json['user'],
      userName: json['user_name'],
      userEmail: json['user_email'],
      graduationYear: json['graduation_year'],
      degree: json['degree'],
      major: json['major'],
      currentPosition: json['current_position'],
      currentCompany: json['current_company'],
      industry: json['industry'],
      location: json['location'],
      bio: json['bio'],
      linkedinUrl: json['linkedin_url'],
      websiteUrl: json['website_url'],
      isMentor: json['is_mentor'],
      isAvailableForMentorship: json['is_available_for_mentorship'],
      mentorshipAreas: List<String>.from(json['mentorship_areas'] ?? []),
      isVerified: json['is_verified'],
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class MentorshipRequest {
  final int id;
  final String requestId;
  final int menteeId;
  final String? menteeName;
  final int mentorId;
  final String? mentorName;
  final String status;
  final String message;
  final List<String> mentorshipAreas;
  final String? mentorResponse;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  MentorshipRequest({
    required this.id,
    required this.requestId,
    required this.menteeId,
    this.menteeName,
    required this.mentorId,
    this.mentorName,
    required this.status,
    required this.message,
    required this.mentorshipAreas,
    this.mentorResponse,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MentorshipRequest.fromJson(Map<String, dynamic> json) {
    return MentorshipRequest(
      id: json['id'],
      requestId: json['request_id'],
      menteeId: json['mentee'],
      menteeName: json['mentee_name'],
      mentorId: json['mentor'],
      mentorName: json['mentor_name'],
      status: json['status'],
      message: json['message'],
      mentorshipAreas: List<String>.from(json['mentorship_areas'] ?? []),
      mentorResponse: json['mentor_response'],
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class AlumniEvent {
  final int id;
  final String title;
  final String eventType;
  final String description;
  final String? location;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? registrationDeadline;
  final int? maxAttendees;
  final String? registrationUrl;
  final bool isActive;
  final int? createdBy;
  final String? createdByName;
  final int? attendeesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  AlumniEvent({
    required this.id,
    required this.title,
    required this.eventType,
    required this.description,
    this.location,
    required this.startDate,
    this.endDate,
    this.registrationDeadline,
    this.maxAttendees,
    this.registrationUrl,
    required this.isActive,
    this.createdBy,
    this.createdByName,
    this.attendeesCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AlumniEvent.fromJson(Map<String, dynamic> json) {
    return AlumniEvent(
      id: json['id'],
      title: json['title'],
      eventType: json['event_type'],
      description: json['description'],
      location: json['location'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      registrationDeadline: json['registration_deadline'] != null
          ? DateTime.parse(json['registration_deadline'])
          : null,
      maxAttendees: json['max_attendees'],
      registrationUrl: json['registration_url'],
      isActive: json['is_active'],
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      attendeesCount: json['attendees_count'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class PlacementOpportunity {
  final int id;
  final String opportunityId;
  final String title;
  final String companyName;
  final String opportunityType;
  final String description;
  final String? requirements;
  final String? location;
  final bool isRemote;
  final double? salaryRangeMin;
  final double? salaryRangeMax;
  final DateTime? applicationDeadline;
  final String status;
  final int? postedBy;
  final String? postedByName;
  final String? applicationUrl;
  final String? contactEmail;
  final List<String> tags;
  final int viewsCount;
  final int applicationsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlacementOpportunity({
    required this.id,
    required this.opportunityId,
    required this.title,
    required this.companyName,
    required this.opportunityType,
    required this.description,
    this.requirements,
    this.location,
    required this.isRemote,
    this.salaryRangeMin,
    this.salaryRangeMax,
    this.applicationDeadline,
    required this.status,
    this.postedBy,
    this.postedByName,
    required this.applicationUrl,
    this.contactEmail,
    required this.tags,
    required this.viewsCount,
    required this.applicationsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlacementOpportunity.fromJson(Map<String, dynamic> json) {
    return PlacementOpportunity(
      id: json['id'],
      opportunityId: json['opportunity_id'],
      title: json['title'],
      companyName: json['company_name'],
      opportunityType: json['opportunity_type'],
      description: json['description'],
      requirements: json['requirements'],
      location: json['location'],
      isRemote: json['is_remote'],
      salaryRangeMin: json['salary_range_min']?.toDouble(),
      salaryRangeMax: json['salary_range_max']?.toDouble(),
      applicationDeadline: json['application_deadline'] != null
          ? DateTime.parse(json['application_deadline'])
          : null,
      status: json['status'],
      postedBy: json['posted_by'],
      postedByName: json['posted_by_name'],
      applicationUrl: json['application_url'],
      contactEmail: json['contact_email'],
      tags: List<String>.from(json['tags'] ?? []),
      viewsCount: json['views_count'],
      applicationsCount: json['applications_count'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class PlacementApplication {
  final int id;
  final String applicationId;
  final int opportunityId;
  final String? opportunityTitle;
  final String? companyName;
  final int applicantId;
  final String? applicantName;
  final String status;
  final String? coverLetter;
  final String? resumeUrl;
  final String? portfolioUrl;
  final List<String> additionalDocuments;
  final String? notes;
  final DateTime? interviewDate;
  final String? interviewLocation;
  final Map<String, dynamic> offerDetails;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlacementApplication({
    required this.id,
    required this.applicationId,
    required this.opportunityId,
    this.opportunityTitle,
    this.companyName,
    required this.applicantId,
    this.applicantName,
    required this.status,
    this.coverLetter,
    this.resumeUrl,
    this.portfolioUrl,
    required this.additionalDocuments,
    this.notes,
    this.interviewDate,
    this.interviewLocation,
    required this.offerDetails,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlacementApplication.fromJson(Map<String, dynamic> json) {
    return PlacementApplication(
      id: json['id'],
      applicationId: json['application_id'],
      opportunityId: json['opportunity'],
      opportunityTitle: json['opportunity_title'],
      companyName: json['company_name'],
      applicantId: json['applicant'],
      applicantName: json['applicant_name'],
      status: json['status'],
      coverLetter: json['cover_letter'],
      resumeUrl: json['resume_url'],
      portfolioUrl: json['portfolio_url'],
      additionalDocuments: List<String>.from(json['additional_documents'] ?? []),
      notes: json['notes'],
      interviewDate: json['interview_date'] != null
          ? DateTime.parse(json['interview_date'])
          : null,
      interviewLocation: json['interview_location'],
      offerDetails: Map<String, dynamic>.from(json['offer_details'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

















