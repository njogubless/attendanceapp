import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendanceapp/Models/unit_model.dart';
import 'package:attendanceapp/services/unit_service.dart';

// Main service provider
final unitServiceProvider = Provider<UnitService>((ref) {
  return UnitService();
});

// Provider for lecturer's units
final lecturerUnitsProvider =
    StreamProvider.family<List<UnitModel>, String>((ref, lecturerId) {
  return ref.read(unitServiceProvider).getLecturerUnits(lecturerId);
});

// Provider for approved units (for students)
final approvedUnitsProvider = StreamProvider<List<UnitModel>>((ref) {
  return ref.read(unitServiceProvider).getApprovedUnits();
});

// State notifier for unit management
// final unitManagerProvider =
//     StateNotifierProvider<UnitNotifier, AsyncValue<List<UnitModel>>>((ref) {
//   return UnitNotifier(ref.read(unitServiceProvider));
// });

class UnitNotifier extends StateNotifier<AsyncValue<List<UnitModel>>> {
  final UnitService _unitService;

  UnitNotifier(this._unitService) : super(const AsyncValue.loading());

  Future<void> updateUnit(UnitModel unit) async {
    try {
      await _unitService.updateUnit(unit);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> addUnit(UnitModel unit) async {
    try {
      await _unitService.addUnit(unit);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteUnit(String unitId) async {
    try {
      await _unitService.deleteUnit(unitId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> toggleAttendanceStatus(String unitId, bool isActive) async {
    try {
      await _unitService.toggleAttendanceStatus(unitId, isActive);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> fetchLecturerUnits(String lecturerId) async {
    state = const AsyncValue.loading();
    try {
      // This is just to load the initial state, the actual data comes from the Stream
      final units = await _unitService.getLecturerUnits(lecturerId).first;
      state = AsyncValue.data(units);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Admin-specific providers (could be in a separate file)
final adminUnitApprovalProvider = Provider<AdminUnitApproval>((ref) {
  return AdminUnitApproval(ref.read(unitServiceProvider));
});

class AdminUnitApproval {
  final UnitService _unitService;

  AdminUnitApproval(this._unitService);

  Future<void> approveUnit(String unitId, {String comments = ''}) async {
    await _unitService.approveUnit(unitId, comments: comments);
  }

  Future<void> rejectUnit(String unitId, {required String comments}) async {
    await _unitService.rejectUnit(unitId, comments: comments);
  }
}
