// Live procedural Flame PositionComponent backed by PixelFxController.

import 'dart:math' as math;
import 'dart:ui' show Canvas, Rect;

import 'package:flame/components.dart';
import 'package:pixelfx_core/pixelfx_core.dart';
import 'package:pixelfx_flutter/pixelfx_flutter.dart';

/// Live Flame [PositionComponent] streaming a procedural [PixelAsset]
/// at crisp nearest-neighbor scaling without needing pre-exported PNGs.
class PixelFxComponent extends PositionComponent {
  final PixelAsset asset;
  final List<Object>? palette;
  final int? seed;
  final BackdropKind backdrop;
  final bool flip;
  final bool? loop;
  final bool playing;
  final double speed;
  final bool showActor;
  final bool removeOnFinish;
  final double light;
  final Map<String, Object?> options;
  final List<PostProcessor> postProcessors;

  PixelFxController? _controller;

  PixelFxComponent({
    required this.asset,
    this.palette,
    this.seed,
    this.backdrop = BackdropKind.none,
    this.flip = false,
    this.loop,
    this.playing = true,
    this.speed = 1.0,
    this.showActor = false,
    this.removeOnFinish = true,
    this.light = 1.0,
    this.options = const {},
    this.postProcessors = const [],
    super.position,
    super.scale,
    super.angle,
    Anchor? anchor,
    super.priority,
    super.key,
  }) : super(
          size: Vector2(
            asset.meta.width.toDouble(),
            asset.meta.height.toDouble(),
          ),
          anchor: anchor ??
              Anchor(
                asset.meta.originX / math.max(1, asset.meta.width),
                asset.meta.originY / math.max(1, asset.meta.height),
              ),
        );

  PixelFxController get controller {
    final c = _controller;
    if (c == null) {
      throw StateError('PixelFxComponent accessed before onLoad.');
    }
    return c;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final mergedOpts = palette == null
        ? options
        : <String, Object?>{...options, 'palette': palette};
    _controller = PixelFxController(
      asset: asset,
      actMode: false,
      playing: playing,
      loop: loop,
      speed: speed,
      backdropKind: backdrop,
      showActor: showActor,
      flip: flip,
      seed: seed,
      lightK: light,
      options: mergedOpts,
      postProcessors: postProcessors,
    );
  }

  void restart() => _controller?.restart();

  void stop() => _controller?.pause();

  @override
  void update(double dt) {
    super.update(dt);
    final c = _controller;
    if (c == null) return;
    c.step(dt);
    if (removeOnFinish && !c.loop && c.done) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final img = _controller?.image;
    if (img == null) return;
    drawCrispImage(canvas, img, Rect.fromLTWH(0, 0, size.x, size.y));
  }

  @override
  void onRemove() {
    _controller?.dispose();
    _controller = null;
    super.onRemove();
  }
}
