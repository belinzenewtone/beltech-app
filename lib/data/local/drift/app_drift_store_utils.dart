part of 'app_drift_store.dart';

class _AppDriftUtils {
  static void emitChange(AppDriftStore store) {
    store._changeSeq += 1;
    store._changes.add(store._changeSeq);
  }

  static int asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }

  static double asDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? 0;
  }
}
