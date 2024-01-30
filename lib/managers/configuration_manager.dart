import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/mocks_configuration.dart';
import 'package:train_de_mots/models/custom_callback.dart';
import 'package:train_de_mots/models/difficulty.dart';
import 'package:train_de_mots/models/exceptions.dart';
import 'package:train_de_mots/models/letter_problem.dart';
import 'package:train_de_mots/models/release_notes.dart';

const String _lastReleaseNotesShownDefault = '';

const _autoplayDefault = true;
const _shouldShowAutoplayDialogDefault = false;
const _autoplayDurationDefault = 25;

const _showAnswersTooltipDefault = false;
const _showLeaderBoardDefault = false;

const _roundDurationDefault = 120;
const _postRoundGracePeriodDurationDefault = 6;
const _postRoundShowCaseDurationDefault = 10;
const _cooldownPeriodDefault = 12;
const _cooldownPenaltyAfterStealDefault = 5;
const _timeBeforeScramblingLettersDefault = 15;

const _nbLetterInSmallestWordDefault = 4;
const _minimumWordLetterDefault = 6;
const _maximumWordLetterDefault = 10;
const _minimumWordsNumberDefault = 20;
const _maximumWordsNumberDefault = 40;

const _canStealDefault = true;

const _musicVolumeDefault = 0.3;
const _soundVolumeDefault = 1.0;

class ConfigurationManager {
  final List<ReleaseNotes> releaseNotes = const [
    ReleaseNotes(
      version: '0.1.0',
      codeName: 'Petit train va loin',
      notes: 'Le jeu est maintenant fonctionnel! On peut jouer en équipe sur '
          'Twitch pour faire avancer le petit Train du Nord',
    ),
    ReleaseNotes(version: '0.2.0', codeName: 'Travail d\'équipe', features: [
      FeatureNotes(
        description: 'Il est maintenant possible d\'enregistrer les scores '
            'des équipes pour les comparer au monde entier! Qui sera la '
            'meilleure équipe de cheminot\u2022e\u2022s?',
      ),
      FeatureNotes(
        description:
            'Travail sur la rapidité de l\'algorithme de génération des '
            'problèmes, ce qui permet d\'avoir des mots plus longs',
      ),
      FeatureNotes(
        description: 'Ajusté la difficulté des niveaux en ajoutant les '
            'lettres inutiles et cachées',
        userWhoRequested: 'Helene_Ducrocq',
        urlOfUserWhoRequested: 'https://twitch.tv/helene_ducrocq',
      ),
    ]),
    ReleaseNotes(
        version: '0.2.1',
        codeName: 'Ouverture sur le monde',
        notes: 'Le petit Train du Nord a pris les rails du monde entier! Et '
            'avec cela vient de nouvelles fonctionnalités!',
        features: [
          FeatureNotes(
            description:
                'Un mode autonome a été ajouté pour permettre au jeu de se '
                'lancer par lui-même',
            userWhoRequested: 'NghtmrTV',
            urlOfUserWhoRequested: 'https://twitch.tv/nghtmrtv',
          ),
          FeatureNotes(
            description: 'Il est maintenant possible de voler des mots à ses '
                'cocheminot\u2022e\u2022s plus d\'une fois par ronde',
            userWhoRequested: 'NghtmrTV',
            urlOfUserWhoRequested: 'https://twitch.tv/nghtmrtv',
          ),
          FeatureNotes(
            description:
                'Les réponses sont maintenant affichées quelques secondes à la '
                'fin de la ronde',
            userWhoRequested: 'NghtmrTV',
            urlOfUserWhoRequested: 'https://twitch.tv/nghtmrtv',
          ),
          FeatureNotes(
            description:
                'Ajouté une boite d\'affichage pour les notes de versions, que '
                'vous êtes en train de lire!',
            userWhoRequested: 'NghtmrTV',
            urlOfUserWhoRequested: 'https://twitch.tv/nghtmrtv',
          ),
        ]),
  ];

  bool get useDebugOptions => MocksConfiguration.showDebugOptions;

  ///
  /// Declare the singleton
  static ConfigurationManager get instance {
    if (_instance == null) {
      throw ManagerNotInitializedException(
          'ConfigurationManager must be initialized before being used');
    }
    return _instance!;
  }

  static ConfigurationManager? _instance;
  ConfigurationManager._internal();

  static Future<void> initialize() async {
    if (_instance != null) {
      throw ManagerAlreadyInitializedException(
          'ConfigurationManager should not be initialized twice');
    }
    _instance = ConfigurationManager._internal();

    instance._loadConfiguration();
    // We must wait for the GameManager to be initialized before listening to
    Future.delayed(Duration.zero, () => instance._listenToGameManagerEvents());
  }

  ///
  /// Connect to callbacks to get notified when the configuration changes
  final onChanged = CustomCallback();
  final onMusicChanged = CustomCallback();
  final onSoundChanged = CustomCallback();

  ///
  /// The current algorithm used to generate the problems
  final Future<LetterProblem> Function({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
  }) _problemGenerator = ProblemGenerator.generateFromRandom;
  Future<LetterProblem> Function({
    required int nbLetterInSmallestWord,
    required int minLetters,
    required int maxLetters,
    required int minimumNbOfWords,
    required int maximumNbOfWords,
    required bool addUselessLetter,
  }) get problemGenerator => _problemGenerator;

  String _lastReleaseNotesShown = _lastReleaseNotesShownDefault;
  String get lastReleaseNotesShown => _lastReleaseNotesShown;
  set lastReleaseNotesShown(String value) {
    _lastReleaseNotesShown = value;
    _saveConfiguration();
  }

  bool _autoplay = _autoplayDefault;
  bool get autoplay => _autoplay;
  set autoplay(bool value) {
    _autoplay = value;
    _saveConfiguration();
  }

  bool _shouldShowAutoplayDialog = _shouldShowAutoplayDialogDefault;
  bool get shouldShowAutoplayDialog => _shouldShowAutoplayDialog;
  set shouldShowAutoplayDialog(bool value) {
    _shouldShowAutoplayDialog = value;
    _saveConfiguration();
  }

  Duration _autoplayDuration =
      const Duration(seconds: _autoplayDurationDefault);
  Duration get autoplayDuration => _autoplayDuration;
  set autoplayDuration(Duration value) {
    _autoplayDuration = value;
    _saveConfiguration();
  }

  bool _showAnswersTooltip = _showAnswersTooltipDefault;
  bool get showAnswersTooltip => _showAnswersTooltip;
  set showAnswersTooltip(bool value) {
    _showAnswersTooltip = value;
    _saveConfiguration();
  }

  bool _showLeaderBoard = _showLeaderBoardDefault;
  bool get showLeaderBoard => _showLeaderBoard;
  set showLeaderBoard(bool value) {
    _showLeaderBoard = value;
    _saveConfiguration();
  }

  Duration _roundDuration = const Duration(seconds: _roundDurationDefault);
  Duration get roundDuration => _roundDuration;
  set roundDuration(Duration value) {
    _roundDuration = value;
    _saveConfiguration();
  }

  Duration _postRoundGracePeriodDuration =
      const Duration(seconds: _postRoundGracePeriodDurationDefault);
  Duration get postRoundGracePeriodDuration => _postRoundGracePeriodDuration;
  set postRoundGracePeriodDuration(Duration value) {
    _postRoundGracePeriodDuration = value;
    _saveConfiguration();
  }

  Duration _postRoundShowCaseDuration =
      const Duration(seconds: _postRoundShowCaseDurationDefault);
  Duration get postRoundShowCaseDuration => _postRoundShowCaseDuration;
  set postRoundShowCaseDuration(Duration value) {
    _postRoundShowCaseDuration = value;
    _saveConfiguration();
  }

  Duration _cooldownPeriod = const Duration(seconds: _cooldownPeriodDefault);
  Duration get cooldownPeriod => _cooldownPeriod;
  set cooldownPeriod(Duration value) {
    _cooldownPeriod = value;
    _saveConfiguration();
  }

  Duration _cooldownPenaltyAfterSteal =
      const Duration(seconds: _cooldownPenaltyAfterStealDefault);
  Duration get cooldownPenaltyAfterSteal => _cooldownPenaltyAfterSteal;
  set cooldownPenaltyAfterSteal(Duration value) {
    _cooldownPenaltyAfterSteal = value;
    _saveConfiguration();
  }

  Duration _timeBeforeScramblingLetters =
      const Duration(seconds: _timeBeforeScramblingLettersDefault);
  Duration get timeBeforeScramblingLetters => _timeBeforeScramblingLetters;
  set timeBeforeScramblingLetters(Duration value) {
    _timeBeforeScramblingLetters = value;
    _saveConfiguration();
  }

  int _nbLetterInSmallestWord = _nbLetterInSmallestWordDefault;
  int get nbLetterInSmallestWord => _nbLetterInSmallestWord;
  set nbLetterInSmallestWord(int value) {
    if (_nbLetterInSmallestWord == value) return;
    _nbLetterInSmallestWord = value;

    _saveConfiguration();
  }

  int _minimumWordLetter = _minimumWordLetterDefault;
  int get minimumWordLetter => _minimumWordLetter;
  set minimumWordLetter(int value) {
    if (_minimumWordLetter == value) return;
    if (value > maximumWordLetter) return;
    _minimumWordLetter = value;

    _tellGameManagerToRepickProblem();
    _saveConfiguration();
  }

  int _maximumWordLetter = _maximumWordLetterDefault;
  int get maximumWordLetter => _maximumWordLetter;
  set maximumWordLetter(int value) {
    if (_maximumWordLetter == value) return;
    if (value < minimumWordLetter) return;
    _maximumWordLetter = value;

    _tellGameManagerToRepickProblem();
    _saveConfiguration();
  }

  int _minimumWordsNumber = _minimumWordsNumberDefault;
  int get minimumWordsNumber => _minimumWordsNumber;
  set minimumWordsNumber(int value) {
    if (_minimumWordsNumber == value) return;
    if (value > maximumWordsNumber) return;
    _minimumWordsNumber = value;

    _tellGameManagerToRepickProblem();
    _saveConfiguration();
  }

  int _maximumWordsNumber = _maximumWordsNumberDefault;
  int get maximumWordsNumber => _maximumWordsNumber;
  set maximumWordsNumber(int value) {
    if (_maximumWordsNumber == value) return;
    if (value < minimumWordsNumber) return;
    _maximumWordsNumber = value;

    _tellGameManagerToRepickProblem();
    _saveConfiguration();
  }

  bool _canSteal = _canStealDefault;
  bool get canSteal => _canSteal;
  set canSteal(bool value) {
    _canSteal = value;
    _saveConfiguration();
  }

  double _musicVolume = _musicVolumeDefault;
  double get musicVolume => _musicVolume;
  set musicVolume(double value) {
    _musicVolume = value;
    onMusicChanged.notifyListeners();
    _saveConfiguration();
  }

  double _soundVolume = _soundVolumeDefault;
  double get soundVolume => _soundVolume;
  set soundVolume(double value) {
    _soundVolume = value;
    onSoundChanged.notifyListeners();
    _saveConfiguration();
  }

  //// LISTEN TO GAME MANAGER ////
  void _listenToGameManagerEvents() {
    final gm = GameManager.instance;
    gm.onRoundIsPreparing.addListener(_reactToGameManagerEvent);
    gm.onNextProblemReady.addListener(_reactToGameManagerEvent);
    gm.onRoundStarted.addListener(_reactToGameManagerEvent);
    gm.onRoundIsOver.addListener(_reactToGameManagerEvent);
  }

  void _reactToGameManagerEvent() => onChanged.notifyListeners();

  //// LOAD AND SAVE ////

  ///
  /// Serialize the configuration to a map
  Map<String, dynamic> serialize() {
    return {
      'lastReleaseNotesShown': lastReleaseNotesShown,
      'autoplay': autoplay,
      'shouldShowAutoplayDialog': shouldShowAutoplayDialog,
      'autoplayDuration': autoplayDuration.inSeconds,
      'showLeaderBoard': showLeaderBoard,
      'roundDuration': roundDuration.inSeconds,
      'postRoundGracePeriodDuration': postRoundGracePeriodDuration.inSeconds,
      'postRoundShowCaseDuration': postRoundShowCaseDuration.inSeconds,
      'cooldownPeriod': cooldownPeriod.inSeconds,
      'cooldownPenaltyAfterSteal': cooldownPenaltyAfterSteal.inSeconds,
      'timeBeforeScramblingLetters': timeBeforeScramblingLetters.inSeconds,
      'nbLetterInSmallestWord': nbLetterInSmallestWord,
      'minimumWordLetter': minimumWordLetter,
      'maximumWordLetter': maximumWordLetter,
      'minimumWordsNumber': minimumWordsNumber,
      'maximumWordsNumber': maximumWordsNumber,
      'canSteal': canSteal,
      'musicVolume': musicVolume,
      'soundVolume': soundVolume,
    };
  }

  ///
  /// Save the configuration to the device
  void _saveConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('gameConfiguration', jsonEncode(serialize()));
    onChanged.notifyListeners();
  }

  ///
  /// Load the configuration from the device
  void _loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('gameConfiguration');
    if (data != null) {
      final map = jsonDecode(data);

      _lastReleaseNotesShown =
          map['lastReleaseNotesShown'] ?? _lastReleaseNotesShownDefault;

      _autoplay = map['autoplay'] ?? _autoplayDefault;
      _shouldShowAutoplayDialog =
          map['shouldShowAutoplayDialog'] ?? _shouldShowAutoplayDialogDefault;
      _autoplayDuration = Duration(
          seconds: map['autoplayDuration'] ?? _autoplayDurationDefault);

      _showAnswersTooltip = false;
      _showLeaderBoard = map['showLeaderBoard'] ?? _showLeaderBoardDefault;

      _roundDuration =
          Duration(seconds: map['roundDuration'] ?? _roundDurationDefault);
      _postRoundGracePeriodDuration = Duration(
          seconds: map['postRoundGracePeriodDuration'] ??
              _postRoundGracePeriodDurationDefault);
      _postRoundShowCaseDuration = Duration(
          seconds: map['postRoundShowCaseDuration'] ??
              _postRoundShowCaseDurationDefault);
      _cooldownPeriod =
          Duration(seconds: map['cooldownPeriod'] ?? _cooldownPeriodDefault);
      _cooldownPenaltyAfterSteal = Duration(
          seconds: map['cooldownPenaltyAfterSteal'] ??
              _cooldownPenaltyAfterStealDefault);
      _timeBeforeScramblingLetters = Duration(
          seconds: map['timeBeforeScramblingLetters'] ??
              _timeBeforeScramblingLettersDefault);

      _nbLetterInSmallestWord =
          map['nbLetterInSmallestWord'] ?? _nbLetterInSmallestWordDefault;
      _minimumWordLetter =
          map['minimumWordLetter'] ?? _minimumWordLetterDefault;
      _maximumWordLetter =
          map['maximumWordLetter'] ?? _maximumWordLetterDefault;
      _minimumWordsNumber =
          map['minimumWordsNumber'] ?? _minimumWordsNumberDefault;
      _maximumWordsNumber =
          map['maximumWordsNumber'] ?? _maximumWordsNumberDefault;

      _canSteal = map['canSteal'] ?? _canStealDefault;

      _musicVolume = map['musicVolume'] ?? _musicVolumeDefault;
      _soundVolume = map['soundVolume'] ?? _soundVolumeDefault;

      _tellGameManagerToRepickProblem();
    }
  }

  ///
  /// Reset the configuration to the default values
  void resetConfiguration() {
    _lastReleaseNotesShown = _lastReleaseNotesShownDefault;

    _autoplay = _autoplayDefault;
    _shouldShowAutoplayDialog = _shouldShowAutoplayDialogDefault;
    _autoplayDuration = const Duration(seconds: _autoplayDurationDefault);

    _showAnswersTooltip = _showAnswersTooltipDefault;
    _showLeaderBoard = _showLeaderBoardDefault;

    _roundDuration = const Duration(seconds: _roundDurationDefault);
    _postRoundGracePeriodDuration =
        const Duration(seconds: _postRoundGracePeriodDurationDefault);
    _postRoundShowCaseDuration =
        const Duration(seconds: _postRoundShowCaseDurationDefault);
    _cooldownPeriod = const Duration(seconds: _cooldownPeriodDefault);
    _cooldownPenaltyAfterSteal =
        const Duration(seconds: _cooldownPenaltyAfterStealDefault);
    _timeBeforeScramblingLetters =
        const Duration(seconds: _timeBeforeScramblingLettersDefault);

    _nbLetterInSmallestWord = _nbLetterInSmallestWordDefault;
    _minimumWordLetter = _minimumWordLetterDefault;
    _maximumWordLetter = _maximumWordLetterDefault;
    _minimumWordsNumber = _minimumWordsNumberDefault;
    _maximumWordsNumber = _maximumWordsNumberDefault;

    _canSteal = _canStealDefault;

    _musicVolume = _musicVolumeDefault;
    _soundVolume = _soundVolumeDefault;

    _tellGameManagerToRepickProblem();
    _saveConfiguration();
  }

  ///
  /// Get the difficulty for a given level
  Difficulty difficulty(int level) {
    if (level < 3) {
      // Levels 1, 2 and 3
      return const Difficulty(
        thresholdFactorOneStar: 0.35,
        thresholdFactorTwoStars: 0.5,
        thresholdFactorThreeStars: 0.75,
        hasUselessLetter: false,
        hasHiddenLetter: false,
      );
    } else if (level < 6) {
      // Levels 4, 5 and 6
      return const Difficulty(
        thresholdFactorOneStar: 0.5,
        thresholdFactorTwoStars: 0.75,
        thresholdFactorThreeStars: 0.85,
        hasUselessLetter: false,
        hasHiddenLetter: false,
      );
    } else if (level < 9) {
      // Levels 7, 8 and 9
      return const Difficulty(
        thresholdFactorOneStar: 0.5,
        thresholdFactorTwoStars: 0.75,
        thresholdFactorThreeStars: 0.85,
        hasUselessLetter: true,
        revealUselessLetterAtTimeLeft: 30,
        hasHiddenLetter: false,
      );
    } else if (level < 12) {
      // Levels 10, 11 and 12
      return const Difficulty(
        thresholdFactorOneStar: 0.5,
        thresholdFactorTwoStars: 0.75,
        thresholdFactorThreeStars: 0.85,
        hasUselessLetter: true,
        revealUselessLetterAtTimeLeft: 30,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: 30,
      );
    } else if (level < 15) {
      // Levels 13, 14 and 15
      return const Difficulty(
        thresholdFactorOneStar: 0.65,
        thresholdFactorTwoStars: 0.85,
        thresholdFactorThreeStars: 0.9,
        hasUselessLetter: true,
        revealUselessLetterAtTimeLeft: 15,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: 30,
      );
    } else if (level < 18) {
      // Levels 16, 17 and 18
      return const Difficulty(
        thresholdFactorOneStar: 0.7,
        thresholdFactorTwoStars: 0.9,
        thresholdFactorThreeStars: 0.95,
        hasUselessLetter: true,
        revealUselessLetterAtTimeLeft: -1,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: 15,
      );
    } else {
      // Levels 19 and above
      return const Difficulty(
        thresholdFactorOneStar: 0.75,
        thresholdFactorTwoStars: 0.95,
        thresholdFactorThreeStars: 1.0,
        hasUselessLetter: true,
        hasHiddenLetter: true,
        revealHiddenLetterAtTimeLeft: -1,
      );
    }
  }

  //// MODIFYING THE CONFIGURATION ////

  ///
  /// If it is currently possible to change the duration of the round
  bool get canChangeDurations =>
      GameManager.instance.gameStatus != GameStatus.roundStarted;

  ///
  /// If it is currently possible to change the problem picker rules
  bool get canChangeProblem =>
      GameManager.instance.gameStatus == GameStatus.initializing ||
      GameManager.instance.gameStatus == GameStatus.roundReady;

  void _tellGameManagerToRepickProblem() =>
      GameManager.instance.rulesHasChanged(shouldRepickProblem: true);

  void finalizeConfigurationChanges() {
    GameManager.instance.rulesHasChanged(repickNow: true);
  }
}
