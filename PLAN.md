# Plan de refonte ergonomique — OTTix

## Objectif
Restructurer l'interface pour séparer clairement la navigation des chaînes de la lecture vidéo, améliorer la navigation par groupes, et déplacer l'administration (playlists + paramètres) dans une page dédiée.

---

## Architecture finale

```
┌──────────────────────────────────────────────────┐
│  Window                                           │
│  ┌──────────────────────────────────────────────┐ │
│  │  PlayerPage (fullscreen overlay)              │ │
│  │  [X] fermer  [≡] naviguer                    │ │
│  │  Multiplex 1-4 + contrôles                   │ │
│  │  ┌────────────────────────────────┐          │ │
│  │  │ ChannelSearchPopup (modal)     │          │ │
│  │  │ Search + grille de chaînes     │          │ │
│  │  │ Support pick mode              │          │ │
│  │  └────────────────────────────────┘          │ │
│  └──────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────┐ │
│  │  Navigation (visible quand player caché)      │ │
│  │  ┌─ Toolbar ──────────────────────────────┐  │ │
│  │  │  Titre vue   [⚙️ Admin]                │  │ │
│  │  └─────────────────────────────────────────┘  │ │
│  │  ┌─ TabBar ───────────────────────────────┐  │ │
│  │  │ [Toutes les chaînes] [Groupes] [Favoris]│  │ │
│  │  └─────────────────────────────────────────┘  │ │
│  │  ┌─ StackLayout ─────────────────────────┐  │ │
│  │  │ AllChannels: search + grid             │  │ │
│  │  │ Groups: liste → drill-down with back   │  │ │
│  │  │ Favorites: grid                        │  │ │
│  │  └─────────────────────────────────────────┘  │ │
│  └──────────────────────────────────────────────┘ │
│                                                    │
│  ┌─ AdminPage (full page, ⚙️) ───────────────────┐ │
│  │  [←] Administration                            │ │
│  │  Tab: [Playlists] [Settings]                    │ │
│  │  Playlists: add/load/delete                     │ │
│  │  Settings: volume, hwdec, cache, database       │ │
│  └──────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
```

---

## Fichiers

### Nouveaux fichiers
| Fichier | Rôle |
|---|---|
| `GroupsPage.qml` | Liste des groupes → drill-down vers les chaînes d'un groupe |
| `AdminDialog.qml` | Page pleine avec onglets Playlists + Settings, accessible via ⚙️ |
| `ChannelSearchPopup.qml` | Popup de navigation dans les chaînes depuis le player |

### Fichiers modifiés
| Fichier | Changement |
|---|---|
| `PlayerPage.qml` | Réécriture complète — devient la vue plein écran du player avec contrôles + close + bouton naviguer |
| `ChannelListPage.qml` | Retrait du ComboBox de filtre par groupe |
| `Main.qml` | Nouveau TabBar 3 onglets, tooltip admin ⚙️, overlay player/navigation, suppression de l'ancienne zone player intégrée |
| `AGENTS.md` | Mise à jour de la structure |

---

## Étapes d'implémentation

### Étape 1 — GroupsPage.qml
- Vue liste/grid des groupes (`ChannelListModel.groups`)
- Au clic : mémorise le groupe sélectionné + affiche une sous-vue
- Sous-vue : header avec `← Nom du groupe` + grille de chaînes (réutilise ChannelDelegate via `ChannelListModel.filterGroup`)
- Bouton retour → revient à la liste des groupes

### Étape 2 — ChannelListPage.qml
- Retirer le `ComboBox` et son `Label` de compteur ?
- Garder uniquement le `TextField` de recherche
- Simplifier le header

### Étape 3 — AdminDialog.qml
- Page pleine (remplace la vue navigation quand ⚙️ cliqué)
- Header avec bouton retour ← + titre "Administration"
- Onglets : Playlists | Settings
- Playlists : contenu repris de l'actuel onglet Playlists dans Main.qml
- Settings : contenu repris de SettingsPage.qml

### Étape 4 — PlayerPage.qml
- Réécriture complète
- Affiche les 4 PlayerSlot en layout multiplex (comme actuellement dans Main.qml)
- Header : `[X]` à gauche + nom de la chaîne active + `[≡]` à droite
- Overlay contrôles : mode selector 1-4, volume, seek
- Signal `closeRequested()` → remonté à Main.qml
- Signal `navigateRequested()` → ouvre ChannelSearchPopup
- Reprend toute la logique de contrôles (auto-hide, timer, etc.)

### Étape 5 — ChannelSearchPopup.qml
- Popup modal avec fond semi-transparent
- Champ de recherche + GridView des résultats
- Support du pick mode pour multiplex
- Signal `channelSelected(name, url, logo, group)` → PlayerPage ou Main.qml
- Bouton "Fermer" / Escape pour fermer

### Étape 6 — Main.qml
- Nouveau `TabBar` : `[Toutes les chaînes] [Groupes] [Favoris]`
- Toolbar : titre + bouton `⚙️` qui ouvre `AdminDialog`
- `showPlayer` : alterne entre `PlayerPage` (overlay plein écran) et la navigation
- `handleChannelSelected` : met à jour le slot + `showPlayer = true`
- `stopPlayback` : vide les slots + `showPlayer = false`
- Garder les signaux/slots et la logique existante

### Étape 7 — AGENTS.md
- Mettre à jour la liste des fichiers QML
- Ajouter les nouveaux fichiers

---

## Détails techniques

### GroupsPage — navigation drill-down
- Deux états : `groupList` et `channelList`
- En mode `groupList` : GridView des groupes
- En mode `channelList` : header avec retour + GridView des chaînes filtrées par `ChannelListModel.filterGroup = selectedGroup`
- Utiliser le même ChannelListModel (pas besoin de nouveau modèle)

### ChannelSearchPopup — intégration avec le player
- Quand ouvert depuis PlayerPage, doit permettre de choisir une chaîne et de la lancer immédiatement dans le slot actif
- En mode multiplex (pick mode) : le popup doit rester ouvert après sélection pour permettre de remplir plusieurs slots

### AdminDialog — réutilisation
- Reprendre le contenu exact des pages Playlists et Settings actuelles
- `PlaylistDialog` reste indépendant (appelé depuis l'AdminDialog)
- `SettingsPage.qml` peut être supprimé après migration (ou gardé comme fichier inutilisé)

### Gestion du multiplex dans PlayerPage
- Reprendre `multiplexMode`, `activeAudioSlot`, `pendingPickSlot`, `slotChannels`
- Les propriétés sont remontées dans Main.qml (comme actuellement)
- PlayerPage expose les mêmes signaux que les PlayerSlot actuels utilisent

---

## Flux utilisateur

### Parcours "Regarder une chaîne"
1. Navigation visible, player caché
2. Onglet "All Channels" ou "Groups" ou "Favorites"
3. Clic sur une chaîne → `handleChannelSelected()` → `showPlayer = true`
4. PlayerPage apparaît en plein écran, lit la chaîne
5. Pour changer de chaîne : clic sur `≡` → ChannelSearchPopup → sélection → chaîne change
6. Pour fermer : clic sur `X` → retour à la navigation

### Parcours "Administration"
1. Navigation visible
2. Clic sur ⚙️ dans la toolbar → `showAdmin = true` → AdminPage remplace la navigation
3. Navigation par onglets Playlists / Settings
4. Clic sur ← → `showAdmin = false` → retour à la navigation

### Parcours "Multiplex"
1. Ouvrir une première chaîne → player s'affiche
2. Clic `≡` → ChannelSearchPopup → sélection pour slot 0
3. Changer mode multiplex à 2 (bouton dans overlay)
4. Slot 1 apparaît vide avec `+`
5. Clic `+` → ChannelSearchPopup en pick mode → sélection pour slot 1
6. etc.
