import 'package:flutter/material.dart';
import 'package:train_de_mots/models/color_scheme.dart';
import 'package:train_de_mots/models/game_manager.dart';
import 'package:train_de_mots/models/solution.dart';
import 'package:train_de_mots/widgets/fireworks.dart';

class SolutionsDisplayer extends StatefulWidget {
  const SolutionsDisplayer({super.key});

  @override
  State<SolutionsDisplayer> createState() => _SolutionsDisplayerState();
}

class _SolutionsDisplayerState extends State<SolutionsDisplayer> {
  final _fireworksControllers = <Solution, FireworksController>{};

  @override
  void initState() {
    super.initState();

    GameManager.instance.onRoundStarted.addListener(_reinitializeFireworks);
    GameManager.instance.onSolutionFound.addListener(_onSolutionFound);
    _reinitializeFireworks();
  }

  void _reinitializeFireworks() {
    _fireworksControllers.clear();
    final solutions = GameManager.instance.problem!.solutions;
    for (final solution in solutions) {
      _fireworksControllers[solution] = FireworksController(
          huge: solution.word.length == solutions.nbLettersInLongest);
    }

    setState(() {});
  }

  void _onSolutionFound(solution) {
    _fireworksControllers[solution]?.trigger();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = CustomColorScheme.instance;
    final solutions = GameManager.instance.problem!.solutions;

    List<Solutions> solutionsByLength = [];
    for (var i = solutions.nbLettersInSmallest;
        i <= solutions.nbLettersInLongest;
        i++) {
      solutionsByLength.add(solutions.solutionsOfLength(i));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var solutions in solutionsByLength)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Mots de ${solutions.first.word.length} lettres',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scheme.textColor,
                        fontSize: scheme.textSize),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(builder: (context, constraint) {
                    return SizedBox(
                      height: constraint.maxHeight,
                      child: Stack(
                        children: [
                          _SolutionWrapper(solutions: solutions),
                          _FireworksWrapper(
                              solutions: solutions,
                              fireworksControllers: _fireworksControllers),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SolutionWrapper extends StatefulWidget {
  const _SolutionWrapper({required this.solutions});

  final Solutions solutions;

  @override
  State<_SolutionWrapper> createState() => _SolutionWrapperState();
}

class _SolutionWrapperState extends State<_SolutionWrapper> {
  @override
  void initState() {
    super.initState();
    GameManager.instance.onSolutionFound.addListener(_onSolutionFound);
  }

  void _onSolutionFound(_) => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.vertical,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...widget.solutions
            .map((e) => _SolutionTile(key: ValueKey(e), solution: e))
      ],
    );
  }
}

class _FireworksWrapper extends StatelessWidget {
  const _FireworksWrapper(
      {required this.solutions, required this.fireworksControllers});

  final Solutions solutions;
  final Map<Solution, FireworksController> fireworksControllers;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.vertical,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...solutions.map((solution) {
          final controller = fireworksControllers[solution]!;
          return _SolutionTile(solution: solution, fireworks: controller);
        })
      ],
    );
  }
}

class _SolutionTile extends StatelessWidget {
  const _SolutionTile({super.key, required this.solution, this.fireworks});

  final Solution solution;
  final FireworksController? fireworks;

  @override
  Widget build(BuildContext context) {
    // Create a letter that ressemble those on a Scrabble board
    final scheme = CustomColorScheme.instance;

    late final Widget? child;
    if (fireworks != null) {
      child = Fireworks(key: fireworks!.key, controller: fireworks!);
    } else {
      final unsolved = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          scheme.solutionUnsolvedColorLight!,
          scheme.solutionUnsolvedColorDark!,
        ],
        stops: const [0, 0.6],
      );
      final solved = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          scheme.solutionSolvedColorLight!,
          scheme.solutionSolvedColorDark!,
        ],
        stops: const [0.1, 1],
      );
      final stolen = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          scheme.solutionStolenColorLight!,
          scheme.solutionStolenColorDark!,
        ],
        stops: const [0.1, 1],
      );

      child = Container(
        decoration: BoxDecoration(
          gradient: solution.isFound
              ? (solution.wasStolen ? stolen : solved)
              : unsolved,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 3.0,
              spreadRadius: 0.0,
              offset: const Offset(5.0, 5.0),
            )
          ],
        ),
        child: solution.isFound
            ? Center(
                child: Text(
                  '${solution.word} (${solution.foundBy!.name})',
                  style: TextStyle(
                      fontSize: 24,
                      color: solution.isFound
                          ? scheme.textSolvedColor
                          : scheme.textUnsolvedColor),
                ),
              )
            : null,
      );
    }

    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: SizedBox(
          width: 300,
          height: 50,
          child: Tooltip(
            message: solution.isFound ? '' : solution.word,
            verticalOffset: -5,
            textStyle: const TextStyle(fontSize: 24, color: Colors.white),
            child: child,
          ),
        ));
  }
}
