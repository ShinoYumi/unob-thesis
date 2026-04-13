#import "@preview/palimset:0.1.0": *

// Porovnání dvou verzí práce.
// thesis-prev.typ = snapshot starší verze
// thesis.typ      = aktuální verze
// Zeleně = přidaný text, červeně = odebraný text.
#diff-content(
  include "thesis-prev.typ",
  include "thesis.typ"
)