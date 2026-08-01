import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../models/bucket_item.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String? _spaceId;
  String? get spaceId => _spaceId;

  Future<void> init() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    final prefs = await SharedPreferences.getInstance();
    _spaceId = prefs.getString('spaceId');
  }

  bool get isPaired => _spaceId != null;

  Future<void> joinSpace(String rawCode) async {
    final code = rawCode.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spaceId', code);
    _spaceId = code;

    final ref = _db.collection('spaces').doc(code);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'createdAt': FieldValue.serverTimestamp(),
        'anniversary': Timestamp.fromDate(DateTime(2026, 2, 4)),
      });
    }
  }

  DocumentReference<Map<String, dynamic>> get _spaceRef =>
      _db.collection('spaces').doc(_spaceId);

  Stream<List<Note>> notesStream() {
    return _spaceRef
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map(Note.fromDoc).toList());
  }

  Future<void> addNote(String text, String authorName) async {
    await _spaceRef.collection('notes').add(
          Note(
            id: '',
            text: text,
            authorId: _auth.currentUser!.uid,
            authorName: authorName,
            createdAt: DateTime.now(),
          ).toMap(),
        );
  }

  Future<void> updateNote(String id, String text) async {
    await _spaceRef.collection('notes').doc(id).update({'text': text});
  }

  Future<void> deleteNote(String id) async {
    await _spaceRef.collection('notes').doc(id).delete();
  }

  Stream<List<BucketItem>> bucketStream() {
    return _spaceRef
        .collection('bucket_list')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map(BucketItem.fromDoc).toList());
  }

  Future<void> addBucketItem(String title) async {
    await _spaceRef.collection('bucket_list').add(
          BucketItem(
            id: '',
            title: title,
            completed: false,
            createdBy: _auth.currentUser!.uid,
            createdAt: DateTime.now(),
          ).toMap(),
        );
  }

  Future<void> updateBucketItem(String id, String title) async {
    await _spaceRef.collection('bucket_list').doc(id).update({'title': title});
  }

  Future<void> toggleBucketItem(String id, bool completed) async {
    await _spaceRef.collection('bucket_list').doc(id).update({
      'completed': completed,
      'completedAt': completed ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> deleteBucketItem(String id) async {
    await _spaceRef.collection('bucket_list').doc(id).delete();
  }

  Future<DateTime> getAnniversary() async {
    try {
      final snap = await _spaceRef.get().timeout(const Duration(seconds: 6));
      final ts = snap.data()?['anniversary'] as Timestamp?;
      return ts?.toDate() ?? DateTime(2026, 2, 4);
    } catch (_) {
      // Offline, slow connection, or first launch with no cache yet —
      // fall back rather than hang. Firestore will sync the real value
      // in behind the scenes once connectivity is back.
      return DateTime(2026, 2, 4);
    }
  }
}