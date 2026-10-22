#!/bin/sh
# abrir_video.sh - abre um video forcando o som no maximo.
# - Sobe o volume do sistema para 100%
# - Abre em navegador baseado em Chromium com autoplay COM som (sem precisar clicar)
# - Sobe o volume de cada stream de aplicativo (mixer por app) para 100%

URL="https://www.youtube.com/watch?v=P6antjcBFZ4&autoplay=1"

# --- 1. Volume do sistema no maximo ---------------------------------------
if command -v wpctl >/dev/null 2>&1; then
    # PipeWire
    wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0
elif command -v pactl >/dev/null 2>&1; then
    # PulseAudio (ou PipeWire com pipewire-pulse)
    pactl set-sink-mute @DEFAULT_SINK@ 0
    pactl set-sink-volume @DEFAULT_SINK@ 100%
elif command -v amixer >/dev/null 2>&1; then
    # ALSA puro
    amixer -q set Master 100% unmute
else
    echo "Nao encontrei wpctl, pactl nem amixer para ajustar o volume." >&2
fi

# --- 2. Abre o navegador forcando autoplay com som ------------------------
# Navegadores Chromium aceitam a flag que libera autoplay com audio.
BROWSER=""
for b in google-chrome google-chrome-stable chromium chromium-browser brave-browser microsoft-edge; do
    if command -v "$b" >/dev/null 2>&1; then
        BROWSER="$b"
        break
    fi
done

if [ -n "$BROWSER" ]; then
    # Perfil novo e limpo: garante que a flag seja respeitada (instancia nova)
    # e evita que o YouTube reaplique um estado "mudo" guardado no perfil padrao.
    PERFIL="$(mktemp -d /tmp/video_profile.XXXXXX)"
    "$BROWSER" --autoplay-policy=no-user-gesture-required \
        --user-data-dir="$PERFIL" \
        --no-first-run --no-default-browser-check \
        --new-window "$URL" >/dev/null 2>&1 &
    BROWSER_PID=$!
    # Quando o navegador fechar, remove o perfil temporario.
    # Usa poll com kill -0 (o navegador nao e filho deste subshell, entao
    # 'wait' nao serviria aqui).
    (
        while kill -0 "$BROWSER_PID" 2>/dev/null; do
            sleep 2
        done
        rm -rf "$PERFIL"
    ) &
else
    # Sem navegador Chromium: abre no padrao (pode iniciar mudo, depende do site)
    xdg-open "$URL" >/dev/null 2>&1 &
fi

# --- 3. Sobe o volume por aplicativo (stream do navegador) ----------------
# O navegador leva alguns segundos para criar o stream de audio.
if command -v pactl >/dev/null 2>&1; then
    (
        i=0
        while [ "$i" -lt 15 ]; do
            pactl list short sink-inputs 2>/dev/null | while read -r id _; do
                pactl set-sink-input-mute "$id" 0 2>/dev/null
                pactl set-sink-input-volume "$id" 100% 2>/dev/null
            done
            i=$((i + 1))
            sleep 1
        done
    ) &
fi
