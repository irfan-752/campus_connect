import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  GroupService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<Map<String, dynamic>?> _getCurrentStudentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('students').doc(user.uid).get();
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> fetchEligiblePeers() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final me = await _getCurrentStudentProfile();
    if (me == null) return [];

    final department = me['department'];
    final semester = me['semester'];

    final snapshot = await _db
        .collection('students')
        .where('department', isEqualTo: department)
        .where('semester', isEqualTo: semester)
        .get();

    return snapshot.docs
        .where((d) => d.id != user.uid)
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
  }

  Future<String> createPeerGroup({
    required String groupName,
    required List<String> memberStudentIds,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    if (memberStudentIds.isEmpty) {
      throw Exception('Select at least one peer');
    }

    final me = await _getCurrentStudentProfile();
    if (me == null) {
      throw Exception('Student profile not found');
    }

    final department = me['department'];
    final semester = me['semester'];

    // Load all selected peers and validate department/semester
    final peerDocs = await _db
        .collection('students')
        .where(FieldPath.documentId, whereIn: memberStudentIds)
        .get();

    if (peerDocs.docs.length != memberStudentIds.length) {
      throw Exception('Some selected peers no longer exist');
    }

    final invalid = peerDocs.docs.where((doc) {
      final data = doc.data();
      return data['department'] != department || data['semester'] != semester;
    }).toList();

    if (invalid.isNotEmpty) {
      throw Exception('Peers must be from same department and semester');
    }

    final participants = <String>{user.uid, ...memberStudentIds}.toList();
    final now = DateTime.now().millisecondsSinceEpoch;

    final chatRoomRef = await _db.collection('chat_rooms').add({
      'name': groupName,
      'description': 'Peer group',
      'type': 'Group',
      'participants': participants,
      'createdBy': user.uid,
      'createdAt': now,
      'lastMessageAt': now,
      'lastMessage': null,
      'isActive': true,
    });

    return chatRoomRef.id;
  }
}
