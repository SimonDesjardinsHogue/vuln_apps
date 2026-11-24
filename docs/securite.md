# Securite du laboratoire

Ces applications sont **intentionnellement vulnerables**. L'objectif n'est pas
de les durcir (cela casserait les exercices) mais de **proteger leur
environnement** : votre machine et votre reseau.

## Mesures appliquees

| Mesure | Detail |
|---|---|
| Publication locale seule | Tous les ports sont lies a `127.0.0.1`, jamais `0.0.0.0`. Aucun acces depuis le LAN ni Internet. |
| Base de donnees non exposee | Le conteneur MariaDB (DVWA) n'a **aucun** port publie : joignable seulement par le conteneur DVWA via un reseau dedie. |
| Reseau isole par application | Chaque application a son propre reseau Docker : elles ne se voient pas entre elles. |
| Absence de privileges | `security_opt: no-new-privileges:true` sur chaque service. Aucun `privileged: true`. |
| Aucun montage sensible | Ni socket Docker (`/var/run/docker.sock`), ni dossier personnel, ni `/`. |
| Pas de demarrage automatique | `restart: "no"` : rien ne redemarre au boot de Kali. |
| Suppression ciblee | `down`/`reset` n'agissent que sur le projet `vuln-apps`. Aucun `docker system prune`. |
| Mises a jour explicites | Les images ne sont jamais mises a jour silencieusement ; `pull` est volontaire. |

## Limites a connaitre

- **`127.0.0.1` limite l'acces entrant, pas les connexions sortantes.** Un
  conteneur compromis peut toujours initier des connexions vers l'exterieur.
  Pour un confinement plus strict, utilisez une VM dediee (voir
  `machines-virtuelles.md`) ou des regles de pare-feu Docker.
- **Les conteneurs partagent le noyau de l'hote.** Docker n'est pas une frontiere
  de securite equivalente a une machine virtuelle.
- **Les donnees des exercices sont jetables.** Ne stockez rien de sensible dans
  les volumes du laboratoire.
- Ne republiez jamais les ports sur `0.0.0.0` « pour tester depuis un autre poste ».

## Bonnes pratiques

1. Lancez une application a la fois quand c'est possible (`./lab.sh up <app>`).
2. Eteignez le laboratoire inutilise (`./lab.sh down all`).
3. Reinitialisez les donnees apres des exercices destructifs (`./lab.sh reset <app>`).
4. Epinglez les tags d'images dans `.env` pour un laboratoire reproductible.
5. N'executez de scans que sur des cibles pour lesquelles vous etes autorise,
   y compris ce laboratoire local.

## Verifier soi-meme

```bash
# Les ports doivent apparaitre en 127.0.0.1 et non en 0.0.0.0
ss -ltn | grep -E '3000|4280|8080|9090'

# La base DVWA ne doit exposer aucun port
./lab.sh status
```
