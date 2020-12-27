# SgAnimator
Outil d'animation d'images vectorielles pour les jeux vidéo.<br>
Fonctionne avec les fichiers vectoriels au format **SVG**. Les données créées par le logiciel (geométrie et données d'animation) sont sauvergardées au format **json**. Ce format permet la modification directe de certains paramètres d'animation avec un éditeur de texte simple.

## Préparation des illustrations vectorielle (SVG)
Seul les **groupes** d'objets apparaissent comme des parties indépendantes et animables dans le logiciel d'animation (liste de gauche). Si aucun groupe n'a été définit dans l'illustration vectorielle, vous ne pourrez animer l'illustration que comme un objet monolithique et n'aurez pas accès à ses sous-parties.
![parts list](res/sga_partslist.png)

Dans le logiciel Inkscape, La création de groupes d'objets se fait par la combinaison des touches <kbd>Ctrl</kbd> + <kbd>G</kbd> ou bien par le menu "Objet > Grouper", après avoir sélectionné les différents objets à regrouper ensemble.<br>
Il peut être pratique de nommer les groupes créés afin de faciliter leur sélection dans la liste des parties animables. Dans Inkscape, sélectionnez le groupe puis accédez à ses propriétés avec la combinaison de touches <kbd>Ctrl</kbd> + <kbd>Maj</kbd> + <kbd>O</kbd> bien par le menu "Objet > Propriétés de l'objet...". Modifiez l'attribut "ID" pour renommer le groupe.
![inkscape group id](res/inkscape_groupid.png)

Un groupe peut contenir, en plus d'objets simples, d'autres sous-groupes. Vous pourrez ainsi animer chaque sous-groupe d'une façon indépendante (Ex : les doigts d'une main) et chaque sous-groupe sera affecté de la même manière par l'animation du groupe parent (lorsque la main bouge, les doigts se déplacent avec la main).<br>
C'est donc l'organisation des groupes qui définit le "rigging" (squelettage) le l'illustration. On organise les groupes de façon hiérarchique en partant des extrémités pour aller vers la raçine. (Pour reprendre notre exemple : chaque doigt est un groupe contenu dans le groupe "main", lui-même contenu dans le groupe "avant-bras", lui-même contenu dans le groupe "bras"...)

## Fonctions d'animation
Chaque partie selectionnable peut-être animée par une ou plusieurs fonctions d'animation.

## Constant
Transformation statique (ne varie pas avec le temps).
Pratique pour redimensionner certaines partie (avec les axes "scale") à l'avant d'autres fonctions d'animation.
## EasingFromTo
## Timetable
## Sin
## Spin
Fonction pour créer une rotation permanente (avec l'axe "rotation"). Permet d'animer les pales d'un moulin à vent par exemple.
## RandomEase
## RandomBlink
