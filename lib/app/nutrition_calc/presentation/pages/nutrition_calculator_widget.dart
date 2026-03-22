import 'package:flutter/material.dart';
import 'package:nutrition_calculator_app/app/nutrition_calc/presentation/widgets/single_sport_nutrition_calculator.dart';
import 'package:nutrition_calculator_app/app/nutrition_calc/presentation/widgets/triathlon_nutrition_calculator.dart';
import 'package:nutrition_calculator_app/app/nutrition_calc/presentation/widgets/sweat_rate_calculator_dialog.dart';
import 'package:nutrition_calculator_app/app/nutrition_calc/presentation/widgets/glucose_fructose_calculator_dialog.dart';
import 'package:nutrition_calculator_app/core/presentation/theme/theme.dart';
import 'package:nutrition_calculator_app/services/storage_service.dart';

enum CalculatorMode { triathlon, cycling, running }

extension on CalculatorMode {
  String get storageValue => name;
}

CalculatorMode _calculatorModeFromStorage(String? value) {
  return CalculatorMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => CalculatorMode.triathlon,
  );
}

class NutritionCalculator extends StatefulWidget {
  const NutritionCalculator({super.key});

  @override
  State<NutritionCalculator> createState() => _NutritionCalculatorState();
}

class _NutritionCalculatorState extends State<NutritionCalculator> {
  final GlobalKey<TriathlonNutritionCalculatorState> _triathlonCalculatorKey =
      GlobalKey<TriathlonNutritionCalculatorState>();
  final GlobalKey<SingleSportNutritionCalculatorState> _cyclingCalculatorKey =
      GlobalKey<SingleSportNutritionCalculatorState>();
  final GlobalKey<SingleSportNutritionCalculatorState> _runningCalculatorKey =
      GlobalKey<SingleSportNutritionCalculatorState>();

  List<Map<String, dynamic>> _savedConfigurations = [];
  bool _isLoadingConfigurations = true;
  bool _isInEditor = false;
  bool isGerman = false;
  CalculatorMode _selectedMode = CalculatorMode.triathlon;
  String? _currentConfigurationName;
  int _selectedIndex = 0;

  Widget _buildModeIcon(CalculatorMode mode, {double size = 18}) {
    final color = blackyellowTheme.colorScheme.primary;

    switch (mode) {
      case CalculatorMode.triathlon:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pool, size: size, color: color),
            SizedBox(width: size * 0.22),
            Icon(Icons.directions_bike, size: size, color: color),
            SizedBox(width: size * 0.22),
            Icon(Icons.directions_run, size: size, color: color),
          ],
        );
      case CalculatorMode.cycling:
        return Icon(Icons.directions_bike, size: size, color: color);
      case CalculatorMode.running:
        return Icon(Icons.directions_run, size: size, color: color);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedConfigurations();
  }

  Future<void> _loadSavedConfigurations() async {
    final configurations = await StorageService.loadSavedConfigurations();
    if (!mounted) {
      return;
    }

    setState(() {
      _savedConfigurations = configurations;
      _isLoadingConfigurations = false;
    });
  }

  Future<void> _createNewConfiguration() async {
    final mode = await _showModePicker();
    if (mode == null || !mounted) {
      return;
    }

    setState(() {
      _selectedMode = mode;
      _currentConfigurationName = null;
      _isInEditor = true;
    });
  }

  Future<CalculatorMode?> _showModePicker() {
    return showModalBottomSheet<CalculatorMode>(
      context: context,
      backgroundColor: blackyellowTheme.colorScheme.secondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGerman ? 'Sport wählen' : 'Choose sport',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isGerman
                      ? 'Wähle zuerst den Sportmodus für den neuen Plan.'
                      : 'Pick the sport mode for the new plan first.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                ...CalculatorMode.values.map((mode) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor: Colors.black.withOpacity(0.22),
                      leading: SizedBox(
                        width: mode == CalculatorMode.triathlon ? 72 : 24,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildModeIcon(mode),
                        ),
                      ),
                      title: Text(
                        _modeLabel(mode),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _modeSubtitle(mode),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(mode),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openConfiguration(Map<String, dynamic> configuration) {
    final mode = _calculatorModeFromStorage(configuration['mode']?.toString());
    final data = configuration['data'];

    setState(() {
      _selectedMode = mode;
      _currentConfigurationName = configuration['name']?.toString();
      _isInEditor = true;
    });

    if (mode == CalculatorMode.triathlon && data is Map) {
      final mappedData = data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triathlonCalculatorKey.currentState?.importConfiguration(mappedData);
      });
    } else if (mode == CalculatorMode.cycling && data is Map) {
      final mappedData = data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cyclingCalculatorKey.currentState?.importConfiguration(mappedData);
      });
    } else if (mode == CalculatorMode.running && data is Map) {
      final mappedData = data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runningCalculatorKey.currentState?.importConfiguration(mappedData);
      });
    }
  }

  Future<void> _deleteConfiguration(Map<String, dynamic> configuration) async {
    final id = configuration['id']?.toString();
    if (id == null || id.isEmpty) {
      return;
    }

    final name =
        configuration['name']?.toString() ??
        (isGerman ? 'diesen Plan' : 'this plan');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: blackyellowTheme.colorScheme.secondary,
          title: Text(
            isGerman ? 'Plan löschen?' : 'Delete plan?',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            isGerman
                ? 'Möchtest du "$name" wirklich löschen?'
                : 'Do you really want to delete "$name"?',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                isGerman ? 'Abbrechen' : 'Cancel',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: blackyellowTheme.colorScheme.primary,
                foregroundColor: Colors.black,
              ),
              child: Text(isGerman ? 'Löschen' : 'Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await StorageService.deleteConfiguration(id);
    await _loadSavedConfigurations();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isGerman ? 'Plan gelöscht' : 'Plan deleted')),
    );
  }

  Future<void> _handleAutoSavedConfiguration(
    Map<String, dynamic> configurationData,
  ) async {
    final entry = <String, dynamic>{
      'id':
          configurationData['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      'name': configurationData['name']?.toString(),
      'mode': _selectedMode.storageValue,
      'updatedAt': DateTime.now().toIso8601String(),
      'data': configurationData,
    };

    await StorageService.saveConfiguration(entry);

    if (!mounted) {
      return;
    }

    setState(() {
      _currentConfigurationName = entry['name']?.toString();
      _savedConfigurations.removeWhere((item) => item['id'] == entry['id']);
      _savedConfigurations.insert(0, entry);
      _isLoadingConfigurations = false;
    });
  }

  String _modeLabel(CalculatorMode mode) {
    switch (mode) {
      case CalculatorMode.triathlon:
        return 'Triathlon';
      case CalculatorMode.cycling:
        return isGerman ? 'Radsport' : 'Cycling';
      case CalculatorMode.running:
        return isGerman ? 'Laufen' : 'Running';
    }
  }

  String _modeSubtitle(CalculatorMode mode) {
    switch (mode) {
      case CalculatorMode.triathlon:
        return isGerman
            ? 'Multi-Segment-Plan mit Pre-Race, Bike und Run'
            : 'Multi-segment plan with pre-race, bike and run';
      case CalculatorMode.cycling:
        return isGerman
            ? 'Single-Sport-Modus für Rennrad, Gravel und Indoor'
            : 'Single-sport mode for road, gravel and indoor rides';
      case CalculatorMode.running:
        return isGerman
            ? 'Single-Sport-Modus für Long Runs und Wettkämpfe'
            : 'Single-sport mode for long runs and races';
    }
  }

  String _formatSavedAt(Map<String, dynamic> configuration) {
    final value = configuration['updatedAt']?.toString();
    if (value == null) {
      return '';
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  Widget _buildModeChip(CalculatorMode mode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: blackyellowTheme.colorScheme.primary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeIcon(
            mode,
            size: mode == CalculatorMode.triathlon ? 13 : 14,
          ),
          const SizedBox(width: 6),
          Text(
            _modeLabel(mode),
            style: TextStyle(
              color: blackyellowTheme.colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedConfigurationList() {
    if (_isLoadingConfigurations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_savedConfigurations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            isGerman
                ? 'Noch keine Einträge gespeichert.'
                : 'No saved plans yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _savedConfigurations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final configuration = _savedConfigurations[index];
        final mode = _calculatorModeFromStorage(
          configuration['mode']?.toString(),
        );
        final name =
            configuration['name']?.toString() ??
            (isGerman ? 'Unbenannter Plan' : 'Untitled plan');

        return Container(
          decoration: appPanelDecoration(),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
            title: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModeChip(mode),
                  const SizedBox(height: 8),
                  Text(
                    _formatSavedAt(configuration),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            onTap: () => _openConfiguration(configuration),
            trailing: IconButton(
              onPressed: () => _deleteConfiguration(configuration),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.white70,
                size: 22,
              ),
              tooltip: isGerman ? 'Plan löschen' : 'Delete plan',
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: appPanelDecoration(highlighted: true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'RATIO',
                          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ADVANCED SPORTS NUTRITION PLANNING',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isGerman
                        ? 'Wähle einen vorhandenen Eintrag oder starte einen neuen Plan. Die Sportart wird erst beim Erstellen gewählt.'
                        : 'Choose an existing entry or start a new plan. The sport is selected when creating a new one.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createNewConfiguration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: blackyellowTheme.colorScheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isGerman ? 'NEUER PLAN' : 'NEW PLAN',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isGerman ? 'Meine Pläne' : 'My plans',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSavedConfigurationList(),
            const SizedBox(height: 20),
            GlucoseFructoseCalculatorWidget(isGerman: isGerman),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorContent() {
    switch (_selectedMode) {
      case CalculatorMode.triathlon:
        return TriathlonNutritionCalculator(
          key: _triathlonCalculatorKey,
          isGerman: isGerman,
          restoreLastConfiguration: false,
          onConfigurationChanged: (configuration) {
            _handleAutoSavedConfiguration(configuration);
          },
        );
      case CalculatorMode.cycling:
        return SingleSportNutritionCalculator(
          key: _cyclingCalculatorKey,
          isGerman: isGerman,
          sportName: isGerman ? 'Radsport' : 'Cycling',
          sportIcon: Icons.directions_bike,
          defaultCarbsPerHour: '80',
          defaultSodiumPerHour: '750',
          defaultFluidPerHour: '700',
          onConfigurationChanged: _handleAutoSavedConfiguration,
        );
      case CalculatorMode.running:
        return SingleSportNutritionCalculator(
          key: _runningCalculatorKey,
          isGerman: isGerman,
          sportName: isGerman ? 'Laufen' : 'Running',
          sportIcon: Icons.directions_run,
          defaultCarbsPerHour: '60',
          defaultSodiumPerHour: '600',
          defaultFluidPerHour: '500',
          onConfigurationChanged: _handleAutoSavedConfiguration,
        );
    }
  }

  Widget _buildEditorScreen() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: appPanelDecoration(highlighted: true),
          child: Row(
            children: [
              _buildModeChip(_selectedMode),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currentConfigurationName ??
                      (isGerman
                          ? 'Neuer ${_modeLabel(_selectedMode)}-Plan'
                          : 'New ${_modeLabel(_selectedMode)} plan'),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildEditorContent(),
      ],
    );
  }

  Widget _buildKnowledgeScreen() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              isGerman ? 'Wissensdatenbank' : 'Knowledge Base',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isGerman
                  ? 'Erfahre mehr über Sporternährung und optimiere deine Performance.'
                  : 'Learn more about sports nutrition and optimize your performance.',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildKnowledgeTile(
              title: isGerman ? 'Schweißraten-Rechner' : 'Sweat Rate Calculator',
              description: isGerman
                  ? 'Berechne deinen individuellen Flüssigkeitsverlust pro Stunde.'
                  : 'Calculate your individual fluid loss per hour.',
              icon: Icons.calculate_outlined,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) =>
                      SweatRateCalculatorDialog(isGerman: isGerman),
                );
              },
            ),
            _buildKnowledgeTile(
              title: isGerman ? 'Glukose & Fruktose' : 'Glucose & Fructose',
              description: isGerman
                  ? 'Das optimale Verhältnis für maximale Energieaufnahme.'
                  : 'The optimal ratio for maximum energy absorption.',
              icon: Icons.science,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) =>
                      GlucoseFructoseCalculatorDialog(isGerman: isGerman),
                );
              },
            ),
            _buildKnowledgeTile(
              title: isGerman ? 'Natrium & Hydrierung' : 'Sodium & Hydration',
              description: isGerman
                  ? 'Verhindere Krämpfe und Leistungsabfall durch Elektrolyte.'
                  : 'Prevent cramps and performance drops with electrolytes.',
              icon: Icons.water_drop,
            ),
            _buildKnowledgeTile(
              title: isGerman ? 'Carb Loading' : 'Carb Loading',
              description: isGerman
                  ? 'Wie du deine Glykogenspeicher vor dem Wettkampf füllst.'
                  : 'How to fill your glycogen stores before the race.',
              icon: Icons.restaurant,
            ),
            _buildKnowledgeTile(
              title: isGerman ? 'Recovery' : 'Recovery',
              description: isGerman
                  ? 'Die ersten 30 Minuten nach der Belastung sind entscheidend.'
                  : 'The first 30 minutes after exercise are crucial.',
              icon: Icons.flash_on,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKnowledgeTile(
      {required String title,
      required String description,
      required IconData icon,
      VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: appPanelDecoration(),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: blackyellowTheme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: blackyellowTheme.colorScheme.primary),
        ),
        title: Text(
          title,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white30),
        onTap: onTap ?? () {
          // Future: Open article
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: blackyellowTheme.colorScheme.secondary,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        toolbarHeight: 60,
        elevation: 0,
        leading: _isInEditor
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _isInEditor = false;
                    _currentConfigurationName = null;
                  });
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: isGerman ? 'Zur Startseite' : 'Back to home',
              )
            : null,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Image.asset(
                'assets/images/logo.png',
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: blackyellowTheme.colorScheme.primary,
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.black,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white12),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isGerman = !isGerman;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: blackyellowTheme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isGerman ? '🇩🇪' : '🇺🇸',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isGerman ? 'DE' : 'EN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isInEditor
          ? _buildEditorScreen()
          : (_selectedIndex == 0
              ? _buildStartScreen()
              : _buildKnowledgeScreen()),
      bottomNavigationBar: _isInEditor
          ? null
          : Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white12, width: 1)),
              ),
              child: SizedBox(
                height: 80, // Increased height
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  backgroundColor: const Color(0xFF1A1A1A),
                  selectedItemColor: blackyellowTheme.colorScheme.primary,
                  unselectedItemColor: Colors.white,
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  iconSize: 28,
                  selectedIconTheme: IconThemeData(
                    color: blackyellowTheme.colorScheme.primary,
                    size: 28,
                    opacity: 1.0,
                  ),
                  unselectedIconTheme: IconThemeData(
                    color: Colors.white.withOpacity(0.6),
                    size: 28,
                    opacity: 0.6,
                  ),
                  selectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13), // Slightly larger font
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  type: BottomNavigationBarType.fixed,
                  items: [
                    BottomNavigationBarItem(
                      icon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.dashboard_outlined),
                      ),
                      activeIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.dashboard),
                      ),
                      label: isGerman ? 'Dashboard' : 'Dashboard',
                    ),
                    BottomNavigationBarItem(
                      icon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.menu_book_outlined),
                      ),
                      activeIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.menu_book),
                      ),
                      label: isGerman ? 'Wissen' : 'Knowledge',
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
