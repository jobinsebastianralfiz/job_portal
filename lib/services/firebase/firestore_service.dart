import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get users => _db.collection(FirebaseConstants.usersCollection);
  CollectionReference get companies => _db.collection(FirebaseConstants.companiesCollection);
  CollectionReference get jobs => _db.collection(FirebaseConstants.jobsCollection);
  CollectionReference get applications => _db.collection(FirebaseConstants.applicationsCollection);
  CollectionReference get chats => _db.collection(FirebaseConstants.chatsCollection);
  CollectionReference get notifications => _db.collection(FirebaseConstants.notificationsCollection);
  CollectionReference get reviews => _db.collection(FirebaseConstants.reviewsCollection);

  // Generic Methods
  Future<void> setDocument(String collection, String docId, Map<String, dynamic> data) async {
    await _db.collection(collection).doc(docId).set(data);
  }

  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    await _db.collection(collection).doc(docId).update(data);
  }

  Future<void> deleteDocument(String collection, String docId) async {
    await _db.collection(collection).doc(docId).delete();
  }

  Future<DocumentSnapshot> getDocument(String collection, String docId) async {
    return await _db.collection(collection).doc(docId).get();
  }

  Stream<DocumentSnapshot> streamDocument(String collection, String docId) {
    return _db.collection(collection).doc(docId).snapshots();
  }

  Stream<QuerySnapshot> streamCollection(String collection) {
    return _db.collection(collection).snapshots();
  }

  // Batch Operations
  WriteBatch batch() => _db.batch();

  Future<void> runTransaction(Future<void> Function(Transaction) updateFunction) async {
    await _db.runTransaction(updateFunction);
  }

  // Increment Field
  Future<void> incrementField(String collection, String docId, String field, int value) async {
    await _db.collection(collection).doc(docId).update({
      field: FieldValue.increment(value),
    });
  }

  // Array Operations
  Future<void> addToArray(String collection, String docId, String field, dynamic value) async {
    await _db.collection(collection).doc(docId).update({
      field: FieldValue.arrayUnion([value]),
    });
  }

  Future<void> removeFromArray(String collection, String docId, String field, dynamic value) async {
    await _db.collection(collection).doc(docId).update({
      field: FieldValue.arrayRemove([value]),
    });
  }
}
