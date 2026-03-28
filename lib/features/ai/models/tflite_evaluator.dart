import 'package:tflite_flutter/tflite_flutter.dart';
import '../../game/data/models/board_state.dart';
import '../../game/domain/engine/board_evaluator.dart';

/// TFLite-based neural network position evaluator.
///
/// Replaces the heuristic BoardEvaluator with a TD-Gammon-inspired
/// neural network for stronger play. The model runs on-device.
///
/// Architecture (from spec):
/// - Input: 198 features (4 binary per point × 24 × 2 players + bar + borne off + turn + cube)
/// - Hidden 1: 80 neurons (sigmoid)
/// - Hidden 2: 40 neurons (sigmoid)
/// - Output: win probability, gammon probability, backgammon probability (sigmoid)
///
/// Model format: TensorFlow Lite (.tflite), <5MB, quantized.
/// Inference target: <50ms per position evaluation.
class TFLiteEvaluator extends BoardEvaluator {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  TFLiteEvaluator();

  /// Load the TFLite model from assets.
  Future<void> loadModel({String modelPath = 'assets/ai_models/tavli_v1.tflite'}) async {
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      _isLoaded = true;
    } catch (e) {
      // Model not available — fall back to heuristic evaluation.
      _isLoaded = false;
    }
  }

  bool get isLoaded => _isLoaded;

  /// Extract 198 input features from a board state.
  ///
  /// Feature encoding per spec:
  /// - For each point (24 × 2 players = 48 groups):
  ///   - 1 if player has 1+ checker
  ///   - 1 if player has 2+ checkers
  ///   - 1 if player has 3+ checkers
  ///   - (count - 3) / 2 if player has 4+ checkers
  /// - Bar count for each player (2 features)
  /// - Borne off count for each player (2 features)
  /// - Whose turn it is (1 feature)
  /// - Cube value (normalized) (1 feature)
  List<double> extractFeatures(BoardState state) {
    final features = <double>[];

    // Point features: 4 per point per player = 192 features.
    for (int i = 0; i < 24; i++) {
      // Player 1 checkers at this point.
      final p1Count = state.points[i] > 0 ? state.points[i] : 0;
      features.add(p1Count >= 1 ? 1.0 : 0.0);
      features.add(p1Count >= 2 ? 1.0 : 0.0);
      features.add(p1Count >= 3 ? 1.0 : 0.0);
      features.add(p1Count >= 4 ? (p1Count - 3) / 2.0 : 0.0);

      // Player 2 checkers at this point.
      final p2Count = state.points[i] < 0 ? -state.points[i] : 0;
      features.add(p2Count >= 1 ? 1.0 : 0.0);
      features.add(p2Count >= 2 ? 1.0 : 0.0);
      features.add(p2Count >= 3 ? 1.0 : 0.0);
      features.add(p2Count >= 4 ? (p2Count - 3) / 2.0 : 0.0);
    }

    // Bar (2 features).
    features.add(state.bar1 / 2.0);
    features.add(state.bar2 / 2.0);

    // Borne off (2 features).
    features.add(state.borneOff1 / 15.0);
    features.add(state.borneOff2 / 15.0);

    // Turn (1 feature).
    features.add(state.activePlayer == 1 ? 1.0 : 0.0);

    // Cube (1 feature).
    features.add(state.doublingCubeValue / 64.0);

    return features; // 198 features total
  }

  /// Neural network evaluation.
  ///
  /// Returns equity from [player]'s perspective based on predicted
  /// win/gammon/backgammon probabilities.
  /// Falls back to heuristic if model not loaded.
  @override
  double evaluate(BoardState state, int player) {
    if (!_isLoaded || _interpreter == null) {
      return super.evaluate(state, player);
    }

    final input = extractFeatures(state);
    // TFLite expects [batch, features] shape.
    final inputTensor = [input];
    // Output: [batch, 3] — [winProb, gammonProb, backgammonProb].
    final outputTensor = [List<double>.filled(3, 0.0)];

    try {
      _interpreter!.run(inputTensor, outputTensor);
    } catch (_) {
      return super.evaluate(state, player);
    }

    final winProb = outputTensor[0][0];
    final gammonProb = outputTensor[0][1];
    final bgProb = outputTensor[0][2];

    // Equity: win probability is primary, gammon/backgammon add bonus.
    // winProb is from P1's perspective (trained that way).
    double equity = winProb + gammonProb * 0.5 + bgProb * 0.25;

    // Normalize to [-1, 1] range (0.5 baseline = equal).
    equity = (equity - 0.5) * 2.0;

    // Flip if evaluating for player 2.
    if (player == 2) {
      equity = -equity;
    }

    return equity.clamp(-1.0, 1.0);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
