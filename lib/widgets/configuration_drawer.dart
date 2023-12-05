import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/custom_scheme.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/models/game_manager.dart';

class ConfigurationDrawer extends ConsumerStatefulWidget {
  const ConfigurationDrawer({super.key});

  @override
  ConsumerState<ConfigurationDrawer> createState() =>
      _ConfigurationDrawerState();
}

class _ConfigurationDrawerState extends ConsumerState<ConfigurationDrawer> {
  @override
  void initState() {
    super.initState();

    ConfigurationManager.instance.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    ConfigurationManager.instance.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cm = ConfigurationManager.instance;
    final gm = ref.watch(gameManagerProvider);
    final scheme = ref.watch(schemeProvider);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: scheme.mainColor,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Text('Configuration de\nTrain de mots',
                  style: TextStyle(color: scheme.textColor, fontSize: 24)),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    ListTile(
                      title: const Text('Configuration du thème'),
                      onTap: () => _showThemeConfiguration(context),
                    ),
                    ListTile(
                      title: const Text('Configuration du jeu'),
                      onTap: () {
                        _showGameConfiguration(context);
                      },
                    ),
                  ],
                ),
                Column(
                  children: [
                    ListTile(
                      title: const Text('Terminer la rounde actuelle'),
                      enabled: gm.gameStatus == GameStatus.roundStarted,
                      onTap: () async {
                        await ref
                            .read(gameManagerProvider)
                            .requestTerminateRound();
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      tileColor: Colors.red,
                      title: const Text('Réinitialiser la configuration'),
                      enabled: cm.canChangeProblem,
                      onTap: () async {
                        final result = await showDialog<bool?>(
                            context: context,
                            builder: (context) => const _AreYouSureDialog());
                        if (result == null || !result) return;

                        cm.resetConfiguration();
                        ref.read(schemeProvider).reset();

                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showThemeConfiguration(context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return const _ThemeConfiguration();
    },
  );
}

class _ThemeConfiguration extends StatefulWidget {
  const _ThemeConfiguration();

  @override
  State<_ThemeConfiguration> createState() => _ThemeConfigurationState();
}

class _ThemeConfigurationState extends State<_ThemeConfiguration> {
  @override
  void initState() {
    super.initState();

    final cm = ConfigurationManager.instance;
    cm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final cm = ConfigurationManager.instance;
    cm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final cm = ConfigurationManager.instance;
        final scheme = ref.watch(schemeProvider);

        return AlertDialog(
          title: Text(
            'Configuration du thème',
            style: TextStyle(color: scheme.mainColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ColorPickerInputField(
                  label: 'Choisir la couleur du temps'),
              const SizedBox(height: 24),
              SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _FontSizePickerInputField(
                        label: 'Choisir la taille du thème'),
                    const SizedBox(height: 12),
                    _SliderInputField(
                      label: 'Volume de la musique',
                      value: cm.musicVolume,
                      onChanged: (value) {
                        cm.musicVolume = value;
                      },
                      thumbLabel: '${(cm.musicVolume * 100).toInt()}%',
                    ),
                    const SizedBox(height: 12),
                    _SliderInputField(
                      label: 'Volume des sons',
                      value: cm.soundVolume,
                      onChanged: (value) {
                        cm.soundVolume = value;
                      },
                      thumbLabel: '${(cm.soundVolume * 100).toInt()}%',
                    ),
                    const SizedBox(height: 12),
                    _BooleanInputField(
                        label: 'Afficher le tableau des cheminot\u2022e\u2022s',
                        value: cm.showLeaderBoard,
                        onChanged: (value) {
                          cm.showLeaderBoard = value;
                        }),
                    const SizedBox(height: 12),
                    _BooleanInputField(
                        label: 'Montrer les réponses au survol\nde la souris',
                        value: cm.showAnswersTooltip,
                        onChanged: (value) {
                          cm.showAnswersTooltip = value;
                        }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _ColorPickerInputField extends StatelessWidget {
  const _ColorPickerInputField({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final scheme = ref.watch(schemeProvider);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: scheme.mainColor)),
          ),
          ColorPicker(
            pickerColor: scheme.mainColor,
            onColorChanged: (Color color) {
              ref.read(schemeProvider).mainColor = color;
            },
          ),
        ],
      );
    });
  }
}

class _FontSizePickerInputField extends StatelessWidget {
  const _FontSizePickerInputField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final currentSize = ref.watch(schemeProvider).textSize;

      late String sizeCategory;
      if (currentSize < 18) {
        sizeCategory = 'Petit';
      } else if (currentSize < 28) {
        sizeCategory = 'Moyen';
      } else if (currentSize < 38) {
        sizeCategory = 'Grand';
      } else {
        sizeCategory = 'Très grand';
      }
      return _SliderInputField(
        label: label,
        value: currentSize,
        min: 12,
        max: 48,
        divisions: 36,
        thumbLabel: 'Taille du thème: $sizeCategory',
        onChanged: (value) => ref.read(schemeProvider).textSize = value,
      );
    });
  }
}

void _showGameConfiguration(BuildContext context) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Consumer(
        builder: (context, ref, child) {
          final cm = ConfigurationManager.instance;
          final scheme = ref.watch(schemeProvider);

          return WillPopScope(
            onWillPop: () async {
              cm.finalizeConfigurationChanges();
              return true;
            },
            child: AlertDialog(
              title: Text(
                'Configuration du jeu',
                style: TextStyle(color: scheme.mainColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IntegerInputField(
                      label: 'Nombre de lettres des mots les plus courts',
                      initialValue: cm.nbLetterInSmallestWord.toString(),
                      onChanged: (value) {
                        cm.nbLetterInSmallestWord = value;
                      },
                      enabled: cm.canChangeProblem,
                      disabledTooltip:
                          'Le nombre de lettres des mots les plus courts ne peut pas\n'
                          'être changé en cours de partie ou lorsque le jeu cherche un mot',
                    ),
                    const SizedBox(height: 12),
                    _DoubleIntegerInputField(
                      label: 'Nombre de lettres à piger',
                      firstLabel: 'Minimum',
                      firstInitialValue: cm.minimumWordLetter.toString(),
                      secondLabel: 'Maximum',
                      secondInitialValue: cm.toString(),
                      onChanged: (mininum, maximum) {
                        cm.minimumWordLetter = mininum;
                        cm.maximumWordLetter = maximum;
                      },
                      enabled: cm.canChangeProblem,
                      disabledTooltip:
                          'Le nombre de lettres à piger ne peut pas\n'
                          'être changé en cours de partie ou lorsque le jeu cherche un mot',
                    ),
                    const SizedBox(height: 12),
                    _DoubleIntegerInputField(
                      label: 'Nombre de mots à trouver',
                      firstLabel: 'Minimum',
                      firstInitialValue: cm.minimumWordsNumber.toString(),
                      secondLabel: 'Maximum',
                      secondInitialValue: cm.maximumWordsNumber.toString(),
                      onChanged: (mininum, maximum) {
                        cm.minimumWordsNumber = mininum;
                        cm.maximumWordsNumber = maximum;
                      },
                      enabled: cm.canChangeProblem,
                      disabledTooltip:
                          'Le nombre de mots à trouver ne peut pas\n'
                          'être changé en cours de partie ou lorsque le jeu cherche un mot',
                    ),
                    const SizedBox(height: 12),
                    _IntegerInputField(
                      label: 'Durée d\'une manche (secondes)',
                      initialValue: cm.roundDuration.inSeconds.toString(),
                      onChanged: (value) {
                        cm.roundDuration = Duration(seconds: value);
                      },
                      enabled: cm.canChangeDurations,
                      disabledTooltip:
                          'La durée d\'une manche ne peut pas être changée en cours de partie',
                    ),
                    const SizedBox(height: 12),
                    _IntegerInputField(
                      label: 'Temps avant de mélanger les lettres (secondes)',
                      initialValue:
                          cm.timeBeforeScramblingLetters.inSeconds.toString(),
                      onChanged: (value) {
                        cm.timeBeforeScramblingLetters =
                            Duration(seconds: value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _BooleanInputField(
                      label: 'Voler un mot est permis',
                      value: cm.canSteal,
                      onChanged: (value) {
                        cm.canSteal = value;
                      },
                    ),
                    const SizedBox(height: 12),
                    _DoubleIntegerInputField(
                      label: 'Période de récupération (secondes)',
                      firstLabel: 'Normale',
                      firstInitialValue: cm.cooldownPeriod.inSeconds.toString(),
                      secondLabel: 'Voleur',
                      secondInitialValue:
                          cm.cooldownPeriodAfterSteal.inSeconds.toString(),
                      enableSecond: cm.canSteal,
                      onChanged: (normal, stealer) {
                        cm.cooldownPeriod = Duration(seconds: normal);
                        cm.cooldownPeriodAfterSteal =
                            Duration(seconds: stealer);
                      },
                      enabled: cm.canChangeDurations,
                      disabledTooltip:
                          'Les périodes de récupération ne peuvent pas être\n'
                          'changées en cours de partie',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.mainColor,
                          foregroundColor: scheme.textColor),
                      child: const Text('Terminer'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _IntegerInputField extends StatelessWidget {
  const _IntegerInputField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.enabled = true,
    this.disabledTooltip,
  });

  final String label;
  final String initialValue;
  final Function(int) onChanged;
  final bool enabled;
  final String? disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer(builder: (context, ref, child) {
          final scheme = ref.watch(schemeProvider);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: scheme.mainColor)),
          );
        }),
        SizedBox(
          width: 150,
          child: TextFormField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            initialValue: initialValue,
            enabled: enabled,
            onChanged: (String value) {
              final newValue = int.tryParse(value);
              if (newValue != null) onChanged(newValue);
            },
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      ],
    );
    return disabledTooltip == null || enabled
        ? child
        : Tooltip(
            message: disabledTooltip!,
            child: child,
          );
  }
}

class _DoubleIntegerInputField extends StatefulWidget {
  const _DoubleIntegerInputField({
    required this.label,
    required this.firstLabel,
    required this.firstInitialValue,
    this.enableSecond = true,
    required this.secondLabel,
    required this.secondInitialValue,
    required this.onChanged,
    this.enabled = true,
    this.disabledTooltip,
  });

  final String label;
  final String firstLabel;
  final String firstInitialValue;
  final bool enableSecond;
  final String secondLabel;
  final String secondInitialValue;
  final Function(int minimum, int maximum) onChanged;
  final bool enabled;
  final String? disabledTooltip;

  @override
  State<_DoubleIntegerInputField> createState() =>
      _DoubleIntegerInputFieldState();
}

class _DoubleIntegerInputFieldState extends State<_DoubleIntegerInputField> {
  late int _first = int.parse(widget.firstInitialValue);
  late int _second = int.parse(widget.secondInitialValue);

  void _callOnChanged() => widget.onChanged(_first, _second);

  @override
  Widget build(BuildContext context) {
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer(builder: (context, ref, child) {
          final scheme = ref.watch(schemeProvider);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(widget.label,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: scheme.mainColor)),
          );
        }),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 150,
              child: TextFormField(
                keyboardType: TextInputType.number,
                initialValue: widget.firstInitialValue,
                decoration: InputDecoration(
                  labelText: widget.firstLabel,
                  border: const OutlineInputBorder(),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  final first = int.tryParse(value);
                  if (first == null) return;
                  _first = first;
                  _callOnChanged();
                },
                enabled: widget.enabled,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 150,
              child: TextFormField(
                keyboardType: TextInputType.number,
                initialValue: widget.secondInitialValue,
                decoration: InputDecoration(
                  labelText: widget.secondLabel,
                  border: const OutlineInputBorder(),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  final second = int.tryParse(value);
                  if (second == null) return;
                  _second = second;
                  _callOnChanged();
                },
                enabled: widget.enabled && widget.enableSecond,
              ),
            ),
          ],
        ),
      ],
    );
    return widget.disabledTooltip == null || widget.enabled
        ? child
        : Tooltip(
            message: widget.disabledTooltip!,
            child: child,
          );
  }
}

class _BooleanInputField extends StatelessWidget {
  const _BooleanInputField(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final scheme = ref.watch(schemeProvider);

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onChanged(!value),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: scheme.mainColor)),
              Checkbox(
                value: value,
                onChanged: (_) => onChanged(!value),
                fillColor: MaterialStateProperty.resolveWith((state) {
                  if (state.contains(MaterialState.selected)) {
                    return scheme.mainColor;
                  }
                  return Colors.white;
                }),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _SliderInputField extends StatelessWidget {
  const _SliderInputField({
    required this.label,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions = 100,
    required this.thumbLabel,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String thumbLabel;
  final Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final scheme = ref.watch(schemeProvider);

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.mainColor,
              ),
            ),
            Slider(
              value: value,
              onChanged: onChanged,
              min: min,
              max: max,
              divisions: divisions,
              label: thumbLabel,
              activeColor: scheme.mainColor,
              inactiveColor: Colors.grey,
            ),
          ],
        ),
      );
    });
  }
}

class _AreYouSureDialog extends StatelessWidget {
  const _AreYouSureDialog();

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final scheme = ref.watch(schemeProvider);

      return AlertDialog(
        title: Text('Réinitialiser la configuration',
            style: TextStyle(color: scheme.mainColor)),
        content: Text(
            'Êtes-vous sûr de vouloir réinitialiser la configuration?',
            style: TextStyle(color: scheme.mainColor)),
        actions: [
          TextButton(
            child: Text('Annuler', style: TextStyle(color: scheme.mainColor)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: scheme.mainColor,
                foregroundColor: scheme.textColor),
            child: const Text('Réinitialiser'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );
    });
  }
}
