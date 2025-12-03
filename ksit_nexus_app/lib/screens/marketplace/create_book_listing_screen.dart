import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../providers/data_providers.dart';
import 'marketplace_home_screen.dart';
import 'books_screen.dart';
import '../../models/user_model.dart';

class CreateBookListingScreen extends ConsumerStatefulWidget {
  const CreateBookListingScreen({super.key});

  @override
  ConsumerState<CreateBookListingScreen> createState() => _CreateBookListingScreenState();
}

class _CreateBookListingScreenState extends ConsumerState<CreateBookListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _publisherController = TextEditingController();
  final _editionController = TextEditingController();
  final _yearController = TextEditingController();
  final _priceController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _semesterController = TextEditingController();
  final _locationController = TextEditingController();

  String _condition = 'good';
  bool _negotiable = true;
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];

  final List<String> _conditions = [
    'new',
    'like_new',
    'good',
    'fair',
    'poor',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _publisherController.dispose();
    _editionController.dispose();
    _yearController.dispose();
    _priceController.dispose();
    _courseCodeController.dispose();
    _semesterController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _getConditionLabel(String condition) {
    switch (condition) {
      case 'new':
        return 'New';
      case 'like_new':
        return 'Like New';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      default:
        return 'Good';
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
      
      // Create book listing with nested marketplace item
      // Backend will automatically fetch email and phone from user profile
      
      // Upload images first
      final imageUrls = await _uploadImages();
      
      // Build marketplace item data (remove null values)
      final marketplaceItemData = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 'available',
        'images': imageUrls,
        'tags': <String>[],
      };
      
      // Only add location if it's not empty
      final location = _locationController.text.trim();
      if (location.isNotEmpty) {
        marketplaceItemData['location'] = location;
      }
      
      // Build book listing data (remove null values)
      final bookData = <String, dynamic>{
        'marketplace_item': marketplaceItemData,
        'author': _authorController.text.trim(),
        'condition': _condition,
        'price': double.parse(_priceController.text.trim()).toString(),
        'negotiable': _negotiable,
      };
      
      // Only add optional fields if they have values
      final isbn = _isbnController.text.trim();
      if (isbn.isNotEmpty) {
        bookData['isbn'] = isbn;
      }
      
      final publisher = _publisherController.text.trim();
      if (publisher.isNotEmpty) {
        bookData['publisher'] = publisher;
      }
      
      final edition = _editionController.text.trim();
      if (edition.isNotEmpty) {
        bookData['edition'] = edition;
      }
      
      final yearStr = _yearController.text.trim();
      if (yearStr.isNotEmpty) {
        final year = int.tryParse(yearStr);
        if (year != null) {
          bookData['year'] = year;
        }
      }
      
      final courseCode = _courseCodeController.text.trim();
      if (courseCode.isNotEmpty) {
        bookData['course_code'] = courseCode;
      }
      
      final semesterStr = _semesterController.text.trim();
      if (semesterStr.isNotEmpty) {
        final semester = int.tryParse(semesterStr);
        if (semester != null) {
          bookData['semester'] = semester;
        }
      }

      // Create the book listing via the API
      // Backend will create marketplace item and link it automatically
      await apiService.createBookListing(bookData);

      if (mounted) {
        // Invalidate marketplace items to refresh the list
        ref.invalidate(marketplaceItemsProvider);
        ref.invalidate(bookListingsProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book listing created successfully!'),
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
        title: const Text('Create Book Listing'),
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
              ref.invalidate(bookListingsProvider);
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
                labelText: 'Book Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter book title';
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
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Author
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter author name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ISBN
            TextFormField(
              controller: _isbnController,
              decoration: const InputDecoration(
                labelText: 'ISBN (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (₹) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter price';
                }
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Condition
            DropdownButtonFormField<String>(
              value: _condition,
              decoration: const InputDecoration(
                labelText: 'Condition *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.check_circle),
              ),
              items: _conditions.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text(_getConditionLabel(condition)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _condition = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Negotiable
            SwitchListTile(
              title: const Text('Price Negotiable'),
              value: _negotiable,
              onChanged: (value) {
                setState(() {
                  _negotiable = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Course Code
            TextFormField(
              controller: _courseCodeController,
              decoration: const InputDecoration(
                labelText: 'Course Code (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
            ),
            const SizedBox(height: 16),

            // Semester
            TextFormField(
              controller: _semesterController,
              decoration: const InputDecoration(
                labelText: 'Semester (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Publisher
            TextFormField(
              controller: _publisherController,
              decoration: const InputDecoration(
                labelText: 'Publisher (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),

            // Edition
            TextFormField(
              controller: _editionController,
              decoration: const InputDecoration(
                labelText: 'Edition (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bookmark),
              ),
            ),
            const SizedBox(height: 16),

            // Year
            TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Year (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_month),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),

            // Images Section
            Text(
              'Book Photos',
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
                  : const Text('Create Listing', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

