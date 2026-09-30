# dwm-instalador

Instalador de **dwm** (el gestor de ventanas en mosaico de suckless.org) ya preconfigurado para **Void Linux**.

> ### ⚠️ VERSIÓN 0.7 (BETA) — puede contener errores
> **SOLO PARA VOID LINUX.** Necesitas **mínimo 20 GB libres** para evitar errores de almacenamiento.

<img width="2880" height="2160" alt="Captura del escritorio dwm con la barra slstatus" src="https://github.com/user-attachments/assets/daacd093-3cd8-4330-ad5d-e77d1c1ad982" />

---

## 📦 Qué instala

| Componente | Para qué sirve |
|---|---|
| **dwm 6.2** | El gestor de ventanas, con el parche **vanitygaps** (separación entre ventanas) |
| **slstatus** | El contenido de la barra: CPU, RAM, wifi, batería y fecha |
| **st** | Emulador de terminal |
| **dmenu** | Lanzador de aplicaciones |
| **pcmanfm** | Gestor de archivos gráfico (muestra pendrives y discos) |
| **lf** | Gestor de archivos en la terminal |
| **picom** | Compositor (transparencias) |
| **feh** | Fondo de pantalla |
| **dunst** | Notificaciones |
| **scrot** | Capturas de pantalla |
| **lightdm** | Pantalla de inicio de sesión (también funciona con `startx`) |
| **udisks2 + polkit + elogind** | Montar pendrives y discos **sin contraseña** |
| Firefox, mpv, zathura, btop | Navegador, video, PDF, monitor del sistema |

Apariencia: paleta **Catppuccin Mocha** y fuente **JetBrainsMono Nerd Font**.

---

## 🚀 Instalación en 4 pasos

### 0. Primero instala `git` (es obligatorio)

```bash
sudo xbps-install -S git
```

> Si no lo haces, el instalador se detendrá y te lo recordará.

### 1. Clonar el repositorio

Copia y pega esto en tu terminal para descargar todo el código:

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

> Ejecútalo como **tu usuario normal**, no como root (usa `sudo` internamente cuando lo necesita).

---

## ❓ Qué te va a preguntar el instalador

| Pregunta | Opciones |
|---|---|
| **Grupo wheel** | Si no estás en él, te ofrece añadirte (necesario para montar discos sin contraseña) |
| **País / zona horaria** | Escribe tu país (ej. `Colombia`, `México`, `Argentina`) o la zona directa (`America/Bogota`) |
| **Teclado** | `1` Inglés (us) · `2` Español de España (es) · `3` Latinoamericano (latam) · `4` No cambiar |
| **Kernel** | Si hay una serie más nueva en los repos, te ofrece instalarla **junto** a la actual |

No hay menú de modos: es un flujo único que instala todo.

---

## 🔁 Al terminar: **REINICIA** (importante)

```bash
sudo reboot
```

El reinicio **no es opcional**: el grupo `wheel`, la zona horaria, el teclado y los servicios
`dbus` / `elogind` / `polkitd` / `udevd` / `lightdm` solo se aplican del todo al reiniciar.

### Cuando vuelvas a arrancar

Verás **lightdm**. Elige la sesión **dwm** en el selector del greeter y entra con tu usuario.

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

> La de texto plano **no está en el repositorio**: la genera el instalador cuando lo ejecutas
> en tu Void Linux. Así en GitHub se ve bonito y en `nano` se ve alineado (el markdown en una
> terminal se lee como ruido, y el texto plano en GitHub pierde la alineación).

Los más usados:

| Atajo | Acción |
|---|---|
| `Super` + `D` | Lanzador (**dmenu**) |
| `Super` + `Enter` / `Super` + `T` | Terminal (**st**) |
| `Super` + `E` | Gestor de archivos en terminal (**lf**) |
| `Super` + `G` | Gestor de archivos gráfico (**pcmanfm**) |
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

**Sobre la barra** (esto en dwm funciona de verdad, no hace falta parche):

| Dónde clicas | Clic | Acción |
|---|---|---|
| El símbolo del layout (`[ ]` `><` `[M]`) | izquierdo | Alternar layout |
| | derecho | Ir directo a *monocle* |
| Un **tag** (los cuadraditos numerados) | izquierdo | Ir a ese tag |
| | derecho | Ver ese tag **junto** al actual |
| | `Super` + izquierdo | Mover la ventana a ese tag |
| | `Super` + derecho | La ventana aparece en ambos tags |
| El título de la ventana activa | central | Convertirla en la ventana maestra |
| La zona de estado (CPU, RAM, hora) | central | Abrir una terminal |

Para ver la lista completa desde la terminal (versión en texto plano, alineada):

```bash
nano ~/Atajos.txt
```

---

## 💾 Pendrives y discos duros

Este instalador deja configurada la pila completa para que montar discos no sea un dolor:

`udevd` detecta el dispositivo → `udisks2` lo monta → `polkit` decide si hace falta contraseña →
tu regla dice que el grupo `wheel` **no la necesita**.

| Qué quieres | Cómo |
|---|---|
| Ver los dispositivos conectados | `Super` + `G` → panel izquierdo de pcmanfm |
| Montar uno | **Clic** sobre el dispositivo |
| Saber dónde se montó | `/run/media/TU-USUARIO/` |

Desde la terminal:

```bash
lsblk -f                          # ver discos y particiones
udisksctl mount -b /dev/sdb1      # montar sin contraseña
udisksctl unmount -b /dev/sdb1    # desmontar
```

Soporta **NTFS** y **exFAT** (pendrives y discos de Windows) y **MTP** (celulares Android).

> Para comprobar que la regla funciona:
> ```bash
> sv status udevd dbus elogind polkitd      # los cuatro servicios arriba
> loginctl                                  # tu sesión registrada
> pkcheck -a org.freedesktop.udisks2.filesystem-mount -p unix-process:pid:$$
> ```

---

## 🎨 Personalizar tu escritorio

| Archivo | Qué cambia | Cómo se aplica |
|---|---|---|
| `~/dwm/config.h` | **Atajos**, colores, fuentes, gaps, reglas de ventanas | `sudo make clean install` |
| `~/slstatus/config.h` | Qué muestra la barra (CPU, RAM, wifi, batería, fecha) | `sudo make clean install` |
| `~/.config/dwm/autostart.sh` | Programas que arrancan con dwm | Al reiniciar la sesión |
| `~/.config/picom/picom.conf` | Transparencias y compositor | Al reiniciar la sesión |
| `~/.config/lf/lfrc` | Gestor de archivos `lf` | Al reabrir `lf` |
| `/usr/local/bin/dwm-session` | Wrapper de sesión (`dbus-run-session dwm`) | Al reiniciar la sesión |
| `/etc/polkit-1/rules.d/49-udisks2-wheel.rules` | Permisos de montaje de discos | `sudo sv restart polkitd` |

### Ejemplo: cambiar un atajo de teclado

```bash
nano ~/dwm/config.h     # 1. edita la tecla
sudo make clean install # 2. recompila dwm y slstatus
# 3. Super+Shift+E para salir y vuelve a entrar
```

> `dwm-rebuild` reinicia **slstatus** sin cerrar la sesión, así que los cambios de barra se ven al instante.

### Cambiar el fondo de pantalla

El fondo es `~/Pictures/wallpaper.jpg` (lo aplica **feh**).

1. Copia tu imagen a `~/Pictures/`.
2. Renómbrala a **`wallpaper.jpg`**.
3. La que venía por defecto puedes borrarla o renombrarla para conservarla.

```bash
cp /ruta/de/mi-fondo.png ~/Pictures/wallpaper.jpg
```

> Solo cambia el **nombre**: el contenido puede ser PNG u otro formato, no hace falta convertirlo.

---

## 🩺 Si algo falla

| Problema | Solución |
|---|---|
| No ves la sesión **dwm** en lightdm | Revisa que exista `/usr/share/xsessions/dwm.desktop` |
| dwm arranca pero no se ve nada | `Ctrl` + `Alt` + `F1` y revisa `~/.xsession-errors` |
| lightdm no reinicia con el botón *restart* | `Ctrl` + `Alt` + `F1` y ahí `sudo reboot` |
| El pendrive pide contraseña al montarlo | Reinicia la sesión (el grupo `wheel` solo aplica al volver a entrar) y comprueba `loginctl` |
| No aparecen los pendrives en pcmanfm | `sv status udevd dbus elogind polkitd` — los cuatro deben estar `run:` |
| La compilación de dwm falla | El instalador fija dwm en el **tag 6.2** por el parche vanitygaps; mira `~/dwm/dwm.c.rej` |
| El instalador dice que falta `git` | `sudo xbps-install -S git` y vuelve a ejecutarlo |

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
| **pcmanfm** — gestor de archivos gráfico | https://github.com/lxqt/pcmanfm |
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
| Login | lightdm | greetd + tuigreet |
| Gaps | ✅ activos (parche) | ❌ dwl no los trae |
| Gaming / GPU | No incluido | Steam + drivers (AMD, Intel, NVIDIA híbridas) |

> Regla rápida: si tus programas son antiguos o necesitas X11 sí o sí, usa **dwm**.
> Si quieres lo moderno y juegas en Linux, usa **dwl**.

---

*Hecho para Void Linux. Si encuentras un error, abre un issue en el repositorio.*
