// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camerapi_platform_interface/camerapi_platform_interface.dart';

export 'package:camerapi_platform_interface/camerapi_platform_interface.dart'
    show VideoFormat, VideoPlayerOptions, BarcodeEvent;

CameraPiPlatform? _lastCameraPiPlatform;

CameraPiPlatform get _cameraPiPlatform {
  final CameraPiPlatform currentInstance = CameraPiPlatform.instance;
  if (_lastCameraPiPlatform != currentInstance) {
    // This will clear all open videos on the platform when a full restart is
    // performed.
    currentInstance.init();
    _lastCameraPiPlatform = currentInstance;
  }
  return currentInstance;
}

/// The duration, current position, buffering state, error state and settings
/// of a [CameraPiController].
class CameraPiValue {
  /// Constructs a video with the given values. Only [duration] is required. The
  /// rest will initialize with default values when unset.
  CameraPiValue({
    this.size = Size.zero,
    this.isInitialized = false,
    this.rotationCorrection = 0,
    this.errorDescription,
  });

  /// Returns an instance for a video that hasn't been loaded.
  CameraPiValue.uninitialized() : this(isInitialized: false);

  /// Returns an instance with the given [errorDescription].
  CameraPiValue.erroneous(String errorDescription) : this(isInitialized: false, errorDescription: errorDescription);

  /// This constant is just to indicate that parameter is not passed to [copyWith]
  /// workaround for this issue https://github.com/dart-lang/language/issues/2009
  static const String _defaultErrorDescription = 'defaultErrorDescription';

  /// A description of the error if present.
  ///
  /// If [hasError] is false this is `null`.
  final String? errorDescription;

  /// The [size] of the currently loaded video.
  final Size size;

  /// Degrees to rotate the video (clockwise) so it is displayed correctly.
  final int rotationCorrection;

  /// Indicates whether or not the video has been loaded and is ready to play.
  final bool isInitialized;

  /// Indicates whether or not the video is in an error state. If this is true
  /// [errorDescription] should have information about the problem.
  bool get hasError => errorDescription != null;

  /// Returns [size.width] / [size.height].
  ///
  /// Will return `1.0` if:
  /// * [isInitialized] is `false`
  /// * [size.width], or [size.height] is equal to `0.0`
  /// * aspect ratio would be less than or equal to `0.0`
  double get aspectRatio {
    if (!isInitialized || size.width == 0 || size.height == 0) {
      return 1.0;
    }
    final double aspectRatio = size.width / size.height;
    if (aspectRatio <= 0) {
      return 1.0;
    }
    return aspectRatio;
  }

  /// Returns a new instance that has the same values as this current instance,
  /// except for any overrides passed in as arguments to [copyWith].
  CameraPiValue copyWith({
    Size? size,
    bool? isInitialized,
    int? rotationCorrection,
    String? errorDescription = _defaultErrorDescription,
  }) {
    return CameraPiValue(
      size: size ?? this.size,
      isInitialized: isInitialized ?? this.isInitialized,
      rotationCorrection: rotationCorrection ?? this.rotationCorrection,
      errorDescription: errorDescription != _defaultErrorDescription ? errorDescription : this.errorDescription,
    );
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, 'VideoPlayerValue')}('
        'size: $size, '
        'isInitialized: $isInitialized, '
        'errorDescription: $errorDescription)';
  }
}

/// Controls a platform video player, and provides updates when the state is
/// changing.
///
/// Instances must be initialized with initialize.
///
/// The video is displayed in a Flutter app by creating a [CameraPi] widget.
///
/// To reclaim the resources used by the player call [dispose].
///
/// After [dispose] all further calls are ignored.
class CameraPiController extends ValueNotifier<CameraPiValue> {
  StreamSubscription<BarcodeEvent>? _barcodeSubscription = null;
  bool allowDuplicates;
  BarcodeEvent? lastBarcode = null;
  Function(BarcodeEvent)? onBarcode;

  /// Constructs a [CameraPiController] playing a video from obtained from
  /// the network.
  ///
  /// The URI for the video is given by the [dataSource] argument and must not be
  /// null.
  /// **Android only**: The [formatHint] option allows the caller to override
  /// the video format detection code.
  /// [httpHeaders] option allows to specify HTTP headers
  /// for the request to the [dataSource].
  CameraPiController({
    this.formatHint,
    this.videoPlayerOptions,
    this.httpHeaders = const <String, String>{},
    this.allowDuplicates = false,
    this.onBarcode,
  }) : super(CameraPiValue());

  /// HTTP headers used for the request to the [dataSource].
  /// Only for [VideoPlayerController.network].
  /// Always empty for other video types.
  final Map<String, String> httpHeaders;

  /// **Android only**. Will override the platform's generic file format
  /// detection with whatever is set here.
  final VideoFormat? formatHint;

  /// Provide additional configuration options (optional). Like setting the audio mode to mix
  final VideoPlayerOptions? videoPlayerOptions;

  bool _isDisposed = false;
  Completer<void>? _creatingCompleter;
  StreamSubscription<dynamic>? _eventSubscription;
  _VideoAppLifeCycleObserver? _lifeCycleObserver;

  /// The id of a texture that hasn't been initialized.
  @visibleForTesting
  static const int kUninitializedTextureId = -1;
  int _textureId = kUninitializedTextureId;

  /// This is just exposed for testing. It shouldn't be used by anyone depending
  /// on the plugin.
  @visibleForTesting
  int get textureId => _textureId;

  /// Attempts to open the given [dataSource] and load metadata about the video.
  Future<void> initialize() async {
    final bool allowBackgroundPlayback = videoPlayerOptions?.allowBackgroundPlayback ?? false;
    if (!allowBackgroundPlayback) {
      _lifeCycleObserver = _VideoAppLifeCycleObserver(this);
    }
    _lifeCycleObserver?.initialize();
    _creatingCompleter = Completer<void>();

    if (videoPlayerOptions?.mixWithOthers != null) {
      await _cameraPiPlatform.setMixWithOthers(videoPlayerOptions!.mixWithOthers);
    }

    _textureId = (await _cameraPiPlatform.create()) ?? kUninitializedTextureId;
    _creatingCompleter!.complete(null);
    final Completer<void> initializingCompleter = Completer<void>();

    void eventListener(VideoEvent event) {
      if (_isDisposed) {
        return;
      }

      switch (event.eventType) {
        case VideoEventType.initialized:
          print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Initialized, size: ${event.size}");
          value = value.copyWith(
            size: event.size,
            rotationCorrection: event.rotationCorrection,
            isInitialized: true,
            errorDescription: null,
          );
          initializingCompleter.complete(null);
          if (_isDisposed) {
            print("CameraPi has been disposed");
            return;
          }
          break;
        case VideoEventType.unknown:
          break;
      }

      print('New video player value: $value');
    }

    void errorListener(Object obj) {
      final PlatformException e = obj as PlatformException;
      value = CameraPiValue.erroneous(e.message!);
      if (!initializingCompleter.isCompleted) {
        initializingCompleter.completeError(obj);
      }
    }

    _eventSubscription = _cameraPiPlatform.videoEventsFor(_textureId).listen(eventListener, onError: errorListener);
    _barcodeSubscription = _cameraPiPlatform.barcodeEvents.listen(barcodeListener, onError: errorListener);
    return initializingCompleter.future;
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    if (_creatingCompleter != null) {
      await _creatingCompleter!.future;
      if (!_isDisposed) {
        _isDisposed = true;
        await _eventSubscription?.cancel();
        await _cameraPiPlatform.dispose(_textureId);
      }
      _lifeCycleObserver?.dispose();
    }
    _isDisposed = true;
    super.dispose();
  }

  /// The position in the current video.
  @override
  void removeListener(VoidCallback listener) {
    // Prevent VideoPlayer from causing an exception to be thrown when attempting to
    // remove its own listener after the controller has already been disposed.
    if (!_isDisposed) {
      super.removeListener(listener);
    }
  }

  void barcodeListener(BarcodeEvent event) {
    print('barcode event received: $event');
    if (event.barcode != lastBarcode?.barcode || event.barcodeType != lastBarcode?.barcodeType) {
      lastBarcode = event;
      onBarcode?.call(event);
    }
  }
}

class _VideoAppLifeCycleObserver extends Object with WidgetsBindingObserver {
  _VideoAppLifeCycleObserver(this._controller);

  final CameraPiController _controller;

  void initialize() {
    _ambiguate(WidgetsBinding.instance)!.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // FIXME: should probably release the camera
        break;
      case AppLifecycleState.resumed:
        // FIXME:Restart?
        break;
      default:
    }
  }

  void dispose() {
    _ambiguate(WidgetsBinding.instance)!.removeObserver(this);
  }
}

/// Widget that displays the video controlled by [controller].
class CameraPi extends StatefulWidget {
  /// Uses the given [controller] for all video rendered in this widget.
  const CameraPi(this.controller, {Key? key}) : super(key: key);

  /// The [CameraPiController] responsible for the video being rendered in
  /// this widget.
  final CameraPiController controller;

  @override
  State<CameraPi> createState() => _CameraPiState();
}

class _CameraPiState extends State<CameraPi> {
  _CameraPiState() {
    _listener = () {
      final int newTextureId = widget.controller.textureId;
      if (newTextureId != _textureId) {
        setState(() {
          _textureId = newTextureId;
        });
      }
    };
  }

  late VoidCallback _listener;

  late int _textureId;

  @override
  void initState() {
    super.initState();
    _textureId = widget.controller.textureId;
    // Need to listen for initialization events since the actual texture ID
    // becomes available after asynchronous initialization finishes.
    widget.controller.addListener(_listener);
  }

  @override
  void didUpdateWidget(CameraPi oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller.removeListener(_listener);
    _textureId = widget.controller.textureId;
    widget.controller.addListener(_listener);
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.controller.removeListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    return _textureId == CameraPiController.kUninitializedTextureId
        ? Container()
        : _CameraPiWithRotation(
            rotation: widget.controller.value.rotationCorrection,
            child: _cameraPiPlatform.buildView(_textureId),
          );
  }
}

class _CameraPiWithRotation extends StatelessWidget {
  const _CameraPiWithRotation({Key? key, required this.rotation, required this.child}) : super(key: key);
  final int rotation;
  final Widget child;

  @override
  Widget build(BuildContext context) => rotation == 0
      ? child
      : Transform.rotate(
          angle: rotation * math.pi / 180,
          child: child,
        );
}

/// This allows a value of type T or T? to be treated as a value of type T?.
///
/// We use this so that APIs that have become non-nullable can still be used
/// with `!` and `?` on the stable branch.
// TODO(ianh): Remove this once we roll stable in late 2021.
T? _ambiguate<T>(T? value) => value;
