import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../providers/data_providers.dart';
import '../../models/chatbot_nlp_model.dart';
import '../../services/api_service.dart';

class ChatbotProfileScreen extends ConsumerStatefulWidget {
  const ChatbotProfileScreen({super.key});

  @override
  ConsumerState<ChatbotProfileScreen> createState() => _ChatbotProfileScreenState();
}

class _ChatbotProfileScreenState extends ConsumerState<ChatbotProfileScreen> {
  bool _isLoading = false;
  bool _isSaving = false;
  ChatbotUserProfile? _profile;
  ChatbotUserStatistics? _statistics;
  String? _errorMessage;

  // Profile form controllers
  String? _selectedLanguage;
  String? _selectedResponseStyle;
  bool? _isPersonalizedEnabled;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final profile = await apiService.getChatbotUserProfile();
      final statistics = await apiService.getUserStatistics();

      setState(() {
        _profile = profile;
        _statistics = statistics;
        _selectedLanguage = _profile?.preferredLanguage ?? 'en';
        _selectedResponseStyle = _profile?.responseStyle ?? 'friendly';
        _isPersonalizedEnabled = _profile?.isPersonalized ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.updateChatbotUserProfile(
        preferredLanguage: _selectedLanguage,
        responseStyle: _selectedResponseStyle,
        isPersonalizedEnabled: _isPersonalizedEnabled,
        preferences: _profile?.preferences,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        await _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update profile: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/chatbot');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadProfile();
            },
            tooltip: 'Refresh',
          ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
              tooltip: 'Save',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _profile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ResponsiveContainer(
                  maxWidth: Responsive.value(
                    context: context,
                    mobile: double.infinity,
                    tablet: 800,
                    desktop: 1000,
                  ),
                  padding: Responsive.padding(context),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Overview Card
                        if (_profile != null) _buildProfileOverviewCard(),
                        const SizedBox(height: 24),

                        // Personalization Settings
                        _buildPersonalizationSettings(),
                        const SizedBox(height: 24),

                        // Statistics Card
                        if (_statistics != null) _buildStatisticsCard(),
                        const SizedBox(height: 24),

                        // Common Topics
                        if (_profile != null && _profile!.commonTopics != null && _profile!.commonTopics!.isNotEmpty)
                          _buildCommonTopicsCard(),
                        const SizedBox(height: 24),

                        // Preferred Categories
                        if (_profile != null && _profile!.preferredCategories != null && _profile!.preferredCategories!.isNotEmpty)
                          _buildPreferredCategoriesCard(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileOverviewCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    size: 30,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chatbot Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.grey900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Personalize your AI assistant experience',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizationSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personalization Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.grey900,
              ),
            ),
            const SizedBox(height: 16),

            // Preferred Language
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: InputDecoration(
                labelText: 'Preferred Language',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.language),
              ),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                DropdownMenuItem(value: 'kn', child: Text('Kannada')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Response Style
            DropdownButtonFormField<String>(
              value: _selectedResponseStyle,
              decoration: InputDecoration(
                labelText: 'Response Style',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.chat_bubble_outline),
              ),
              items: const [
                DropdownMenuItem(value: 'friendly', child: Text('Friendly')),
                DropdownMenuItem(value: 'formal', child: Text('Formal')),
                DropdownMenuItem(value: 'casual', child: Text('Casual')),
                DropdownMenuItem(value: 'professional', child: Text('Professional')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedResponseStyle = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Personalization Toggle
            SwitchListTile(
              title: const Text('Enable Personalization'),
              subtitle: const Text('Allow the chatbot to learn from your interactions'),
              value: _isPersonalizedEnabled ?? true,
              onChanged: (value) {
                setState(() {
                  _isPersonalizedEnabled = value;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.grey900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Interactions',
                    '${_statistics!.totalInteractions ?? 0}',
                    Icons.chat,
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Total Sessions',
                    '${_statistics!.totalSessions ?? 0}',
                    Icons.chat_bubble,
                    AppTheme.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Average Rating',
                    _statistics!.averageRating != null
                        ? '${_statistics!.averageRating!.toStringAsFixed(1)}/5.0'
                        : 'N/A',
                    Icons.star,
                    AppTheme.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Total Messages',
                    '${_statistics!.totalMessagesCount ?? 0}',
                    Icons.message,
                    AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.grey600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonTopicsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Common Topics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.grey900,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _profile!.commonTopics!.map((topic) {
                return Chip(
                  label: Text(topic),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  labelStyle: TextStyle(color: AppTheme.primaryColor),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferredCategoriesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferred Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.grey900,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _profile!.preferredCategories!.map((category) {
                return Chip(
                  label: Text(category),
                  backgroundColor: AppTheme.success.withOpacity(0.1),
                  labelStyle: TextStyle(color: AppTheme.success),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

