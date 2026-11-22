// Reference PixelFxExtension providing Flame component factories and baking helpers.

import 'package:pixelfx_core/pixelfx_core.dart';

import 'flame_baker.dart';
import 'pixel_act_component.dart';
import 'pixel_fx_component.dart';

/// Flame engine integration module implementing [PixelFxExtension].
///
/// Register it into a [PixelFxRegistry] alongside domain packs, or call
/// its helper factories directly to spawn live [PixelFxComponent] /
/// [PixelActComponent] instances or bake GPU [BakedFlameAnimation] atlases.
class PixelFxFlameExtension extends PixelFxExtension {
  @override
  final List<PixelAsset> assets;

  PixelFxFlameExtension({this.assets = const []});

  @override
  ExtensionManifest get manifest => const ExtensionManifest(
        id: 'pixelfx.flame',
        name: 'PixelFx Flame Bridge',
        version: '0.2.0',
        description:
            'Flame engine runtime adapter providing PositionComponents and packed SpriteAnimation baking.',
        author: 'Fausto BDLS',
        tags: ['flame', 'runtime', 'sprite-animation', 'act'],
      );

  /// Spawn a live animated Flame component for any [PixelAsset].
  PixelFxComponent createComponent(
    PixelAsset asset, {
    List<Object>? palette,
    int? seed,
    bool flip = false,
    bool? loop,
    bool removeOnFinish = true,
  }) =>
      PixelFxComponent(
        asset: asset,
        palette: palette,
        seed: seed,
        flip: flip,
        loop: loop,
        removeOnFinish: removeOnFinish,
      );

  /// Spawn an acted Flame component with character, target dummy, hit-stop, and camera shake.
  PixelActComponent createActComponent(
    PixelEffect effect, {
    List<Object>? palette,
    int? seed,
    bool flip = false,
    bool? loop,
    void Function(HitSpec hit)? onHit,
    bool removeOnFinish = true,
  }) =>
      PixelActComponent(
        effect: effect,
        palette: palette,
        seed: seed,
        flip: flip,
        loop: loop,
        onHit: onHit,
        removeOnFinish: removeOnFinish,
      );

  /// Bake [asset] into a packed Flame [BakedFlameAnimation] (dispose when done).
  Future<BakedFlameAnimation> bakeAnimation(
    PixelAsset asset, {
    BackdropKind bg = BackdropKind.none,
    int? fps,
    int? seed,
    bool showActor = false,
    Map<String, Object?> options = const {},
  }) =>
      PixelFxFlameBaker.bakeWithAtlas(
        asset,
        bg: bg,
        fps: fps,
        seed: seed,
        showActor: showActor,
        options: options,
      );
}
