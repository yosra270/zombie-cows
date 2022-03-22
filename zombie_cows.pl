%  Les relations rocher(X,Y) et arbre(X,Y) retournent vrai si la case (X,Y) est encombrée par un rocher (respectivement par un arbre).
:- dynamic rocher/2.
:- dynamic arbre/2.

% La relation vache(X, Y, Race, Etat) retourne vrai lorsqu’une vache de race Race est sur la case (X,Y).
:- dynamic vache/4.

% La relation dimitri(X, Y) donne la position de Dimitri.
:- dynamic dimitri/2.

% Les faits largeur(X) et hauteur(Y) donnent la largeur et la longueur du plateau de jeu.
largeur(5).
hauteur(6).

% Les faits nombre_rochers(N), nombre_arbres(N), nombre_vaches(Race, N) donnent le nombre de rochers, d’arbres et de vaches de chaque race sur le plateau du jeu.
nombre_rochers(2).
nombre_arbres(1).
nombre_vaches(brune,3).
nombre_vaches(simmental,2).
nombre_vaches(alpine_herens,4).

% La règle occupe(X,Y) est vrai si et seulement si la case (X,Y) est occupée par un arbre, un rocher, une vache ou Dimitri.
occupe(X,Y) :- rocher(X,Y); arbre(X,Y); vache(X,Y,_,_); dimitri(X,Y).

% La règle libre(X,Y) retourne dans X et Y les coordonnées d’une case libre ( n’ayant ni rocher, ni arbre, ni vache, ni Dimitri).
libre(X,Y) :- repeat, hauteur(H), largeur(L),random(0,L,X), random(0,H,Y),not(occupe(X,Y)),!.

% Les règles placer_rochers(N), placer_arbres(N), placer_vaches(Race, N) placent N rochers, arbres ou vaches sur le plateau de jeu.
placer_rochers(0).
placer_rochers(N) :- libre(X,Y), assertz(rocher(X,Y)), N1 is N-1,placer_rochers(N1).

placer_arbres(0).
placer_arbres(N) :- libre(X,Y), assertz(arbre(X,Y)), N1 is N-1, placer_arbres(N1).

placer_vaches(_,0).
placer_vaches(Race,N) :- libre(X,Y),assertz(vache(X,Y,Race,vivante)), N1 is N-1, placer_vaches(Race,N1).

placer_dimitri :- libre(X,Y), assertz(dimitri(X,Y)).

% La règle vaches(L) retourne dans L la liste des positions occupées par des vaches.
vaches(L) :- findall([X,Y], vache(X,Y,_,vivante),L).

% La règle creer_zombie sélectionne aléatoirement une vache et la transforme en zombie.
/*list_length([],0).
list_length([X|L],N) :- list_length(L,N1), N is N1+1.*/

creer_zombie :-
  vaches(Vaches),
  /*l is list_length(Vaches),
  Pos is random(l),
  nth0(Pos,Vaches,Zombie_position),*/
  random_member(Zombie_position,Vaches),
  nth0(0, Zombie_position,X), nth0(1, Zombie_position,Y),
  retract(vache(X,Y,Race,vivante)),
  assertz(vache(X,Y,Race,zombie)).


% La règle question(R) demande au joueur dans quelle direction déplacer Dimitri, et retourne le résultat sous forme d’atome (reste, nord, sud, est, ouest) dans R. 
% reste indique de ne pas bouger.
question(R) :-
  writeln('Dans quelle direction voulez vous déplacer Dimitri ? :)'),
  read(X),
  (
      X = 'reste', R = reste;
      X = 'nord', R = nord;
      X = 'sud', R = sud;
      X = 'est', R = est;
      X = 'ouest', R = ouest
  ).

% La règle zombification transforme en zombies les vaches autour (nord, sud, est, ouest) de toute position (X,Y) occupée par une vache zombie. 
% En effet, celle-ci mord ses voisines...
zombification :-
  findall([X,Y],vache(X,Y,_,zombie),L),
  coordonnees_victimes(L,C),
  zombification(C).

coordonnees_victimes([],[]).
coordonnees_victimes([[X,Y]|L],C):-
  coordonnees_victimes(L,C1),
  X1 is X+1,X2 is X-1, Y1 is Y+1, Y2 is Y-1,
  C = [[X1,Y],[X2,Y],[X,Y1],[X,Y2]|C1].

zombification([]).
zombification([[X,Y]|L]) :-
  vaches(Vaches),
  (   member([X,Y],Vaches),
      retract(vache(X,Y,Race,vivante)),
      assertz(vache(X,Y,Race,zombie));
      true
  ),
  zombification(L).

% La règle deplacement_vache(X, Y, Direction) déplace la vache située en (X, Y) dans la direction Direction (reste, nord, sud, est, ouest) sans sortir du plateau de jeu ni arriver sur une case occupée. 
% Si c’est le cas, il n’y a pas de mouvement.
deplacement_vaches :-
      findall([X,Y],vache(X,Y,_,_),Vaches),
      deplacement_vaches(Vaches).

deplacement_vaches([]).
deplacement_vaches([[X,Y]|L]):-
      random_member(Direction,[reste,nord,sud,est,ouest]),
      deplacement_vache(X,Y,Direction),
      deplacement_vaches(L).

deplacement_vache(_,_,Direction) :-
  Direction == reste.

deplacement_vache(X,Y,Direction) :-
  Direction == est,
  hauteur(H),
  X1 is X+1,
  (   X1 < H,
      not(occupe(X1,Y)),
      retract(vache(X,Y,Race,Etat)),
      assertz(vache(X1,Y,Race,Etat));
      true
  ).


deplacement_vache(X,Y,Direction) :-
  Direction == ouest,
  X1 is X-1,
 (    X1 >= 0,
      not(occupe(X1,Y)),
      retract(vache(X,Y,Race,Etat)),
      assertz(vache(X1,Y,Race,Etat));
      true
 ).


deplacement_vache(X,Y,Direction) :-
  Direction == sud,
  largeur(L),
  Y1 is Y+1,
  (   Y1 < L,
      not(occupe(X,Y1)),
      retract(vache(X,Y,Race,Etat)),
      assertz(vache(X,Y1,Race,Etat));
      true
  ).



deplacement_vache(X,Y,Direction) :-
  Direction == nord,
  Y1 is Y-1,
  (   Y1 >= 0,
      not(occupe(X,Y1)),
      retract(vache(X,Y,Race,Etat)),
      assertz(vache(X,Y1,Race,Etat));
      true
  ).

% La règle deplacement_joueur(Direction) déplace Dimitri en respectant les mêmes contraintes précédentes.
deplacement_joueur(Direction) :-
  Direction == reste.

deplacement_joueur(Direction) :-
  Direction == est,
  dimitri(X,Y),
  hauteur(H),
  X1 is X+1,
  (   X1 < H,
      not(occupe(X1,Y)),
      retract(dimitri(X,Y)),
      assertz(dimitri(X1,Y));
      true
  ).


deplacement_joueur(Direction) :-
  Direction == ouest,
  dimitri(X,Y),
  X1 is X-1,
  (   X1 >= 0,
      not(occupe(X1,Y)),
      retract(dimitri(X,Y)),
      assertz(dimitri(X1,Y));
      true
  ).


deplacement_joueur(Direction) :-
  Direction == sud,
  dimitri(X,Y),
  largeur(L),
  Y1 is Y+1,
  (   Y1 < L,
      not(occupe(X,Y1)),
      retract(dimitri(X,Y)),
      assertz(dimitri(X,Y1));
      true
  ).



deplacement_joueur(Direction) :-
  Direction == nord,
  dimitri(X,Y),
  Y1 is Y-1,
  (   Y1 >= 0,
      not(occupe(X,Y1)),
      retract(dimitri(X,Y)),
      assertz(dimitri(X,Y1));
      true
  ).

% La règle verification retourne vrai si Dimitri n’est pas à côté d’une vache zombie. 
% Il peut ainsi continuer son chemin sans se faire mordre et devenir lui-même un zombie.
verification :-
  findall([X,Y],vache(X,Y,_,zombie),Vaches_zombies),
  verification(Vaches_zombies).

verification([]).
verification([[Xv,Yv]|L]):-
  dimitri(Xd,Yd),
  Dxx is Xd-Xv, Dyy is Yd-Yv,
  Dx is abs(Dxx), Dy is abs(Dyy),
  Distance is Dx+Dy, Distance > 1,
  verification(L).


initialisation :-
  nombre_rochers(NR),
  placer_rochers(NR),
  nombre_arbres(NA),
  placer_arbres(NA),
  nombre_vaches(brune, NVB),
  placer_vaches(brune, NVB),
  nombre_vaches(simmental, NVS),
  placer_vaches(simmental, NVS),
  nombre_vaches(alpine_herens, NVH),
  placer_vaches(alpine_herens, NVH),
  placer_dimitri,
  creer_zombie,
  !.

affichage(L, _) :-
  largeur(L),
  nl,nl.

affichage(L, H) :-
  rocher(L, H),
  write('\tO'),
  L_ is L + 1,
  affichage(L_, H).

affichage(L, H) :-
  arbre(L, H),
  write('\tT'),
  L_ is L + 1,
  affichage(L_, H).

affichage(L, H) :-
  dimitri(L, H),
  write('\tD'),
  L_ is L + 1,
  affichage(L_, H).

affichage(L, H) :-
  vache(L, H, brune, vivante),
  write('\tB'),
  L_ is L + 1,
  affichage(L_, H).
affichage(L, H) :-
  vache(L, H, brune, zombie),
  write('\tb'),
  L_ is L + 1,
  affichage(L_, H).

affichage(L, H) :-
  vache(L, H, simmental, vivante),
  write('\tS'),
  L_ is L + 1,
  affichage(L_, H).
affichage(L, H) :-
  vache(L, H, simmental, zombie),
  write('\ts'),
  L_ is L + 1,
  affichage(L_, H).

affichage(L, H) :-
  vache(L, H, alpine_herens, vivante),
  write('\tH'),
  L_ is L + 1,
  affichage(L_, H).
affichage(L, H) :-
  vache(L, H, alpine_herens, zombie),
  write('\th'),
  L_ is L + 1,
  affichage(L_, H).

affichage(L, H) :-
  \+ occupe(L, H),
  write('\t.'),
  L_ is L + 1,
  affichage(L_, H).

affichage(H) :-
  hauteur(H).

affichage(H) :-
  hauteur(HMax),
  H < HMax,
  affichage(0, H),
  H_ is H + 1,
  affichage(H_).

affichage :-
  affichage(0),!.



jouer :-
  initialisation,
  tour(0).

tour_(_) :-
  \+ verification,
  write('Dimitri s\'est fait mordre <3'),!.
tour_(N) :-
  verification,
  M is N + 1,
  tour(M).

tour(N) :-
  affichage,
  question(R),
  deplacement_joueur(R),
  deplacement_vaches,
  zombification,
  tour_(N).
