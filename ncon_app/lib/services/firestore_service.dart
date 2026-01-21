import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../models/user.dart' as app_user;
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -------------------- POSTS --------------------

  Stream<List<Post>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['postId'] = doc.id;
        return Post.fromMap(data);
      }).toList();
    });
  }

  Stream<List<Post>> getPostsByCategory(String category) {
    return _firestore
        .collection('posts')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['postId'] = doc.id;
        return Post.fromMap(data);
      }).toList();
    });
  }

  Future<void> addPost(Post post) async {
    try {
      await _firestore.collection('posts').add(post.toMap());
      debugPrint('✅ Post added to Firestore');
      debugPrint('🖼️ Post images: ${post.images}');
    } catch (e) {
      debugPrint('❌ Error adding post: ${e.toString()}');
      rethrow;
    }
  }
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      print("Error deleting post: $e");
      rethrow;
    }
  }

  // -------------------- PLACES --------------------

  Future<void> addPlace(String name, String description, String imageUrl) async {
    try {
      await _firestore.collection('places').add({
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'createdAt': DateTime.now(),
      });
      debugPrint('✅ Place added to Firestore');
    } catch (e) {
      debugPrint('❌ Error adding place: ${e.toString()}');
      rethrow;
    }
  }

  // -------------------- USERS --------------------

  Future<app_user.User?> getUser(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return app_user.User.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user: ${e.toString()}');
      return null;
    }
  }

  Future<void> updateUser(app_user.User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(
            user.toMap(),
            SetOptions(merge: true),
          );
      debugPrint('✅ User updated');
    } catch (e) {
      debugPrint('❌ Error updating user: ${e.toString()}');
    }
  }
  Future<Post?> getPostById(String postId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('posts').doc(postId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        // Inject the ID into the map just like you do in getPosts()
        data['postId'] = doc.id;

        // Now pass only the map to fromMap
        return Post.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching post by ID: $e");
      return null;
    }
  }
  Future<void> updatePost(String postId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('posts').doc(postId).update(updatedData);
      debugPrint('✅ Post updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating post: ${e.toString()}');
      rethrow;
    }
  }

  Future<String> uploadImage(File file) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref = FirebaseStorage.instance.ref().child('post_images').child(fileName);
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}