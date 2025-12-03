import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ResponsiveContainer(
        maxWidth: Responsive.value(
          context: context,
          mobile: double.infinity,
          tablet: 600,
          desktop: 700,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bug_report,
                size: Responsive.value(context: context, mobile: 64.0, tablet: 80.0, desktop: 96.0),
                color: AppTheme.primaryColor,
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
              Text(
                'API Testing',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 24),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 10)),
              Text(
                'Test backend API endpoints',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 16),
                  color: AppTheme.grey600,
                ),
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28)),
              Text(
                'Feature coming soon!',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                  color: AppTheme.info,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}