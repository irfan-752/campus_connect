import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditLogService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  AuditLogService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> logAction({
    required String action,
    required String resource,
    String? details,
    String? ipAddress,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get user name
      String userName = 'Unknown';
      try {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          userName = userDoc.data()?['name'] ?? 'Unknown';
        }
      } catch (e) {
        // Ignore error
      }

      await _db.collection('audit_logs').add({
        'action': action,
        'userId': user.uid,
        'userName': userName,
        'resource': resource,
        'details': details,
        'ipAddress': ipAddress,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error logging audit: $e');
      // Don't throw - audit logging should not break the app
    }
  }
}

