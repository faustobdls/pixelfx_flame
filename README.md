# pixelfx_flame

Flame game-engine bridge for `pixelfx_core` and `pixelfx_flutter`:

- `PixelFxFlameExtension` (`PixelFxExtension`)
- `PixelFxComponent` & `PixelActComponent` (`PositionComponent` with nearest-neighbor rendering & `onHit`)
- `PixelFxFlameBaker` (`bakeWithAtlas`, `toSpriteAnimationComponent`)

## Usage

```dart
add(PixelActComponent(
  effect: swordSlashEffect,
  palette: Pal.fire,
  onHit: (hit) => camera.shake(intensity: hit.amp),
));
```
