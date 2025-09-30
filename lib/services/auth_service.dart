import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register user
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;
      final now = DateTime.now().millisecondsSinceEpoch;

      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': role,
        'approved': role == 'Admin' ? true : false,
        'avatarUrl': null,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      // Create role specific skeleton document if needed
      if (role == 'Student') {
        await _firestore.collection('students').doc(uid).set({
          'name': name,
          'email': email,
          'avatarUrl': null,
          'attendance': 0.0,
          'gpa': 0.0,
          'eventsParticipated': 0,
          'courses': <String>[],
          'department': '',
          'semester': '',
          'parentEmail': null,
          'createdAt': now,
          'updatedAt': now,
        }, SetOptions(merge: true));
      } else if (role == 'Teacher' || role == 'Mentor') {
        await _firestore.collection('mentors').doc(uid).set({
          'userId': uid,
          'name': name,
          'email': email,
          'department': '',
          'designation': 'Mentor',
          'avatarUrl': null,
          'studentIds': <String>[],
          'specialization': '',
          'experience': '',
          'isAvailable': true,
          'createdAt': now,
          'updatedAt': now,
        }, SetOptions(merge: true));
      }
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Login user
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Forgot password
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }
}
