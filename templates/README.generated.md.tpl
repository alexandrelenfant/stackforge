# {{PROJECT_NAME}}

Projet généré avec Stackforge.

## Description

Ce projet contient une infrastructure Docker prête à l'emploi pour lancer une application composée de :

- une API ;
- un front public ;
{{#if ADMIN_ENABLED}}
- une interface admin ;
{{/if}}
- un reverse proxy Caddy ;
- des certificats HTTPS locaux de développement générés avec `mkcert`.

Domaine local :

```text
{{DOMAIN_LCL}}
```

Domaine de production :

```text
{{DOMAIN}}
```

Si le domaine de production est vide, renseigne-le dans `.env` avant de lancer `./project.sh prod`.

## Structure du projet

```text
{{PROJECT_NAME}}/
├── api/
├── front/
{{#if ADMIN_ENABLED}}
├── admin/
{{/if}}
{{#if MOBILE_ENABLED}}
├── mobile/
{{/if}}
├── infra/
│   ├── certs/
│   │   └── .gitkeep
│   ├── reverse_proxy/
│   │   ├── Caddyfile.dev
│   │   ├── Caddyfile.prod
│   │   └── Caddyfile.test
│   ├── scripts/
│   │   └── generate-certs.sh
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

## Prérequis

- Docker
- Docker Compose
- Git
- `mkcert`

Make est optionnel. Il ne sert que de wrapper autour de `project.sh`.

Composer, Node.js, npm, npx, Angular CLI, Java, Maven, curl et unzip ne sont pas requis sur l'hôte pour les modes générés par Stackforge.
Ces outils sont fournis par Docker pendant la génération ou l'exécution.

## Fichiers Dotenv

Les commandes chargent automatiquement les fichiers dotenv présents dans ce dossier `infra`, dans cet ordre :

```text
.env
.env.<environnement>
.env.local
.env.<environnement>.local
```

Exemple pour `./project.sh dev` :

```text
.env
.env.dev
.env.local
.env.dev.local
```

Exemple pour `./project.sh prod` :

```text
.env
.env.prod
.env.local
.env.prod.local
```

Les fichiers chargés en dernier surchargent les précédents. Les fichiers `.local` sont destinés aux réglages propres à ta machine, comme des ports locaux différents :

```dotenv
HTTP_PORT=880
HTTPS_PORT=8443
```

En développement, les dépendances restent accessibles depuis la machine hôte :

- `vendor/` est installé dans le dossier API monté ;
- `node_modules/` est installé dans le dossier front/admin monté.

En test et production, les dépendances sont installées uniquement dans les images Docker.

## Configuration

La configuration Docker se trouve dans :

```text
.env
```

Variables principales :

```dotenv
COMPOSE_PROJECT_NAME={{PROJECT_NAME}}

DOMAIN={{DOMAIN}}
DOMAIN_LCL={{DOMAIN_LCL}}

HTTP_PORT=80
HTTPS_PORT=443

API_DIR=../api
FRONT_DIR=../front
{{#if ADMIN_ENABLED}}
ADMIN_DIR=../admin
{{/if}}{{#if MOBILE_ENABLED}}
MOBILE_DIR=../mobile
{{/if}}
```

Si les ports 80 ou 443 sont déjà utilisés sur la machine hôte, change les ports publiés dans `.env` :

```dotenv
HTTP_PORT=8080
HTTPS_PORT=8443
```

Dans ce cas, les URLs locales utilisent le port choisi, par exemple `https://{{DOMAIN_LCL}}:8443`.

## Commandes disponibles

Afficher l'aide :

```bash
./project.sh help
```

Générer les certificats de développement :

```bash
./project.sh certs
```

Démarrer l'environnement de développement :

```bash
./project.sh dev
```

Démarrer l'environnement de test :

```bash
./project.sh test
```

Démarrer l'environnement de production :

```bash
./project.sh prod
```

Afficher les logs :

```bash
./project.sh logs
```

Afficher l'état des conteneurs :

```bash
./project.sh ps
```

Arrêter les conteneurs :

```bash
./project.sh down
```

Sur Windows PowerShell avec Git for Windows installé :

```powershell
.\project.ps1 dev
```

Les commandes `make dev`, `make prod`, etc. restent disponibles si Make est installé.

## Certificats de développement

Les certificats locaux sont générés avec :

```bash
./project.sh certs
```

Ils sont créés dans :

```text
infra/certs/
```

Domaines couverts :

```text
{{DOMAIN_LCL}}
api.{{DOMAIN_LCL}}
mail.{{DOMAIN_LCL}}
{{#if ADMIN_ENABLED}}
admin.{{DOMAIN_LCL}}
{{/if}}
```

Les certificats générés par cette commande sont uniquement destinés au développement local.

## Production

Les certificats de production ne sont pas générés par `./project.sh certs`.

En production, Caddy peut gérer automatiquement les certificats via Let's Encrypt si :

- `DOMAIN` est renseigné dans `.env` ;
- le domaine pointe vers le serveur ;
- les ports `80` et `443` sont accessibles ;
- les volumes Caddy sont conservés.

Avant de lancer la production, vérifier :

```dotenv
DOMAIN={{DOMAIN}}
```

Puis lancer :

```bash
./project.sh prod
```

## Développement

Générer les certificats :

```bash
./project.sh certs
```

Démarrer l'environnement :

```bash
./project.sh dev
```

URLs locales :

```text
https://{{DOMAIN_LCL}}
https://api.{{DOMAIN_LCL}}
https://mail.{{DOMAIN_LCL}}
{{#if ADMIN_ENABLED}}
https://admin.{{DOMAIN_LCL}}
{{/if}}
```

## Test

Démarrer l'environnement de test :

```bash
./project.sh test
```

URLs de test :

```text
https://test.{{DOMAIN}}
https://test.api.{{DOMAIN}}
{{#if ADMIN_ENABLED}}
https://test.admin.{{DOMAIN}}
{{/if}}
```

## Notes

Ce projet est déjà généré.

Il ne contient volontairement pas :

- les templates Stackforge ;
- le script d'initialisation Stackforge ;
- la commande `init` ;
- la commande `render`.

Pour générer un autre projet, utilise le dépôt Stackforge d'origine.
```
