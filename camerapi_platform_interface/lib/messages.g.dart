// Autogenerated from Pigeon (v0.1.21), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import
// @dart = 2.12
import 'dart:async';
import 'dart:typed_data' show Uint8List, Int32List, Int64List, Float64List;

import 'package:flutter/services.dart';

class TextureMessage {
  int? textureId;

  Object encode() {
    final Map<Object?, Object?> pigeonMap = <Object?, Object?>{};
    pigeonMap['textureId'] = textureId;
    return pigeonMap;
  }

  static TextureMessage decode(Object message) {
    final Map<Object?, Object?> pigeonMap = message as Map<Object?, Object?>;
    return TextureMessage()
      ..textureId = pigeonMap['textureId'] as int?;
  }
}

class MixWithOthersMessage {
  bool? mixWithOthers;

  Object encode() {
    final Map<Object?, Object?> pigeonMap = <Object?, Object?>{};
    pigeonMap['mixWithOthers'] = mixWithOthers;
    return pigeonMap;
  }

  static MixWithOthersMessage decode(Object message) {
    final Map<Object?, Object?> pigeonMap = message as Map<Object?, Object?>;
    return MixWithOthersMessage()
      ..mixWithOthers = pigeonMap['mixWithOthers'] as bool?;
  }
}

class CameraPiApi {
  Future<void> initialize() async {
    const BasicMessageChannel<Object?> channel =
        BasicMessageChannel<Object?>('dev.flutter.pigeon.CameraPiApi.initialize', StandardMessageCodec());
    final Map<Object?, Object?>? replyMap = await channel.send(null) as Map<Object?, Object?>?;
    if (replyMap == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
        details: null,
      );
    } else if (replyMap['error'] != null) {
      final Map<Object?, Object?> error = replyMap['error'] as Map<Object?, Object?>;
      throw PlatformException(
        code: error['code'] as String,
        message: error['message'] as String?,
        details: error['details'],
      );
    } else {
      // noop
    }
  }

  Future<TextureMessage> create() async {
    const BasicMessageChannel<Object?> channel =
        BasicMessageChannel<Object?>('dev.flutter.pigeon.CameraPiApi.create', StandardMessageCodec());
    final Map<Object?, Object?>? replyMap = await channel.send(null) as Map<Object?, Object?>?;
    if (replyMap == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
        details: null,
      );
    } else if (replyMap['error'] != null) {
      final Map<Object?, Object?> error = replyMap['error'] as Map<Object?, Object?>;
      throw PlatformException(
        code: error['code'] as String,
        message: error['message'] as String?,
        details: error['details'],
      );
    } else {
      return TextureMessage.decode(replyMap['result']!);
    }
  }

  Future<void> dispose(TextureMessage arg) async {
    final Object encoded = arg.encode();
    const BasicMessageChannel<Object?> channel =
        BasicMessageChannel<Object?>('dev.flutter.pigeon.CameraPiApi.dispose', StandardMessageCodec());
    final Map<Object?, Object?>? replyMap = await channel.send(encoded) as Map<Object?, Object?>?;
    if (replyMap == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
        details: null,
      );
    } else if (replyMap['error'] != null) {
      final Map<Object?, Object?> error = replyMap['error'] as Map<Object?, Object?>;
      throw PlatformException(
        code: error['code'] as String,
        message: error['message'] as String?,
        details: error['details'],
      );
    } else {
      // noop
    }
  }

  Future<void> setMixWithOthers(MixWithOthersMessage arg) async {
    final Object encoded = arg.encode();
    const BasicMessageChannel<Object?> channel =
        BasicMessageChannel<Object?>('dev.flutter.pigeon.CameraPiApi.setMixWithOthers', StandardMessageCodec());
    final Map<Object?, Object?>? replyMap = await channel.send(encoded) as Map<Object?, Object?>?;
    if (replyMap == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
        details: null,
      );
    } else if (replyMap['error'] != null) {
      final Map<Object?, Object?> error = replyMap['error'] as Map<Object?, Object?>;
      throw PlatformException(
        code: error['code'] as String,
        message: error['message'] as String?,
        details: error['details'],
      );
    } else {
      // noop
    }
  }
}
