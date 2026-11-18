# MISTFALL — prototipo Godot 4

Nome del gioco: **MISTFALL**. Prototipo 3D giocabile, non è ancora un APK né il gioco completo.

## Contenuto
- ambiente 3D di jungla con passerelle sopraelevate e avamposto;
- personaggio in terza persona;
- controlli touch: trascina sul lato sinistro per muoverti, sul destro per ruotare la visuale, pulsante SALTA;
- nebbie tossiche e tre rifornimenti raccoglibili.

## Aprire il progetto
Importa questa cartella in Godot 4.x (renderer Compatibility / GL Compatibility) e avvia `Main.tscn`.

## Build Android
Il repository include `export_presets.cfg` e `.github/workflows/android.yml` per tentare una build APK tramite GitHub Actions. Dopo aver caricato l'intero contenuto di questa cartella nella root del repository sul branch `main`, apri Actions > Build Android APK > Run workflow. Se termina con successo, scarica l'artefatto `MISTFALL-Android-APK`.

La build cloud dipende dalla compatibilità dell'immagine Godot CI e dai template Android. Il workflow potrebbe richiedere correzioni in base al log. I minuti GitHub Actions gratuiti hanno limiti. L'APK di debug è per test, non per pubblicazione sul Play Store.

## Controlli PC
WASD per muoversi, Spazio per saltare.
