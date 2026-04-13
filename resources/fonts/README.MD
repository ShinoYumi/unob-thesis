# Fonts for UNOB Thesis Template

Tato složka slouží pro lokální uložení fontů používaných šablonou:
- `TeX Gyre Termes`
- `TeX Gyre Termes Math`

## Download URL

- TeX Gyre Termes (OTF):  
  https://www.gust.org.pl/projects/e-foundry/tex-gyre/termes/qtm2.004otf.zip
- TeX Gyre Termes Math:  
  https://www.gust.org.pl/projects/e-foundry/tg-math/download/texgyretermes-math-1543.zip

## Jednoduchý postup

1. Spusť automatický setup:

```sh
make get-fonts
```

Windows (PowerShell):

```powershell
make get-fonts
```

2. Alternativně ručně stáhni oba ZIP soubory, rozbal je a zkopíruj `.otf` soubory do `resources/fonts/`.

3. Kompiluj s explicitní cestou na fonty:

```sh
typst compile --root . --font-path resources/fonts template/thesis.typ build/thesis.pdf
```

## Poznámka

Pokud máš fonty nainstalované systémově, `--font-path` není nutný.
