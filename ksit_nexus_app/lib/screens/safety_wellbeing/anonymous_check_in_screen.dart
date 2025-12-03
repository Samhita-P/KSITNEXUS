import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../providers/data_providers.dart';
import '../../widgets/error_widget.dart';

class AnonymousCheckInScreen extends ConsumerStatefulWidget {
  const AnonymousCheckInScreen({super.key});

  @override
  ConsumerState<AnonymousCheckInScreen> createState() => _AnonymousCheckInScreenState();
}

class _AnonymousCheckInScreenState extends ConsumerState<AnonymousCheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  int _moodLevel = 3;
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _allowFollowUp = false;

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anonymous Check-In'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/safety');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TRUE REFRESH: Reset all form fields and clear form state
              setState(() {
                _selectedType = null;
                _moodLevel = 3;
                _messageController.clear();
                _emailController.clear();
                _phoneController.clear();
                _allowFollowUp = false;
              });
              
              // Reset form validation state
              _formKey.currentState?.reset();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your privacy is important to us',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This check-in is completely anonymous. You can choose to provide contact information if you\'d like follow-up support.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Check-In Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'wellness', child: Text('Wellness Check')),
                  DropdownMenuItem(value: 'stress', child: Text('Stress Management')),
                  DropdownMenuItem(value: 'anxiety', child: Text('Anxiety Support')),
                  DropdownMenuItem(value: 'depression', child: Text('Depression Support')),
                  DropdownMenuItem(value: 'crisis', child: Text('Crisis Support')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a check-in type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'How are you feeling today?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final level = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _moodLevel = level;
                      });
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _moodLevel == level
                            ? AppTheme.primaryColor
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$level',
                          style: TextStyle(
                            color: _moodLevel == level ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _getMoodLabel(_moodLevel),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                  hintText: 'Share how you\'re feeling...',
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              Text(
                'Contact Information (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Allow follow-up contact'),
                value: _allowFollowUp,
                onChanged: (value) {
                  setState(() {
                    _allowFollowUp = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitCheckIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Submit Check-In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMoodLabel(int level) {
    switch (level) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Neutral';
      case 4:
        return 'Good';
      case 5:
        return 'Very Good';
      default:
        return '';
    }
  }

  Future<void> _submitCheckIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.submitAnonymousCheckIn({
        'check_in_type': _selectedType,
        'mood_level': _moodLevel,
        'message': _messageController.text.isEmpty ? null : _messageController.text,
        'contact_email': _emailController.text.isEmpty ? null : _emailController.text,
        'contact_phone': _phoneController.text.isEmpty ? null : _phoneController.text,
        'allow_follow_up': _allowFollowUp,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in submitted successfully. Thank you for reaching out.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}


