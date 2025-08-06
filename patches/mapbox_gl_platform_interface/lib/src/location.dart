// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:mapbox_gl_platform_interface/src/types.dart';
import 'package:flutter/foundation.dart' show hashValues;

/// A geographical point
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  bool operator ==(dynamic other) {
    return other is LatLng &&
        latitude == other.latitude &&
        longitude == other.longitude;
  }

  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

/// A geographical bounding box
class LatLngBounds {
  final LatLng southwest;
  final LatLng northeast;

  const LatLngBounds(this.southwest, this.northeast);

  @override
  bool operator ==(dynamic other) {
    return other is LatLngBounds &&
        southwest == other.southwest &&
        northeast == other.northeast;
  }

  int get hashCode => Object.hash(southwest, northeast);

  @override
  String toString() => 'LatLngBounds($southwest, $northeast)';
}

/// A geographical quadrilateral
class LatLngQuad {
  final LatLng topLeft;
  final LatLng topRight;
  final LatLng bottomRight;
  final LatLng bottomLeft;

  const LatLngQuad(
      this.topLeft, this.topRight, this.bottomRight, this.bottomLeft);

  @override
  bool operator ==(dynamic other) {
    return other is LatLngQuad &&
        topLeft == other.topLeft &&
        topRight == other.topRight &&
        bottomRight == other.bottomRight &&
        bottomLeft == other.bottomLeft;
  }

  int get hashCode => Object.hash(topLeft, topRight, bottomRight, bottomLeft);

  @override
  String toString() =>
      'LatLngQuad($topLeft, $topRight, $bottomRight, $bottomLeft)';
}

/// User's observed location
class UserLocation {
  /// User's position in latitude and longitude
  final LatLng position;

  /// User's altitude in meters
  final double? altitude;

  /// Direction user is traveling, measured in degrees
  final double? bearing;

  /// User's speed in meters per second
  final double? speed;

  /// The radius of uncertainty for the location, measured in meters
  final double? horizontalAccuracy;

  /// Accuracy of the altitude measurement, in meters
  final double? verticalAccuracy;

  /// Time the user's location was observed
  final DateTime timestamp;

  /// The heading of the user location, null if not available.
  final UserHeading? heading;

  const UserLocation(
      {required this.position,
      required this.altitude,
      required this.bearing,
      required this.speed,
      required this.horizontalAccuracy,
      required this.verticalAccuracy,
      required this.timestamp,
      required this.heading});
}

/// Type represents a geomagnetic value, measured in microteslas, relative to a
/// device axis in three dimensional space.
class UserHeading {
  /// Represents the direction in degrees, where 0 degrees is magnetic North.
  /// The direction is referenced from the top of the device regardless of
  /// device orientation as well as the orientation of the user interface.
  final double? magneticHeading;

  /// Represents the direction in degrees, where 0 degrees is true North. The
  /// direction is referenced from the top of the device regardless of device
  /// orientation as well as the orientation of the user interface
  final double? trueHeading;

  /// Represents the maximum deviation of where the magnetic heading may differ
  /// from the actual geomagnetic heading in degrees. A negative value indicates
  /// an invalid heading.
  final double? headingAccuracy;

  /// Returns a raw value for the geomagnetism measured in the x-axis.
  final double? x;

  /// Returns a raw value for the geomagnetism measured in the y-axis.
  final double? y;

  /// Returns a raw value for the geomagnetism measured in the z-axis.
  final double? z;

  /// Returns a timestamp for when the magnetic heading was determined.
  final DateTime timestamp;
  const UserHeading(
      {required this.magneticHeading,
      required this.trueHeading,
      required this.headingAccuracy,
      required this.x,
      required this.y,
      required this.z,
      required this.timestamp});
}
