/// App `GameVariant` <-> core `Variant` (design §2, adapters/).
library;

import 'package:tavli/features/game/domain/engine/variants/game_variant.dart';
import 'package:tavli_core/tavli_core.dart';

/// The core variant for an app variant.
extension GameVariantToCore on GameVariant {
  Variant get core => switch (this) {
        GameVariant.portes => Variant.portes,
        GameVariant.plakoto => Variant.plakoto,
        GameVariant.fevga => Variant.fevga,
        GameVariant.tavla => Variant.tavla,
        GameVariant.tapa => Variant.tapa,
        GameVariant.moultezim => Variant.moultezim,
        GameVariant.gulBara => Variant.gulBara,
        GameVariant.longNard => Variant.longNard,
        GameVariant.shortNard => Variant.shortNard,
        GameVariant.sheshBesh => Variant.sheshBesh,
        GameVariant.mahbusa => Variant.mahbusa,
        GameVariant.tawla31 => Variant.tawla31,
        GameVariant.mahbusaArab => Variant.mahbusaArab,
      };
}

/// The app variant for a core variant.
extension VariantToApp on Variant {
  GameVariant get app => switch (this) {
        Variant.portes => GameVariant.portes,
        Variant.plakoto => GameVariant.plakoto,
        Variant.fevga => GameVariant.fevga,
        Variant.tavla => GameVariant.tavla,
        Variant.tapa => GameVariant.tapa,
        Variant.moultezim => GameVariant.moultezim,
        Variant.gulBara => GameVariant.gulBara,
        Variant.longNard => GameVariant.longNard,
        Variant.shortNard => GameVariant.shortNard,
        Variant.sheshBesh => GameVariant.sheshBesh,
        Variant.mahbusa => GameVariant.mahbusa,
        Variant.tawla31 => GameVariant.tawla31,
        Variant.mahbusaArab => GameVariant.mahbusaArab,
      };
}
