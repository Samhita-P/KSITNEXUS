import 'package:ksit_nexus_app/services/api_service.dart';

void main() {
  // Test if the methods are accessible
  final apiService = ApiService();
  
  // These should work without compilation errors
  apiService.joinStudyGroup(1);
  apiService.leaveStudyGroup(1);
  
  print('API methods are accessible');
}
