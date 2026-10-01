import 'catalog.dart';
import 'variant_rules.dart';

/// The 13 app variants. Behaviour lives only in [variantCatalog].
enum Variant {
  portes,
  plakoto,
  fevga,
  tavla,
  tapa,
  moultezim,
  gulBara,
  longNard,
  shortNard,
  sheshBesh,
  mahbusa,
  mahbusaArab,
  tawla31;

  VariantRules get rules => variantCatalog[this]!;
}
