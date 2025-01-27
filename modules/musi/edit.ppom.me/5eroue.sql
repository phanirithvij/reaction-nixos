.mode csv

.output ateliers.csv
SELECT a.id atelier_id, a.nom_anim, a.date, a.duree, a.lieu, a.commentaires
FROM Atelier a
ORDER BY a.id;

.output participations.csv
SELECT p.atelier atelier_id, p.id participation_id, p.nom, p.age, p.genre, p.mail, s.texte situation_pro, p.commentaires
FROM participation p
INNER JOIN situation_pro s ON p.situation_pro = s.id
ORDER BY p.atelier, p.id;

.output cartes.csv
SELECT pc.participation_id, c.intitule carte, pc.positif, pc.commentaire
FROM participation_carte pc
INNER JOIN carte c ON c.id = pc.carte_id
ORDER BY pc.participation_id;
