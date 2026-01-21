import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/colors.dart';
import '../services/firestore_service.dart';
import '../services/imgbb_upload_service.dart';
import '../models/post.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:intl/intl.dart';

class CreatePostScreen extends StatefulWidget {
  final ImagePicker _picker = ImagePicker();
  final String selectedCategory;

  CreatePostScreen({super.key, required this.selectedCategory});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _showLinkField = false;
  bool _showDateField = false;
  bool _showPriceField = false;
  DateTime? _selectedDate;

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((image) => File(image.path)));
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

// ADD THIS TO REMOVE AN IMAGE
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _pickStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  @override
  void initState() {
    super.initState();
    _showLinkField = widget.selectedCategory == 'Jobs' || widget.selectedCategory == 'Events';
    _showDateField = widget.selectedCategory == 'Events';
    _showPriceField = widget.selectedCategory == 'Marketplace' || widget.selectedCategory == 'Events'|| widget.selectedCategory == 'Carpooling';
  }

  Future<List<String>> _uploadImagesToImgBB() async {
    List<String> imageUrls = [];

    for (int i = 0; i < _selectedImages.length; i++) {
      try {
        String? imageUrl = await ImgBBUploadService.uploadImage(_selectedImages[i]);

        if (imageUrl != null) {
          imageUrls.add(imageUrl);
        }
      } catch (e) {
        debugPrint('Error uploading image: $e');
      }
    }

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

        List<String> imageUrls = [];
        if (_selectedImages.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Uploading images to ImgBB...')),
            );
          }

          imageUrls = await _uploadImagesToImgBB();

          if (imageUrls.isEmpty && _selectedImages.isNotEmpty) {
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

        String description = _descriptionController.text.trim();

        DateTime? startDateTime;
        DateTime? endDateTime;

        if (_selectedDate != null) {
          if (_startTime != null) {
            startDateTime = DateTime(
              _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
              _startTime!.hour, _startTime!.minute,
            );
          } else {
            startDateTime = _selectedDate;
          }

          if (_endTime != null) {
            endDateTime = DateTime(
              _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
              _endTime!.hour, _endTime!.minute,
            );
          }
        }

        double eventFee = double.tryParse(_priceController.text) ?? 0.0;

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
          eventDate: startDateTime,
          eventEndDate: endDateTime,
          eventFee: eventFee,
          price: double.tryParse(_priceController.text) ?? 0.0,
        );

        await _firestoreService.addPost(post);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.selectedCategory} post created successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
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
  Color _getCategoryColor() {
    switch (widget.selectedCategory) {
      case 'Carpooling': return AppColors.punchyCoral;
      case 'Marketplace': return AppColors.electricYellow;
      case 'Jobs': return AppColors.neonLime;
      case 'Events': return AppColors.electricBlue;
      case 'Newsletters': return AppColors.neonPurple;
      default: return AppColors.electricYellow;
    }
  }

  String _getCategoryInstructions() {
    switch (widget.selectedCategory) {
      case 'Carpooling':
        return 'Share your carpooling details';
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
    final accentColor = _getCategoryColor();

    return Scaffold(
      backgroundColor: AppColors.darkCharcoal,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        shape: Border(bottom: BorderSide(color: accentColor, width: 3)),
        title: Text(
          'Create ${widget.selectedCategory}',
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
        iconTheme: IconThemeData(color: accentColor),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: accentColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: accentColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getCategoryInstructions(),
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Title Field
                _buildInputField(
                  controller: _titleController,
                  label: 'Title',
                  icon: Icons.title,
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter a title' : null,
                  color: accentColor,
                ),
                const SizedBox(height: 16),

                // Price Field
                if (_showPriceField)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildInputField(
                      controller: _priceController,
                      label: widget.selectedCategory == 'Events' ? 'Entry Fee (Rs.)' : 'Price (Rs.)',
                      icon: Icons.payments,
                      keyboardType: TextInputType.number,
                      hint: widget.selectedCategory == 'Events' ? 'Leave blank if FREE' : null,
                      color: accentColor,
                    ),
                  ),

                // Description Field
                _buildTextAreaField(
                  controller: _descriptionController,
                  label: 'Description',
                  color: accentColor,
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 16),

                // Event Details
                if (_showDateField)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Event Schedule",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: accentColor,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: accentColor, width: 2),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month, color: accentColor),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDate == null ? 'Select Event Date' : DateFormat('EEEE, MMM d').format(_selectedDate!),
                                style: TextStyle(
                                  color: _selectedDate == null ? AppColors.greyText : Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickStartTime,
                              icon: const Icon(Icons.access_time, size: 18),
                              label: Text(_startTime == null ? "Start" : _startTime!.format(context)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accentColor,
                                side: BorderSide(color: accentColor, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickEndTime,
                              icon: const Icon(Icons.history, size: 18),
                              label: Text(_endTime == null ? "End" : _endTime!.format(context)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accentColor,
                                side: BorderSide(color: accentColor, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                // Link Field
                if (_showLinkField)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildInputField(
                      controller: _linkController,
                      label: 'Relevant Link (Optional)',
                      icon: Icons.link,
                      color: accentColor,
                    ),
                  ),

                // Image Picker
                if (widget.selectedCategory != 'Carpooling') ...[
                  Text(
                    'Photos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickImages,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        side: BorderSide(color: accentColor, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Add Images'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedImages.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) => Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: accentColor, width: 2),
                            ),
                            child: Image.file(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.punchyCoral,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black,
                                      offset: Offset(2, 2),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close, size: 14, color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: Colors.black, width: 3),
                        ),
                        margin: const EdgeInsets.only(left: 4, top: 4),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: const BorderSide(color: Colors.black, width: 3),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        )
                            : Text(
                          'POST',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    required Color color,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w900),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.greyText),
        prefixIcon: Icon(icon, color: color),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: color, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: color, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: color, width: 3),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildTextAreaField({
    required TextEditingController controller,
    required String label,
    required Color color,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 5,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w900),
        alignLabelWithHint: true,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: color, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: color, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: color, width: 3),
        ),
      ),
      validator: validator,
    );
  }
}
