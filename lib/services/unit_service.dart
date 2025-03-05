// lib/services/unit_service.dart
import 'package:attendanceapp/Models/unit_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class UnitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<UnitModel>> getUnits() {
    return _firestore.collection('units').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => UnitModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addUnit(UnitModel unit) async {
    try {
      await _firestore.collection('units').add(unit.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUnit(UnitModel unit) async {
    try {
      await _firestore.collection('units').doc(unit.id).update(unit.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUnit(String unitId) async {
    try {
      await _firestore.collection('units').doc(unitId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> enrollStudent(String unitId, String studentId) async {
    try {
      await _firestore.collection('units').doc(unitId).update({
        'enrolledStudents': FieldValue.arrayUnion([studentId])
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UnitModel>> getUnitsByCourse(String courseId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('units')
          .where('courseId', isEqualTo: courseId)
          .get();

      return snapshot.docs.map((doc) => UnitModel.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }
}