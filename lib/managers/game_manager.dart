import 'dart:async';

import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/configuration_manager.dart';
import 'package:train_de_mots/managers/database_manager.dart';
import 'package:train_de_mots/managers/twitch_manager.dart';
import 'package:train_de_mots/models/custom_callback.dart';
import 'package:train_de_mots/models/exceptions.dart';
import 'package:train_de_mots/models/player.dart';
import 'package:train_de_mots/models/word_solution.dart';
import 'package:train_de_mots/models/success_level.dart';
import 'package:train_de_mots/models/letter_problem.dart';

enum GameStatus {
  initializing,
  roundPreparing,
  roundReady,
  roundStarted,
}

class GameManager {
  /// ---------- ///
  /// GAME LOGIC ///
  /// ---------- ///

  final Players players = Players();

  GameStatus _gameStatus = GameStatus.initializing;
  GameStatus get gameStatus => _gameStatus;
  int? _roundDuration;
  int? get timeRemaining => _roundDuration == null || _roundStartedSince == null
      ? null
      : ((_roundDuration! ~/ 1000 - _roundStartedSince!)) -
          ConfigurationManager.instance.postRoundDuration.inSeconds;
  int? get _roundStartedSince => _roundStartedAt == null
      ? null
      : (DateTime.now().millisecondsSinceEpoch -
              _roundStartedAt!.millisecondsSinceEpoch) ~/
          1000;
  DateTime? _roundStartedAt;
  DateTime? _nextTickAt;
  int _roundCount = 0;
  int get roundCount => _roundCount;

  int _scramblingLetterTimer = 0;

  LetterProblem? _currentProblem;
  LetterProblem? _nextProblem;
  bool _isSearchingNextProblem = false;
  LetterProblem? get problem => _currentProblem;
  SuccessLevel? _successLevel;

  bool _forceEndTheRound = false;

  /// ----------- ///
  /// CONSTRUCTOR ///
  /// ----------- ///

  ///
  /// Initialize the game logic. This should be called at the start of the
  /// application.
  static Future<void> initialize() async {
    if (_instance != null) {
      throw ManagerAlreadyInitializedException(
          'GameManager should not be initialized twice');
    }
    GameManager._instance = GameManager._internal();

    Timer.periodic(const Duration(milliseconds: 100), instance._gameLoop);
    instance._initializeWordProblem();
  }

  Future<void> _initializeWordProblem() async {
    final cm = ConfigurationManager.instance;

    await LetterProblem.initialize(
        nbLetterInSmallestWord: cm.nbLetterInSmallestWord);
    _isSearchingNextProblem = false;
    _nextProblem = null;
    await _searchForNextProblem();

    // Make sure the game don't run if the player is not logged in
    final dm = DatabaseManager.instance;
    dm.onLoggedOut.addListener(() => requestTerminateRound());
    dm.onFullyLoggedIn.addListener(() {
      if (gameStatus != GameStatus.initializing) _startNewRound();
    });
  }

  /// ----------- ///
  /// INTERACTION ///
  /// ----------- ///

  ///
  /// Provide a way to request the start of a new round, if the game is not
  /// already started or if the game is not already over.
  Future<void> requestStartNewRound() async => await _startNewRound();

  ///
  /// Provide a way to request the premature end of the round
  Future<void> requestTerminateRound() async {
    if (_gameStatus != GameStatus.roundStarted) return;
    _forceEndTheRound = true;
  }

  SuccessLevel get successLevel => _successLevel ?? SuccessLevel.failed;

  bool get hasUselessLetter =>
      ConfigurationManager.instance.difficulty(_roundCount).hasUselessLetter;

  bool get hasHiddenLetter =>
      ConfigurationManager.instance.difficulty(_roundCount).hasHiddenLetter &&
      !_isHiddenLetterRevealed;
  bool _isHiddenLetterRevealed = false;
  int get hiddenLetterIndex => _currentProblem?.hiddenLettersIndex ?? -1;

  /// --------- ///
  /// CALLBACKS ///
  /// When registering to a callback, one should remind themselves to
  /// unregister when the widget is disposed, otherwise it will leak memory.
  /// --------- ///

  /// Callbacks for that tells listeners that the round is preparing
  final onGameIsInitializing = CustomCallback<VoidCallback>();
  final onRoundIsPreparing = CustomCallback<VoidCallback>();
  final onNextProblemReady = CustomCallback<VoidCallback>();
  final onRoundStarted = CustomCallback<VoidCallback>();
  final onRoundIsOver = CustomCallback<VoidCallback>();
  final onTimerTicks = CustomCallback<VoidCallback>();
  final onScrablingLetters = CustomCallback<VoidCallback>();
  final onRevealHiddenLetter = CustomCallback<VoidCallback>();
  final onSolutionFound = CustomCallback<Function(WordSolution)>();
  final onSolutionWasStolen = CustomCallback<Function(WordSolution)>();
  final onPlayerUpdate = CustomCallback<VoidCallback>();

  /// -------- ///
  /// INTERNAL ///
  /// -------- ///

  ///
  /// Declare the singleton
  static GameManager get instance {
    if (_instance == null) {
      throw ManagerNotInitializedException(
          'GameManager must be initialized before being used');
    }
    return _instance!;
  }

  static GameManager? _instance;
  GameManager._internal();

  ///
  /// This is a method to tell the game manager that the rules have changed and
  /// some things may need to be updated
  /// [shouldRepickProblem] is used to tell the game manager that the problem
  /// picker rules have changed and that it should repick a problem.
  /// [repickNow] is used to tell the game manager that it should repick a
  /// problem now or wait a future call. That is to wait until all the changes
  /// to the rules are made before repicking a problem.
  void rulesHasChanged({
    bool shouldRepickProblem = false,
    bool repickNow = false,
  }) {
    if (shouldRepickProblem) _forceRepickProblem = true;
    if (repickNow && shouldRepickProblem) _initializeWordProblem();
  }

  ///
  /// As soon as anything changes, we need to notify the listeners of players.
  /// Otherwise, the UI would be spammed with updates.
  bool _forceRepickProblem = false;
  bool _hasAPlayerBeenUpdate = false;
  // This helps calling [_hasAPlayerBeenUpdate] a single frame after a player is out of cooldown
  final Map<String, bool> _playersWasInCooldownLastFrame = {};

  Future<void> _searchForNextProblem() async {
    if (_isSearchingNextProblem) return;
    if (_nextProblem != null && !_forceRepickProblem) return;

    _forceRepickProblem = false;
    _isSearchingNextProblem = true;

    final cm = ConfigurationManager.instance;
    _nextProblem = await cm.problemGenerator(
      nbLetterInSmallestWord: cm.nbLetterInSmallestWord,
      minLetters: cm.minimumWordLetter,
      maxLetters: cm.maximumWordLetter,
      minimumNbOfWords: cm.minimumWordsNumber,
      maximumNbOfWords: cm.maximumWordsNumber,
      addUselessLetter: ConfigurationManager.instance
          .difficulty(_roundCount + SuccessLevel.threeStars.toInt())
          .hasUselessLetter,
    );

    _isSearchingNextProblem = false;
  }

  ///
  /// Prepare the game for a new round by making sure everything is initialized.
  /// Then, it finds a new word problem and start the timer.
  Future<void> _startNewRound() async {
    if (_gameStatus == GameStatus.initializing) {
      onGameIsInitializing.notifyListeners();
      _initializeTrySolutionCallback();
      _gameStatus = GameStatus.roundPreparing;
    }

    if (_gameStatus != GameStatus.roundPreparing &&
        _gameStatus != GameStatus.roundReady) {
      return;
    }

    final cm = ConfigurationManager.instance;
    onRoundIsPreparing.notifyListeners();

    // Wait until a problem is found
    while (_isSearchingNextProblem) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_currentProblem != null && _successLevel == SuccessLevel.failed) {
      _restartGame();
    }
    _currentProblem = _nextProblem;
    _nextProblem = null;

    // Prepare the problem according to the results of the current round
    if (!hasUselessLetter) _currentProblem!.tossUselessLetter();

    // Reinitialize the round timer and players
    _roundDuration =
        cm.roundDuration.inMilliseconds + cm.postRoundDuration.inMilliseconds;
    for (final player in players) {
      player.resetForNextRound();
    }

    // Start searching for the next problem as soon as possible to avoid
    // waiting for the next round
    _searchForNextProblem();

    // Start the round
    _gameStatus = GameStatus.roundStarted;
    _isHiddenLetterRevealed = false;
    _roundStartedAt = DateTime.now();
    _nextTickAt = _roundStartedAt!.add(const Duration(seconds: 1));
    _scramblingLetterTimer = cm.timeBeforeScramblingLetters.inSeconds;
    onRoundStarted.notifyListeners();
  }

  ///
  /// Initialize the callbacks from Twitch chat to [_trySolution]
  Future<void> _initializeTrySolutionCallback() async => TwitchManager.instance
      .addChatListener((sender, message) => _trySolution(sender, message));

  ///
  /// Try to solve the problem from a [message] sent by a [sender], that is a
  /// Twitch chatter.
  Future<void> _trySolution(String sender, String message) async {
    if (problem == null || timeRemaining == null) return;
    final cm = ConfigurationManager.instance;

    // Get the player from the players list
    final player = players.firstWhereOrAdd(sender);

    // If the player is in cooldown, they are not allowed to answer
    if (player.isInCooldownPeriod) return;

    // Find if the proposed word is valid
    final solution = problem!.trySolution(message,
        nbLetterInSmallestWord: cm.nbLetterInSmallestWord);
    if (solution == null) return;

    // Add to player score
    Duration cooldownTimer = cm.cooldownPeriod;
    if (solution.isFound) {
      // If the solution was already found, the player can steal it. It however
      // provides half the score and doubles the cooldown period.

      // The player cannot steal
      // if the game is not configured to allow it
      // or if the word was already stolen once
      // or the player is trying to steal from themselves
      // or the player has already stolen once during this round
      // or was stolen in less than the cooldown of the previous founder
      if (!cm.canSteal ||
          solution.wasStolen ||
          solution.foundBy == player ||
          player.isAStealer ||
          DateTime.now().isBefore(solution.foundAt.add(cooldownTimer))) {
        return;
      }

      // Remove the score to original founder and override the cooldown
      solution.foundBy.score -= solution.value;
      cooldownTimer = cm.cooldownPeriodAfterSteal;
    }
    solution.foundBy = player;
    player.lastSolutionFound = solution;
    if (solution.wasStolen) {
      solution.foundBy.hasStolen();

      solution.stolenFrom.lastSolutionFound = null;
      solution.stolenFrom.resetCooldown();

      onSolutionWasStolen.notifyListenersWithParameter(solution);
    }

    player.score += solution.value;
    player.startCooldown(duration: cooldownTimer);

    // Call the listeners of solution found
    onSolutionFound.notifyListenersWithParameter(solution);

    // Also plan for an call to the listeners of players on next game loop
    _hasAPlayerBeenUpdate = true;
    _playersWasInCooldownLastFrame[player.name] = true;
  }

  ///
  /// Restart the game by resetting the players and the round count
  void _restartGame() {
    _roundCount = 0;
    for (final player in players) {
      player.score = 0;
      player.resetForNextRound();
    }
  }

  ///
  /// Tick the game timer. If the timer is over, [_roundIsOver] is called.
  void _gameLoop(Timer timer) {
    if ((_gameStatus == GameStatus.initializing ||
            _gameStatus == GameStatus.roundPreparing) &&
        _nextProblem != null) {
      if (_gameStatus == GameStatus.roundPreparing) {
        _gameStatus = GameStatus.roundReady;
      }
      onNextProblemReady.notifyListeners();
      return;
    }
    if (_gameStatus == GameStatus.roundReady) return;

    _gameTick();
    _endOfRound();
  }

  ///
  /// Tick the game timer and the cooldown timer of players. Call the
  /// listeners if needed.
  void _gameTick() {
    if (_gameStatus != GameStatus.roundStarted || timeRemaining == null) return;

    // Wait for a full second to pass before ticking
    if (DateTime.now().isBefore(_nextTickAt!)) return;
    _nextTickAt = _nextTickAt!.add(const Duration(seconds: 1));

    final cm = ConfigurationManager.instance;

    // Manager players cooling down
    for (final player in players) {
      if (player.isInCooldownPeriod) {
        _hasAPlayerBeenUpdate = true;
      } else if (_playersWasInCooldownLastFrame[player.name] ?? false) {
        _playersWasInCooldownLastFrame[player.name] = false;
        _hasAPlayerBeenUpdate = true;
      }
    }
    if (_hasAPlayerBeenUpdate) {
      onPlayerUpdate.notifyListeners();
      _hasAPlayerBeenUpdate = false;
    }

    // Manager letter swapping in the problem
    _scramblingLetterTimer -= 1;
    if (_scramblingLetterTimer <= 0) {
      _scramblingLetterTimer = cm.timeBeforeScramblingLetters.inSeconds;
      _currentProblem!.scrambleLetters();
      onScrablingLetters.notifyListeners();
    }

    // Manage hidden letter
    if (!_isHiddenLetterRevealed &&
        ConfigurationManager.instance.difficulty(_roundCount).hasHiddenLetter &&
        timeRemaining! <=
            cm.difficulty(_roundCount).revealHiddenLetterAtTimeLeft) {
      _isHiddenLetterRevealed = true;
      onRevealHiddenLetter.notifyListeners();
    }

    onTimerTicks.notifyListeners();
  }

  ///
  /// Clear the current round
  Future<void> _endOfRound() async {
    // Do not end the round if we are not playing
    if (_gameStatus != GameStatus.roundStarted) return;

    // End round
    // if the request was made
    // if the timer is over
    // if all the words have been found
    bool shouldEndTheRound = _forceEndTheRound ||
        timeRemaining! <=
            -ConfigurationManager.instance.postRoundDuration.inSeconds ||
        _currentProblem!.areAllSolutionsFound;
    if (!shouldEndTheRound) return;

    _successLevel = completedLevel;
    _roundCount += _successLevel!.toInt();

    _forceEndTheRound = false;
    _roundDuration = null;
    _roundStartedAt = null;
    _gameStatus = GameStatus.roundPreparing;

    _searchForNextProblem();

    DatabaseManager.instance.registerTrainStationReached(roundCount);
    onRoundIsOver.notifyListeners();
  }

  SuccessLevel get completedLevel {
    if (problem!.currentScore < _pointsToObtain(SuccessLevel.oneStar)) {
      return SuccessLevel.failed;
    } else if (problem!.currentScore < _pointsToObtain(SuccessLevel.twoStars)) {
      return SuccessLevel.oneStar;
    } else if (problem!.currentScore <
        _pointsToObtain(SuccessLevel.threeStars)) {
      return SuccessLevel.twoStars;
    } else {
      return SuccessLevel.threeStars;
    }
  }

  int remainingPointsToNextLevel() {
    final currentLevel = completedLevel;
    if (currentLevel == SuccessLevel.threeStars) return 0;

    final nextLevel = SuccessLevel.values[currentLevel.index + 1];
    return _pointsToObtain(nextLevel) - problem!.currentScore;
  }

  int _pointsToObtain(SuccessLevel level) {
    final difficulty = ConfigurationManager.instance.difficulty(roundCount);

    final maxScore = problem!.maximumScore;
    switch (level) {
      case SuccessLevel.oneStar:
        return (maxScore * difficulty.thresholdFactorOneStar).toInt();
      case SuccessLevel.twoStars:
        return (maxScore * difficulty.thresholdFactorTwoStars).toInt();
      case SuccessLevel.threeStars:
        return (maxScore * difficulty.thresholdFactorThreeStars).toInt();
      case SuccessLevel.failed:
        throw Exception('Failed is not a valid level');
    }
  }
}

class GameManagerMock extends GameManager {
  LetterProblemMock? _problemMocker;

  static Future<void> initialize({
    GameStatus? gameStatus,
    LetterProblemMock? problem,
    List<Player>? players,
    int? roundCount,
    SuccessLevel? successLevel,
  }) async {
    if (GameManager._instance != null) {
      throw ManagerAlreadyInitializedException(
          'GameManager should not be initialized twice');
    }
    GameManager._instance = GameManagerMock._internal();

    if (gameStatus != null) GameManager._instance!._gameStatus = gameStatus;

    if (players != null) {
      for (final player in players) {
        GameManager._instance!.players.add(player);
      }
    }

    GameManager._instance!._gameStatus = GameStatus.initializing;
    if (roundCount != null) {
      GameManager._instance!._roundCount = roundCount;
      GameManager._instance!._gameStatus = GameStatus.roundReady;
    }
    if (successLevel != null) {
      GameManager._instance!._roundCount += successLevel.toInt();
      (GameManager._instance! as GameManagerMock)._successLevel = successLevel;
    }

    GameManager._instance!._initializeTrySolutionCallback();
    if (problem == null) {
      GameManager._instance!._searchForNextProblem();
    } else {
      (GameManager._instance! as GameManagerMock)._problemMocker = problem;
      GameManager._instance!._currentProblem = problem;
      GameManager._instance!._nextProblem = problem;
      GameManager._instance!._gameStatus = GameStatus.roundReady;

      Future.delayed(const Duration(seconds: 1)).then((value) =>
          GameManager._instance!.onNextProblemReady.notifyListeners());
    }

    Timer.periodic(
        const Duration(milliseconds: 100), GameManager._instance!._gameLoop);
  }

  @override
  Future<void> _searchForNextProblem() async {
    if (_problemMocker == null) {
      await super._searchForNextProblem();
    } else {
      _nextProblem = _problemMocker;

      // Make sure the game don't run if the player is not logged in
      final dm = DatabaseManager.instance;
      dm.onLoggedOut.addListener(() => requestTerminateRound());
      dm.onFullyLoggedIn.addListener(() {
        if (gameStatus != GameStatus.initializing) _startNewRound();
      });

      _isSearchingNextProblem = false;
    }
    GameManager._instance!.onGameIsInitializing.notifyListeners();
  }

  GameManagerMock._internal() : super._internal();
}
