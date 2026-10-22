#!/usr/bin/env bash
# terminais_ascii.sh - abre 20 terminais mostrando a arte ASCII do aviso.
# Uso: ./terminais_ascii.sh        (abre os terminais)
#      ./terminais_ascii.sh stop   (fecha todos)

QUANTIDADE=20
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
ART="$DIR/../recursos/bloquear_ascii.txt"
PIDFILE="/tmp/terminais_ascii_${USER}.pid"
TITULO="BLOQUEAR_PC_AO_SAIR"

# --- parar: fecha os terminais abertos antes ------------------------------
if [ "$1" = "stop" ]; then
    if [ -f "$PIDFILE" ]; then
        while read -r pid; do
            kill "$pid" 2>/dev/null
        done < "$PIDFILE"
        rm -f "$PIDFILE"
    fi
    # Rede de seguranca: fecha por titulo tambem
    pkill -f "$TITULO" 2>/dev/null
    echo "Terminais fechados."
    exit 0
fi

[ -f "$ART" ] || { echo "Arte nao encontrada: $ART" >&2; exit 1; }

# --- escolhe um terminal disponivel ---------------------------------------
TERM_BIN=""
for t in gnome-terminal terminator xfce4-terminal mate-terminal konsole xterm; do
    if command -v "$t" >/dev/null 2>&1; then
        TERM_BIN="$t"
        break
    fi
done
[ -n "$TERM_BIN" ] || { echo "Nenhum terminal grafico encontrado." >&2; exit 1; }

# Tamanho da tela (para espalhar as janelas em posicoes aleatorias)
RES="$(xrandr 2>/dev/null | awk '/\*/{print $1; exit}')"
SCREEN_W="${RES%x*}"; SCREEN_H="${RES#*x}"
[ -n "$SCREEN_W" ] || SCREEN_W=1920
[ -n "$SCREEN_H" ] || SCREEN_H=1080

# Dimensiona o terminal pela propria arte, para garantir que ela caiba.
# Mede a maior largura e o numero de linhas do arquivo e soma uma margem.
ART_COLS=$(awk '{ if (length > m) m = length } END { print m }' "$ART")
ART_LINES=$(wc -l < "$ART")
COLS=$(( ART_COLS + 4 ))     # tamanho em caracteres (gnome/xterm/etc.)
LINES=$(( ART_LINES + 3 ))

# Tamanho aproximado da janela em pixels (fonte monospace ~9x19 px)
JAN_W=$(( COLS * 9 ))
JAN_H=$(( LINES * 19 ))

# Comando que roda dentro de cada terminal: mostra a arte e mantem a janela
# aberta sem abrir um shell interativo (evita prompt e mensagens de inicio).
INNER='cat "$0"; exec sleep infinity'

abrir_um() {
    # Posicao aleatoria dentro da tela
    local maxx=$(( SCREEN_W - JAN_W )); [ "$maxx" -lt 0 ] && maxx=0
    local maxy=$(( SCREEN_H - JAN_H )); [ "$maxy" -lt 0 ] && maxy=0
    local px=$(( RANDOM % (maxx + 1) ))
    local py=$(( RANDOM % (maxy + 1) ))
    local geo="${COLS}x${LINES}+${px}+${py}"      # geometria estilo X
    local geopx="${JAN_W}x${JAN_H}+${px}+${py}"   # variantes em pixels

    case "$TERM_BIN" in
        gnome-terminal)
            gnome-terminal --geometry="$geo" --title="$TITULO" \
                -- bash -c "$INNER" "$ART" &
            ;;
        terminator)
            terminator --geometry="$geopx" -T "$TITULO" \
                -x bash -c "$INNER" "$ART" &
            ;;
        xfce4-terminal)
            xfce4-terminal --geometry="$geo" --title="$TITULO" \
                -x bash -c "$INNER" "$ART" &
            ;;
        mate-terminal)
            mate-terminal --geometry="$geo" --title="$TITULO" \
                -- bash -c "$INNER" "$ART" &
            ;;
        konsole)
            konsole -p tabtitle="$TITULO" -e bash -c "$INNER" "$ART" &
            ;;
        xterm)
            xterm -geometry "$geo" -T "$TITULO" -fa Monospace -fs 10 \
                -e bash -c "$INNER" "$ART" &
            ;;
    esac
    echo $! >> "$PIDFILE"
}

: > "$PIDFILE"
echo "Abrindo $QUANTIDADE terminais com $TERM_BIN..."
i=0
while [ "$i" -lt "$QUANTIDADE" ]; do
    abrir_um
    i=$((i + 1))
done
echo "Pronto. Para fechar todos: $0 stop"
