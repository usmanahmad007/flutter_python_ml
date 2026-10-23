import 'package:flutter/material.dart';

import '../core/python_ml_model.dart';
import '../models/ml_prediction.dart';

/// Pre-built interactive Flutter card for triggering and visualizing
/// on-device Python ML model predictions.
class ModelInferenceCard extends StatelessWidget {
  final PythonMLModel model;
  final String title;
  final String description;
  final Widget? inputControls;
  final VoidCallback onPredictPressed;
  final MLPrediction? prediction;
  final bool isDark;

  const ModelInferenceCard({
    super.key,
    required this.model,
    required this.title,
    required this.description,
    this.inputControls,
    required this.onPredictPressed,
    this.prediction,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final pred = prediction ?? model.lastPrediction;
    final isPredicting = model.status == ModelStatus.predicting;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2436) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Title & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(model.status),
            ],
          ),
          const SizedBox(height: 16),

          // Custom Input Controls (Sliders, text boxes, etc.)
          if (inputControls != null) ...[
            inputControls!,
            const SizedBox(height: 14),
          ],

          // Predict Button
          ElevatedButton.icon(
            icon: isPredicting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.bolt_rounded, size: 20),
            label: Text(
                isPredicting ? 'Executing on-device...' : 'Run Python Model'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: isPredicting ? null : onPredictPressed,
          ),

          // Output Display
          if (pred != null) ...[
            const SizedBox(height: 16),
            _buildPredictionView(pred),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ModelStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case ModelStatus.ready:
        bg = Colors.green.withAlpha(35);
        fg = Colors.greenAccent;
        label = 'READY';
        break;
      case ModelStatus.loading:
      case ModelStatus.predicting:
        bg = Colors.amber.withAlpha(35);
        fg = Colors.amberAccent;
        label = status == ModelStatus.loading ? 'LOADING' : 'PREDICTING';
        break;
      case ModelStatus.error:
        bg = Colors.red.withAlpha(35);
        fg = Colors.redAccent;
        label = 'ERROR';
        break;
      default:
        bg = Colors.grey.withAlpha(35);
        fg = Colors.grey;
        label = 'STANDBY';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(
            color: fg,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildPredictionView(MLPrediction pred) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ON-DEVICE INFERENCE RESULT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.grey,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '⚡ ${pred.latencyMs.toStringAsFixed(2)} ms',
                  style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: Colors.greenAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Predicted Class Label or Main Value
          if (pred.predictedLabel != null)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pred.predictedLabel!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF818CF8),
                    ),
                  ),
                ),
                if (pred.confidence != null)
                  Text(
                    'Confidence: ${(pred.confidence! * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87),
                  ),
              ],
            ),

          // Probabilities Breakdown
          if (pred.probabilities != null && model.labels != null) ...[
            const SizedBox(height: 10),
            ...List.generate(
              _min(pred.probabilities!.length, model.labels!.length),
              (idx) {
                final label = model.labels![idx];
                final prob = pred.probabilities![idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${(prob * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: prob,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation(
                            prob > 0.5
                                ? const Color(0xFF6366F1)
                                : Colors.cyan.withAlpha(150),
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  int _min(int a, int b) => a < b ? a : b;
}
