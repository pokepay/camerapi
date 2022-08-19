// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'messages.g.dart';
import 'camerapi_platform_interface.dart';

/// An implementation of [CameraPiPlatform] that uses method channels.
///
/// This is the default implementation, for compatibility with existing
/// third-party implementations. It is not used by other implementations in
/// this repository.
class MethodChannelCameraPi extends CameraPiPlatform {
  final CameraPiApi _api = CameraPiApi();

  @override
  Future<void> init() {
    return _api.initialize();
  }

  @override
  Future<void> dispose(int textureId) {
    return _api.dispose(TextureMessage()..textureId = textureId);
  }

  @override
  Future<int?> create() async {
    final TextureMessage response = await _api.create();
    return response.textureId;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return _eventChannelFor(textureId).receiveBroadcastStream().map((dynamic event) {
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      switch (map['event']) {
        case 'initialized':
          return VideoEvent(
            eventType: VideoEventType.initialized,
            size: Size((map['width'] as num?)?.toDouble() ?? 0.0, (map['height'] as num?)?.toDouble() ?? 0.0),
            rotationCorrection: map['rotationCorrection'] as int? ?? 0,
          );
        default:
          return VideoEvent(eventType: VideoEventType.unknown);
      }
    });
  }

  @override
  Stream<BarcodeEvent> get barcodeEvents {
    return _barcodeEventChannel.receiveBroadcastStream().map((dynamic event) {
      final map = event as Map<dynamic, dynamic>;
      return BarcodeEvent(
        barcode: map['barcode'] as String,
        barcodeType: map['barcode_type'] as String,
        quality: map['quality'] as int,
      );
    });
  }

  @override
  Widget buildView(int textureId) {
    return Texture(textureId: textureId);
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) {
    return _api.setMixWithOthers(
      MixWithOthersMessage()..mixWithOthers = mixWithOthers,
    );
  }

  EventChannel get _barcodeEventChannel => EventChannel('flutter.io/camerapi/barcodeEvents');

  EventChannel _eventChannelFor(int textureId) {
    return EventChannel('flutter.io/camerapi/videoEvents$textureId');
  }
}
