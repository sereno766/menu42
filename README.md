# menu42

Menu gráfico simples (Python/tkinter) para acionar um conjunto de scripts de
brincadeira/alerta em Linux — pensado para lembrar colegas de **bloquear a tela
ao sair** do computador.

## Estrutura

```
menu42/
├── menu.py                 # interface gráfica (ponto de entrada)
├── instalar.sh             # instala o lançador .desktop e abre o menu
├── menu-scripts.desktop    # lançador (gerado/atualizado pelo instalar.sh)
├── scripts/                # scripts acionados pelo menu
│   ├── abrir_video.sh          # abre um vídeo forçando o som no máximo
│   ├── bloqueia_clipboard.sh   # impede copiar/colar
│   ├── gira_tela.sh            # gira a tela em intervalos
│   └── terminais_ascii.sh      # abre 20 terminais com arte ASCII de aviso
└── recursos/
    ├── aviso.txt               # texto aberto ao fechar o menu
    └── bloquear_ascii.txt      # arte ASCII usada pelos terminais
```

## Uso

### Abrir o menu

```sh
./menu.py
```

Cada botão aciona um script. Os scripts que rodam em segundo plano têm um botão
**Parar** ao lado. Ao fechar o menu (pelo **X** ou pelo botão **Sair**), ele abre
`recursos/aviso.txt` com o lembrete.

### Instalar como aplicativo (ícone no menu de aplicativos)

```sh
./instalar.sh
```

O instalador faz tudo de uma vez:

1. **Instala as dependências** que estiverem faltando via `apt` (pede `sudo`):
   `x11-xserver-utils`, `xsel`, `xinput`, `wl-clipboard`, `python3-tk`.
2. Descobre sozinho o caminho atual e (re)gera o lançador `menu-scripts.desktop`.
3. Registra em `~/.local/share/applications/` e cria um ícone na Área de Trabalho.
4. Abre o menu.

**Moveu a pasta de lugar?** Basta rodar `./instalar.sh` de novo.

## Os scripts

| Script | O que faz | Tem `stop`? |
|---|---|---|
| `abrir_video.sh` | Sobe o volume do sistema e por aplicativo a 100% e abre um vídeo no navegador com autoplay com som (perfil limpo, descartado ao fechar). | não |
| `bloqueia_clipboard.sh` | Limpa o clipboard continuamente, impedindo copiar/colar. | sim |
| `gira_tela.sh` | Gira a tela em intervalos (`xrandr`, sessões X11). | sim |
| `terminais_ascii.sh` | Abre 20 terminais espalhados pela tela com a arte ASCII do aviso. | sim |

Cada script com `stop` é parado com, por exemplo:

```sh
scripts/terminais_ascii.sh stop
```

## Personalização

- **Mensagem de aviso:** edite `recursos/aviso.txt`.
- **Arte ASCII dos terminais:** edite `recursos/bloquear_ascii.txt` — os terminais
  se redimensionam sozinhos para caber a arte.
- **Vídeo:** altere a variável `URL` em `scripts/abrir_video.sh`.

## Requisitos

- Linux com sessão gráfica **X11** (o `gira_tela.sh` usa `xrandr`, que não funciona
  no Wayland).
- Python 3 com tkinter.
- Um emulador de terminal (gnome-terminal, terminator, xterm, …).
- Opcional por script: `xrandr`, `xsel`/`wl-clipboard`, `xinput`, `wpctl`/`pactl`.

## Aviso

Os scripts alteram volume, clipboard, orientação da tela e abrem muitas janelas.
Use apenas na sua própria máquina ou com consentimento — é uma ferramenta de
brincadeira/conscientização, não para incomodar terceiros sem permissão.
