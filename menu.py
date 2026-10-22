#!/usr/bin/env python3
# menu.py - interface grafica simples para acionar os scripts da pasta
import os
import subprocess
import tkinter as tk
from tkinter import messagebox

BASE = os.path.dirname(os.path.abspath(__file__))
SCRIPTS_DIR = os.path.join(BASE, "scripts")
RECURSOS_DIR = os.path.join(BASE, "recursos")

SCRIPTS = [
    {
        "nome": "Abrir video",
        "script": "abrir_video.sh",
        "tem_stop": False,
    },
    {
        "nome": "Bloquear clipboard",
        "script": "bloqueia_clipboard.sh",
        "tem_stop": True,
    },
    {
        "nome": "Girar tela",
        "script": "gira_tela.sh",
        "tem_stop": True,
    },
    {
        "nome": "20 terminais",
        "script": "terminais_ascii.sh",
        "tem_stop": True,
    },
]


def caminho(script):
    return os.path.join(SCRIPTS_DIR, script)


def rodar(script, arg=None):
    cmd = [caminho(script)]
    if arg:
        cmd.append(arg)
    try:
        subprocess.Popen(cmd)
    except OSError as e:
        messagebox.showerror("Erro", f"Nao foi possivel executar {script}:\n{e}")


def main():
    janela = tk.Tk()
    janela.title("Menu de Scripts")
    janela.resizable(False, False)

    # Centraliza na tela
    largura, altura = 340, 300
    janela.update_idletasks()
    x = (janela.winfo_screenwidth() - largura) // 2
    y = (janela.winfo_screenheight() - altura) // 2
    janela.geometry(f"{largura}x{altura}+{x}+{y}")

    def ao_fechar():
        # Ao fechar (pelo X ou pelo botao Sair), abre o aviso em .txt
        aviso = os.path.join(RECURSOS_DIR, "aviso.txt")
        try:
            if not os.path.exists(aviso):
                os.makedirs(RECURSOS_DIR, exist_ok=True)
                with open(aviso, "w") as f:
                    f.write("NAO DEIXAR O COMPUTADOR DESBLOQUEADO\n")
            subprocess.Popen(["xdg-open", aviso])
        except OSError:
            pass
        janela.destroy()

    # O X da janela (e Alt+F4) tambem dispara o aviso
    janela.protocol("WM_DELETE_WINDOW", ao_fechar)

    tk.Label(janela, text="Escolha uma acao", font=("Sans", 14, "bold")).pack(pady=12)

    for item in SCRIPTS:
        linha = tk.Frame(janela)
        linha.pack(fill="x", padx=16, pady=4)

        tk.Button(
            linha,
            text=item["nome"],
            width=18,
            command=lambda s=item["script"]: rodar(s),
        ).pack(side="left")

        if item["tem_stop"]:
            tk.Button(
                linha,
                text="Parar",
                width=8,
                command=lambda s=item["script"]: rodar(s, "stop"),
            ).pack(side="right")

    tk.Button(janela, text="Sair", width=10, command=ao_fechar).pack(pady=14)

    janela.mainloop()


if __name__ == "__main__":
    main()
