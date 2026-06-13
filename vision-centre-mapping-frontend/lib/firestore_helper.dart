import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreHelper {
  // Singleton instance
  static final FirestoreHelper instance = FirestoreHelper._privateConstructor();
  FirestoreHelper._privateConstructor();

  // Reference to the "centers" collection in the cloud
  final CollectionReference _centersCollection = 
      FirebaseFirestore.instance.collection('centers');

  // 1. ADD: Send data to the Cloud
  Future<void> insertCenter(Map<String, dynamic> row) async {
    // We don't need to manually handle IDs anymore, Firebase does it
    await _centersCollection.add(row);
  }

  // 2. GET: Fetch all data from the Cloud
  Future<List<Map<String, dynamic>>> getAllCenters() async {
    QuerySnapshot snapshot = await _centersCollection.get();
    
    // Convert the cloud documents into a List of Maps
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      // Add the unique Firebase ID so we can edit/delete later if needed
      data['id'] = doc.id; 
      return data;
    }).toList();
  }

  Future<void> deleteCenter(String id) async {
    await _centersCollection.doc(id).delete();
  }
}