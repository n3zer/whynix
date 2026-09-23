#!/usr/bin/env python3
# Applies visual edits to the writable niri binds. Two copies are kept in sync:
#   --live  ~/.local/state/niri/binds.user.kdl   (what niri actually reads)
#   --repo  ~/dotfiles/home/config/niri/binds.user.kdl  (git-tracked source)
#
# niri includes binds.user.kdl from binds.kdl and watches included files, so a
# write here live-reloads the compositor — no rebuild required. Repo copy is
# kept identical so the change is also captured for git / future rebuilds.
#
# usage:
#   patch_niri_binds.py --live <path> --repo <path> '<json ops>'
#
# ops: [ {"combo":"Mod+T","mods":"SUPER","key":"L"},   # rebind (new combo)
#        {"combo":"Mod+T","unbind":true},              # remove bind
#        {"combo":"Mod+T","restoreCombo":"Mod+U"} ]    # back to default combo
#
# "combo" is matched case-insensitively against the first token of each bind
# line (i.e. the combo before any allow-when-locked / flags / braces).
import json, os, re, sys

_MOD_TO_NIRI = {
    "SUPER": "Mod", "CTRL": "Ctrl", "ALT": "Alt", "SHIFT": "Shift",
}
_KEY_TO_NIRI = {
    # shell/Qt capture name → niri key name
    "(space)":             "Space",
    "minus":               "Minus",
    "equal":               "Equal",
    "bracketleft":         "BracketLeft",
    "bracketright":        "BracketRight",
    "backslash":           "Backslash",
    "semicolon":           "Semicolon",
    "apostrophe":          "Apostrophe",
    "comma":               "Comma",
    "period":              "Period",
    "slash":               "Slash",
    "quoteleft":           "Grave",
    "Prior":               "Page_Up",
    "Next":                "Page_Down",
    "Scroll":              "Scroll_Lock",
    "Num_Lock":            "Num_Lock",
    "Return":              "Return",
    "Escape":              "Escape",
    "Tab":                 "Tab",
    "Backspace":           "BackSpace",
    "Delete":              "Delete",
    "Insert":              "Insert",
    "Home":                "Home",
    "End":                 "End",
    "Left":                "Left",
    "Right":               "Right",
    "Up":                  "Up",
    "Down":                "Down",
    "Pause":               "Pause",
    "Print":               "Print",
    "Space":               "Space",
}

def to_niri_combo(mods_shell, key_shell):
    mods = []
    for p in re.split(r"\s*\+\s*", (mods_shell or "").strip()):
        p = p.strip().upper()
        if p in _MOD_TO_NIRI:
            mods.append(_MOD_TO_NIRI[p])
    key = _KEY_TO_NIRI.get(key_shell, key_shell)
    return "+".join(mods + [key])

def _combo_of(combo_token):
    """Normalize a combo token (e.g. 'Mod+T', '%Super+1', 'F9') for matching."""
    s = combo_token.lstrip("%").strip()
    return s.upper().replace(" ", "")

def main():
    args = sys.argv[1:]
    live = repo = None
    if "--live" in args:
        live = args[args.index("--live") + 1]
    if "--repo" in args:
        repo = args[args.index("--repo") + 1]
    ops = json.loads(sys.argv[-1]) if sys.argv[-1].startswith("[") else []

    def read(path):
        if not path or not os.path.isfile(path):
            return []
        with open(path, encoding="utf-8") as f:
            return f.read().splitlines()

    lines = read(live) or read(repo) or []
    # Annotate each line with its leading combo for stable lookup.
    annotated = []
    for ln in lines:
        s = ln.strip()
        combo = ""
        m = re.match(r"^([^\s{]+)", s)
        if m and not s.startswith(("//", "binds")) and "{" in s:
            combo = m.group(1)
        annotated.append({"line": ln, "combo": _combo_of(combo), "orig": combo})

    for op in ops:
        target = _combo_of(op.get("combo", ""))
        if not target:
            continue
        if op.get("unbind"):
            # drop first matching line
            for i, a in enumerate(annotated):
                if a["combo"] == target:
                    annotated[i] = None
                    break
        elif "mods" in op or "restoreCombo" in op:
            new_combo = op.get("restoreCombo")
            if not new_combo:
                new_combo = to_niri_combo(op.get("mods", ""), op.get("key", ""))
            for i, a in enumerate(annotated):
                if a and a["combo"] == target:
                    a["line"] = re.sub(r"^(\s*)[^\s{]+", r"\1" + new_combo, a["line"], count=1)
                    a["combo"] = _combo_of(new_combo)
                    break

    out = [a["line"] for a in annotated if a]
    text = "\n".join(out) + "\n"
    for path in (live, repo):
        if not path:
            continue
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
    print("ok")

if __name__ == "__main__":
    main()
