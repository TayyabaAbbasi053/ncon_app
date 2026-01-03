import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/colors.dart';
import '../services/firestore_service.dart';
import '../services/imgbb_upload_service.dart';
import '../models/post.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class CreatePostScreen extends StatefulWidget {
  final String selectedCategory;

  const CreatePostScreen({super.key, required this.selectedCategory});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  
  final FirestoreService _firestoreService = FirestoreService();
  final List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _showLinkField = false;
  bool _showDateField = false;
  bool _showPriceField = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _showLinkField = widget.selectedCategory == 'Jobs' || 
                    widget.selectedCategory == 'Events';
    _showDateField = widget.selectedCategory == 'Events';
    _showPriceField = widget.selectedCategory == 'Marketplace';
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      
      if (images != null && images.isNotEmpty && mounted) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
        debugPrint('📸 Selected ${images.length} images');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImagesToImgBB() async {
    List<String> imageUrls = [];
    
    for (int i = 0; i < _selectedImages.length; i++) {
      try {
        debugPrint('🔄 Uploading image $i to ImgBB...');
        String? imageUrl = await ImgBBUploadService.uploadImage(_selectedImages[i]);
        
        if (imageUrl != null) {
          imageUrls.add(imageUrl);
          debugPrint('✅ Image $i uploaded successfully: $imageUrl');
        } else {
          debugPrint('❌ Failed to upload image $i');
        }
      } catch (e) {
        debugPrint('❌ Error uploading image $i: $e');
      }
    }
    
    debugPrint('📤 Total images uploaded to ImgBB: ${imageUrls.length}');
    return imageUrls;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitPost() async {
    if (_formKey.currentState!.validate()) {
      if (_showDateField && _selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an event date')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final user = firebase_auth.FirebaseAuth.instance.currentUser;
        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please login to create posts')),
            );
          }
          return;
        }

        final userData = await _firestoreService.getUser(user.uid);
        if (userData == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User data not found')),
            );
          }
          return;
        }

        // Upload images to ImgBB
        List<String> imageUrls = [];
        if (_selectedImages.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Uploading images to ImgBB...')),
            );
          }
          
          imageUrls = await _uploadImagesToImgBB();
          
          if (imageUrls.isEmpty) {
            debugPrint('⚠️ No images were uploaded successfully to ImgBB');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to upload images. Please try again.')),
              );
            }
          }
        }

        List<String> links = [];
        if (_linkController.text.isNotEmpty) {
          links.add(_linkController.text);
        }

        // Add price to description for Marketplace posts
        String description = _descriptionController.text.trim();
        if (_showPriceField && _priceController.text.isNotEmpty) {
          description = 'Price: Rs. ${_priceController.text}\n\n$description';
        }

        final post = Post(
          postId: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          description: description,
          category: widget.selectedCategory,
          authorId: user.uid,
          authorName: userData.name,
          createdAt: DateTime.now(),
          images: imageUrls,
          links: links,
          eventDate: _selectedDate,
        );

        debugPrint('🎯 FINAL POST DATA:');
        debugPrint('🎯 Title: ${post.title}');
        debugPrint('🎯 Category: ${post.category}');
        debugPrint('🎯 Images count: ${post.images.length}');
        debugPrint('🎯 Image URLs: ${post.images}');

        await _firestoreService.addPost(post);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.selectedCategory} post created successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint('❌ Error creating post: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating post: $e')),
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
  }

  String _getCategoryInstructions() {
    switch (widget.selectedCategory) {
      case 'Carpooling':
        return 'Share your carpooling details (e.g., "I am in C1 and going to C2")';
      case 'Marketplace':
        return 'Describe your item, set a price, and add images from gallery';
      case 'Jobs':
        return 'Share job details, requirements, and application link';
      case 'Events':
        return 'Describe your event and share relevant links. Don\'t forget to set the event date!';
      case 'Newsletters':
        return 'Create a detailed newsletter with proper formatting';
      default:
        return 'Create a new post';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Create ${widget.selectedCategory} Post',
          style: TextStyle(color: AppColors.primary),
        ),
        iconTheme: IconThemeData(color: AppColors.primary),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getCategoryInstructions(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.title, color: AppColors.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Price Field (only for Marketplace)
                if (_showPriceField)
                  Column(
                    children: [
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Price (Rs.)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a price';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: _showPriceField ? 'Item Description' : 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Event Date Field (only for Events)
                if (_showDateField)
                  Column(
                    children: [
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDate == null
                                    ? 'Select Event Date'
                                    : 'Event Date: ${_selectedDate!.toString().split(' ')[0]}',
                                style: TextStyle(
                                  color: _selectedDate == null ? Colors.grey : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Link Field (only for Jobs and Events)
                if (_showLinkField)
                  Column(
                    children: [
                      TextFormField(
                        controller: _linkController,
                        decoration: InputDecoration(
                          labelText: 'Link (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.link, color: AppColors.primary),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Image Picker (for all except Carpooling)
                if (widget.selectedCategory != 'Carpooling')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Images (optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.photo_library, color: Colors.white),
                        label: const Text(
                          'Pick Images from Gallery',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Selected Images Grid
                      if (_selectedImages.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Images (${_selectedImages.length})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: FileImage(_selectedImages[index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            'Create Post',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}