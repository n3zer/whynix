#!/usr/bin/env python3
# Parses the live niri binds file into a JSON list of bindings for the
# Brain_Shell keybinds page. Output schema:
#   [{"combo": "Mod+Shift+T", "mods": "SUPER + SHIFT", "key": "T",
#     "action": "spawn", "args": "kitty", "comment": "..."}]
#
# Priority for the source file:
#   1. argv[1] if given
#   2. ~/.local/state/niri/binds.user.kdl   (writable, live-edited by the UI)
#   3. ~/.config/niri/binds.kdl             (store copy, pre-user-file fallback)
import os, json, re, sys

_DEFAULT = os.path.expanduser("~/.local/state/niri/binds.user.kdl")
_FALLBACK = os.path.expanduser("~/.config/niri/binds.kdl")

# shell-style modifier normalization (niri Mod/Ctrl/Alt/Shift -> SUPER/CTRL/ALT/SHIFT)
_MOD_MAP = {
    "MOD": "SUPER", "SUPER": "SUPER", "META": "SUPER",
    "CTRL": "CTRL", "CONTROL": "CTRL",
    "ALT": "ALT", "SHIFT": "SHIFT",
}

# One niri bind:  Mod+Shift+T  allow-when-locked=true  { spawn "x"; }  // comment
# Tokens before the braces can include modifiers + key and optional flags.
BIND_RE = re.compile(
    r"^\s*(?P<combo>%?\w+(?:\s*\+\s*[\w%]+)*)\s*"
    r"(?P<flags>[^\{]*?)?\s*\{\s*(?P<action>\S+)\s*(?P<args>[^\}]*?)\s*\}\s*"
    r"(?://\s*(?P<comment>.*))?\s*$"
)

def parse_combo(combo):
    """'Mod+Shift+Slash' / 'F9' / '%Super+1' → (mods, key) shell-style.
    Mods are joined with ' + ' and normalized to SUPER/CTRL/ALT/SHIFT."""
    raw = combo.replace("%", "").strip()
    parts = [p.strip() for p in raw.split("+") if p.strip()]
    if not parts:
        return "", ""
    key = parts[-1]
    mods = " + ".join(_MOD_MAP.get(p.upper(), p.upper()) for p in parts[:-1])
    return mods, key

def read_binds(path):
    if not os.path.isfile(path):
        return []
    binds = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            s = line.strip()
            if not s or s.startswith(("//", "binds")):
                continue
            m = BIND_RE.match(s)
            if not m:
                continue
            combo = m.group("combo").strip()
            action = (m.group("action") or "").strip().rstrip(";").strip()
            args = (m.group("args") or "").strip().rstrip(";").strip().strip('"')
            comment = (m.group("comment") or "").strip()
            mods, key = parse_combo(combo)
            if not key or not action:
                continue
            # label = trailing comment when present, else fall back to action
            if comment:
                label = comment
            elif args:
                label = action + " " + args
            else:
                label = action
            binds.append({
                "combo": combo,
                "mods": mods,
                "key": key,
                "action": action,
                "args": args,
                "comment": comment,
                "label": label,
            })
    return binds

def main():
    path = None
    if len(sys.argv) > 1:
        path = sys.argv[1]
    if not path or not os.path.isfile(path):
        path = _DEFAULT if os.path.isfile(_DEFAULT) else _FALLBACK
    binds = read_binds(path)
    print(json.dumps(binds, ensure_ascii=False))

if __name__ == "__main__":
    main()