#!/usr/bin/env bash
# bloqueia_clipboard.sh - impede copiar/colar limpando o clipboard continuamente
# Uso: ./bloqueia_clipboard.sh        (inicia o bloqueio)
#      ./bloqueia_clipboard.sh stop   (desfaz)

INTERVALO=0.3
PIDFILE="/tmp/bloqueia_clipboard_${USER}.pid"
SESSAO="${XDG_SESSION_TYPE:-x11}"
FRASE="NAO DEIXE DESBLOQUEADO SUA MAQUINA"

restaurar() {
    # Reativa a colagem com o botão do meio (GNOME/GTK)
    command -v gsettings >/dev/null && \
        gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true 2>/dev/null

    # Restaura o mapa de botões dos mouses (X11)
    if [ "$SESSAO" = "x11" ] && command -v xinput >/dev/null; then
        for id in $(xinput list | grep -i 'slave  pointer' | grep -o 'id=[0-9]*' | cut -d= -f2); do
            xinput set-button-map "$id" 1 2 3 2>/dev/null
        done
    fi
    rm -f "$PIDFILE"
}

if [ "$1" = "stop" ]; then
    [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null
    restaurar
    echo "Bloqueio removido."
    exit 0
fi

# Verifica dependências
if [ "$SESSAO" = "wayland" ]; then
    command -v wl-copy >/dev/null || { echo "Instale: sudo apt install wl-clipboard"; exit 1; }
else
    command -v xsel >/dev/null || { echo "Instale: sudo apt install xsel xinput"; exit 1; }
fi

# Desativa colagem com botão do meio (GNOME/GTK)
command -v gsettings >/dev/null && \
    gsettings set org.gnome.desktop.interface gtk-enable-primary-paste false 2>/dev/null

# Desativa o botão do meio em todos os mouses (X11)
if [ "$SESSAO" = "x11" ] && command -v xinput >/dev/null; then
    for id in $(xinput list | grep -i 'slave  pointer' | grep -o 'id=[0-9]*' | cut -d= -f2); do
        xinput set-button-map "$id" 1 0 3 2>/dev/null
    done
fi

trap 'restaurar; exit 0' INT TERM
echo $$ > "$PIDFILE"
echo "Bloqueio ativo (sessão: $SESSAO). Para parar: $0 stop"

# Loop que substitui qualquer conteúdo copiado pela frase fixa
while true; do
    if [ "$SESSAO" = "wayland" ]; then
        [ "$(wl-paste -n 2>/dev/null)" != "$FRASE" ] && \
            wl-copy -- "$FRASE" 2>/dev/null
        [ "$(wl-paste --primary -n 2>/dev/null)" != "$FRASE" ] && \
            wl-copy --primary -- "$FRASE" 2>/dev/null
    else
        [ "$(xsel --clipboard --output 2>/dev/null)" != "$FRASE" ] && \
            printf '%s' "$FRASE" | xsel --clipboard --input 2>/dev/null
        [ "$(xsel --primary --output 2>/dev/null)" != "$FRASE" ] && \
            printf '%s' "$FRASE" | xsel --primary --input 2>/dev/null
    fi
    sleep "$INTERVALO"
done