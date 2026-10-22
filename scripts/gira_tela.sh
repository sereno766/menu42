#!/usr/bin/env bash
# gira_tela.sh - fica girando a tela em intervalos
# Uso: ./gira_tela.sh        (inicia)
#      ./gira_tela.sh stop   (para e volta ao normal)

INTERVALO=10     # segundos entre cada giro (evite menos de 1s)
PIDFILE="/tmp/gira_tela_${USER}.pid"

command -v xrandr >/dev/null || { echo "Instale: sudo apt install x11-xserver-utils"; exit 1; }

# Monitores conectados
MONITORES=$(xrandr | awk '/ connected/ {print $1}')

voltar_normal() {
    for m in $MONITORES; do
        xrandr --output "$m" --rotate normal 2>/dev/null
    done
    rm -f "$PIDFILE"
}

if [ "$1" = "stop" ]; then
    [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null
    voltar_normal
    echo "Tela restaurada."
    exit 0
fi

if [ "${XDG_SESSION_TYPE}" = "wayland" ]; then
    echo "Sessão Wayland detectada: o xrandr não funciona aqui. Veja as alternativas abaixo."
    exit 1
fi

trap 'voltar_normal; exit 0' INT TERM
echo $$ > "$PIDFILE"
echo "Girando a tela. Para parar: $0 stop"

while true; do
    for orientacao in left inverted right normal; do
        for m in $MONITORES; do
            xrandr --output "$m" --rotate "$orientacao" 2>/dev/null
        done
        sleep "$INTERVALO"
    done
done