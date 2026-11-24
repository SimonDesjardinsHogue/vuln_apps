# Machines virtuelles vulnerables (Metasploitable 2, VulnHub)

Certaines cibles - systemes complets avec services reseau multiples et escalade
de privileges - ne se reproduisent pas fidelement dans un conteneur. Pour
celles-ci, utilisez une **machine virtuelle** sur un **reseau isole**.

## Pourquoi une VM et pas un conteneur

| Besoin | Conteneur | VM |
|---|---|---|
| Application web (Juice Shop, DVWA, WebGoat) | oui, ideal | possible mais lourd |
| Systeme complet, services multiples, noyau vulnerable | non | oui, necessaire |
| Isolation forte vis-a-vis du noyau hote | faible | forte |

## Isolation recommandee

1. **Reseau « hote seulement » (host-only)** ou **reseau interne** : la VM ne
   doit atteindre ni votre LAN ni Internet.
2. **Aucun dossier partage** avec l'hote, aucune copie de vos identifiants.
3. **Snapshots** avant chaque exercice, pour revenir a un etat propre.
4. Ressources limitees (CPU/RAM) pour ne pas saturer Kali.

## Metasploitable 2

Machine d'entrainement reseau (services volontairement vulnerables).

1. Telecharger l'image depuis la page officielle Rapid7 (Metasploitable 2).
2. Creer une VM (VirtualBox ou `virt-manager`/KVM) et y attacher le disque.
3. La placer sur un reseau **host-only**.
4. Verifier que la VM n'a **pas** d'acces Internet.

## VulnHub

VulnHub est un **catalogue** de machines (Linux/Windows, escalade de privileges,
exploitation reseau), pas une application unique.

1. Choisir une machine sur <https://www.vulnhub.com>.
2. Telecharger l'image (`.ova` / `.vmdk`) et l'importer.
3. Reseau host-only, snapshot initial.
4. Lire l'enonce (souvent un objectif du type « obtenir root »).

## Outils d'hote

- **VirtualBox** : `sudo apt install virtualbox` - simple, adapte au debutant.
- **KVM/QEMU** : `sudo apt install qemu-kvm libvirt-daemon-system virt-manager` -
  meilleures performances.

## Rappel

Ces machines ne doivent **jamais** etre mises en reseau avec votre LAN ou
Internet : elles sont concues pour etre compromises.
