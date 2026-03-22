import 'package:flutter/material.dart';
import 'package:nutrition_calculator_app/core/presentation/theme/theme.dart';

class SweatRateCalculatorDialog extends StatefulWidget {
  final bool isGerman;

  const SweatRateCalculatorDialog({
    super.key,
    required this.isGerman,
  });

  @override
  State<SweatRateCalculatorDialog> createState() => _SweatRateCalculatorDialogState();
}

class _SweatRateCalculatorDialogState extends State<SweatRateCalculatorDialog> {
  final _weightBeforeController = TextEditingController();
  final _weightAfterController = TextEditingController();
  final _durationController = TextEditingController();
  final _fluidConsumedController = TextEditingController();

  double? _calculatedRate;

  @override
  void dispose() {
    _weightBeforeController.dispose();
    _weightAfterController.dispose();
    _durationController.dispose();
    _fluidConsumedController.dispose();
    super.dispose();
  }

  void _calculate() {
    final weightBefore = double.tryParse(_weightBeforeController.text.replaceAll(',', '.')) ?? 0.0;
    final weightAfter = double.tryParse(_weightAfterController.text.replaceAll(',', '.')) ?? 0.0;
    final durationMins = double.tryParse(_durationController.text.replaceAll(',', '.')) ?? 0.0;
    final fluidMl = double.tryParse(_fluidConsumedController.text.replaceAll(',', '.')) ?? 0.0;

    if (weightBefore > 0 && durationMins > 0) {
      // Loss in kg (approx L) = weightBefore - weightAfter
      // Plus fluid consumed in L
      final totalLossLiters = (weightBefore - weightAfter) + (fluidMl / 1000.0);
      final rateLitersPerHour = totalLossLiters / (durationMins / 60.0);
      
      setState(() {
        _calculatedRate = rateLitersPerHour * 1000.0; // Convert to ml/h
      });
    }
  }

  InputDecoration _inputDecoration(String label, String suffix) {
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      suffixStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: blackyellowTheme.colorScheme.primary)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.isGerman ? 'Schweißraten-Rechner' : 'Sweat Rate Calculator',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _weightBeforeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(widget.isGerman ? 'Gewicht vorher' : 'Weight before', 'kg'),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightAfterController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(widget.isGerman ? 'Gewicht nachher' : 'Weight after', 'kg'),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _durationController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(widget.isGerman ? 'Dauer' : 'Duration', 'min'),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fluidConsumedController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(widget.isGerman ? 'Getrunken' : 'Fluid consumed', 'ml'),
              onChanged: (_) => _calculate(),
            ),
            if (_calculatedRate != null && _calculatedRate! > 0) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: blackyellowTheme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: blackyellowTheme.colorScheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.isGerman ? 'Berechnete Rate:' : 'Calculated Rate:',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_calculatedRate!.toStringAsFixed(0)} ml/h',
                      style: TextStyle(
                        color: blackyellowTheme.colorScheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            widget.isGerman ? 'Abbrechen' : 'Cancel',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: _calculatedRate != null && _calculatedRate! > 0
              ? () => Navigator.pop(context, _calculatedRate)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: blackyellowTheme.colorScheme.primary,
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.white10,
          ),
          child: Text(widget.isGerman ? 'Übernehmen' : 'Apply'),
        ),
      ],
    );
  }
}
