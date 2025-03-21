import 'package:attendanceapp/Models/unit_model.dart';
import 'package:attendanceapp/services/unit_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnitManagerState {
  final List<UnitModel> units;
  final bool isLoading;
  final String? errorMessage;

  UnitManagerState({
    this.units = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  UnitManagerState copyWith({
    List<UnitModel>? units,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UnitManagerState(
      units: units ?? this.units,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final unitServiceProvider = Provider<UnitService>((ref) {
  return UnitService();
});

final unitsProvider = StreamProvider<List<UnitModel>>((ref) {
  return ref.read(unitServiceProvider).getUnits();
});

final unitNotifierProvider =
    StateNotifierProvider<UnitNotifier, AsyncValue<List<UnitModel>>>((ref) {
  return UnitNotifier(ref.read(unitServiceProvider));
});

class UnitNotifier extends StateNotifier<AsyncValue<List<UnitModel>>> {
  final UnitService _unitService;

  UnitNotifier(this._unitService) : super(const AsyncValue.loading());

  Future<void> addUnit(UnitModel unit) async {
    state = const AsyncValue.loading();
    try {
      await _unitService.addUnit(unit);
      final units = await _unitService.getUnits().first;
      state = AsyncValue.data(units);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> enrollStudent(String unitId, String studentId) async {
    state = const AsyncValue.loading();
    try {
      await _unitService.enrollStudent(unitId, studentId);
      final units = await _unitService.getUnits().first;
      state = AsyncValue.data(units);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
      }
  
  }
  
  final unitManagerProvider = StateNotifierProvider<UnitManagerNotifier, UnitManagerState>((ref) {
    return UnitManagerNotifier(FirebaseFirestore.instance);
  });
  
  class UnitManagerNotifier extends StateNotifier<UnitManagerState> {
  final FirebaseFirestore _firestore;

  UnitManagerNotifier(this._firestore) : super(UnitManagerState());

  Future<void> fetchUnitsForCourse(String  courseId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final unitDocs = await _firestore.collection('courses').where('courseId', isEqualTo:courseId).get();
      final units = unitDocs.docs.map((doc) => UnitModel.fromFirestore(doc)).toList();

      state = state.copyWith(units:units, isLoading: false);
      
    } catch (e) {
      state = state.copyWith(
        isLoading:false, errorMessage: 'Failed to fetch units: ${e.toString()}',
      );
    }
  }

  Future<void> addUnit(UnitModel unit, String courseId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      // Add unit to Firestore
      final unitRef = _firestore.collection('courses').doc();
      final unitWithId = unit.copyWith(id: unitRef.id);
      
      await unitRef.set(unitWithId.toFirestore());
      
      // Update course's units array
      await _firestore.collection('courses').doc(courseId).update({
        'units': FieldValue.arrayUnion([unitRef.id])
      });
      
      // Update local state
      state = state.copyWith(
        units: [...state.units, unitWithId],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: 'Failed to add unit: ${e.toString()}'
      );
    }
  }

  Future<void> deleteUnit(String unitId, String courseId) async {
  state = state.copyWith(isLoading: true, errorMessage: null);
  
  try {
    // Delete the unit document from Firestore
    await _firestore.collection('courses').doc(unitId).delete();
    
    // Remove the unit ID from the course's units array
    await _firestore.collection('courses').doc(courseId).update({
      'units': FieldValue.arrayRemove([unitId])
    });
    
    // Update local state by filtering out the deleted unit
    state = state.copyWith(
      units: state.units.where((unit) => unit.id != unitId).toList(),
      isLoading: false,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Failed to delete unit: ${e.toString()}'
    );
  }
}

Future<void> updateUnit(UnitModel updatedUnit) async {
  state = state.copyWith(isLoading: true, errorMessage: null);
  
  try {
    // Update the unit document in Firestore
    await _firestore.collection('courses').doc(updatedUnit.id).update(
      updatedUnit.toFirestore()
    );
    
    // Update local state
    state = state.copyWith(
      units: state.units.map((unit) => 
        unit.id == updatedUnit.id ? updatedUnit : unit
      ).toList(),
      isLoading: false,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Failed to update unit: ${e.toString()}'
    );
  }
}

Future<void> toggleAttendanceStatus(String unitId, bool isActive) async {
  state = state.copyWith(isLoading: true, errorMessage: null);
  
  try {
    // Update the unit's attendance status in Firestore
    await _firestore.collection('courses').doc(unitId).update({
      'isAttendanceActive': isActive
    });
    
    // Update the local state
    state = state.copyWith(
      units: state.units.map((unit) => 
        unit.id == unitId ? unit.copyWith(isAttendanceActive: isActive) : unit
      ).toList(),
      isLoading: false,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Failed to toggle attendance status: ${e.toString()}'
    );
  }
}
  }

