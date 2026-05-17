# Stackforge

Stackforge permet de générer un projet Docker avec ou sans interface admin.

Source-available project.
Not open source.

## Types de projet

```text
with-admin
without-admin
```

Si le projet est généré sans admin, aucune section admin n'est présente dans les fichiers Docker Compose, Caddy ou certificats.

## Frameworks front supportés

- Vue / Vite
- React / Vite
- Nuxt SSR
- Angular

## Modes de déploiement

Stackforge adapte automatiquement l’infrastructure selon le framework choisi :

| Framework | Mode |
|---|---|
| Vue / React / Angular | statique |
| Nuxt | serveur SSR |

Pour les applications statiques :
- les assets sont générés puis servis par Caddy.

Pour les applications SSR :
- l’application Node.js reste active ;
- Caddy agit comme reverse proxy.

## Générer un projet

```bash
./stackforge.sh generate
```

Sur Windows PowerShell avec Git for Windows installé :

```powershell
.\stackforge.ps1 generate
```

`make generate` reste disponible comme wrapper optionnel.
```

Le script demande :

- le nom du projet ;
- le dossier cible ;
- le type de projet ;
- les domaines ;
- les dépôts Git optionnels.

## Prérequis hôte

- Docker
- Docker Compose
- Git
- `mkcert`

Make est optionnel. Il ne sert que de wrapper autour de `stackforge.sh`.

Composer, Node.js, npm, npx, Angular CLI, Java, Maven, curl et unzip ne sont pas requis sur l'hôte pour les modes générés par Stackforge.
Ces outils sont fournis par Docker pendant la génération ou l'exécution.

## Fichiers Dotenv

Stackforge charge automatiquement les fichiers dotenv présents dans le dossier du générateur, dans cet ordre :

```text
.env
.env.<commande>
.env.local
.env.<commande>.local
```

Exemple pour `./stackforge.sh generate` :

```text
.env
.env.generate
.env.local
.env.generate.local
```

Les fichiers chargés en dernier surchargent les précédents. Les fichiers `.local` sont destinés aux réglages propres à ta machine.

En développement, les dépendances restent accessibles depuis la machine hôte :

- `vendor/` est installé dans le dossier API monté ;
- `node_modules/` est installé dans le dossier front/admin monté.

En test et production, les dépendances sont installées uniquement dans les images Docker.

## Utilisation depuis n'importe quel dossier

Le générateur peut être appelé avec le chemin absolu du script :

```bash
/Users/taleia/Projets/skeleton/stackforge.sh generate
```

Exemple :

```bash
cd ~/Projets
/Users/taleia/Projets/skeleton/stackforge.sh generate
```

Par défaut, le nouveau projet est créé dans le dossier courant :

```text
./nom_du_projet
```

## Installer l'alias de commande

Pour éviter de retaper le chemin complet du script, tu peux installer un alias :

```bash
./stackforge.sh install-alias
```

Cette commande ajoute automatiquement l'alias dans le fichier de configuration adapté au shell utilisé :

- `~/.zshrc` pour Zsh ;
- `~/.bashrc` pour Bash.

L'alias installé par défaut est :

```bash
stackforge
```

Après installation, recharge ton shell :

```bash
source ~/.zshrc
```

ou, si tu utilises Bash :

```bash
source ~/.bashrc
```

Tu peux ensuite générer un projet depuis n'importe quel dossier :

```bash
cd ~/Projets
stackforge
```

Si tu veux utiliser un autre nom d'alias :

```bash
ALIAS_NAME=create-project ./stackforge.sh install-alias
```

## Structure générée

```text
mon-projet/
├── api/
├── front/
├── admin/
├── infra/
│   ├── certs/
│   ├── reverse_proxy/
│   ├── scripts/
│   ├── .env
│   ├── compose.yml
│   ├── compose.dev.yml
│   ├── compose.prod.yml
│   ├── compose.test.yml
│   ├── project.sh
│   ├── project.ps1
│   ├── Makefile
│   └── README.md
```
```
