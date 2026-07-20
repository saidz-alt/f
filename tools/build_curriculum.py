#!/usr/bin/env python3
"""Build Kabylingo's curriculum.json from the Tatoeba French-Kabyle export.

Source: KabyleAI/KabTatoebaCorpus  (Tatoeba.org open data, CC-BY 2.0)
Format of fra_kab.txt:  <french>\t<kabyle>

Everything Kabyle here is a real human translation pulled from Tatoeba:
  * WORDS  - curated French nouns/interjections (each with an emoji) matched to
             their Kabyle word, pooled into picture/listen/text lessons.
  * PHRASES- curated everyday French sentences matched to their Kabyle, used by
             word-bank / listen / text lessons.
Unmatched items are dropped; nothing is machine-translated or invented.
Kabyle text is normalized (Greek γ/ε -> Latin ɣ/ɛ) for consistent rendering.

Usage:
    # 1. Download the Tatoeba French-Kabyle export next to this script:
    curl -L -o fra_kab.txt \\
      https://raw.githubusercontent.com/KabyleAI/KabTatoebaCorpus/main/fra_kab.txt
    # 2. Regenerate the bundled curriculum:
    python3 tools/build_curriculum.py
Override the input/output paths with the FRA_KAB_TSV / CURRICULUM_OUT env vars.
"""
import json
import os
import re
import sys
from collections import defaultdict

_HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.environ.get("FRA_KAB_TSV", os.path.join(_HERE, "fra_kab.txt"))
OUT = os.environ.get(
    "CURRICULUM_OUT",
    os.path.join(_HERE, "..", "assets", "curriculum", "curriculum.json"),
)

# Interjections / greetings (usually appear as one-word sentences).
GREETINGS = {
    "bonjour": "👋", "merci": "🙏", "oui": "✅", "non": "❌",
    "bonsoir": "🌆", "peut-être": "🤔",
}

# Concrete, imageable nouns. Only those Tatoeba can isolate survive; they are
# pooled (in this order) into picture lessons of six.
NOUN_EMOJI = {
    "chat": "🐈", "chien": "🐕", "cheval": "🐴", "oiseau": "🐦",
    "poisson": "🐟", "lion": "🦁", "mouton": "🐑", "âne": "🫏",
    "soleil": "☀️", "lune": "🌙", "ciel": "🌌", "eau": "💧",
    "feu": "🔥", "mer": "🌊", "arbre": "🌳", "fleur": "🌸",
    "pain": "🍞", "lait": "🥛", "orange": "🍊", "pomme": "🍎",
    "œuf": "🥚", "miel": "🍯", "café": "☕", "viande": "🥩",
    "mère": "👩", "père": "👨", "fille": "👧", "garçon": "👦",
    "homme": "👨", "femme": "👩", "enfant": "🧒", "roi": "🤴",
    "maison": "🏠", "porte": "🚪", "livre": "📖", "clé": "🔑",
    "voiture": "🚗", "école": "🏫", "ville": "🏙️", "fenêtre": "🪟",
    "travail": "🛠️", "chemin": "🥾", "table": "🍽️", "route": "🛣️",
    "tête": "🧠", "main": "✋", "pied": "🦶", "œil": "👁️",
    "cœur": "❤️", "dent": "🦷", "bouche": "👄", "nez": "👃",
    "jour": "📅", "nuit": "🌙", "argent": "💰", "chose": "📦",
}
NOUN_LESSON_TITLES = [
    ("Premiers mots", "Imeslayen imezwura", "star", "#1CB0F6"),
    ("Mots utiles", "Imeslayen iɣawasen", "star", "#CE82FF"),
    ("Encore des mots", "Ugar n imeslayen", "star", "#FF86D0"),
    ("Le vocabulaire", "Ammud n wawalen", "star", "#58A700"),
]

PHRASE_LESSONS = [
    ("u_polite", "Politesse", "Leqder", "#FFC800", "wave", [
        "Merci beaucoup.", "Au revoir.", "À demain.", "À bientôt.",
        "Bonne nuit.", "Bienvenue !", "Bonne chance !", "De rien.",
        "S'il te plaît.", "Excuse-moi.", "Félicitations !", "Bravo !",
    ]),
    ("u_questions", "Les questions", "Isteqsiyen", "#1CB0F6", "wave", [
        "Ça va ?", "Comment vas-tu ?", "Où es-tu ?", "Qui es-tu ?",
        "Tu comprends ?", "Tu parles français ?", "Quelle heure est-il ?",
        "Que fais-tu ?", "Où est la maison ?", "Comment tu t'appelles ?",
    ]),
    ("u_daily", "Le quotidien", "Amur n wass", "#FF9600", "family", [
        "J'ai faim.", "J'ai soif.", "Je suis fatigué.", "Je suis content.",
        "J'ai froid.", "Il fait froid.", "Il pleut.", "Il fait beau.",
        "Je t'aime.", "C'est bon.", "Viens ici.", "Écoute-moi.",
        "Regarde !", "Assieds-toi.", "Je ne sais pas.", "Aide-moi.",
    ]),
]

ARTICLES = ["", "le ", "la ", "les ", "l'", "un ", "une ", "du ", "de la ",
            "c'est un ", "c'est une ", "c'est le ", "c'est la ",
            "voici ", "voilà "]


def norm(s):
    s = s.strip().lower()
    s = re.sub(r"\s+", " ", s)
    s = re.sub(r"\s*([?!.…,])", r"\1", s)
    s = re.sub(r"[.!?…]+$", "", s).strip()
    return s


def norm_kab(s):
    # Tatoeba mixes Greek gamma/epsilon with the Latin Berber letters; unify.
    return (s.replace("γ", "ɣ").replace("Γ", "Ɣ")
             .replace("ε", "ɛ").replace("Ε", "Ɛ"))


def clean_tokens(text):
    out = []
    for t in re.split(r"\s+", text.strip()):
        t = t.strip(".,!?…;:«»\"()")
        if t:
            out.append(t)
    return out


def strip_end(s):
    return re.sub(r"\s*([?!.])", r"\1", s).strip()


def main():
    pairs = []
    with open(SRC, encoding="utf-8") as f:
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) >= 2 and p[0].strip() and p[1].strip():
                pairs.append((p[0].strip(), norm_kab(p[1].strip())))
    print(f"loaded {len(pairs)} pairs", file=sys.stderr)

    index = defaultdict(list)
    for fr, kab in pairs:
        index[norm(fr)].append((fr, kab))
    for k in index:
        index[k].sort(key=lambda p: len(p[1]))

    def lookup(french):
        key = norm(french)
        return index[key][0] if key in index else None

    def find_word(french):
        for art in ARTICLES:
            hit = lookup(art + french)
            if hit:
                kab = re.sub(r"[.!?…]+$", "", hit[1]).strip()
                # Drop a leading predicative "d " ("c'est ...").
                kab = re.sub(r"^[Dd]\s+", "", kab).strip()
                if 1 <= len(kab.split()) <= 2 and len(kab) <= 18:
                    return kab
        return None

    def resolve_words(candidates):
        out, used = [], set()
        for french, emoji in candidates.items():
            kab = find_word(french)
            if not kab or kab.lower() in used:
                continue
            used.add(kab.lower())
            out.append({"kab": kab, "fr": french, "emoji": emoji})
        return out

    units = []

    # --- Greetings vocab lesson ---
    greet = resolve_words(GREETINGS)
    if len(greet) >= 4:
        for i, w in enumerate(greet):
            w["id"] = f"w_greet_{i}"
        units.append({
            "id": "u_greeting", "title_fr": "Salutations", "title_kab": "Azul",
            "theme": "greeting", "color": "#58CC02",
            "lessons": [{"id": "u_greeting_l1", "title_fr": "Salutations",
                         "title_kab": "Azul", "icon": "greeting", "xp": 10,
                         "words": greet, "phrases": []}],
        })

    # --- Pool concrete nouns, chunk into lessons of six ---
    nouns = resolve_words(NOUN_EMOJI)
    print(f"nouns resolved: {len(nouns)}", file=sys.stderr)
    chunks = [nouns[i:i + 6] for i in range(0, len(nouns), 6)]
    chunks = [c for c in chunks if len(c) >= 4]
    for ci, chunk in enumerate(chunks):
        tf, tk, icon, color = NOUN_LESSON_TITLES[ci % len(NOUN_LESSON_TITLES)]
        for i, w in enumerate(chunk):
            w["id"] = f"w_noun{ci}_{i}"
        units.append({
            "id": f"u_words{ci}", "title_fr": tf, "title_kab": tk,
            "theme": "olive", "color": color,
            "lessons": [{"id": f"u_words{ci}_l1", "title_fr": tf,
                         "title_kab": tk, "icon": icon, "xp": 10,
                         "words": chunk, "phrases": []}],
        })

    # --- Phrase lessons ---
    p_hits = p_total = 0
    for uid, tf, tk, color, icon, sentences in PHRASE_LESSONS:
        phrases, seen = [], set()
        for fr in sentences:
            p_total += 1
            hit = lookup(fr)
            if not hit:
                continue
            fr_d, kab_d = strip_end(hit[0]), strip_end(hit[1])
            tfr, tkab = clean_tokens(fr_d), clean_tokens(kab_d)
            if not (1 <= len(tkab) <= 6) or not tfr or kab_d in seen:
                continue
            seen.add(kab_d)
            p_hits += 1
            phrases.append({"id": f"{uid}_p{len(phrases)}", "kab": kab_d,
                            "fr": fr_d, "tokens_kab": tkab, "tokens_fr": tfr})
        if len(phrases) >= 4:
            units.append({
                "id": uid, "title_fr": tf, "title_kab": tk,
                "theme": "greeting", "color": color,
                "lessons": [{"id": f"{uid}_l1", "title_fr": tf, "title_kab": tk,
                             "icon": icon, "xp": 15, "words": [],
                             "phrases": phrases}],
            })
    print(f"phrases: {p_hits}/{p_total} sourced", file=sys.stderr)

    curriculum = {
        "version": 2,
        "_note": (
            "Content built from the Tatoeba French-Kabyle corpus "
            "(KabyleAI/KabTatoebaCorpus, Tatoeba.org open data, CC-BY 2.0). "
            "Every Kabyle string is a real human translation from Tatoeba "
            "(Greek γ/ε normalized to Latin ɣ/ɛ); emoji are added by Kabylingo."
        ),
        "units": units,
    }
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(curriculum, f, ensure_ascii=False, indent=2)
    tw = sum(len(l["words"]) for u in units for l in u["lessons"])
    tp = sum(len(l["phrases"]) for u in units for l in u["lessons"])
    print(f"units={len(units)} words={tw} phrases={tp}", file=sys.stderr)


if __name__ == "__main__":
    main()
