## 0.2.0

- Depend on `pixelfx_core ^0.2.0`, `pixelfx_flutter ^0.2.0`, and `pixelfx_iso ^0.1.0`.
- Add 2.5D Flame components (`PixelIsoSpriteComponent`, `PixelIsoEffectComponent`, `PixelIsoActComponent`, `IsoDepthSortingMixin`) with automatic isometric depth priority.
- Add `PixelFxFlameBaker.bakeTurntableAtlas` (`BakedIsoTurntable`) for 8-direction isometric sprite animation baking.

## 0.1.0

- Initial release: Flame engine extension bridge (`PixelFxFlameExtension`, `PixelFxComponent`, `PixelActComponent`, `PixelFxFlameBaker`).
- Configured standalone GitHub Actions CI & pub.dev OIDC automated publishing workflows using `_ci_workspace` isolation (`flutter pub publish`).
