import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../providers/data_providers.dart';
import 'marketplace_home_screen.dart';
import 'lost_found_screen.dart';

class CreateLostFoundScreen extends ConsumerStatefulWidget {
  const CreateLostFoundScreen({super.key});

  @override
  ConsumerState<CreateLostFoundScreen> createState() => _CreateLostFoundScreenState();
}

class _CreateLostFoundScreenState extends ConsumerState<CreateLostFoundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _colorController = TextEditingController();
  final _sizeController = TextEditingController();
  final _foundLocationController = TextEditingController();
  final _rewardController = TextEditingController();
  final _verificationDetailsController = TextEditingController();

  String _category = 'other';
  DateTime? _foundDate;
  bool _verificationRequired = false;
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];

  final List<String> _categories = [
    'electronics',
    'clothing',
    'books',
    'accessories',
    'documents',
    'keys',
    'other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    _foundLocationController.dispose();
    _rewardController.dispose();
    _verificationDetailsController.dispose();
    super.dispose();
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'electronics':
        return 'Electronics';
      case 'clothing':
        return 'Clothing';
      case 'books':
        return 'Books';
      case 'accessories':
        return 'Accessories';
      case 'documents':
        return 'Documents';
      case 'keys':
        return 'Keys';
      case 'other':
        return 'Other';
      default:
        return 'Other';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _foundDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _foundDate) {
      setState(() {
        _foundDate = picked;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) {
      return [];
    }

    final apiService = ref.read(apiServiceProvider);
    final List<String> imageUrls = [];

    for (final image in _selectedImages) {
      try {
        final url = await apiService.uploadMarketplaceImage(image);
        imageUrls.add(url);
      } catch (e) {
        print('Error uploading image: $e');
        // Continue with other images even if one fails
      }
    }

    return imageUrls;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final currentUser = ref.read(authStateProvider).user;
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      if (currentUser.email.isEmpty) {
        throw Exception('Email is required. Please update your profile.');
      }
      
      // Create lost found item with nested marketplace item
      // Backend will automatically fetch email and phone from user profile
      
      // Upload images first
      final imageUrls = await _uploadImages();
      
      // Build marketplace item data
      final marketplaceItemData = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 'available',
        'images': imageUrls,
        'tags': <String>[],
      };
      
      // Build lost found item data (remove null values)
      final lostFoundData = <String, dynamic>{
        'marketplace_item': marketplaceItemData,
        'category': _category,
        'verification_required': _verificationRequired,
      };
      
      // Only add optional fields if they have values
      final brand = _brandController.text.trim();
      if (brand.isNotEmpty) {
        lostFoundData['brand'] = brand;
      }
      
      final color = _colorController.text.trim();
      if (color.isNotEmpty) {
        lostFoundData['color'] = color;
      }
      
      final size = _sizeController.text.trim();
      if (size.isNotEmpty) {
        lostFoundData['size'] = size;
      }
      
      final foundLocation = _foundLocationController.text.trim();
      if (foundLocation.isNotEmpty) {
        lostFoundData['found_location'] = foundLocation;
      }
      
      if (_foundDate != null) {
        lostFoundData['found_date'] = DateFormat('yyyy-MM-dd').format(_foundDate!);
      }
      
      final rewardStr = _rewardController.text.trim();
      if (rewardStr.isNotEmpty) {
        final reward = double.tryParse(rewardStr);
        if (reward != null && reward > 0) {
          lostFoundData['reward_offered'] = reward;
        }
      }
      
      final verificationDetails = _verificationDetailsController.text.trim();
      if (verificationDetails.isNotEmpty) {
        lostFoundData['verification_details'] = verificationDetails;
      }

      // Create the lost found item via the API
      // Backend will create marketplace item and link it automatically
      await apiService.createLostFoundItem(lostFoundData);

      if (mounted) {
        // Invalidate marketplace items to refresh the list
        ref.invalidate(marketplaceItemsProvider);
        ref.invalidate(lostFoundItemsProvider); // This is defined in lost_found_screen.dart
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lost & Found item posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating listing: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Lost & Found'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/marketplace');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(marketplaceItemsProvider('all'));
              ref.invalidate(lostFoundItemsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Item Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
                hintText: 'e.g., Lost iPhone 14, Found Blue Backpack',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter item title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'Describe the item in detail...',
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_getCategoryLabel(category)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _category = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Brand
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Brand (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.branding_watermark),
              ),
            ),
            const SizedBox(height: 16),

            // Color
            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Color (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.palette),
              ),
            ),
            const SizedBox(height: 16),

            // Size
            TextFormField(
              controller: _sizeController,
              decoration: const InputDecoration(
                labelText: 'Size (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.aspect_ratio),
              ),
            ),
            const SizedBox(height: 16),

            // Images Section
            Text(
              'Item Photos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Selected Images Grid
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    final image = _selectedImages[index];
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? Image.network(
                                    image.path,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(image.path),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, size: 18, color: Colors.white),
                                onPressed: () => _removeImage(index),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Add Image Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Select from Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Found Location
            TextFormField(
              controller: _foundLocationController,
              decoration: const InputDecoration(
                labelText: 'Found/Lost Location (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),

            // Found Date
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Found/Lost Date (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _foundDate != null
                      ? DateFormat('MMM dd, yyyy').format(_foundDate!)
                      : 'Select date',
                  style: TextStyle(
                    color: _foundDate != null ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reward Offered
            TextFormField(
              controller: _rewardController,
              decoration: const InputDecoration(
                labelText: 'Reward Offered (₹) (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (double.tryParse(value) == null || double.parse(value) < 0) {
                    return 'Please enter a valid reward amount';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Verification Required
            SwitchListTile(
              title: const Text('Verification Required'),
              subtitle: const Text('Item requires verification before claim'),
              value: _verificationRequired,
              onChanged: (value) {
                setState(() {
                  _verificationRequired = value;
                });
              },
            ),
            const SizedBox(height: 8),

            // Verification Details
            if (_verificationRequired) ...[
              TextFormField(
                controller: _verificationDetailsController,
                decoration: const InputDecoration(
                  labelText: 'Verification Details',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.verified_user),
                  hintText: 'What details are needed to verify ownership?',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
            ],

            // Contact Info (Read-only from profile)
            Consumer(
              builder: (context, ref, child) {
                final currentUser = ref.watch(authStateProvider).user;
                return Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Contact Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (currentUser != null) ...[
                          Row(
                            children: [
                              Icon(Icons.email, size: 16, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Email: ${currentUser.email}',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 16, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Phone: ${currentUser.phoneNumber ?? "Not provided"}',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          if (currentUser.phoneNumber == null || currentUser.phoneNumber!.isEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              '⚠️ Phone number not found. Please update your profile.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Text('Post Item', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

