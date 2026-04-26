import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/all_models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signUp(String email, String password, String name) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await cred.user?.updateDisplayName(name);
      final user = UserModel(
        uid: cred.user!.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
        workspaceIds: [],
      );
      await _db.collection('users').doc(user.uid).set(user.toMap());
      // Create default workspace
      final wsRef = _db.collection('workspaces').doc();
      final ws = Workspace(
        id: wsRef.id,
        name: '$name\'s Workspace',
        ownerId: user.uid,
        memberIds: [user.uid],
        memberRoles: {user.uid: 'owner'},
        createdAt: DateTime.now(),
        iconEmoji: '📊',
      );
      await wsRef.set(ws.toMap());
      await _db.collection('users').doc(user.uid).update({
        'workspaceIds': FieldValue.arrayUnion([wsRef.id]),
      });
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password,
      );
      final doc = await _db.collection('users').doc(cred.user!.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async => await _auth.signOut();

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!, doc.id);
    return null;
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }
}
