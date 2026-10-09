# dwm-instalador

Instalador de **dwm** (el gestor de ventanas en mosaico de suckless.org) ya preconfigurado para **Void Linux** y **Arch Linux**.

> ### VERSIÓN 1.0
> Soporta **Void Linux** (runit) y **Arch Linux** (systemd). Se comprobó con simulaciones de `sudo`, `xbps` y `pacman`; falta probarlo en un equipo real.
> Se recomiendan **10 GB libres** en `/`. El instalador avisa si hay menos y te pregunta si continúa.

<img width="2880" height="2160" alt="Captura del escritorio dwm con la barra slstatus" src="https://github.com/user-attachments/assets/daacd093-3cd8-4330-ad5d-e77d1c1ad982" />

---

## 📦 Qué instala

| Componente | Para qué sirve |
|---|---|
| **dwm 6.2** | El gestor de ventanas, con el parche **vanitygaps** (separación entre ventanas) |
| **slstatus** | El contenido de la barra: **CPU** (carga), **RAM**, **volumen**, **wifi** y **batería** (si hay), y la **hora** |
| **st** | Terminal. Se **compila desde el código** con la paleta Tokyo Night y la fuente JetBrainsMono Nerd Font |
| **dmenu** | Lanzador de aplicaciones |
| **lf** | Gestor de archivos en la terminal — **el único**, no se instala ninguno gráfico |
| **picom** | Compositor. Pone la terminal al **75 %** de opacidad |
| **feh** | Fondo de pantalla |
| **dunst** | Notificaciones |
| **scrot** | Capturas de pantalla |
| **lightdm** | Pantalla de inicio de sesión (también funciona con `startx`) |
| **udisks2 + polkit** | Montar pendrives y discos **sin contraseña** |
| **gvfs, ntfs-3g, exfatprogs** | MTP (celulares), NTFS y exFAT |
| Firefox, mpv, zathura, btop, fastfetch, cowsay | Navegador, video, PDF, monitor del sistema y utilidades |

> 📁 **Solo `lf` como gestor de archivos.** Este instalador **no** instala ninguno gráfico
> (ni pcmanfm ni Thunar): si quieres uno, lo instalas tú y le pones el atajo que prefieras.
> La pila de montaje (`udisks2` + `polkit`) **sí** queda configurada, así que montar discos
> sin contraseña funciona igual con cualquier gestor que añadas después.

**Apariencia:** paleta **Tokyo Night** (la misma que el instalador de dwl), fuente **JetBrainsMono Nerd Font** y fondo de pantalla anime 4K.

**Tamaño de la fuente:** se elige según la resolución del monitor conectado: 11 pt (hasta Full HD), 13 pt (2400 px de ancho o más) o 15 pt (3000 px o más).

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
| **País / zona horaria** | Escribe tu país (ej. `Colombia`, `México`, `Argentina`) o la zona directa (`America/Bogota`). Vacío = `America/Bogota` |
| **Kernel** (solo Void) | Si hay una serie más nueva en los repos, pregunta si la instalas. La actual no se borra |

El **grupo `wheel`** no se pregunta: el instalador añade tu usuario a `wheel`, `video` e `input` sin preguntar (es lo que necesita la regla de polkit para los discos).

No hay menú de modos: es un flujo único que instala todo.

---

## 🔁 Al terminar: **REINICIA** (importante)

```bash
sudo reboot
```

Reinicia para que se apliquen:

- **Los grupos** (`wheel`, `video`, `input`): solo valen en una sesión nueva.
- **La zona horaria y el teclado de consola**.
- **lightdm**, que queda habilitado para arrancar con el sistema.

### Cuando vuelvas a arrancar

Verás **lightdm**. Elige la sesión **dwm** en el selector y entra con tu usuario.

> 💡 ¿Prefieres arrancar sin lightdm? El instalador también deja `~/.xinitrc`, así que funciona con:
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
la regla dice que el grupo `wheel` **no la necesita**.

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
> systemctl status polkit                   # Arch
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

## 🐧 Diferencias entre Void y Arch

| | **Void Linux** | **Arch Linux** |
|---|---|---|
| Init | runit | systemd |
| Paquetes | `xbps-install` | `pacman -Syu --needed` (evita actualizaciones parciales) |
| Paquetes que no estén en los repos | Se omiten con aviso | Se intentan por AUR con `yay` o `paru` (si hay alguno) |
| Servicios | Enlaces en `/var/service` | `systemctl enable` |
| Kernel | El instalador ofrece la serie más nueva | Se actualiza con `pacman -Syu` |
| Sesión de logind | elogind | systemd-logind (incluido en systemd) |

> En Arch, si `ttf-jetbrains-mono-nerd` no está en los repos oficiales y no tienes `yay` ni `paru`, el instalador avisa y sigue. Instala la fuente a mano; si no, dwm y st usarán otra fuente.

Otras distribuciones (y Arch o Void sin systemd o runit) **no están soportadas**: el instalador se detiene al detectarlas, antes de cambiar nada.

---

## 🩺 Si algo falla

| Problema | Solución |
|---|---|
| No ves la sesión **dwm** en lightdm | Revisa que exista `/usr/share/xsessions/dwm.desktop` |
| dwm arranca pero no se ve nada | Entra por consola (`Ctrl` + `Alt` + `F2`) y ejecuta `startx > ~/dwm-error.log 2>&1`; mira el log |
| El pendrive pide contraseña al montarlo | Cierra sesión y vuelve a entrar (el grupo `wheel` solo aplica en una sesión nueva) y comprueba `loginctl` |
| `lsblk` no ve el pendrive | Void: `sv status udevd dbus elogind polkitd` (los cuatro deben estar `run:`). Arch: `systemctl status polkit` |
| La compilación de dwm falla | Mira `/tmp/dwm-make.log`. Si lo que falla es el parche, mira `~/dwm/dwm.c.rej` |
| La compilación de st o slstatus falla | Mira `/tmp/st-make.log` o `/tmp/slstatus-make.log` |
| El instalador dice que la distro no es compatible | Solo Void (runit) y Arch (systemd). Otras distros no están soportadas |
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
| Login | lightdm | greetd + tuigreet |
| Distribuciones | Void y Arch | Void y Arch |
| Gaps | ✅ activos (parche) | ❌ dwl no los trae |

> Regla rápida: si tus programas son antiguos o necesitas X11 sí o sí, usa **dwm**.
> Si quieres lo moderno y Wayland, usa **dwl**.

---

*Hecho para Void Linux y Arch Linux. Si encuentras un error, abre un issue en el repositorio.*
