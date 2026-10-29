import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/work_log.dart';

/// Camera access was refused; the UI offers settings or manual entry.
class CameraPermissionDenied implements Exception {
  const CameraPermissionDenied();
}

abstract interface class PhotoCaptureService {
  /// Opens the camera. Returns the temporary file, or null if cancelled.
  /// Throws [CameraPermissionDenied] when access is refused.
  Future<File?> capture();
}

class ImagePickerCaptureService implements PhotoCaptureService {
  ImagePickerCaptureService([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<File?> capture() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 75,
        requestFullMetadata: false,
      );
      return x == null ? null : File(x.path);
    } on PlatformException catch (e) {
      if (e.code.contains('access_denied')) {
        throw const CameraPermissionDenied();
      }
      rethrow;
    }
  }
}

class LocationFix {
  const LocationFix(this.status, {this.lat, this.lng, this.accuracy});

  final LocationStatus status;
  final double? lat;
  final double? lng;
  final double? accuracy;
}

abstract interface class LocationService {
  /// True when asking for location would show the system permission dialog
  /// (so the app can explain why first). Never throws.
  Future<bool> needsPermissionPrompt();

  /// Best-effort current position. Never throws.
  Future<LocationFix> current();

  Future<void> openSettings();
}

class GeolocatorLocationService implements LocationService {
  static const _timeout = Duration(seconds: 10);

  @override
  Future<bool> needsPermissionPrompt() async {
    try {
      return await Geolocator.isLocationServiceEnabled() &&
          await Geolocator.checkPermission() == LocationPermission.denied;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<LocationFix> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationFix(LocationStatus.serviceOff);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationFix(LocationStatus.denied);
      }
      final pos =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: _timeout,
            ),
          ).catchError(
            (_) async =>
                await Geolocator.getLastKnownPosition() ??
                (throw TimeoutException('no fix')),
          );
      return LocationFix(
        LocationStatus.captured,
        lat: pos.latitude,
        lng: pos.longitude,
        accuracy: pos.accuracy,
      );
    } catch (_) {
      return const LocationFix(LocationStatus.unavailable);
    }
  }

  @override
  Future<void> openSettings() => Geolocator.openAppSettings();
}

/// App-private storage for evidence photos. Stores paths relative to the
/// documents directory so they survive iOS container moves.
class PhotoStore {
  PhotoStore({Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _baseDir;
  Directory? _base;

  Future<Directory> _root() async => _base ??= await _baseDir();

  /// Moves [source] into `evidence/<companyId>/<name>.jpg`; returns the
  /// relative path.
  Future<String> keep(
    File source, {
    required String companyId,
    required String name,
  }) async {
    final root = await _root();
    final rel = p.join('evidence', companyId, '$name.jpg');
    final dest = File(p.join(root.path, rel));
    await dest.parent.create(recursive: true);
    try {
      await source.rename(dest.path);
    } on FileSystemException {
      await source.copy(dest.path); // different volume
      await source.delete().catchError((_) => source);
    }
    return rel;
  }

  Future<File> resolve(String relativePath) async =>
      File(p.join((await _root()).path, relativePath));

  Future<void> discard(String relativePath) async {
    final f = await resolve(relativePath);
    if (await f.exists()) await f.delete();
  }
}
