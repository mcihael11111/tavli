/// Paint measurements of the 2026 baked-bear-off board art (sets 1–3
/// share the template), ported from the legacy baked-mode `BoardLayout`
/// (design §8). All values are in source pixels of the 2102 × 2374 PNG;
/// the layout only uses them as fractions, so they stay valid for the
/// resized WebP boards (design §5.5). Re-measure if the art is re-exported.
abstract final class BoardCalibration {
  static const double width = 2102;
  static const double height = 2374;

  /// Width / height of the board image (contain-fit).
  static const double aspect = width / height;

  /// Playing region (inside the frame, between the two tray strips).
  static const double boardTop = 213;
  static const double boardBottom = 2162; // exclusive: 213 + 1949

  /// The red bear-off trays. Y spans per the legacy calibration; x spans
  /// are the narrowest of the three sets (set 3: 614..1489), so a sliver
  /// never sits on the wood of any set.
  static const double topTrayTop = 43;
  static const double topTrayBottom = 181;
  static const double bottomTrayTop = 2202;
  static const double bottomTrayBottom = 2340;
  static const double trayLeft = 614;
  static const double trayRight = 1490;

  /// Painted triangle bases (top and bottom rows) and triangle length.
  static const double topBaseY = 268;
  static const double bottomBaseY = 2103;
  static const double triangleHeight = 933 - 258;

  /// Centres of the leftmost (view point 11 / 12) and rightmost
  /// (view point 0 / 23) point columns.
  static const double leftmostCenterX = 161.5;
  static const double rightmostCenterX = 1974.5;

  /// Centre-to-centre spacing within each half (hand-painted, unequal).
  static const double spacingLeft = 154;
  static const double spacingRight = 158;

  /// Checker radius as a fraction of the (left, smaller) point spacing:
  /// leaves a margin so neighbouring stacks never touch.
  static const double checkerRadiusPerPoint = 0.46;

  /// Stack step as a fraction of the checker diameter.
  static const double stackOverlap = 0.75;

  /// Piles taller than this compress to this pile's span.
  static const int maxUncompressed = 7;

  /// Die (visible face) edge as a multiple of the checker radius.
  static const double dieSizePerRadius = 1.6;

  /// Gap between dice as a fraction of the die size.
  static const double diceGapPerDie = 0.37;

  /// Dice area centre x as a fraction of the image width (y: board centre).
  static const double diceCenterXFrac = 0.75;

  /// Bear-off sliver visible height as a fraction of the tray height.
  static const double sliverHeightPerTray = 0.92;

  /// Bear-off sliver step, as a multiple of the sliver width (capped so 15
  /// fit in the tray).
  static const double sliverStepPerWidth = 1.2;
}
