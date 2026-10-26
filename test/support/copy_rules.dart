import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Words a person using Curre should never meet: how Curre is built, where
/// it came from, and the team's own names for its parts. The plain words
/// that replace them are "plan", "Hidden apps", "Bring back" and "Why now?".
final bannedCopy = <String, RegExp>{
  for (final word in const <String>[
    'Clocked',
    'Rezolve',
    'hackathon',
    'backend',
    'server',
    'API',
    'endpoint',
    'credits?',
    'latency',
    'telemetry',
    'pipeline',
    'judge',
    'demo mode',
    'under the hood',
    'out of sight',
    'into sight',
    'in sight',
    'task doors?',
    'horizon',
    'grants?',
    'candidates?',
    'check-ins?',
    'override',
    'Guard',
    'Decide',
    'Extract',
    'Fill',
  ])
    word: RegExp('(?<![A-Za-z])$word(?![A-Za-z])', caseSensitive: false),
};

/// The banned words found in [text], if any.
List<String> bannedWordsIn(String text) => [
  for (final MapEntry(:key, :value) in bannedCopy.entries)
    if (value.hasMatch(text)) key,
];

/// Every piece of text on screen right now: text widgets, editable text
/// and what TalkBack would read (labels, hints, values, tooltips).
Set<String> visibleCopy(WidgetTester tester) {
  final copy = <String>{};
  for (final widget in tester.allWidgets) {
    switch (widget) {
      case Text(:final data?):
        copy.add(data);
      case Text(:final textSpan?):
        copy.add(textSpan.toPlainText());
      case RichText(:final text):
        copy.add(text.toPlainText());
      case EditableText(:final controller):
        copy.add(controller.text);
      case Tooltip(:final message?):
        copy.add(message);
      case Semantics(:final properties):
        copy.addAll([?properties.label, ?properties.hint, ?properties.value]);
      default:
        break;
    }
  }
  final root = tester.binding.rootPipelineOwner.semanticsOwner?.rootSemanticsNode;
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    copy.addAll([data.label, data.hint, data.value, data.tooltip]);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  if (root != null) visit(root);
  copy.removeWhere((text) => text.trim().isEmpty);
  return copy;
}

/// Fails with every banned word on screen and where it was found.
void expectPlainCopy(WidgetTester tester, {String where = 'this screen'}) {
  final problems = <String>[
    for (final text in visibleCopy(tester))
      for (final word in bannedWordsIn(text)) '“$word” in “$text”',
  ];
  expect(problems, isEmpty, reason: 'Jargon on $where');
}
