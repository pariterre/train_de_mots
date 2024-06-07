class ReleaseNotes {
  final String version;
  final String? codeName;
  final String? notes;
  final List<FeatureNotes> features;

  const ReleaseNotes(
      {required this.version,
      this.codeName,
      this.notes,
      this.features = const []});
}

class FeatureNotes {
  final String description;
  final String? userWhoRequested;
  final String? urlOfUserWhoRequested;

  const FeatureNotes({
    required this.description,
    this.userWhoRequested,
    this.urlOfUserWhoRequested,
  });
}

const List<ReleaseNotes> releaseNotes = [
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
          'meilleure équipe de cheminot\u00b7e\u00b7s?',
    ),
    FeatureNotes(
      description: 'Travail sur la rapidité de l\'algorithme de génération des '
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
              'cocheminot\u00b7e\u00b7s plus d\'une fois par ronde',
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
  ReleaseNotes(
    version: '0.3.0',
    codeName: 'Connais-toi toi-même',
    notes: 'La connaissance de soi est d\'une importance capitale. C\'est '
        'une meilleure représentation de vous-mêmes vous est proposée',
    features: [
      FeatureNotes(
        description:
            'Le petit train avance maintenant visuellement sur la carte, '
            'ce qui permet de voir les stations futures',
      ),
      FeatureNotes(
        description: 'Le score du ou de la meilleur\u00b7e cheminot\u00b7e '
            'est maintenant affiché dans le tableau final. Qui sera le ou la '
            'meilleur\u00b7e?',
        userWhoRequested: 'Kyaroline',
        urlOfUserWhoRequested: 'https://twitch.tv/kyaroline',
      ),
    ],
  ),
  ReleaseNotes(
    version: '0.3.1',
    codeName: 'Tous pour un et un pour un',
    notes:
        'Oui, la citation est bien "un pour tous", mais maintenant que l\'unique score '
        'du ou de la meilleure cheminot\u00b7e de l\'équipe est enregistré au '
        'tableau d\'honneur, nous aurons probablement droits à des élans '
        'd\'individualisme! Mais qui saura résister à l\'appel de la gloire '
        'pour faire avancer le train?',
    features: [
      FeatureNotes(
          description:
              'Le score du ou de la meilleure cheminot\u00b7e de l\'équipe est '
              'enregistré au tableau d\'honneur'),
      FeatureNotes(
          description:
              'Quelques ajustements pour améliorer le visuel des bulles de '
              'notification'),
      FeatureNotes(
          description: 'Les feux d\'artifices ont maintenant leurs palettes de '
              'couleur individualisées'),
    ],
  ),
  ReleaseNotes(
    version: '0.3.2',
    codeName: 'Mes ami\u00b7e\u00b7s sont mes ennemi\u00b7e\u00b7s',
    notes:
        'Le Train de Mots est un jeu d\'équipe, jusqu\'à ce que ce ne le soit plus! '
        'Le jeu montre maintenant le joueur MVP de votre équipe de façon plus '
        'précise. Vous savez maintenant qui cibler pour devenir le ou la '
        'meilleur\u00b7e cheminot\u00b7e!',
    features: [
      FeatureNotes(
          description:
              'Le ou la joueuse MVP de votre équipe est maintenant affiché en or '
              'dans la page de fin de ronde. De plus, sa tuile est elle aussi '
              'affichée avec sa propre couleur lorsqu\'il ou elle trouve une solution'),
    ],
  ),
  ReleaseNotes(
    version: '0.3.3',
    codeName: 'Plus vites, plus fort, plus loin',
    notes: 'Bien que le Train de mots est un jeu d\'équipe, une petite équipe '
        'ne devrait pas être pénalisée! Tout le monde peut maintenant partir '
        'vers le Nord!',
    features: [
      FeatureNotes(
          description:
              'La période de repos après avoir trouvé un mot est maintenant '
              'ajustée en fonction du nombre de joueurs présents.'),
      FeatureNotes(
          description:
              'Le jeu est maintenant garanti de trouver un mot avant la fin de '
              'la ronde, pour plus de plaisir sans attendre!'),
    ],
  ),
  ReleaseNotes(
    version: '0.3.4',
    codeName: 'Je vAzalée encore plus loin',
    notes: 'Certain\u00b7e\u00b7s cheminot\u00b7e\u00b7s ont vu le Petit Train'
        'du Nord les priver de leurs prouesses. On aurait pu accepter cet état '
        'de fait... mais non! Et rendons à César ce qui est Azalee et réparons '
        'ce problème...',
    features: [
      FeatureNotes(
          description:
              'Réparation du bogue qui supprimait le score du ou de la meilleur\u00b7e '
              'cheminot\u00b7e de l\'équipe à la fin de la ronde si ce même joueur '
              'est le ou la MVP de la ronde courante',
          userWhoRequested: 'LaLoutreBurlesques',
          urlOfUserWhoRequested: 'https://twitch.tv/laloutreburlesques'),
    ],
  ),
  ReleaseNotes(
    version: '0.3.5',
    codeName: 'Le tintamare',
    notes: 'Petit update pour indiquer aux joueurs et joueuses que le train a '
        'reculé derrière la station!',
    features: [
      FeatureNotes(
          description:
              'L\'animation des explosions a été réécrites pour permettre de '
              'l\'inverser. Cette inversion est utilisée pour indiquer que le '
              'train a reculé derrière la station'),
    ],
  ),
  ReleaseNotes(
    version: '0.3.6',
    codeName: 'Scintillement',
    notes:
        'Un petit ajustement pour rendre le jeu plus agréable pour les yeux!',
    features: [
      FeatureNotes(
          description:
              'Les étoiles scintillent maintenant dans le ciel de nuit!'),
    ],
  ),
  ReleaseNotes(
    version: '0.4.0',
    codeName: 'Liberté',
    notes:
        'Certains ont demandé de pouvoir modifier les règles du jeu, et bien soit! Modifions!',
    features: [
      FeatureNotes(
          description:
              'Les options de débogue sont rendues disponible pour le bonheur et le plaisir de tous!',
          userWhoRequested: 'NghtmrTV',
          urlOfUserWhoRequested: 'https://twitch.tv/NghtmrTV'),
      FeatureNotes(
          description:
              'Il est également possible de ne pas avancer de plus d\'une station par ronde',
          userWhoRequested: 'NghtmrTV',
          urlOfUserWhoRequested: 'https://twitch.tv/NghtmrTV'),
    ],
  ),
  ReleaseNotes(
    version: '1.0.0',
    codeName: 'Un peu plus haut, un peu plus loin',
    notes:
        'Le Petit train du Nord se sent mature et désire est enfin considéré comme '
        'quelque chose comme un grand train!',
    features: [
      FeatureNotes(
        description:
            'Plusieurs options débogueurs sont maintenant incluses dans la '
            'progression de difficulté du jeu.',
      ),
    ],
  ),
  ReleaseNotes(
    version: '1.0.1',
    codeName: 'Pardonnez-nous nos offenses',
    notes: 'Il est naturel de faire des erreurs et de demander le pardon.'
        'Jusqu\'à maintenant le Petit Train du Nord était sans pitié... '
        'Cette époque est révolue! Il est maintenant possible de pardonner '
        'un vol, mais choississez bien, vous n\'avez pas beaucoup de pardons '
        'en banque!',
    features: [
      FeatureNotes(
        description:
            'Il est maintenant possible de pardonner avec la commande: !pardon. '
            'Un pardon redonne les points à l\'équipe mais laisse les points au voleur. '
            'Seul le ou la cheminot\u00b7e volé\u00b7e peut pardonner (sans récupérer ses points)',
      ),
      FeatureNotes(
          description:
              'Il est également possible de booster le train avec la commande !boost. '
              'Si trois cheminot·e·s demandent un boost, le train accélère. '
              'Les points réalisés dans les 30 secondes subséquentes '
              'sont alors comptés doubles'),
      FeatureNotes(
          description:
              'Il est maintenant possible de revoir les réponses après qu\'elles'
              'aient disparues',
          userWhoRequested: 'AlchimisteDesMots',
          urlOfUserWhoRequested: 'https://twitch.tv/alchimistedesmots'),
    ],
  ),
  ReleaseNotes(
    version: '1.0.2',
    codeName: 'Ne t\'arrête plus jamais!',
    notes: 'Un bogue aux stations 15 et plus a été réparés permettant au train '
        'de continuer la partie sans perdre la progression! '
        'Désolé aux cheminot·e·s qui ont été laissé·e·s sur le quai depuis deux semaines!',
    features: [
      FeatureNotes(
          description:
              'Réparation du bogue qui empêchait le train de continuer '
              'la partie après la station 15',
          userWhoRequested: 'AlchimisteDesMots',
          urlOfUserWhoRequested: 'https://twitch.tv/alchimistedesmots'),
    ],
  ),
  ReleaseNotes(
    version: '1.0.3',
    codeName: 'Ne t\'arrête plus jamais (prise 2)!',
    notes: 'Le même bogue réglé dans la version précédente s\'est faufilé dans '
        'et existait encore... Il a été réglé une fois pour toute (j\'espère..)!',
    features: [
      FeatureNotes(
          description:
              'Réparation du bogue qui empêchait le train de continuer '
              'la partie à la station 16, 19 ou 22 si un ensemble de lettres était trouvé '
              'pendant l\'affichage du télégramme.',
          userWhoRequested: 'AlchimisteDesMots',
          urlOfUserWhoRequested: 'https://twitch.tv/alchimistedesmots'),
    ],
  ),
  ReleaseNotes(
    version: '1.0.4',
    codeName: 'Mais attend quand même',
    notes:
        'Le Petit Train du Nord était maintenant tellement pressé de partir, '
        'qu\'il n\'attendait même plus la fin de la lecture du télégramme pour '
        's\'élancer! De plus, il ne s\'arrêtait plus après un boost! '
        'Nous l\'avons donc un peu calmé!',
    features: [
      FeatureNotes(
          description:
              'Le chronomètre ne démarre plus avant la fin de la lecture du télégramme.'),
      FeatureNotes(
          description:
              'Un boost pris dans les dernières secondes de la ronde ne pose '
              'plus de problème'),
      FeatureNotes(
          description: 'Les aides du contrôleur peuvent être désactivées dans '
              'le menu d\'options avancées',
          userWhoRequested: 'NghtmrTV',
          urlOfUserWhoRequested: 'https://twitch.tv/nghtmrtv'),
      FeatureNotes(
          description: 'Le mot PESTO est maintenant accepté',
          userWhoRequested: 'emmabouquine',
          urlOfUserWhoRequested: 'https://twitch.tv/emmabouquine'),
    ],
  ),
];
