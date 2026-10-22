#!/usr/bin/env bash
# menu.sh - lancador do menu: encontra um Python que tenha tkinter e abre menu.py.
# Resolve o problema de /usr/bin/python3 nao ter tkinter enquanto o do pyenv tem.

DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# Tenta, em ordem, candidatos a Python com tkinter. O 'import tkinter' garante
# que so vamos usar um que realmente funcione (ignora os que nao tem).
for py in \
    python3 \
    "$HOME/.pyenv/shims/python3" \
    /opt/pyenv/shims/python3 \
    /usr/local/bin/python3 \
    python; do
    if command -v "$py" >/dev/null 2>&1 && "$py" -c "import tkinter" 2>/dev/null; then
        exec "$py" "$DIR/menu.py" "$@"
    fi
done

# Nenhum Python com tkinter encontrado: avisa da forma que der.
MSG="Nenhum Python com tkinter encontrado.
Instale com: sudo apt install python3-tk"
if command -v zenity >/dev/null 2>&1; then
    zenity --error --no-wrap --text="$MSG"
else
    echo "$MSG" >&2
fi
exit 1
