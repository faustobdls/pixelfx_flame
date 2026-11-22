// Live acted Flame PositionComponent with hero rig, target dummy, hit-stop, shake, and onHit callback.

import 'dart:math' as math;
import 'dart:ui' show Canvas, Rect;

import 'package:flame/components.dart';
import 'package:pixelfx_core/pixelfx_core.dart';
import 'package:pixelfx_flutter/pixelfx_flutter.dart';

/// Performs a [PixelEffect]'s full choreographed act inside a Flame game scene.
class PixelActComponent extends PositionComponent {
  final PixelEffect effect;
  final List<Object>? palette;
  final int? seed;
  final BackdropKind backdrop;
  final bool flip;
  final bool? loop;
  final bool playing;
  final double speed;
  final bool showActor;
  final bool showTarget;
  final bool showSkeleton;
  final bool removeOnFinish;
  final double light;
  final Map<String, Object?> options;
  final List<PostProcessor> postProcessors;
  final void Function(HitSpec hit)? onHit;

  PixelFxController? _controller;
  final bool _customAnchor;

  PixelActComponent({
    required this.effect,
    this.palette,
    this.seed,
    this.backdrop = BackdropKind.none,
    this.flip = false,
    this.loop,
    this.playing = true,
    this.speed = 1.0,
    this.showActor = true,
    this.showTarget = true,
    this.showSkeleton = false,
    this.removeOnFinish = true,
    this.light = 1.0,
    this.options = const {},
    this.postProcessors = const [],
    this.onHit,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
    super.key,
  }) : _customAnchor = anchor != null;

  PixelFxController get controller {
    final c = _controller;
    if (c == null) {
      throw StateError('PixelActComponent accessed before onLoad.');
    }
    return c;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final mergedOpts = palette == null
        ? options
        : <String, Object?>{...options, 'palette': palette};
    final ctrl = PixelFxController(
      asset: effect,
      actMode: true,
      playing: playing,
      loop: loop,
      speed: speed,
      backdropKind: backdrop,
      showActor: showActor,
      showTarget: showTarget,
      flip: flip,
      showSkeleton: showSkeleton,
      seed: seed,
      lightK: light,
      options: mergedOpts,
      postProcessors: postProcessors,
      onHit: onHit,
    );
    _controller = ctrl;
    size = Vector2(ctrl.frameWidth.toDouble(), ctrl.frameHeight.toDouble());
    if (!_customAnchor) {
      anchor = Anchor(
        ctrl.pivot.$1 / math.max(1, ctrl.frameWidth),
        ctrl.pivot.$2 / math.max(1, ctrl.frameHeight),
      );
    }
  }

  void restart() => _controller?.restart();

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
    final c = _controller;
    final img = c?.image;
    if (c == null || img == null) return;
    final (sx, sy) = c.shake;
    drawCrispImage(
      canvas,
      img,
      Rect.fromLTWH(sx.toDouble(), sy.toDouble(), size.x, size.y),
    );
  }

  @override
  void onRemove() {
    _controller?.dispose();
    _controller = null;
    super.onRemove();
  }
}
