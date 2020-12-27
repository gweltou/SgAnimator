# SgAnimator
Animation tool for spacegame

## Préparation des illustrations vectorielle en vue de leur animation
Seul les groupes d'objets apparaissent comme des parties indépendantes et animables dans le logiciel d'animation (liste de gauche). Si aucun groupe n'a été définit dans l'illustration vectorielle, vous ne pourrez animer l'illustration que comme un objet monolithique et n'aurez pas accès à ses sous-parties.
<img src="res/sga_partslist.png" alt="parts list" style="float:left;scale:50%;">

Dans le logiciel Inkscape, La création de groupes d'objets se fait par la combinaison des touches `Ctrl + G` ou bien par le menu "Objet > Grouper", après avoir sélectionné les différents objets à regrouper ensemble.
Il peut être pratique de nommer les groupes créés afin de faciliter leur sélection dans la liste des parties animables. Dans Inkscape, sélectionnez le groupe puis accédez à ses propriétés avec la combinaison de touches `Ctrl + Maj + O` bien par le menu "Objet > Propriétés de l'objet...". Modifiez l'attribut "ID" pour renommer le groupe.
<img src="res/inkscape_groupid.png" alt="inkscape group id" style="scale:50%;">

Un groupe peut contenir, en plus d'objets simples, d'autres sous-groupes. Vous pourrez ainsi animer chaque sous-groupe d'une façon indépendante (Ex : les doigts d'une main) et chaque sous-groupe sera affecté de la même manière par l'animation du groupe parent (lorsque la main bouge, les doigts se déplacent avec la main).
C'est donc l'organisation des groupes qui définit le "rigging" (squelettage) le l'illustration. On organise les groupes de façon hiérarchique en partant des extrémités pour aller vers la raçine. (Pour reprendre notre exemple : chaque doigt est un groupe contenu dans le groupe "main", lui-même contenu dans le groupe "avant-bras", lui-même contenu dans le groupe "bras"...)
