# UNOB Thesis Template

## Česky

Oficiální šablona pro psaní bakalářských, diplomových a disertačních prací na Univerzitě obrany. Šablona je navržena tak, aby pokryla všechny univerzitní fakulty (`fvl`, `fvt`, `vlf`, `uo`). Pokud tvoje fakulta nebo katedra vyžaduje další lokální úpravy, přizpůsob konfiguraci podle vlastních směrnic.

## Použití

### Webová aplikace

Klikni na **Create project in app** na stránce [balíčku](https://typst.app/universe/package/unob-thesis) a vytvoř nový projekt ve webové aplikaci.

### Lokálně

Nainstaluj [Typst compiler](https://typst.app/open-source/).

Spuštěním následujícího příkazu inicializuj projekt v novém adresáři:

```bash
typst init @preview/unob-thesis:1.0.0
```

Pak přejdi do adresáře projektu a spusť průběžnou kompilaci:

```bash
cd unob-thesis
typst watch thesis.typ
```

Pokud chceš celý repozitář včetně build skriptů, testů a přiložených zdrojů, naklonuj projekt přímo z repozitáře:

```bash
git clone https://github.com/ShinoYumi/unob-typst-template.git
cd unob-typst-template
make pdf
```

Jednodušší alternativou pro lokální práci může být rozšíření [Tinymist](https://marketplace.visualstudio.com/items?itemName=myriad-dreamin.tinymist) pro [VS Code](https://code.visualstudio.com/).

## Instalace fontů

Šablona používá rodinu TeX Gyre:

- `TeX Gyre Termes` pro hlavní text
- `TeX Gyre Termes Math` pro matematickou sazbu
- `TeX Gyre Cursor` pro sazbu kódu a výpisů

Přiložené skripty aktuálně připravují automaticky `TeX Gyre Termes` a `TeX Gyre Termes Math`. `TeX Gyre Cursor` je v šabloně nastaven s fallbackem, takže při jeho chybějící instalaci se dokument stále vysází, jen se může lišit vzhled výpisů.

Fonty můžeš nainstalovat systémově nebo je uložit lokálně do `resources/fonts`.

### Webová aplikace

Ve webové aplikaci obvykle nejsou potřeba žádné další kroky. Pokud se projekt vysází správně, není nutné fonty doplňovat ručně.

### Lokálně

Nejsnazší možnost je stáhnout fonty automaticky:

```bash
make get-fonts
```

Ve Windows můžeš použít i:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/get-fonts.ps1
```

Alternativně stáhni archivy ručně, rozbal je a zkopíruj `.otf` soubory do `resources/fonts/`:

- [TeX Gyre Termes](https://www.gust.org.pl/projects/e-foundry/tex-gyre/termes/qtm2.004otf.zip)
- [TeX Gyre Termes Math](https://www.gust.org.pl/projects/e-foundry/tg-math/download/texgyretermes-math-1543.zip)
- [TeX Gyre Cursor](https://www.gust.org.pl/projects/e-foundry/tex-gyre/cursor/tg_cursor-otf-2_609-31_03_2026.zip)

Pokud už máš fonty nainstalované v operačním systému, `--font-path` není potřeba.

## Konfigurace

Řiď se komentáři v `template/thesis.toml`. Hlavní volby zahrnují:

- jazyk dokumentu (`cs` nebo `en`)
- draft režim
- výběr fakulty (`fvl`, `fvt`, `vlf`, `uo`)
- typ práce (`bachelor`, `master`, `doctoral`)
- metadata práce, autora, vedoucího, konzultanta a případného školitele
- volitelné úvodní části a generované seznamy
- zdroj bibliografie (`bib` nebo `yml`) a citační styl (`numeric` nebo `harvard`)
- barevné přepínače pro odkazy, poznámky a fakultní akcentní barvy

Hlavní obsah práce patří do `template/thesis.typ`. Zkratky a pojmy jsou uložené v `template/glossary.toml`.

## Draft a final výstup

Proměnná `draft` v `template/thesis.toml` určuje, zda se dokument kompiluje v draft nebo final režimu.

Draft režim je určený pro samotné psaní. Zapíná draftové chování, například TODO poznámky a viditelné označení rozpracované verze.

Final režim je určený pro odevzdanou verzi.

Můžeš kompilovat podle hodnoty nastavené v `template/thesis.toml`:

```bash
make pdf
```

Nebo režim vynutit bez úpravy konfiguračního souboru:

```bash
make pdf TYPE=draft
make pdf TYPE=final
```

Vygenerované PDF se ukládá do `build/` a automaticky se pojmenuje podle aktuálního data, názvu práce a režimu. Build také udržuje `build/latest-draft.pdf` a `build/latest-final.pdf`.

## Titulní strana a úvodní části

Ve výchozím stavu šablona generuje titulní stranu a úvodní části automaticky z `template/thesis.toml` a metadata bloků v `template/thesis.typ`.

Úvodní části mohou zahrnovat:

- zadání práce
- poděkování
- čestné prohlášení
- prohlášení o použití AI
- český a anglický abstrakt
- klíčová slova
- úvod

Pokud některou část nepotřebuješ, vypni ji v odpovídající sekci `[lists]` v `template/thesis.toml`.

## Jak psát v Typstu?

Ukázková práce v `template/thesis.typ` demonstruje očekávanou strukturu a hlavní vlastnosti šablony, mimo jiné:

- metadata bloky pro úvodní části
- zkratky a pojmy přes `#trm(...)`
- TODO poznámky v draft režimu
- výpis bibliografie přes `#show-bibliography()`
- režim příloh přes `#show: annex`

Projekt také obsahuje znovupoužitelné moduly pro callouty, glosář, drafting podporu, lokalizované popisky a generování titulní strany podle fakulty.

## Dobrá praxe

- Udržuj zkratky a pojmy v `template/glossary.toml` a v textu je používej konzistentně.
- Pokud to jde, preferuj vektorovou grafiku, např. `.svg`.
- Před odevzdáním optimalizuj větší obrázky a další assety.
- Před finálním odevzdáním vygeneruj final PDF a zkontroluj seznamy, reference i úvodní části.
- Pokud chceš přísnější validaci, zapni `submit_check`, který kontroluje povinné nastavení před odevzdáním.

## Testování

Repozitář obsahuje regresní testy postavené na `tytanic`, které pokrývají draft/final režim, český i anglický výstup, chování glosáře, annex režim a stabilitu titulní strany.

Testy spustíš:

```bash
make test
```

Pokud `tt` není dostupné v `PATH`, nastav binárku explicitně:

```bash
TT=./.tools/tt scripts/test-phases.sh
```

## Problémy a příspěvky

Pokud narazíš na problém nebo chceš navrhnout vylepšení, otevři issue nebo pošli pull request do repozitáře projektu.

## Licence

Zdrojový kód šablony je distribuován pod licencí MIT. Podrobnosti jsou v souboru `LICENSE`.

## Důležité

Tento projekt obsahuje oficiální loga fakult a univerzity v `resources/logos/` pro generování titulní strany.

Ověř si, že jejich zamýšlené použití odpovídá pravidlům Univerzity obrany a požadavkům tvé fakulty.

Ukázkový obsah práce je pouze zástupný. Před formálním použitím šablony nahraď všechen dummy text, reference, položky glosáře a metadata vlastním ověřeným obsahem.

## Poděkování

Tato šablona vychází ze standardních konvencí Typst thesis templates a přizpůsobuje je workflow závěrečných prací na Univerzitě obrany.

---

## English

Official template for writing bachelor, master, and doctoral theses at the University of Defence. The template is designed to cover all university faculties (`fvl`, `fvt`, `vlf`, `uo`). If your faculty or department requires additional local adjustments, adapt the configuration to match your own guidelines.

## Usage

### Web app

Click **Create project in app** on the [package page](https://typst.app/universe/package/unob-thesis) and create a new project in the web app.

### Locally

Install the [Typst compiler](https://typst.app/open-source/).

Run the following command to initialize a project in a new directory:

```bash
typst init @preview/unob-thesis:1.0.0
```

Then go to the project directory and start continuous compilation:

```bash
cd unob-thesis
typst watch thesis.typ
```

If you want the full repository including build scripts, tests, and bundled resources, clone the project directly from the repository:

```bash
git clone https://github.com/ShinoYumi/unob-typst-template.git
cd unob-typst-template
make pdf
```

A simpler alternative for local work can be the [Tinymist](https://marketplace.visualstudio.com/items?itemName=myriad-dreamin.tinymist) extension for [VS Code](https://code.visualstudio.com/).

## Font installation

The template uses the TeX Gyre family:

- `TeX Gyre Termes` for the main text
- `TeX Gyre Termes Math` for mathematical typesetting
- `TeX Gyre Cursor` for code and listings

The bundled scripts currently prepare `TeX Gyre Termes` and `TeX Gyre Termes Math` automatically. `TeX Gyre Cursor` is configured in the template with a fallback, so the document will still compile if it is missing, but the appearance of code listings may differ.

You can install the fonts system-wide or store them locally in `resources/fonts`.

### Web app

In the web app, no extra steps are usually needed. If the project compiles correctly, there is no need to add the fonts manually.

### Locally

The easiest option is to download the fonts automatically:

```bash
make get-fonts
```

On Windows, you can also use:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/get-fonts.ps1
```

Alternatively, download the archives manually, extract them, and copy the `.otf` files into `resources/fonts/`:

- [TeX Gyre Termes](https://www.gust.org.pl/projects/e-foundry/tex-gyre/termes/qtm2.004otf.zip)
- [TeX Gyre Termes Math](https://www.gust.org.pl/projects/e-foundry/tg-math/download/texgyretermes-math-1543.zip)
- [TeX Gyre Cursor](https://www.gust.org.pl/projects/e-foundry/tex-gyre/cursor/tg_cursor-otf-2_609-31_03_2026.zip)

If the fonts are already installed in your operating system, `--font-path` is not needed.

## Configuration

Follow the comments in `template/thesis.toml`. The main options include:

- document language (`cs` or `en`)
- draft mode
- faculty selection (`fvl`, `fvt`, `vlf`, `uo`)
- thesis type (`bachelor`, `master`, `doctoral`)
- thesis metadata, author, supervisor, advisor, and optional co-supervisor
- optional frontmatter sections and generated lists
- bibliography source (`bib` or `yml`) and citation style (`numeric` or `harvard`)
- color switches for links, notes, and faculty accent colors

The main thesis content belongs in `template/thesis.typ`. Acronyms and glossary terms are stored in `template/glossary.toml`.

## Draft and final output

The `draft` variable in `template/thesis.toml` determines whether the document is compiled in draft mode or final mode.

Draft mode is intended for the writing phase. It enables draft-specific behavior such as TODO notes and visible marking of a work-in-progress version.

Final mode is intended for the submission version.

You can compile according to the value set in `template/thesis.toml`:

```bash
make pdf
```

Or force the mode without editing the configuration file:

```bash
make pdf TYPE=draft
make pdf TYPE=final
```

The generated PDF is written to `build/` and automatically named according to the current date, thesis title, and mode. The build also maintains `build/latest-draft.pdf` and `build/latest-final.pdf`.

## Title page and frontmatter

By default, the template generates the title page and frontmatter automatically from `template/thesis.toml` and the metadata blocks in `template/thesis.typ`.

The frontmatter sections can include:

- thesis assignment
- acknowledgement
- declaration
- AI usage statement
- Czech and English abstract
- keywords
- introduction

If you do not need a section, disable it in the corresponding `[lists]` section in `template/thesis.toml`.

## How to write in Typst?

The sample thesis in `template/thesis.typ` demonstrates the expected structure and the main template features, including:

- metadata blocks for frontmatter sections
- acronyms and glossary terms through `#trm(...)`
- TODO notes in draft mode
- bibliography output through `#show-bibliography()`
- annex mode through `#show: annex`

The project also contains reusable modules for callouts, glossary handling, drafting support, localized labels, and faculty-specific title page generation.

## Good practices

- Keep acronyms and glossary terms in `template/glossary.toml` and use them consistently in the text.
- Prefer vector graphics whenever possible, for example `.svg`.
- Optimize larger images and other assets before submission.
- Before the final submission, generate a final PDF and verify the lists, references, and frontmatter sections.
- If you want stricter validation, enable `submit_check`, which verifies required settings before submission.

## Testing

The repository includes `tytanic`-based regression tests that cover draft/final mode, Czech and English output, glossary behavior, annex mode, and title page stability.

Run the tests with:

```bash
make test
```

If `tt` is not available in `PATH`, set the binary explicitly:

```bash
TT=./.tools/tt scripts/test-phases.sh
```

## Problems and contributions

If you encounter a problem or want to suggest an improvement, open an issue or send a pull request to the project repository.

## License

The template source code is distributed under the MIT license. See the `LICENSE` file for details.

## Important

This project contains official faculty and university logos in `resources/logos/` for title page generation.

Make sure that their intended use complies with the rules of the University of Defence and the requirements of your faculty.

The sample thesis content is placeholder content only. Before any formal use of the template, replace all dummy text, references, glossary entries, and metadata with your own verified content.

## Acknowledgements

This template builds on standard Typst thesis-template conventions and adapts them to the University of Defence thesis workflow.
