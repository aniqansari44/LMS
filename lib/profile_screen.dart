import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();
  User? _currentUser;
  String _role = '';
  String _name = '';
  String _email = '';
  String _profileImageUrl = '';
  File? _profileImage;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _getUserRole();
    _getUserInfo();
  }

  Future<void> _getUserRole() async {
    if (_currentUser != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (mounted) {
        setState(() {
          _role = userDoc['role'];
        });
      }
    }
  }

  Future<void> _getUserInfo() async {
    if (_currentUser != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (mounted) {
        setState(() {
          _name = userDoc['name'];
          _email = userDoc['email'];
          _profileImageUrl = userDoc['profileImageUrl'] ?? '';
        });
      }
    }
  }

  Future<void> _updateUserInfo() async {
    setState(() {
      _isUpdating = true;
    });
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      if (_currentUser != null) {
        await _firestore.collection('users').doc(_currentUser!.uid).update({
          'name': _name,
          'email': _email,
        });

        if (_profileImage != null) {
          String fileName = _currentUser!.uid + '.jpg';
          try {
            await _storage.ref('profile_pictures/$fileName').putFile(_profileImage!);
            String profileImageUrl = await _storage.ref('profile_pictures/$fileName').getDownloadURL();
            await _firestore.collection('users').doc(_currentUser!.uid).update({
              'profileImageUrl': profileImageUrl,
            });
            setState(() {
              _profileImageUrl = profileImageUrl;
            });
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload profile picture')));
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated')));
        }
      }
    }
    setState(() {
      _isUpdating = false;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_role.isEmpty) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : _profileImageUrl.isNotEmpty
                      ? NetworkImage(_profileImageUrl) as ImageProvider
                      : null,
                  child: _profileImage == null && _profileImageUrl.isEmpty
                      ? Icon(Icons.camera_alt, size: 50)
                      : null,
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) => value?.isEmpty ?? true ? 'Enter your name' : null,
                onSaved: (value) => _name = value ?? '',
              ),
              TextFormField(
                initialValue: _email,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) => value?.isEmpty ?? true ? 'Enter your email' : null,
                onSaved: (value) => _email = value ?? '',
              ),
              SizedBox(height: 16.0),
              _isUpdating
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _updateUserInfo,
                child: Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
