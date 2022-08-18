// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.9

import 'package:pigeon/pigeon_lib.dart';

class TextureMessage {
  int textureId;
}

class PositionMessage {
  int textureId;
  int position;
}

class CreateMessage {
  String asset;
  String uri;
  String packageName;
  String formatHint;
  Map<String, String> httpHeaders;
}

class MixWithOthersMessage {
  bool mixWithOthers;
}

@HostApi(dartHostTestHandler: 'TestHostVideoPlayerApi')
abstract class CameraPiApi {
  void initialize();
  TextureMessage create(CreateMessage msg);
  void dispose(TextureMessage msg);
  void play(TextureMessage msg);
  PositionMessage position(TextureMessage msg);
  void pause(TextureMessage msg);
  void setMixWithOthers(MixWithOthersMessage msg);
}

void configurePigeon(PigeonOptions opts) {
  opts.dartOut = 'lib/messages.g.dart';
  opts.dartTestOut = 'test/test.dart';
}
