import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelfx_core/pixelfx_core.dart';
import 'package:pixelfx_flame/pixelfx_flame.dart';
import 'package:pixelfx_iso/pixelfx_iso.dart';

final PureEffect _flameTestSlash = PureEffect(
  meta: const EffectMeta(
    id: 'flame/test-slash',
    name: 'Flame Test Slash',
    desc: 'Minimal acted effect for Flame runtime tests.',
    size: (32, 32),
    origin: (16, 16),
    duration: 0.4,
    loop: false,
    fps: 15,
    actorScale: 1,
    defaultOptions: {'palette': Pal.fire},
  ),
  act: const ActSpec(
    poses: [
      PoseKey(-0.1, kStand),
      PoseKey(0.1, kReady),
      PoseKey(0.4, kStand),
    ],
    hits: [HitSpec(t: 0.1, shake: 0.1, amp: 2.0)],
  ),
  onDraw: (p, t, o) {
    final c = ramp(o.palette);
    p.glow(0, 0, 6, c[1], 0.7);
    p.dot(0, 0, c[3]);
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PixelFxFlameExtension registers cleanly in PixelFxRegistry', () {
    final ext = PixelFxFlameExtension(assets: [_flameTestSlash]);
    final reg = PixelFxRegistry()..register(ext);
    expect(reg.getAsset('flame/test-slash'), same(_flameTestSlash));
    expect(reg.extensions.any((e) => e.manifest.id == 'pixelfx.flame'), isTrue);
  });

  test('PixelFxFlameBaker bakes packed atlas and SpriteAnimationComponent', () async {
    final baked = await PixelFxFlameBaker.bakeWithAtlas(_flameTestSlash, seed: 2);
    expect(baked.animation.frames.length, equals(7));
    expect(baked.atlas.frameWidth, equals(32));
    expect(baked.atlas.frameHeight, equals(32));

    final comp = PixelFxFlameBaker.toSpriteAnimationComponent(
      baked,
      position: Vector2(10, 20),
      removeOnFinish: true,
    );
    expect(comp.paint.filterQuality, equals(ui.FilterQuality.none));
    expect(comp.anchor, equals(const Anchor(0.5, 0.5)));
    baked.dispose();
  });

  test('PixelFxComponent and PixelActComponent decode GPU frames on load', () async {
    final fxComp = PixelFxComponent(asset: _flameTestSlash);
    final actComp = PixelActComponent(effect: _flameTestSlash);
    await fxComp.onLoad();
    await actComp.onLoad();
    await fxComp.controller.flushDecodeForTest();
    await actComp.controller.flushDecodeForTest();

    expect(fxComp.controller.image, isNotNull);
    expect(actComp.controller.image, isNotNull);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    fxComp.render(canvas);
    actComp.render(canvas);
    recorder.endRecording().dispose();

    fxComp.onRemove();
    actComp.onRemove();
  });

  testWidgets(
    'PixelFxComponent and PixelActComponent drive FlameGame updates, hit callbacks, and auto-remove',
    (tester) async {
      final game = FlameGame();
      final hits = <HitSpec>[];

      final fxComp = PixelFxComponent(
        asset: _flameTestSlash,
        removeOnFinish: true,
      );
      final actComp = PixelActComponent(
        effect: _flameTestSlash,
        onHit: hits.add,
        removeOnFinish: true,
      );

      await game.addAll([fxComp, actComp]);
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(fxComp.isMounted, isTrue);
      expect(actComp.isMounted, isTrue);

      for (var i = 0; i < 15; i++) {
        game.update(0.05);
      }
      await tester.pump();

      expect(hits, isNotEmpty);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      game.render(canvas);
      recorder.endRecording().dispose();

      for (var i = 0; i < 30; i++) {
        game.update(0.05);
      }
      await tester.pump();

      expect(fxComp.isMounted, isFalse);
      expect(actComp.isMounted, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test('PixelFxFlameBaker.bakeTurntableAtlas bakes 4 isometric directions cleanly', () async {
    final turntable = await PixelFxFlameBaker.bakeTurntableAtlas(
      _flameTestSlash,
      directions: const [IsoDir.se, IsoDir.sw, IsoDir.nw, IsoDir.ne],
      seed: 4,
    );
    expect(turntable.animations.length, equals(4));
    expect(turntable[IsoDir.se].atlas.frameCount, equals(7));
    turntable.dispose();
  });

  testWidgets(
    '2.5D iso Flame components sort priority by world coordinates and render in FlameGame',
    (tester) async {
      final bgComp = PixelIsoSpriteComponent(
        asset: isoStoneTile,
        worldX: 0.0,
        worldY: 0.0,
      );
      final fgComp = PixelIsoEffectComponent(
        source: _flameTestSlash,
        dir: IsoDir.se,
        worldX: 1.5,
        worldY: 1.5,
      );
      final actComp = PixelIsoActComponent(
        effect: _flameTestSlash,
        dir: IsoDir.nw,
        worldX: 2.0,
        worldY: 2.0,
      );
      expect(fgComp.priority, greaterThan(bgComp.priority));
      expect(actComp.priority, greaterThan(fgComp.priority));

      final game = FlameGame();
      await game.addAll([bgComp, fgComp, actComp]);
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      for (var i = 0; i < 6; i++) {
        game.update(1 / 30);
      }
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      recorder.endRecording().dispose();

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
