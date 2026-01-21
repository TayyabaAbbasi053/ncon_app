import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ncon_app/models/post.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../services/imgbb_upload_service.dart';
import '../utils/colors.dart';

class AddPostScreen extends StatefulWidget {
  final Post? postToEdit;
  const AddPostScreen({super.key, this.postToEdit});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  // 1. Controllers to hold text data
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  bool _isEditing = false;
  bool _isPressed = false;
  bool _isUploading = false;
  List<String> imageUrls = [];
  final ImagePicker _picker = ImagePicker();
  List<File> _newFiles = [];

  @override
  void initState() {
    super.initState();
    // 2. Check if we are editing or creating
    _isEditing = widget.postToEdit != null;
    if (_isEditing) {
      imageUrls = List<String>.from(widget.postToEdit!.images);
    }

    // 3. Pre-fill if editing, otherwise leave blank
    _titleController = TextEditingController(text: _isEditing ? widget.postToEdit!.title : '');
    _descController = TextEditingController(text: _isEditing ? widget.postToEdit!.description : '');
    double displayPrice = 0.0;
    if (_isEditing) {
      displayPrice = (widget.postToEdit!.price != 0)
          ? widget.postToEdit!.price
          : (widget.postToEdit!.eventFee ?? 0.0);
    }

    _priceController = TextEditingController(
        text: _isEditing ? displayPrice.toString() : ''
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // 4. Save/Update Logic
  void _savePost() async {
    final user = FirebaseAuth.instance.currentUser;
    final String currentUid = user?.uid ?? '';
    final String currentName = user?.displayName ?? 'Anonymous';
    if (currentUid.isEmpty) {  // Optional: show an error if not logged in
      return;
    }
    // Remove everything except numbers and dots before saving
    String cleanPrice = _priceController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    double finalPrice = double.tryParse(cleanPrice) ?? 0.0;
    final data = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'images': imageUrls,
      'price': finalPrice,
      'eventFee': finalPrice,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (_isEditing) {
      await FirestoreService().updatePost(widget.postToEdit!.postId, data);
    } else {
      Post newPost = Post(
        postId: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: finalPrice,
        category: 'General', // Or get this from a dropdown/field
        authorId: currentUid, // Your model uses authorId
        authorName: currentName,
        createdAt: DateTime.now(),
        images: imageUrls,
        links: [], // Default empty list
      );
      await FirestoreService().addPost(newPost);
    }
    if (mounted) Navigator.pop(context);
  }
  Future<void> _pickNewImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isUploading = true);

      try {
        // FIX: Use ImgBBUploadService instead of FirestoreService
        String? downloadUrl = await ImgBBUploadService.uploadImage(File(pickedFile.path));

        if (downloadUrl != null) {
          setState(() {
            imageUrls.add(downloadUrl);
            _isUploading = false;
          });
        }
      } catch (e) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppColors.darkCharcoal,
      appBar: AppBar(
        title: Text(_isEditing ? "EDIT POST" : "NEW POST",
            style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        // 2. Wrap everything in a SingleChildScrollView so it doesn't overflow when the keyboard opens
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align labels to the left
            children: [
              _buildBrutalistField("TITLE", _titleController),
              const SizedBox(height: 20),

              // 3. Insert the Image UI here
              const Text("IMAGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length + 1,
                  itemBuilder: (context, index) {
                    if (_isUploading) {
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 4, bottom:4),
                        decoration: BoxDecoration(border: Border.all(color: Colors.white)),
                        child: const Center(child: CircularProgressIndicator(color: AppColors.neonLime)),
                      );
                    }
                    if (index == 0) {
                      return GestureDetector(
                        onTap: _pickNewImage,
                        child: Container(
                          margin: const EdgeInsets.only(right: 4, bottom:4),
                          width: 100,
                          height: 100,
                          child: CustomPaint(
                            painter: DashedBorderPainter(
                              color: _isEditing ? AppColors.electricBlue : AppColors.neonLime,
                            ),
                            child: Container(
                              color: Colors.black.withOpacity(0.5), // Semi-transparent black background
                              child: const Icon(Icons.add_a_photo, color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    }
                    final imageIndex = index - 1;
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            image: DecorationImage(
                                image: NetworkImage(imageUrls[imageIndex]),
                                fit: BoxFit.cover
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8, // Adjusted for margin
                          top: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => imageUrls.removeAt(imageIndex)),
                            child: Container(
                              color: Colors.black,
                              child: const Icon(Icons.close, color: Colors.red, size: 20),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              _buildBrutalistField("PRICE", _priceController, isNumber: true),
              const SizedBox(height: 20),
              _buildBrutalistField("DESCRIPTION", _descController, maxLines: 5),

              const SizedBox(height: 40), // Use spacing instead of Spacer inside ScrollView

              // SUBMIT BUTTON
              GestureDetector(
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapUp: (_) => setState(() => _isPressed = false),
                onTapCancel: () => setState(() => _isPressed = false),
                onTap: _savePost,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100), // Speed of the "squish"
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  transform: Matrix4.identity()
                    ..scale(_isPressed ? 0.95 : 1.0), // Shrinks to 95% size
                  decoration: BoxDecoration(
                    color: _isPressed
                        ? Colors.white // Flashes white on tap for "pop"
                        : (_isEditing ? AppColors.electricBlue : AppColors.neonLime),
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: _isPressed ? [] : [
                      // Brutalist "Hard Shadow" that disappears when pressed
                      const BoxShadow(color: Colors.black, offset: Offset(4, 4))
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isEditing ? "SAVE CHANGES" : "PUBLISH POST",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for Brutalist Text Fields
  Widget _buildBrutalistField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _isEditing ? AppColors.electricBlue : AppColors.neonLime, width: 2),
              borderRadius: BorderRadius.circular(5),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ],
    );
  }
}
class DashedBorderPainter extends CustomPainter {
  final Color color;
  DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 8, dashSpace = 4, strokeWidth = 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path = Path();
    // Create a rectangular path
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Manually draw the dashes
    for (PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}