import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

/// A door on Home: the app, where a tap lands, and the user's own words
/// that put it there.
@immutable
class DoorSample {
  const DoorSample({required this.app, required this.destination, required this.words, required this.icon});

  final String app;

  /// The door's destination ("Search", "Messages").
  final String destination;

  /// The user's words that drive it, quoted on the row ("G chord").
  final String words;

  /// Stand-in for the app's own icon.
  final IconData icon;
}

/// A check-in sentence with the spans Clocked would mark in it.
@immutable
class PlanSample {
  const PlanSample({
    required this.sentence,
    required this.doors,
    required this.endPhrase,
    required this.startedAt,
    required this.endsAt,
    required this.progress,
  });

  final String sentence;

  /// In link order: door i is span i + 1.
  final List<DoorSample> doors;
  final String endPhrase;
  final String startedAt;
  final String endsAt;

  /// How far the plan's window has run, 0–1 (positions the sun).
  final double progress;
}

/// The demo plan (differentiator report §6.8).
const demoPlan = PlanSample(
  sentence: 'Pray, then learn the G chord on YouTube and play worship on Spotify till 7',
  doors: [
    DoorSample(app: 'YouTube', destination: 'Search', words: 'G chord', icon: SolarIconsBold.playCircle),
    DoorSample(app: 'Spotify', destination: 'Search', words: 'worship', icon: SolarIconsBold.musicNotes),
  ],
  endPhrase: 'till 7',
  startedAt: '05:13',
  endsAt: '07:00',
  progress: .17,
);

/// A deliberately long plan with long app labels and long search words,
/// for the detail pass at 360 dp.
const longPlan = PlanSample(
  sentence:
      'Pray, then learn how to play the G chord on an acoustic guitar for beginners on YouTube, '
      'play the Sunday worship playlist on Spotify and find the rehearsal studio on Google Maps till 8',
  doors: [
    DoorSample(
      app: 'YouTube',
      destination: 'Search',
      words: 'how to play the G chord on an acoustic guitar for beginners',
      icon: SolarIconsBold.playCircle,
    ),
    DoorSample(
      app: 'Spotify',
      destination: 'Search',
      words: 'Sunday worship playlist',
      icon: SolarIconsBold.musicNotes,
    ),
    DoorSample(
      app: 'Google Maps',
      destination: 'Search',
      words: 'rehearsal studio',
      icon: SolarIconsBold.mapPoint,
    ),
  ],
  endPhrase: 'till 8',
  startedAt: '05:13',
  endsAt: '08:00',
  progress: .07,
);
