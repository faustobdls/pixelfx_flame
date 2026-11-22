// 2.5D Flame PositionComponents with depth-sorted iso priority, plane projection, and pitched rigs.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:pixelfx_core/pixelfx_core.dart';
import 'package:pixelfx_flutter/pixelfx_flutter.dart';
import 'package:pixelfx_iso/pixelfx_iso.dart';

/// Computes a deterministic Flame render [priority] from isometric world `(x, y, z)` coordinates.
int isoDepthPriority(
  double worldX,
  double worldY, [
  double worldZ = 0.0,
]) =>
    ((worldX + worldY) * 100.0 + worldZ * 10.0).round();

/// Mixin giving any Flame [PositionComponent] automatic isometric painter-order sorting.
mixin IsoDepthSortingMixin on PositionComponent {
  double worldX = 0.0;
  double worldY = 0.0;
  double worldZ = 0.0;

  /// Update logical 3D world coordinates and refresh Flame [priority] in painter order.
  void setWorldPosition(
    double x,
    double y, [
    double z = 0.0,
    IsoProjection projection = const IsoProjection.standard(),
    Vector2? originOffset,
  ]) {
    worldX = x;
    worldY = y;
    worldZ = z;
    final (sx, sy) = projection.project(x, y, z);
    final ox = originOffset?.x ?? 0.0;
    final oy = originOffset?.y ?? 0.0;
    position.setValues(ox + sx, oy + sy);
    priority = isoDepthPriority(x, y, z);
  }
}

/// Depth-sorted Flame component for static or animated native `iso/*` tiles and props.
class PixelIsoSpriteComponent extends PositionComponent with IsoDepthSortingMixin {
  final PixelAsset asset;
  final List<Object>? palette;
  final int? seed;
  final BackdropKind backdrop;
  final bool? loop;
  final bool playing;
  final double speed;
  final double light;
  final Map<String, Object?> options;
  final List<PostProcessor> postProcessors;

  PixelFxController? _controller;

  PixelIsoSpriteComponent({
    required this.asset,
    double worldX = 0.0,
    double worldY = 0.0,
    double worldZ = 0.0,
    this.palette,
    this.seed,
    this.backdrop = BackdropKind.none,
    this.loop,
    this.playing = true,
    this.speed = 1.0,
    this.light = 1.0,
    this.options = const {},
    this.postProcessors = const [],
    super.position,
    super.scale,
    super.angle,
    Anchor? anchor,
    int? priority,
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
          priority: priority ?? isoDepthPriority(worldX, worldY, worldZ),
        ) {
    this.worldX = worldX;
    this.worldY = worldY;
    this.worldZ = worldZ;
  }

  PixelFxController get controller {
    final c = _controller;
    if (c == null) {
      throw StateError('PixelIsoSpriteComponent accessed before onLoad.');
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
      showActor: false,
      seed: seed,
      lightK: light,
      options: mergedOpts,
      postProcessors: postProcessors,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _controller?.step(dt);
  }

  @override
  void render(ui.Canvas canvas) {
    final img = _controller?.image;
    if (img == null) return;
    drawCrispImage(canvas, img, ui.Rect.fromLTWH(0, 0, size.x, size.y));
  }

  @override
  void onRemove() {
    _controller?.dispose();
    _controller = null;
    super.onRemove();
  }
}

/// Live Flame component projecting any 2D [PixelAsset] onto a 2.5D [IsoPlane].
class PixelIsoEffectComponent extends PositionComponent with IsoDepthSortingMixin {
  final PixelAsset source;
  final IsoPlane plane;
  final IsoDir dir;
  final IsoProjection projection;
  final double fxScale;
  final List<Object>? palette;
  final int? seed;
  final BackdropKind backdropKind;
  final bool? loop;
  final bool playing;
  final double speed;
  final bool removeOnFinish;
  final double light;
  final Map<String, Object?> options;
  final List<PostProcessor> postProcessors;

  late final IsoProjectedEffect _projected;
  PixelFxController? _controller;

  PixelIsoEffectComponent({
    required this.source,
    this.plane = IsoPlane.floor,
    this.dir = IsoDir.se,
    this.projection = const IsoProjection.standard(),
    this.fxScale = 1.0,
    double worldX = 0.0,
    double worldY = 0.0,
    double worldZ = 0.0,
    this.palette,
    this.seed,
    this.backdropKind = BackdropKind.none,
    this.loop,
    this.playing = true,
    this.speed = 1.0,
    this.removeOnFinish = true,
    this.light = 1.0,
    this.options = const {},
    this.postProcessors = const [],
    super.position,
    super.scale,
    super.angle,
    Anchor? anchor,
    int? priority,
    super.key,
  }) : super(priority: priority ?? isoDepthPriority(worldX, worldY, worldZ)) {
    this.worldX = worldX;
    this.worldY = worldY;
    this.worldZ = worldZ;
    _projected = IsoProjectedEffect(
      source,
      plane: plane,
      projection: projection,
      dir: dir,
      scale: fxScale,
      bg: backdropKind,
    );
    size = Vector2(
      _projected.meta.width.toDouble(),
      _projected.meta.height.toDouble(),
    );
    this.anchor = anchor ??
        Anchor(
          _projected.meta.originX / math.max(1, _projected.meta.width),
          _projected.meta.originY / math.max(1, _projected.meta.height),
        );
  }

  PixelFxController get controller {
    final c = _controller;
    if (c == null) {
      throw StateError('PixelIsoEffectComponent accessed before onLoad.');
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
      asset: _projected,
      actMode: false,
      playing: playing,
      loop: loop,
      speed: speed,
      backdropKind: backdropKind,
      showActor: false,
      seed: seed,
      lightK: light,
      options: mergedOpts,
      postProcessors: postProcessors,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final c = _controller;
    if (c == null) return;
    c.step(dt);
    if (removeOnFinish &&
        !(loop ?? source.meta.loop) &&
        c.currentTime >= c.totalDuration) {
      removeFromParent();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final img = _controller?.image;
    if (img == null) return;
    drawCrispImage(canvas, img, ui.Rect.fromLTWH(0, 0, size.x, size.y));
  }

  @override
  void onRemove() {
    _controller?.dispose();
    _controller = null;
    super.onRemove();
  }
}

/// Live Flame component running a 2.5D acted [IsoActInstance] with pitched character rig,
/// 2:1 contact shadows, directional target dummy, hit-stop, and camera shake.
class PixelIsoActComponent extends PositionComponent with IsoDepthSortingMixin {
  final PixelAsset effect;
  final IsoDir dir;
  final IsoPlane plane;
  final IsoProjection projection;
  final double pitch;
  final List<Object>? palette;
  final int? seed;
  final BackdropKind backdropKind;
  final bool? loop;
  final bool playing;
  final double speed;
  final bool showActor;
  final bool showTarget;
  final bool removeOnFinish;
  final double light;
  final Map<String, Object?> options;
  final void Function(HitSpec hit)? onHit;

  late final IsoActBounds _bounds;
  late PixelIsoFrame _frame;
  late Uint8List _rgba;
  Uint32List? _bgBuffer;
  IsoActInstance? _inst;
  double _accum = 0.0;
  ui.Image? _image;
  bool _decoding = false;
  bool _pending = false;
  bool _disposed = false;

  PixelIsoActComponent({
    required this.effect,
    this.dir = IsoDir.se,
    this.plane = IsoPlane.floor,
    this.projection = const IsoProjection.standard(),
    this.pitch = kIsoCameraPitch,
    double worldX = 0.0,
    double worldY = 0.0,
    double worldZ = 0.0,
    this.palette,
    this.seed,
    this.backdropKind = BackdropKind.none,
    this.loop,
    this.playing = true,
    this.speed = 1.0,
    this.showActor = true,
    this.showTarget = true,
    this.removeOnFinish = true,
    this.light = 1.0,
    this.options = const {},
    this.onHit,
    super.position,
    super.scale,
    super.angle,
    Anchor? anchor,
    int? priority,
    super.key,
  }) : super(priority: priority ?? isoDepthPriority(worldX, worldY, worldZ)) {
    this.worldX = worldX;
    this.worldY = worldY;
    this.worldZ = worldZ;
    _bounds = isoActBounds(
      effect,
      RigRasterizer.instance,
      dir: dir,
      projection: projection,
      pitch: pitch,
    );
    size = Vector2(_bounds.width.toDouble(), _bounds.height.toDouble());
    this.anchor = anchor ??
        Anchor(
          _bounds.originX / math.max(1, _bounds.width),
          _bounds.originY / math.max(1, _bounds.height),
        );
  }

  IsoActInstance get instance {
    final i = _inst;
    if (i == null) {
      throw StateError('PixelIsoActComponent accessed before onLoad.');
    }
    return i;
  }

  ui.Image? get currentImage => _image;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _frame = createIsoFrame(_bounds.width, _bounds.height);
    _rgba = Uint8List(_bounds.width * _bounds.height * 4);
    _bgBuffer = backdropKind == BackdropKind.none
        ? null
        : backdrop(backdropKind, _bounds.width, _bounds.height, _bounds.originY);
    _createInst();
    _scheduleDecode();
  }

  void _createInst() {
    final merged = <String, Object?>{
      ...options,
      if (palette != null) 'palette': palette,
      if (seed != null) 'seed': seed,
      'x': _bounds.originX,
      'y': _bounds.originY,
      'light': light,
    };
    _inst = IsoActInstance(
      source: effect,
      spec: IsoActSpec(
        dir: dir,
        plane: plane,
        projection: projection,
        pitch: pitch,
        showStageTile: false,
      ),
      options: merged,
      showActor: showActor,
      showTarget: showTarget,
      onHit: onHit,
    );
    _renderNow();
  }

  void _renderNow() {
    final i = _inst;
    if (i == null) return;
    clearIsoFrame(_frame);
    i.draw(_frame, DrawLayer.both);
    composite(_frame, _rgba, bgBuffer: _bgBuffer, lightK: light);
  }

  void _scheduleDecode() {
    if (_disposed) return;
    if (_decoding) {
      _pending = true;
      return;
    }
    _decoding = true;
    final copy = Uint8List.fromList(_rgba);
    rgbaToUiImage(copy, _bounds.width, _bounds.height).then((img) {
      _decoding = false;
      if (_disposed) {
        img.dispose();
        return;
      }
      _image?.dispose();
      _image = img;
      if (_pending) {
        _pending = false;
        _scheduleDecode();
      }
    });
  }

  Future<void> flushDecodeForTest() async {
    _renderNow();
    final copy = Uint8List.fromList(_rgba);
    final img = await rgbaToUiImage(copy, _bounds.width, _bounds.height);
    if (_disposed) {
      img.dispose();
      return;
    }
    _image?.dispose();
    _image = img;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final i = _inst;
    if (!playing || i == null) return;
    final fps = effect.meta.fps > 0 ? effect.meta.fps : 30;
    final stepDt = 1.0 / fps;
    _accum += dt * speed;
    var advanced = false;
    while (_accum >= stepDt) {
      _accum -= stepDt;
      i.update(stepDt);
      advanced = true;
      if (i.done) {
        if (loop ?? effect.meta.loop) {
          _createInst();
        } else if (removeOnFinish) {
          removeFromParent();
          return;
        }
        break;
      }
    }
    if (advanced) {
      _renderNow();
      _scheduleDecode();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final img = _image;
    if (img == null || _inst == null) return;
    final (sx, sy) = _inst!.shake;
    drawCrispImage(
      canvas,
      img,
      ui.Rect.fromLTWH(sx.toDouble(), sy.toDouble(), size.x, size.y),
    );
  }

  @override
  void onRemove() {
    _disposed = true;
    _image?.dispose();
    _image = null;
    super.onRemove();
  }
}
