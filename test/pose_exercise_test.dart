// Unit tests for the pose-based jumping jack counter logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:hypemotiv/screens/pose_exercise_screen.dart';

PoseLandmark _landmark(PoseLandmarkType type, double x, double y) {
  return PoseLandmark(type: type, x: x, y: y, z: 0, likelihood: 1);
}

void main() {
  test('elbow arm angle reads near 0 down and near 180 up', () {
    final PoseLandmark shoulder = _landmark(
      PoseLandmarkType.leftShoulder,
      0,
      0,
    );
    expect(
      elbowArmAngle(shoulder, _landmark(PoseLandmarkType.leftElbow, 0.01, 0.3)),
      lessThan(10),
    );
    expect(
      elbowArmAngle(
        shoulder,
        _landmark(PoseLandmarkType.leftElbow, 0.01, -0.3),
      ),
      greaterThan(170),
    );
  });

  test('landmark distance uses x and y', () {
    expect(
      landmarkDistance(
        _landmark(PoseLandmarkType.leftAnkle, 0, 0),
        _landmark(PoseLandmarkType.rightAnkle, 3, 4),
      ),
      5,
    );
  });

  test('counts down-to-up transitions only while legs are spread', () {
    final JumpingJackCounter counter = JumpingJackCounter();

    // First frame is arms down: establishes the starting state, no rep.
    expect(
      counter.update(
        leftElbowAngle: 10,
        rightElbowAngle: 12,
        legSpreadRatio: 1.8,
      ),
      isFalse,
    );
    expect(counter.isArmsDown, isTrue);

    // Arms up with spread legs: one rep.
    expect(
      counter.update(
        leftElbowAngle: 130,
        rightElbowAngle: 125,
        legSpreadRatio: 1.6,
      ),
      isTrue,
    );
    expect(counter.reps, 1);

    // Still up: no extra rep.
    expect(
      counter.update(
        leftElbowAngle: 140,
        rightElbowAngle: 138,
        legSpreadRatio: 1.7,
      ),
      isFalse,
    );

    // Down again, then up with legs together: no rep.
    counter.update(
      leftElbowAngle: 20,
      rightElbowAngle: 18,
      legSpreadRatio: 1.0,
    );
    expect(
      counter.update(
        leftElbowAngle: 120,
        rightElbowAngle: 115,
        legSpreadRatio: 1.1,
      ),
      isFalse,
    );

    // Down again, then up with legs spread: second rep.
    counter.update(
      leftElbowAngle: 15,
      rightElbowAngle: 22,
      legSpreadRatio: 1.0,
    );
    expect(
      counter.update(
        leftElbowAngle: 135,
        rightElbowAngle: 128,
        legSpreadRatio: 1.5,
      ),
      isTrue,
    );
    expect(counter.reps, 2);
  });

  test('an already-raised start does not award a free rep', () {
    final JumpingJackCounter counter = JumpingJackCounter();
    expect(
      counter.update(
        leftElbowAngle: 160,
        rightElbowAngle: 150,
        legSpreadRatio: 2.0,
      ),
      isFalse,
    );
    expect(counter.reps, 0);
  });
}
