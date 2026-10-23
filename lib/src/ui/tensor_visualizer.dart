import 'package:flutter/material.dart';

import '../models/tensor_data.dart';

/// Renders a multi-dimensional [TensorData] structure as an interactive numeric grid or bar chart.
class TensorVisualizer extends StatelessWidget {
  final TensorData tensor;
  final String? title;
  final bool isDark;

  const TensorVisualizer({
    super.key,
    required this.tensor,
    this.title,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131722) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title ?? 'Tensor (${tensor.shape.join("×")})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Text(
                tensor.dtype.name,
                style: const TextStyle(fontSize: 10, color: Colors.cyanAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildElementsView(),
        ],
      ),
    );
  }

  Widget _buildElementsView() {
    final floatList = tensor.toFloatList();
    if (floatList.isEmpty) {
      return const Text('Empty tensor',
          style: TextStyle(fontSize: 11, color: Colors.grey));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(floatList.length, (i) {
        final val = floatList[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            val.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        );
      }),
    );
  }
}
