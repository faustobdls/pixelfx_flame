// Atlas baker turning pixelfx_core assets into Flame SpriteAnimation + crisp SpriteAnimationComponent.

import 'dart:math' as math;
import 'dart:ui' show FilterQuality, Paint;

import 'package:flame/components.dart';
import 'package:pixelfx_core/pixelfx_core.dart';
import 'package:pixelfx_flutter/pixelfx_flutter.dart';
import 'package:pixelfx_iso/pixelfx_iso.dart';

/// Holds baked 8-direction (or custom subset) [BakedFlameAnimation]s for an isometric turntable.
class BakedIsoTurntable {
  final Map<IsoDir, BakedFlameAnimation> animations;
  final (int w, int h) frameSize;
  final (int ox, int oy) origin;

  const BakedIsoTurntable({
    required this.animations,
    required this.frameSize,
    required this.origin,
  });

  BakedFlameAnimation operator [](IsoDir dir) => animations[dir]!;

  /// Dispose all baked atlas textures across orientations.
  void dispose() {
    for (final a in animations.values) {
      a.dispose();
    }
  }
}

/// Holds a Flame [SpriteAnimation] together with its backing [PixelFxSheetAtlas]
/// so callers can deterministically [dispose] GPU memory on scene unload.
class BakedFlameAnimation {
  final SpriteAnimation animation;
  final PixelFxSheetAtlas atlas;

  const BakedFlameAnimation({
    required this.animation,
    required this.atlas,
  });

  /// Proportional Flame anchor matching the asset's `(originX, originY)` pivot.
  Anchor get recommendedAnchor => Anchor(
        atlas.origin.$1 / math.max(1, atlas.frameWidth),
        atlas.origin.$2 / math.max(1, atlas.frameHeight),
      );

  /// Dispose the packed GPU texture backing [animation].
  void dispose() => atlas.dispose();
}

/// Converts programmatic [PixelAsset]s into baked Flame animations & components.
class PixelFxFlameBaker {
  const PixelFxFlameBaker._();

  /// Bake [asset] into a single packed atlas + Flame [SpriteAnimation].
  static Future<BakedFlameAnimation> bakeWithAtlas(
    PixelAsset asset, {
    BackdropKind bg = BackdropKind.none,
    int? fps,
    int? seed,
    bool showActor = false,
    Map<String, Object?> options = const {},
    List<PostProcessor> postProcessors = const [],
  }) async {
    final atlas = await PixelFxBaker.bakeAtlas(
      asset,
      bg: bg,
      fps: fps,
      seed: seed,
      showActor: showActor,
      options: options,
      postProcessors: postProcessors,
    );
    final anim = SpriteAnimation.fromFrameData(
      atlas.image,
      SpriteAnimationData.sequenced(
        amount: atlas.frameCount,
        stepTime: 1.0 / math.max(1, atlas.fps),
        textureSize: Vector2(
          atlas.frameWidth.toDouble(),
          atlas.frameHeight.toDouble(),
        ),
        amountPerRow: atlas.columns,
        loop: atlas.loop,
      ),
    );
    return BakedFlameAnimation(animation: anim, atlas: atlas);
  }

  /// Convenience shortcut returning only the [SpriteAnimation].
  /// Prefer [bakeWithAtlas] in production scenes so you can dispose [BakedFlameAnimation.atlas].
  static Future<SpriteAnimation> bakeSpriteAnimation(
    PixelAsset asset, {
    BackdropKind bg = BackdropKind.none,
    int? fps,
    int? seed,
    bool showActor = false,
    Map<String, Object?> options = const {},
    List<PostProcessor> postProcessors = const [],
  }) async {
    final baked = await bakeWithAtlas(
      asset,
      bg: bg,
      fps: fps,
      seed: seed,
      showActor: showActor,
      options: options,
      postProcessors: postProcessors,
    );
    return baked.animation;
  }

  /// Create a nearest-neighbor [SpriteAnimationComponent] from a [BakedFlameAnimation].
  static SpriteAnimationComponent toSpriteAnimationComponent(
    BakedFlameAnimation baked, {
    Vector2? position,
    Vector2? scale,
    bool removeOnFinish = false,
    Anchor? anchor,
    int? priority,
  }) =>
      SpriteAnimationComponent(
        animation: baked.animation,
        position: position,
        scale: scale,
        anchor: anchor ?? baked.recommendedAnchor,
        removeOnFinish: removeOnFinish,
        priority: priority,
        paint: Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false,
      );

  /// Bake all [directions] of [asset] projected onto [plane] into a [BakedIsoTurntable].
  static Future<BakedIsoTurntable> bakeTurntableAtlas(
    PixelAsset asset, {
    List<IsoDir> directions = IsoDir.values,
    IsoPlane plane = IsoPlane.floor,
    IsoProjection projection = const IsoProjection.standard(),
    BackdropKind bg = BackdropKind.none,
    int? fps,
    int? seed,
    Map<String, Object?> options = const {},
    List<PostProcessor> postProcessors = const [],
  }) async {
    final isNativeIso = asset.meta.extra['iso'] == true;
    final out = <IsoDir, BakedFlameAnimation>{};
    for (final d in directions) {
      final projected = isNativeIso
          ? asset
          : IsoProjectedEffect(
              asset,
              plane: plane,
              projection: projection,
              dir: d,
              bg: bg,
            );
      out[d] = await bakeWithAtlas(
        projected,
        bg: bg,
        fps: fps,
        seed: seed,
        showActor: false,
        options: options,
        postProcessors: postProcessors,
      );
    }
    final first = out.values.first;
    return BakedIsoTurntable(
      animations: out,
      frameSize: (first.atlas.frameWidth, first.atlas.frameHeight),
      origin: first.atlas.origin,
    );
  }
}
