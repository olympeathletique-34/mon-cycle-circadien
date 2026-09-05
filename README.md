# Code Circadien — Espace Client · Olympe Athlétique

App web statique (HTML/CSS/JS, aucun build) avec authentification par lien magique
et stockage cloud via [Supabase](https://supabase.com), déployée sur [Vercel](https://vercel.com).

- `index.html` — bilan + résultats + suivi, vus par un client connecté (lecture/écriture de ses propres données) ou par le coach en train de consulter un client précis (`?client=<id>`).
- `coach.html` — tableau de bord du coach : liste des clients, lien vers leur bilan.
- `assets/style.css`, `assets/supabase-client.js` — partagés par les deux pages.
- `supabase/schema.sql` — tables, policies de sécurité (RLS) et triggers à exécuter une fois dans Supabase.

## 1. Créer le projet Supabase

1. [supabase.com](https://supabase.com) → New project (choisis une région proche de tes clients, ex. Europe).
2. Une fois créé : **SQL Editor** → New query → colle tout le contenu de [`supabase/schema.sql`](supabase/schema.sql) → Run.
3. **Authentication → Providers → Email** : vérifie que "Email" est activé. Le lien magique (`Magic Link` / OTP) est actif par défaut, aucune configuration de mot de passe n'est nécessaire.
4. **Authentication → URL Configuration** :
   - *Site URL* : `https://mon-cycle-circadien.vercel.app`
   - *Redirect URLs* : ajoute `https://mon-cycle-circadien.vercel.app/**` (et `http://localhost:5500/**` ou équivalent si tu testes en local).
5. **Project Settings → API** : note l'**URL du projet** et la clé **`anon public`**.

## 2. Brancher l'app sur Supabase

Ouvre [`assets/supabase-client.js`](assets/supabase-client.js) et remplace :

```js
const SUPABASE_URL = "https://VOTRE-PROJET.supabase.co";
const SUPABASE_ANON_KEY = "VOTRE_CLE_ANON_PUBLIC";
```

par les valeurs récupérées à l'étape précédente. La clé `anon` est publique par nature
(elle est prévue pour être visible côté client) : la vraie sécurité vient des policies
RLS définies dans `schema.sql`, pas du secret de cette clé.

## 3. Te créer un compte coach

1. Lance l'app (en local ou une fois déployée) et connecte-toi une première fois avec **ton propre email** via le lien magique — ça crée automatiquement ta ligne dans `profiles` avec le rôle `client` par défaut.
2. Dans Supabase → **SQL Editor**, lance :
   ```sql
   update public.profiles set role = 'coach' where email = 'olympeathletique@gmail.com';
   ```
3. Déconnecte-toi puis reconnecte-toi : tu es maintenant redirigé vers `coach.html`.

Tous les autres comptes qui se connectent restent `client` par défaut — c'est le
comportement voulu : seul toi (et les comptes que tu bascules manuellement en `coach`)
as accès au tableau de bord.

## 4. Déployer sur Vercel

Le plus simple, sans rien installer :

1. Crée un repo Git (GitHub/GitLab) avec ces fichiers, ou utilise directement [vercel.com/new](https://vercel.com/new) → "Deploy" → glisse le dossier du projet.
2. Donne le nom **`mon-cycle-circadien`** au projet Vercel — ton URL sera alors `https://mon-cycle-circadien.vercel.app` (si ce nom est déjà pris par quelqu'un d'autre, Vercel te proposera automatiquement une variante, ex. `mon-cycle-circadien-xxxx.vercel.app` : dans ce cas, reporte l'URL réelle dans Supabase à l'étape 1.4).
3. Aucune configuration de build n'est nécessaire (site 100 % statique) — Vercel le détecte automatiquement.
4. Vérifie que l'URL déployée correspond bien à celle déjà renseignée dans Supabase → Authentication → URL Configuration (étape 1.4) ; sinon mets-la à jour.

Alternative en ligne de commande :

```bash
npm i -g vercel
vercel --prod
```

## 5. Tester

1. Va sur `https://mon-cycle-circadien.vercel.app/index.html`, entre l'email d'un client test, clique sur le lien reçu par mail.
2. Remplis un bilan complet (45 questions + horaires).
3. Connecte-toi sur `coach.html` avec ton compte coach : le client doit apparaître dans la liste, clique sur "Ouvrir" pour voir son diagnostic et fixer un ajustement (fenêtre TRE personnalisée, objectifs poids/tour de taille).
4. Reconnecte-toi côté client : l'ajustement du coach doit apparaître dans "Ajustement du coach" (lecture seule) et être pris en compte dans le plan.

## Notes de sécurité

- L'ancien "verrou coach" (mot de passe en clair `OLYMPE` dans le JS) a été supprimé : l'accès coach passe désormais uniquement par le rôle `coach` en base, vérifié côté serveur par les policies RLS de Supabase (pas seulement côté client).
- Un client ne peut jamais lire ni modifier les données d'un autre client : RLS restreint chaque ligne de `bilans`/`profiles` à `auth.uid()`, sauf pour les comptes `coach` qui ont un accès élargi en lecture (et en écriture limitée au champ d'ajustement, du côté applicatif).
- Ne committe jamais de clé **`service_role`** Supabase dans ce projet — seule la clé `anon` doit apparaître dans le code client.
