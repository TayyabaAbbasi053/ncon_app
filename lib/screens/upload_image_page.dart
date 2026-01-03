import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/imgbb_upload_service.dart'; // Fixed import path

class UploadImagePage extends StatefulWidget {
  const UploadImagePage({super.key});

  @override
  State<UploadImagePage> createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    setState(() => _isUploading = true);

    final url = await ImgBBUploadService.uploadImage(_selectedImage!);

    setState(() {
      _isUploading = false;
      _uploadedImageUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Image to ImgBB')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _selectedImage != null
                  ? Image.file(_selectedImage!, height: 200)
                  : const Icon(Icons.image, size: 100, color: Colors.grey),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Pick Image'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadImage,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Upload to ImgBB'),
              ),
              const SizedBox(height: 20),
              if (_uploadedImageUrl != null) ...[
                const Text('Uploaded Successfully!'),
                const SizedBox(height: 10),
                SelectableText(_uploadedImageUrl!),
                const SizedBox(height: 10),
                Image.network(_uploadedImageUrl!, height: 200),
              ],
            ],
          ),
        ),
      ),
    );
  }
}