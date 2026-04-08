#!/usr/bin/env python3
import subprocess
import re
import os
import unicodedata

def build_keysym_database():
    keysym_to_char = {}
    paths = ["/usr/include/X11/keysymdef.h", "/usr/include/X11/XF86keysym.h"]
    
    keysym_re = re.compile(r'#define\s+XK_([a-zA-Z_0-9]+)\s+0x([0-9a-fA-F]+)')
    unicode_re = re.compile(r'U\+([0-9a-fA-F]{4,6})')

    for path in paths:
        if not os.path.exists(path): continue
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                match = keysym_re.search(line)
                if match:
                    name, hex_val = match.groups()
                    uni_match = unicode_re.search(line)
                    if uni_match:
                        keysym_to_char[name] = chr(int(uni_match.group(1), 16))
                    elif int(hex_val, 16) < 0x100:
                        keysym_to_char[name] = chr(int(hex_val, 16))
    dead_keys = {
        "dead_acute": "\u0301",        # Combining Acute Accent
        "dead_grave": "\u0300",        # Combining Grave Accent
        "dead_tilde": "\u0303",        # Combining Tilde
        "dead_circumflex": "\u0302",   # Combining Circumflex Accent
        "dead_diaeresis": "\u0308",    # Combining Diaeresis
        "dead_cedilla": "\u0327",      # Combining Cedilla
        "dead_caron": "\u030c",        # Combining Caron
        "dead_breve": "\u0306",        # Combining Breve
        "dead_abovering": "\u030a",    # Combining Ring Above
        "dead_doubleacute": "\u030b",  # Combining Double Acute Accent
        "dead_belowdot": "\u0323",     # Combining Dot Below
        "dead_ogonek": "\u0328",       # Combining Ogonek
        "dead_abovedot": "\u0307",     # Combining Dot Above
        "dead_macron": "\u0304",       # Combining Macron
        "space": "\u0020"              # Standard Space
    }

    keysym_to_char.update(dead_keys)
    return keysym_to_char

KEYSYM_DB = build_keysym_database()

def sanitize_char(c):
    if not c or not isinstance(c, str) or len(c) != 1:
        return c if c else " "
    if unicodedata.combining(c):
        return f" ◌{c} " 
    return c

def get_char(sym):
    if not sym or sym == "NoSymbol": return " "
    if sym.startswith("U") and len(sym) >= 5:
        try:
            return sanitize_char(chr(int(sym[1:], 16)))
        except: pass
    char = KEYSYM_DB.get(sym, sym if len(sym) == 1 else " ")
    return sanitize_char(char)

# Alphanumeric block
LAYOUT_ROWS = [
    [49, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21], 
    [24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35],     
    [38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 51],     
    [94, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61]          
]

# Numpad block (Standard PC layout)
NUMPAD_ROWS = [
    [106, 63, 82], # [NL] / * -
    [79, 80, 81, 86],   # 7 8 9 +
    [83, 84, 85, 129],  # 4 5 6 .
    [87, 88, 89],  # 1 2 3 [Enter]
    [90, 91]            # 0 .
]

def render_section(row_list, key_data):
    for row in row_list:
        lines = ["", "", "", "", ""]
        for kc in row:
            k, sk, ak, ask = key_data.get(kc, (" ", " ", " ", " "))
            lines[0] += "┌───┬───┐ "
            lines[1] += f"│{sk:^3}│{ask:^3}│ "
            lines[2] += "├───┼───┤ "
            lines[3] += f"│{k:^3}│{ak:^3}│ "
            lines[4] += "└───┴───┘ "
        for l in lines: print(l)
        print()

def render():
    key_data = {}
    try:
        raw = subprocess.check_output(["xmodmap", "-pke"], text=True)
    except FileNotFoundError:
        print("Error: xmodmap not found. Please install x11-xserver-utils.")
        return

    for line in raw.splitlines():
        p = line.split()
        if len(p) < 4: continue
        kc = int(p[1])
        s = p[3:]
        key_data[kc] = (
            get_char(s[0]), 
            get_char(s[1]) if len(s) > 1 else " ", 
            get_char(s[4]) if len(s) > 4 else " ", 
            get_char(s[5]) if len(s) > 5 else " "
        )

    print("--- ALPHANUMERIC BLOCK ---")
    render_section(LAYOUT_ROWS, key_data)
    
    print("--- NUMERIC KEYPAD ---")
    render_section(NUMPAD_ROWS, key_data)

if __name__ == "__main__":
    render()
