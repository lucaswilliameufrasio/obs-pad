import 'dart:math' as math;

/// Volume helpers. OBS works with a linear multiplier (0..1 = -inf..0 dB);
/// people expect a fader where the middle sounds like "half".

const double meterFloorDb = -60;

double mulToDb(double mul) =>
    mul <= 0 ? double.negativeInfinity : 20 * math.log(mul) / math.ln10;

double dbToMul(double db) =>
    db == double.negativeInfinity ? 0 : math.pow(10, db / 20).toDouble();

/// Fader position (0..1) -> multiplier, cubic taper.
double faderToMul(double position) {
  final p = position.clamp(0.0, 1.0);
  return p * p * p;
}

/// Multiplier -> fader position (0..1).
double mulToFader(double mul) {
  if (mul <= 0) return 0;
  return math.pow(mul.clamp(0.0, 1.0), 1 / 3).toDouble();
}

/// Peak multiplier -> 0..1 bar height on a [meterFloorDb]..0 dB scale.
double meterFraction(double peakMul) {
  final db = mulToDb(peakMul);
  if (db.isInfinite || db <= meterFloorDb) return 0;
  return ((db - meterFloorDb) / -meterFloorDb).clamp(0.0, 1.0);
}

String formatDb(double mul) {
  final db = mulToDb(mul);
  if (db.isInfinite || db < -99) return '-∞ dB';
  return '${db.toStringAsFixed(1)} dB';
}
