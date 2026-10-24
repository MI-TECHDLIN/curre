// Screens will import the design system, the phone-owned core and the door
// policy side by side. This file only compiles while they share one
// ReasonKind instead of declaring rival ones.
import 'package:curre/core/models.dart' as core;
import 'package:curre/design/design.dart';
import 'package:curre/doors/door_models.dart' as doors;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('design, core and doors share one ReasonKind', () {
    const fromDesign = ReasonKind.timeSensitive;
    const core.ReasonKind fromCore = fromDesign;
    const doors.ReasonKind fromDoors = fromCore;
    expect(identical(fromDesign, fromDoors), isTrue);
    expect(kindLabels.keys, containsAll(doors.ReasonKind.values));
  });
}
