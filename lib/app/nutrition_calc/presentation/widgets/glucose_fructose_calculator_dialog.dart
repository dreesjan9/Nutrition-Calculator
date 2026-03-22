import 'package:flutter/material.dart';
import 'package:nutrition_calculator_app/core/presentation/theme/theme.dart';

class GlucoseFructoseCalculatorDialog extends StatefulWidget {
  final bool isGerman;

  const GlucoseFructoseCalculatorDialog({super.key, required this.isGerman});

  @override
  State<GlucoseFructoseCalculatorDialog> createState() =>
      _GlucoseFructoseCalculatorDialogState();
}

class _GlucoseFructoseCalculatorDialogState
    extends State<GlucoseFructoseCalculatorDialog> {
  final TextEditingController _glucoseController = TextEditingController();
  final TextEditingController _fructoseController = TextEditingController();

  double _glucose = 0;
  double _fructose = 0;

  void _calculate() {
    setState(() {
      _glucose = double.tryParse(_glucoseController.text.replaceAll(',', '.')) ?? 0;
      _fructose = double.tryParse(_fructoseController.text.replaceAll(',', '.')) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _glucose + _fructose;
    
    // We want to show it as 2:1 or 1:0.8 etc.
    // Standard format is Glucose:Fructose where Glucose is often normalized to 1 or 2.
    // More common in sports science is Glucose:Fructose ratio like 1:0.8 or 2:1.
    
    String ratioText = '-';
    if (_glucose > 0 && _fructose > 0) {
      if (_glucose >= _fructose) {
        ratioText = '1 : ${( _fructose / _glucose).toStringAsFixed(2)}';
      } else {
        ratioText = '${(_glucose / _fructose).toStringAsFixed(2)} : 1';
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.isGerman
                            ? 'Glukose-Fruktose Rechner'
                            : 'Glucose-Fructose Calculator',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(
                      controller: _glucoseController,
                      label: widget.isGerman ? 'Glukose (g)' : 'Glucose (g)',
                      hint: 'z.B. 60',
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _fructoseController,
                      label: widget.isGerman ? 'Fruktose (g)' : 'Fructose (g)',
                      hint: 'z.B. 30',
                    ),
                    const SizedBox(height: 24),
                    
                    // Results
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: blackyellowTheme.colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          _buildResultRow(
                            widget.isGerman ? 'Gesamtmenge' : 'Total Amount',
                            '${total.toStringAsFixed(1)} g',
                            isTotal: true,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Colors.white10),
                          ),
                          _buildResultRow(
                            widget.isGerman ? 'Verhältnis (G:F)' : 'Ratio (G:F)',
                            ratioText,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Info text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.blue[300]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.isGerman
                                  ? 'Ein Verhältnis von 1:0.8 (Glukose zu Fruktose) gilt aktuell als optimal für hohe Kohlenhydrataufnahmen (>90g/h).'
                                  : 'A ratio of 1:0.8 (Glucose to Fructose) is currently considered optimal for high carbohydrate intake (>90g/h).',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _calculate(),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: blackyellowTheme.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 15,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? blackyellowTheme.colorScheme.primary : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
