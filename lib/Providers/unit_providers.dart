import 'package:attendanceapp/Models/unit_model.dart';
import 'package:attendanceapp/services/unit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final unitServiceProvider = Provider<UnitService>((ref) {
  return UnitService();
});

final unitsProvider = StreamProvider<List<UnitModel>>((ref) {
  return ref.read(unitServiceProvider).getUnits();
});

final unitNotifierProvider = StateNotifierProvider<UnitNotifier, AsyncValue<List<UnitModel>>>((ref) {
  return UnitNotifier(ref.read(unitServiceProvider));
});

class UnitNotifier extends StateNotifier<AsyncValue<List<UnitModel>>> {
  final UnitService _unitService;

  UnitNotifier(this._unitService) : super(AsyncValue.loading());

  Future<void> addUnit(UnitModel unit) async {
    state = AsyncValue.loading();
    try {
      await _unitService.addUnit(unit);
      final units = await _unitService.getUnits().first;
      state = AsyncValue.data(units);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> enrollStudent(String unitId, String studentId) async {
    state = AsyncValue.loading();
    try {
      await _unitService.enrollStudent(unitId, studentId);
      final units = await _unitService.getUnits().first;
      state = AsyncValue.data(units);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}