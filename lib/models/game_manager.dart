import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/custom_callback.dart';
import 'package:train_de_mots/models/game_configuration.dart';
import 'package:train_de_mots/models/player.dart';
import 'package:train_de_mots/models/solution.dart';
import 'package:train_de_mots/models/twitch_interface.dart';
import 'package:train_de_mots/models/word_problem.dart';

enum GameStatus {
  initializing,
  roundPreparing,
  roundReady,
  roundStarted,
}

// Declare the GameManager provider
final gameManagerProvider = Provider<_GameManager>((ref) {
  return _GameManager.instance;
});

class _GameManager {
  /// ---------- ///
  /// GAME LOGIC ///
  /// ---------- ///

  final Players players = Players();

  GameStatus _gameStatus = GameStatus.initializing;
  GameStatus get gameStatus => _gameStatus;
  int? _roundDuration;
  int? get timeRemaining => _roundDuration == null
      ? null
      : (_roundDuration! -
              (DateTime.now().millisecondsSinceEpoch -
                  _roundStartedAt!.millisecondsSinceEpoch)) ~/
          1000;
  DateTime? _roundStartedAt;
  DateTime? _nextTickAt;
  int _roundCount = 0;
  int get roundCount => _roundCount;

  WordProblem? _currentProblem;
  WordProblem? _nextProblem;
  bool _isSearchingNextProblem = false;
  WordProblem? get problem => _currentProblem;

  bool _forceEndTheRound = false;

  /// ----------- ///
  /// CONSTRUCTOR ///
  /// ----------- ///

  ///
  /// Initialize the game logic. This should be called at the start of the
  /// application.
  Future<void> initialize() async {
    Timer.periodic(const Duration(milliseconds: 100), _gameLoop);
    await _initializeWordProblem();
  }

  Future<void> _initializeWordProblem() async {
    final configuration = ProviderContainer().read(gameConfigurationProvider);

    await WordProblem.initialize(
        nbLetterInSmallestWord: configuration.nbLetterInSmallestWord);
    _isSearchingNextProblem = false;
    _nextProblem = null;
    await _searchForNextProblem();
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
  final onSolutionFound = CustomCallback<Function(Solution)>();
  final onSolutionWasStolen = CustomCallback<Function(Solution)>();
  final onPlayerUpdate = CustomCallback<VoidCallback>();

  /// -------- ///
  /// INTERNAL ///
  /// -------- ///

  ///
  /// Declare the singleton
  static _GameManager get instance => _instance;
  static final _GameManager _instance = _GameManager._internal();
  _GameManager._internal();

  ///
  /// This is a method to tell the game manager that the rules have changed and
  /// some things may need to be updated
  /// [shoulRepickProblem] is used to tell the game manager that the problem
  /// picker rules have changed and that it should repick a problem.
  /// [repickNow] is used to tell the game manager that it should repick a
  /// problem now or wait a future call. That is to wait until all the changes
  /// to the rules are made before repicking a problem.
  void rulesHasChanged({
    bool shoulRepickProblem = false,
    bool repickNow = false,
  }) {
    if (shoulRepickProblem) _forceRepickProblem = true;
    if (repickNow && shoulRepickProblem) _initializeWordProblem();
  }

  ///
  /// As soon as anything changes, we need to notify the listeners of players.
  /// Otherwise, the UI would be spammed with updates.
  bool _forceRepickProblem = false;
  bool _hasAPlayerBeenUpdate = false;

  Future<void> _searchForNextProblem() async {
    if (_isSearchingNextProblem) return;
    if (_nextProblem != null && !_forceRepickProblem) return;

    _forceRepickProblem = false;
    _isSearchingNextProblem = true;

    final configuration = ProviderContainer().read(gameConfigurationProvider);
    _nextProblem = await configuration.problemGenerator(
      nbLetterInSmallestWord: configuration.nbLetterInSmallestWord,
      minLetters: configuration.minimumWordLetter,
      maxLetters: configuration.maximumWordLetter,
      minimumNbOfWords: configuration.minimumWordsNumber,
      maximumNbOfWords: configuration.maximumWordsNumber,
    );
    _nextProblem!.cooldownScrambleTimer =
        configuration.timeBeforeScramblingLetters.inSeconds;

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
    onRoundIsPreparing.notifyListeners();

    // Wait until a problem is found
    while (_isSearchingNextProblem) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (_currentProblem != null && !_currentProblem!.isSuccess) _restartGame();

    _currentProblem = _nextProblem;
    _nextProblem = null;

    // Reinitialize the round timer and players
    _roundDuration = ProviderContainer()
        .read(gameConfigurationProvider)
        .roundDuration
        .inMilliseconds;
    for (final player in players) {
      player.resetForNextRound();
    }

    // Start searching for the next problem as soon as possible to avoid
    // waiting for the next round
    _searchForNextProblem();

    // Start the round
    _gameStatus = GameStatus.roundStarted;
    _roundStartedAt = DateTime.now();
    _nextTickAt = _roundStartedAt!.add(const Duration(seconds: 1));
    onRoundStarted.notifyListeners();
  }

  ///
  /// Initialize the callbacks from Twitch chat to [_trySolution]
  Future<void> _initializeTrySolutionCallback() async =>
      TwitchInterface.instance
          .addChatListener((sender, message) => _trySolution(sender, message));

  ///
  /// Try to solve the problem from a [message] sent by a [sender], that is a
  /// Twitch chatter.
  Future<void> _trySolution(String sender, String message) async {
    if (problem == null || timeRemaining == null) return;
    final configuration = ProviderContainer().read(gameConfigurationProvider);

    // Get the player from the players list
    final player = players.firstWhereOrAdd(sender);

    // If the player is in cooldown, they are not allowed to answer
    if (player.isInCooldownPeriod) return;

    // Find if the proposed word is valid
    final solution = problem!.trySolution(message,
        nbLetterInSmallestWord: configuration.nbLetterInSmallestWord);
    if (solution == null) return;

    // Add to player score
    Duration cooldownTimer = configuration.cooldownPeriod;
    if (solution.isFound) {
      // If the solution was already found, the player can steal it. It however
      // provides half the score and doubles the cooldown period.

      // The player cannot steal
      // if the game is not configured to allow it
      // or if the word was already stolen once
      // or the player is trying to steal from themselves
      // or the player has already stolen once during this round
      // or was stolen in less than the cooldown of the previous founder
      if (!configuration.canSteal ||
          solution.wasStolen ||
          solution.foundBy == player ||
          player.isAStealer ||
          DateTime.now().isBefore(solution.foundAt.add(cooldownTimer))) {
        return;
      }

      // Remove the score to original founder and override the cooldown
      solution.foundBy.score -= solution.value;
      cooldownTimer = configuration.cooldownPeriodAfterSteal;
    }
    solution.foundBy = player;
    if (solution.wasStolen) {
      solution.foundBy.hasStolen();
      solution.stolenFrom.resetCooldown();
      onSolutionWasStolen.notifyListenersWithParameter(solution);
    }

    player.score += solution.value;
    player.startCooldown(duration: cooldownTimer);

    // Call the listeners of solution found
    onSolutionFound.notifyListenersWithParameter(solution);

    // Also plan for an call to the listeners of players on next game loop
    _hasAPlayerBeenUpdate = true;
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
    if (_gameStatus == GameStatus.initializing) return;
    if (_gameStatus == GameStatus.roundPreparing) {
      if (_nextProblem != null) {
        _gameStatus = GameStatus.roundReady;
        onNextProblemReady.notifyListeners();
      }
      return;
    }
    if (_gameStatus == GameStatus.roundReady) return;

    _gameTick();
    _checkEndOfRound();
  }

  ///
  /// Tick the game timer and the cooldown timer of players. Call the
  /// listeners if needed.
  void _gameTick() {
    if (_gameStatus != GameStatus.roundStarted || timeRemaining == null) return;

    // Wait for a full second to pass before ticking
    if (DateTime.now().isBefore(_nextTickAt!)) return;
    _nextTickAt = _nextTickAt!.add(const Duration(seconds: 1));

    final configuration = ProviderContainer().read(gameConfigurationProvider);

    // Manager players cooling down
    for (final player in players) {
      if (player.isInCooldownPeriod) _hasAPlayerBeenUpdate = true;
    }
    if (_hasAPlayerBeenUpdate) {
      onPlayerUpdate.notifyListeners();
      _hasAPlayerBeenUpdate = false;
    }

    // Manager letter swapping in the problem
    _currentProblem!.cooldownScrambleTimer -= 1;
    if (_currentProblem!.cooldownScrambleTimer <= 0) {
      _currentProblem!.cooldownScrambleTimer =
          configuration.timeBeforeScramblingLetters.inSeconds;
      _currentProblem!.scrambleLetters();
      onScrablingLetters.notifyListeners();
    }

    onTimerTicks.notifyListeners();
  }

  ///
  /// Clear the current round
  void _checkEndOfRound() {
    // Do not end the round if we are not playing
    if (_gameStatus != GameStatus.roundStarted) return;

    // End round
    // if the request was made
    // if the timer is over
    // if all the words have been found
    bool shouldEndTheRound = _forceEndTheRound ||
        timeRemaining! <= 0 ||
        _currentProblem!.isAllSolutionsFound;
    if (!shouldEndTheRound) return;

    _roundCount++;

    _forceEndTheRound = false;
    _roundDuration = null;
    _roundStartedAt = null;
    _gameStatus = GameStatus.roundPreparing;
    onRoundIsOver.notifyListeners();

    _searchForNextProblem();
  }
}
