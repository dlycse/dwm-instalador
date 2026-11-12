# dwm-instalador

Instalador de **dwm** (el gestor de ventanas en mosaico de suckless.org) ya preconfigurado para **Void Linux**, **Arch Linux**, **Fedora / Nobara** y **Debian**.

> ### VERSIÓN 1.06
> Soporta **Void Linux** (runit), **Arch Linux** (systemd), **Fedora 44 o superior** y **Nobara** (dnf + systemd), y **Debian** (apt + systemd).

<img width="1281" height="800" alt="image" src="https://github.com/user-attachments/assets/558d5949-c612-41ca-8eb3-7dfb3bbdb62d" />

---

## 📦 Qué instala

| Componente | Para qué sirve |
|---|---|
| **dwm 6.2** | El gestor de ventanas, con el parche **vanitygaps** (separación entre ventanas). Se compila desde el código en todas las distros |
| **slstatus** | El contenido de la barra: **CPU** (carga), **RAM**, **volumen**, **wifi** y **batería** (si hay), y la **hora** |
| **st** | Terminal. Se **compila desde el código** con la paleta Tokyo Night y la fuente JetBrainsMono Nerd Font |
| **dmenu** | Lanzador de aplicaciones |
| **lf** | Gestor de archivos en la terminal — **el único**, no se instala ninguno gráfico |
| **picom** | Compositor. Pone la terminal al **75 %** de opacidad |
| **feh** | Fondo de pantalla |
| **dunst** | Notificaciones |
| **scrot** | Capturas de pantalla |
| **greetd + tuigreet** | Pantalla de inicio de sesión (en **tty1**), si no conservas tu gestor actual |
| **udisks2 + polkit** | Montar pendrives y discos **sin contraseña** |
| **gvfs, ntfs-3g, exfatprogs** | MTP (celulares), NTFS y exFAT |
| Firefox, mpv, zathura, btop, fastfetch, cowsay | Navegador, video, PDF, monitor del sistema y utilidades |

> 📁 **Solo `lf` como gestor de archivos.** Este instalador **no** instala ninguno gráfico
> (ni pcmanfm ni Thunar): si quieres uno, lo instalas tú y le pones el atajo que prefieras.
> La pila de montaje (`udisks2` + `polkit`) **sí** queda configurada, así que montar discos
> sin contraseña funciona igual con cualquier gestor que añadas después.

**Apariencia:** paleta **Tokyo Night** (la misma que el instalador de dwl), fuente **JetBrainsMono Nerd Font** y fondo de pantalla anime 4K.

**Tamaño de la fuente:** se elige según la resolución del monitor conectado: 11 pt (hasta Full HD), 13 pt (2400 px de ancho o más) o 15 pt (3000 px o más).

### Fedora, Nobara y Debian

- **Fedora y Nobara:** Fedora no empaqueta **JetBrainsMono Nerd Font**. El instalador la descarga de la [release oficial de Nerd Fonts](https://github.com/ryanoasis/nerd-fonts/releases) a `~/.local/share/fonts`.
- **Debian:** la fuente base viene de `fonts-jetbrains-mono`, y la Nerd Font se descarga igual que en Fedora. Firefox se instala como `firefox-esr`.
- En Debian, el grupo de administradores es **`sudo`** (no `wheel`). El instalador añade tu usuario a ese grupo.

---

## 🚀 Instalación en 4 pasos

### 0. Primero instala `git` (para clonar este repositorio)

En **Void**:

```bash
sudo xbps-install -S git
```

En **Arch**:

```bash
sudo pacman -S git
```

En **Fedora** y **Nobara**:

```bash
sudo dnf install -y git
```

En **Debian**:

```bash
sudo apt install -y git
```

### 1. Clonar el repositorio

```bash
git clone https://github.com/dlycse/dwm-instalador.git
```

### 2. Entrar a la carpeta

```bash
cd dwm-instalador
```

### 3. Darle permisos de ejecución

```bash
chmod +x install-dwm.sh
```

### 4. Ejecutar el instalador

```bash
./install-dwm.sh
```

> Ejecútalo como **tu usuario normal**, no como root. El script se niega a ejecutarse como root y pide `sudo` cuando lo necesita.
> Al empezar pide tu contraseña de `sudo` una vez, y la mantiene viva durante la compilación.

---

## ❓ Qué te va a preguntar el instalador

| Pregunta | Opciones |
|---|---|
| **Espacio libre** | Solo aparece si hay menos de 10 GB en `/`. Responde `s` para continuar o `N` para cancelar |
| **Teclado** | `1` Inglés (us) · `2` Español de España (es) · `3` Latinoamericano (latam, **por defecto**) |
| **País / zona horaria** | Escribe tu país (ej. `Colombia`, `México`, `Costa Rica`, `Estados Unidos`) o la zona directa (`America/Bogota`). Vacío = `America/Bogota` |
| **Gestor de sesión** *(si ya tienes uno)* | Pregunta si cambiarlo por **greetd + tuigreet**. `N` (por defecto) lo conserva y eliges **dwm** en su menú. Si lo cambias y tienes una sesión gráfica abierta, el cambio se aplica **al reiniciar** |
| **Kernel** (solo Void) | Si hay una serie más nueva en los repos, pregunta si la instalas. La actual no se borra |

El grupo de administradores (`wheel`, o `sudo` en Debian) no se pregunta: el instalador añade tu usuario a ese grupo, a `video` y a `input` sin preguntar. Es lo que necesita la regla de polkit para los discos.

No hay menú de modos: es un flujo único que instala todo.

---

## 🔁 Al terminar: **REINICIA** (importante)

```bash
sudo reboot
```

Reinicia para que se apliquen:

- **Los grupos** (administradores, `video`, `input`): solo valen en una sesión nueva.
- **La zona horaria y el teclado de consola**.
- **greetd + tuigreet**, que queda habilitado para arrancar con el sistema.

### Cuando vuelvas a arrancar

Verás **tuigreet** en la **tty 1**: una pantalla de login en texto. Escribe tu usuario y contraseña, y entras a **dwm**.

| Tecla (tuigreet) | Acción |
|---|---|
| `F2` | Cambiar el comando de la sesión |
| `F3` | Elegir otra sesión |
| `F12` | Menú de apagar / reiniciar — **solo si hay `loginctl`** |

> ℹ️ Las consolas `tty2`…`tty6` siguen con `agetty` normal, por si necesitas entrar a una consola.

> 💡 ¿Prefieres arrancar sin greetd? El instalador también deja `~/.xinitrc`, así que funciona con:
> ```bash
> startx
> ```

---

## ⌨️ Atajos principales

La tecla **Super** es la de Windows (⌘ en teclados de Mac).

📄 **La lista completa existe en dos versiones**, con el mismo contenido:

| Versión | Dónde está | Para qué |
|---|---|---|
| **[Atajos.md](Atajos.md)** | Aquí, en GitHub | Leerla con formato (tablas, enlaces) |
| **`~/Atajos.txt`** | En tu equipo, la crea el instalador | Leerla en la terminal: `nano ~/Atajos.txt` |

> La de texto plano **no está en el repositorio**: la genera el instalador en tu equipo.
> Así en GitHub se ve bonito y en `nano` se ve alineado.

Los más usados:

| Atajo | Acción |
|---|---|
| `Super` + `D` | Lanzador (**dmenu**) |
| `Super` + `Enter` / `Super` + `T` | Terminal (**st**) |
| `Super` + `E` | Gestor de archivos en terminal (**lf**, dentro de st) |
| `Super` + `B` | Firefox |
| `Super` + `Q` | Cerrar ventana |
| `Super` + `J` / `K` | Siguiente / anterior ventana |
| `Super` + `H` / `L` | Achicar / agrandar el área maestra |
| `Super` + `W` | Ocultar / mostrar la barra |
| `Super` + `R` | Alternar con el layout anterior |
| `Super` + `F` | Layout *monocle* |
| `Super` + `Ctrl` + `U` | Aumentar gaps *(aquí sí están activos)* |
| `Super` + `Ctrl` + `0` | Activar / desactivar gaps |
| `Super` + `1`…`9` | Ir a ese tag |
| `Super` + `Shift` + `1`…`9` | Mover la ventana a ese tag |
| `Super` + `Tab` | Volver al tag anterior |
| `Super` + `Shift` + `E` | **Cerrar la sesión** |

### 🖱️ Con el ratón

**Sobre una ventana:**

| Clic | Acción |
|---|---|
| `Super` + clic izquierdo | **Mover** la ventana |
| `Super` + clic central | Volverla **flotante** |
| `Super` + clic derecho | **Redimensionar** la ventana |

**Sobre la barra:**

| Dónde clicas | Clic | Acción |
|---|---|---|
| El símbolo del layout (`[]=` `><>` `[M]`) | izquierdo | Alternar layout |
| | derecho | Ir directo a *monocle* |
| Un **tag** (los números 1–9) | izquierdo | Ir a ese tag |
| | derecho | Ver ese tag **junto** al actual |
| | `Super` + izquierdo | Mover la ventana a ese tag |
| | `Super` + derecho | Añadir o quitar la ventana de ese tag |
| El título de la ventana activa | central | Convertirla en la ventana maestra |
| La zona de estado (CPU, RAM, hora) | central | Abrir una terminal |

Para ver la lista completa desde la terminal:

```bash
nano ~/Atajos.txt
```

---

## 💾 Pendrives y discos duros

El instalador deja configurada la pila para que montar discos no sea un dolor:

`udevd` detecta el dispositivo → `udisks2` lo monta → `polkit` decide si hace falta contraseña →
la regla dice que los miembros del grupo de administradores (`wheel`, o `sudo` en Debian) **no la necesitan**.

No hay gestor de archivos gráfico: esto se hace desde la terminal, o desde `lf`
(`Super` + `E`).

| Qué quieres | Comando |
|---|---|
| Ver los discos y particiones | `lsblk -f` |
| Ver el resumen de discos que reconoce udisks2 | `udisksctl status` |
| **Montar** uno, sin contraseña | `udisksctl mount -b /dev/sdb1` |
| **Desmontarlo** | `udisksctl unmount -b /dev/sdb1` |
| Saber dónde se montó | `/run/media/TU-USUARIO/` |

Soporta **NTFS** y **exFAT** (pendrives y discos de Windows) y **MTP** (celulares Android, con gvfs).

> Para comprobar que todo está bien:
> ```bash
> sv status udevd dbus elogind polkitd      # Void: los cuatro servicios arriba
> systemctl status polkit                   # Arch, Fedora, Nobara y Debian
> loginctl                                  # tu sesión registrada
> pkcheck -a org.freedesktop.udisks2.filesystem-mount -p unix-process:pid:$$
> ```

---

## 🎨 Personalizar tu escritorio

| Archivo | Qué cambia | Cómo se aplica |
|---|---|---|
| `~/dwm/config.h` | **Atajos**, colores, fuentes, gaps, reglas de ventanas | `cd ~/dwm && sudo make clean install` |
| `~/slstatus/config.h` | Qué muestra la barra (CPU, RAM, volumen, wifi, batería, hora) | `cd ~/slstatus && sudo make clean install` |
| `~/st/config.h` | Fuente y colores de la terminal | `cd ~/st && sudo make clean install` |
| `~/.config/dwm/autostart.sh` | Programas que arrancan con dwm | Al reiniciar la sesión |
| `~/.config/picom/picom.conf` | Opacidad de la terminal y compositor | Al reiniciar la sesión |
| `~/.config/lf/lfrc` | Gestor de archivos `lf` | Al reabrir `lf` |
| `/usr/local/bin/dwm-session` | Wrapper de sesión (`dbus-run-session dwm`) | Al reiniciar la sesión |
| `/usr/local/bin/dwm-startx` | Lanza dwm desde greetd (usa `startx`) | Al reiniciar la sesión |
| `/etc/greetd/config.toml` | Pantalla de login (greetd + tuigreet) | `sudo sv restart greetd` (Void) o `sudo systemctl restart greetd` (Arch, Fedora, Nobara y Debian) |
| `/etc/polkit-1/rules.d/49-udisks2-wheel.rules` | Permisos de montaje de discos | Normalmente sin reiniciar nada |

### Ejemplo: cambiar un atajo de teclado

```bash
nano ~/dwm/config.h                   # 1. edita la tecla
cd ~/dwm && sudo make clean install   # 2. recompila e instala
# 3. Super+Shift+E para salir y vuelve a entrar
```

> ⚠️ `sudo make clean install` recompila **solo el proyecto en cuya carpeta estés**.
> Si también cambiaste `~/slstatus/config.h`, repítelo ahí y reinicia la barra a mano
> para ver el cambio sin cerrar la sesión:
> ```bash
> cd ~/slstatus && sudo make clean install
> pkill -x slstatus; sleep 1; slstatus &
> ```

### Cambiar el fondo de pantalla

El fondo es `~/Pictures/wallpaper.jpg` y lo aplica **feh** al iniciar la sesión.

1. Copia tu imagen a `~/Pictures/`.
2. Renómbrala a **`wallpaper.jpg`**.

```bash
cp /ruta/de/mi-fondo.png ~/Pictures/wallpaper.jpg
```

> Solo cambia el **nombre**: el contenido puede ser PNG u otro formato, feh lo detecta.
> Si ya existe `~/Pictures/wallpaper.jpg`, el instalador no lo reemplaza al volver a ejecutarlo.

---

## 🔄 Si vuelves a ejecutar el instalador

- Los archivos de configuración **no se sobrescriben**. Si ya existen `dwm/config.h`, `slstatus/config.h`, `st/config.h`, `picom.conf` o `lfrc`, tu versión se conserva y la nueva queda con el sufijo **`.nuevo`** para que la compares.
- `~/.config/dwm/autostart.sh` tampoco se toca si ya existe (sin `.nuevo`).
- El fondo existente también se conserva.
- El parche vanitygaps no se aplica dos veces.

Para cambiar el tamaño de la fuente en una instalación ya hecha, edita la fuente en `~/st/config.h` (`pixelsize=`) y en `~/dwm/config.h` (`size=`, en dos líneas), y recompila cada uno.

---

## 🐧 Diferencias entre las distros

| | **Void** | **Arch** | **Fedora / Nobara** | **Debian** |
|---|---|---|---|---|
| Init | runit | systemd | systemd | systemd |
| Paquetes | `xbps-install` | `pacman -Syu --needed` (evita actualizaciones parciales) | `dnf install --skip-unavailable` | `apt-get install` (solo paquetes con candidato) |
| Paquetes que no estén en los repos | Se omiten con aviso | Se intentan por AUR con `yay` o `paru` (si hay alguno) | Se omiten con aviso | Se omiten con aviso |
| Nerd Font | Paquete `nerd-fonts` | Paquete `ttf-jetbrains-mono-nerd` | Descarga oficial | Descarga oficial |
| Grupo de administradores | `wheel` | `wheel` | `wheel` | `sudo` |
| Servicios | Enlaces en `/var/service` | `systemctl enable` | `systemctl enable` | `systemctl enable` |
| Kernel | El instalador ofrece la serie más nueva | Se actualiza con `pacman -Syu` | Se actualiza con `dnf` | Se actualiza con `apt` |
| Sesión de logind | elogind | systemd-logind (incluido en systemd) | systemd-logind | systemd-logind |

> En Arch, si `ttf-jetbrains-mono-nerd` no está en los repos oficiales y no tienes `yay` ni `paru`, el instalador avisa y sigue. Instala la fuente a mano; si no, dwm y st usarán otra fuente.

**Ubuntu y Linux Mint no están soportados.** El instalador solo acepta Debian puro, y se detiene en otras distros antes de cambiar nada. Artix (OpenRC o runit) tampoco: no tiene systemd.

---

## 🩺 Si algo falla

| Problema | Solución |
|---|---|
| tuigreet no aparece tras el reinicio | Void `sudo sv status greetd` · Arch, Fedora, Nobara y Debian `systemctl status greetd` |
| El instalador termina con `greetd NO arranco` | Revisa el log: Void `sudo tail -n 30 /var/log/greetd/current` · el resto `journalctl -u greetd -b` |
| Vuelve el gestor de sesión viejo tras reiniciar (lightdm, gdm, sddm) | Desactívalo: `systemctl disable <gestor>` (systemd) o `sudo rm /var/service/<gestor>` (Void), y luego `sudo reboot` |
| Debian: el instalador dice que tuigreet no está en los repos | Tu versión de Debian no lo trae. Se conserva tu gestor actual (o instala uno, como `sudo apt install lightdm lightdm-gtk-greeter`) y eliges **dwm** en su menú |
| tuigreet abre pero dwm no arranca | Revisa `~/.local/share/xorg/Xorg.0.log` y `journalctl -u greetd -b`. Comprueba que `startx` esté instalado (`xinit` en Debian, `xorg-x11-xinit` en Fedora) |
| El instalador se detiene con `Este instalador necesita systemd` | Tu distro no usa systemd (Artix con OpenRC o runit). No está soportada |
| No ves la sesión **dwm** en el menú de tu gestor | Revisa que exista `/usr/share/xsessions/dwm.desktop` |
| dwm arranca pero no se ve nada | Entra por consola (`Ctrl` + `Alt` + `F2`) y ejecuta `startx > ~/dwm-error.log 2>&1`; mira el log |
| El pendrive pide contraseña al montarlo | Cierra sesión y vuelve a entrar (el grupo de administradores solo aplica en una sesión nueva) y comprueba `loginctl` |
| `lsblk` no ve el pendrive | Void: `sv status udevd dbus elogind polkitd` (los cuatro deben estar `run:`). Resto: `systemctl status polkit` |
| Debian: no sale el volumen en la barra | Revisa que `pipewire-bin` esté instalado (`dpkg -l pipewire-bin`) y, si no, instálalo con `sudo apt install pipewire-bin wireplumber` |
| Fedora / Nobara: `lf` no se instaló | Instálalo a mano: `sudo dnf install lf` o desde un COPR |
| La compilación de dwm falla | Mira `/tmp/dwm-make.log`. Si lo que falla es el parche, mira `~/dwm/dwm.c.rej` |
| La compilación de st o slstatus falla | Mira `/tmp/st-make.log` o `/tmp/slstatus-make.log` |
| El instalador dice que la distro no es compatible | Solo Void, Arch, Fedora, Nobara y Debian. Ubuntu, Mint y Artix no están soportados |
| El instalador dice que no puede ejecutarse como root | Ejecútalo con tu usuario normal, no con `sudo ./install-dwm.sh` |

---

## 🔗 Proyectos usados

Este instalador no reinventa nada: une y configura proyectos existentes.

| Proyecto | Enlace |
|---|---|
| **dwm** — el gestor de ventanas | https://dwm.suckless.org |
| **slstatus** — contenido de la barra | https://tools.suckless.org/slstatus |
| **vanitygaps** — parche de separación entre ventanas | https://dwm.suckless.org/patches/vanitygaps |
| **st** — terminal | https://st.suckless.org |
| **dmenu** — lanzador | https://tools.suckless.org/dmenu |
| **lf** — gestor de archivos en terminal | https://github.com/gokcehan/lf |
| **picom** — compositor | https://github.com/yshui/picom |
| **greetd / tuigreet** — inicio de sesión | https://git.sr.ht/~kennylevinsen/greetd |

---

## 🔀 ¿dwm o dwl?

Tengo dos instaladores hermanos:

| | **dwm-instalador** (este) | **[dwl-instalador](https://github.com/dlycse/dwl-instalador)** |
|---|---|---|
| Protocolo | **X11** | **Wayland** |
| Gestor | dwm 6.2 + vanitygaps | dwl |
| Barra | slstatus (integrada en dwm) | dwlb (externa) |
| Terminal | st | foot |
| Lanzador | dmenu | wmenu |
| Gestor de archivos | `lf` (solo terminal) | `lf` (solo terminal) |
| Login | greetd + tuigreet | greetd + tuigreet |
| Distribuciones | Void, Arch, Fedora, Nobara y Debian | Void, Arch, Fedora, Nobara y Debian |
| Gaps | ✅ activos (parche) | ❌ dwl no los trae |

> Regla rápida: si tus programas son antiguos o necesitas X11 sí o sí, usa **dwm**.
> Si quieres lo moderno y Wayland, usa **dwl**.

---

*Hecho para Void Linux, Arch Linux, Fedora, Nobara y Debian. Si encuentras un error, abre un issue en el repositorio.*
