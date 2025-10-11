import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<void> saveData(String path, Map<String, dynamic> data) async {
    await _dbRef.child(path).set(data);
  }

  Future<DataSnapshot> getData(String path) async {
    return await _dbRef.child(path).get();
  }

  Future<void> updateData(String path, Map<String, dynamic> data) async {
    await _dbRef.child(path).update(data);
  }

  Future<void> deleteData(String path) async {
    await _dbRef.child(path).remove();
  }
}