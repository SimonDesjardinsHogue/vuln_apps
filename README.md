# vuln_apps

Applications **volontairement vulnerables** a installer en local sur Kali, pour
s'entrainer et pour **valider un outil de test d'intrusion** (par exemple
`autopentest`) sur des cibles dont on maitrise le perimetre.

> ATTENTION : ces applications sont concues pour etre vulnerables.
> Ne les exposez **jamais** sur un reseau (LAN, Internet, VPN).
> Les ports sont publies sur `127.0.0.1` uniquement, sans demarrage automatique.

## Applications incluses

| Application | Type | URL locale |
|---|---|---|
| OWASP Juice Shop | Boutique JS (OWASP Top 10) | http://127.0.0.1:3000 |
| DVWA (+ MariaDB) | Application PHP | http://127.0.0.1:4280 |
| OWASP WebGoat (+ WebWolf) | Lecons Java/Spring | http://127.0.0.1:8080/WebGoat/ |

Machines virtuelles (Metasploitable 2, VulnHub) : voir
[`docs/machines-virtuelles.md`](docs/machines-virtuelles.md).

## Prerequis

- Kali Linux (teste) ou autre distribution avec Docker
- Docker + Compose v2
- ~5 GiB d'espace disque, ~2 GiB de RAM

Installation (Kali / Debian) :

Sur Kali et Debian, Docker est reparti en **plusieurs paquets** et il **n'existe
pas** de paquet `docker-compose-v2` :

| Paquet | Role |
|---|---|
| `docker.io` | le **demon** (`dockerd`, `docker.service`) - ne fournit pas le client |
| `docker-cli` | le **client** `docker` |
| `docker-compose` | **Compose v2** (fournit `docker compose` et `docker-compose`) |

```bash
sudo apt update
sudo apt install -y docker.io docker-cli docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"   # puis se reconnecter, ou : newgrp docker
```

`containerd`, `runc` et `iptables` sont installes automatiquement comme
dependances. **N'installez pas `podman-docker`** : il entre en conflit avec
`docker.io` / `docker-cli`.

Verification :

```bash
docker --version          # 28.x
docker compose version    # v2.x
docker info               # le demon doit repondre
```

## Demarrage rapide

```bash
./lab.sh doctor            # verifie l'environnement (Docker, ports, ressources)
cp .env.example .env       # ports, identifiants locaux, tags d'images
./lab.sh pull juice-shop   # telecharge l'image
./lab.sh up juice-shop     # demarre (127.0.0.1 uniquement)
./lab.sh status            # etat des conteneurs
./lab.sh down juice-shop   # arrete (donnees conservees)
./lab.sh reset dvwa        # arrete + supprime les donnees (confirmation)
```

`all` est accepte partout ou une application est attendue : `./lab.sh up all`,
`./lab.sh pull all`, `./lab.sh down all`, `./lab.sh reset all`.

## Commandes

| Commande | Role |
|---|---|
| `doctor` | Verifie Docker, Compose, ressources et ports libres |
| `list` | Liste les applications et leurs URL |
| `pull <app\|all>` | Telecharge les images (sans demarrer) |
| `up <app\|all>` | Demarre une application |
| `down <app\|all>` | Arrete et supprime les conteneurs (donnees conservees) |
| `status` | Etat des conteneurs du laboratoire |
| `logs <app>` | Journaux d'une application (suivi) |
| `reset <app\|all>` | Arrete + supprime conteneurs **et** volumes |
| `help` | Aide |

## Configuration

Tout se regle dans `.env` (copie depuis `.env.example`) : ports, mots de passe
locaux de la base DVWA, fuseau horaire, et **tags d'images** pour figer les
versions. Le fichier `compose.yaml` definit un **profil par application** : une
seule application demarre a la fois, sans lancer les autres.

## Securite du laboratoire

Details : [`docs/securite.md`](docs/securite.md). En resume :

- publication **127.0.0.1 uniquement**, base MariaDB jamais exposee ;
- un reseau Docker isole par application ;
- aucun conteneur privilegie, aucun montage du socket Docker ni du dossier personnel ;
- aucun redemarrage automatique ;
- mise a jour des images **explicite**, jamais silencieuse ;
- `reset` limite aux ressources du projet.

## Tests

```bash
./tests/smoke.sh
```

Verifie la syntaxe, l'aide, la liste, les erreurs d'usage et (si disponible) la
validite de la configuration Compose.

## Depannage

| Symptome | Cause / Solution |
|---|---|
| `Unable to locate package docker-compose-v2` | Ce paquet n'existe pas sur Kali/Debian. Installer **`docker-compose`** (Compose v2). |
| `Unit docker.service does not exist` | Le demon n'est pas installe : `sudo apt install docker.io`. |
| `group 'docker' does not exist` | Demon non installe, ou session non rechargee : `newgrp docker` ou reconnexion. |
| `permission denied ... docker.sock` | Utilisateur hors du groupe `docker` : `sudo usermod -aG docker "$USER"` puis reconnexion. |
| `docker: command not found` apres `docker.io` | Le client est dans le paquet separe **`docker-cli`**. |
| Conflit `podman-docker` / `docker.io` | Ne pas installer les deux (ils sont en conflit). |

Diagnostic automatique : `./lab.sh doctor`.

## Licence

GNU Affero General Public License v3 - voir [`LICENSE`](LICENSE).
