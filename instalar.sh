#!/usr/bin/env bash
# instalar.sh - gera e instala o lancador .desktop apontando para esta pasta.
# Rode novamente sempre que mover a pasta de lugar.

# Descobre o diretorio onde este script esta, nao importa de onde foi chamado
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# --- Dependencias ---------------------------------------------------------
# Instala automaticamente o que estiver faltando (precisa de apt + sudo).
instalar_dependencias() {
    command -v apt-get >/dev/null 2>&1 || {
        echo "apt-get nao encontrado; pulando instalacao de dependencias."
        return
    }

    # Precisa poder usar sudo sem travar pedindo senha (ou ja ser root).
    SUDO=""
    if [ "$(id -u)" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
            SUDO="sudo"
        else
            echo "Sem permissao de sudo: pulando instalacao de dependencias."
            echo "O menu funciona assim mesmo; itens opcionais (xinput, wl-clipboard)"
            echo "so sao instalaveis por quem tiver sudo."
            return
        fi
    fi

    pkgs=""
    # Comando ausente -> pacote que o fornece
    command -v xrandr  >/dev/null 2>&1 || pkgs="$pkgs x11-xserver-utils"
    command -v xsel    >/dev/null 2>&1 || pkgs="$pkgs xsel"
    command -v xinput  >/dev/null 2>&1 || pkgs="$pkgs xinput"
    command -v wl-copy >/dev/null 2>&1 || pkgs="$pkgs wl-clipboard"
    # tkinter no python do sistema (o menu precisa de tkinter em algum python)
    /usr/bin/python3 -c "import tkinter" >/dev/null 2>&1 || pkgs="$pkgs python3-tk"

    # Remove espacos das pontas
    pkgs="$(echo "$pkgs" | xargs)"
    if [ -z "$pkgs" ]; then
        echo "Dependencias ja satisfeitas."
        return
    fi

    echo "Instalando dependencias: $pkgs"
    if $SUDO apt-get update -qq && $SUDO apt-get install -y $pkgs; then
        echo "Dependencias instaladas."
    else
        echo "AVISO: nao foi possivel instalar: $pkgs" >&2
        echo "       Instale manualmente: sudo apt install $pkgs" >&2
    fi
}

instalar_dependencias

DEST="$HOME/.local/share/applications/menu-scripts.desktop"
LOCAL="$DIR/menu-scripts.desktop"

chmod +x "$DIR/menu.py" "$DIR/menu.sh" 2>/dev/null
chmod +x "$DIR"/scripts/*.sh 2>/dev/null

gerar() {
    cat <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Menu de Scripts
Name[pt_BR]=Menu de Scripts
Comment=Aciona os scripts da pasta por uma interface grafica
Comment[pt_BR]=Aciona os scripts da pasta por uma interface grafica
Exec=$DIR/menu.sh
Path=$DIR
Icon=system-lock-screen
Terminal=false
Categories=Utility;
EOF
}

# Atualiza a copia local (que fica junto dos scripts) e a instalada (menu de apps)
gerar > "$LOCAL"
chmod +x "$LOCAL"

mkdir -p "$HOME/.local/share/applications"
gerar > "$DEST"
chmod +x "$DEST"

command -v update-desktop-database >/dev/null && \
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null
command -v gio >/dev/null && \
    gio set "$DEST" metadata::trusted true 2>/dev/null

# Cria tambem um icone clicavel na Area de Trabalho (duplo clique abre o menu)
DESK="$(xdg-user-dir DESKTOP 2>/dev/null)"
[ -z "$DESK" ] && DESK="$HOME/Desktop"
if [ -d "$DESK" ]; then
    ATALHO="$DESK/menu-scripts.desktop"
    gerar > "$ATALHO"
    chmod +x "$ATALHO"
    # Marca como confiavel (GNOME exige para permitir o duplo clique)
    command -v gio >/dev/null && gio set "$ATALHO" metadata::trusted true 2>/dev/null
    echo "Icone criado na Area de Trabalho: $ATALHO"
fi

echo "Lancador instalado apontando para:"
echo "  $DIR"
echo "Procure por 'Menu de Scripts' no menu de aplicativos ou use o icone da Area de Trabalho."

# Abre o menu logo apos instalar
echo "Abrindo o menu..."
exec "$DIR/menu.sh"
