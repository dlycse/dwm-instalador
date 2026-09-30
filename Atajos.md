# ⌨️ Atajos de teclado — dwm + slstatus

Lista **completa y real** de los atajos que deja configurados el instalador.

> **¿Qué es "Super"?** Es la tecla con el logo de **Windows** ⊞ (en teclados de Mac es **⌘ Command**).

> 📄 **¿Estás leyendo esto desde la terminal?** El instalador genera una versión en
> **texto plano** pensada para `nano`, alineada y sin markdown:
>
> ```bash
> nano ~/Atajos.txt
> ```
>
> Este archivo (`Atajos.md`) es el mismo contenido, pero con formato para leerlo en GitHub.

---

## 🆘 Si acabas de instalar, con esto ya puedes usar el sistema

| Quieres… | Presiona |
|---|---|
| Abrir una **terminal** | `Super` + `Enter` |
| Abrir un **programa** (lanzador) | `Super` + `D` |
| **Cerrar** la ventana que estás usando | `Super` + `Q` |
| Ver tus **archivos** (`lf`) | `Super` + `E` |
| Abrir el **navegador** | `Super` + `B` |
| **Cerrar la sesión** (volver al login) | `Super` + `Shift` + `E` |

Con esos seis ya puedes manejarte. El resto lo vas aprendiendo sobre la marcha.

---

## 📖 Mini glosario

Un gestor de ventanas **mosaico** (*tiling*) no apila ventanas como Windows: las **reparte** automáticamente por la pantalla.

| Palabra | Qué significa |
|---|---|
| **Tag** | Un "escritorio virtual". Hay 9 y cada uno guarda sus propias ventanas. |
| **Área maestra** | La ventana grande y principal, normalmente a la izquierda. |
| **Layout** | La forma de repartir las ventanas. |
| **Monocle** | Layout donde **una sola ventana** ocupa toda la pantalla. |
| **Flotante** | Ventana fuera del mosaico: la mueves y redimensionas a mano. |
| **Barra** | La línea de arriba (la dibuja dwm, el contenido lo genera **slstatus**). |
| **Gaps** | Separación entre ventanas. **Aquí sí están activos** (parche *vanitygaps*). |

---

## 🚀 Programas

| Atajo | Qué abre |
|---|---|
| `Super` + `D` | **Lanzador de aplicaciones** (dmenu) |
| `Super` + `Enter` | **Terminal** (st) |
| `Super` + `T` | **Terminal** (st) — atajo alternativo |
| `Super` + `B` | **Firefox** |
| `Super` + `E` | **lf**, gestor de archivos en terminal (se abre dentro de st) |

> ⚠️ **`lf` es el único gestor de archivos.** Este instalador **no** instala ninguno
> gráfico. Si quieres uno, instálalo tú y añádele un atajo en `~/dwm/config.h`:
> ```bash
> sudo xbps-install -S pcmanfm
> ```
> Y recuerda que `Super` + `R` **no** abre lf — es el de alternar layout.

---

## 🪟 Ventanas

| Atajo | Qué hace |
|---|---|
| `Super` + `Q` | **Cerrar** la ventana enfocada |
| `Super` + `J` &nbsp;o&nbsp; `Super` + `↓` | Enfocar la **siguiente** ventana |
| `Super` + `K` &nbsp;o&nbsp; `Super` + `↑` | Enfocar la ventana **anterior** |
| `Super` + `H` | Hacer el área maestra **más angosta** |
| `Super` + `L` | Hacer el área maestra **más ancha** |
| `Super` + `I` | Meter **una ventana más** en el área maestra |
| `Super` + `Shift` + `T` | Volver la ventana **flotante** (o devolverla al mosaico) |

---

## 📊 Barra (slstatus)

| Atajo | Qué hace |
|---|---|
| `Super` + `W` | Ocultar o mostrar la barra |

La barra la dibuja **dwm** y su texto lo genera **slstatus**: CPU, RAM, la red wifi,
la batería (si el equipo tiene) y la fecha.

Para cambiar lo que muestra:

```bash
nano ~/slstatus/config.h
cd ~/slstatus && sudo make clean install
pkill -x slstatus; sleep 1; slstatus &   # reinicia la barra sin cerrar sesión
```

---

## 📐 Layouts

| Símbolo en la barra | Layout |
|---|---|
| `[]=` | **Mosaico**: área maestra + columna de ventanas (el inicial) |
| `"><>"` | **Flotante**: cada ventana se mueve y redimensiona a mano |
| `[M]` | **Monocle**: una sola ventana ocupando todo |

| Atajo | Qué hace |
|---|---|
| `Super` + `R` | **Alternar** con el layout anterior |
| `Super` + `Space` | **Alternar** con el layout anterior (hace lo mismo que `Super` + `R`) |
| `Super` + `F` | Ir directo a **monocle** |

> 📌 El layout **flotante** (`"><>"`) no tiene tecla propia: se llega alternando con `Super` + `R`.

---

## 🔢 Tags (los 9 escritorios)

| Atajo | Qué hace |
|---|---|
| `Super` + `1` … `9` | **Ir** a ese tag |
| `Super` + `Shift` + `1` … `9` | **Mover** la ventana actual a ese tag |
| `Super` + `Ctrl` + `1` … `9` | **Ver dos tags a la vez** (el actual + ese) |
| `Super` + `Ctrl` + `Shift` + `1`…`9` | La ventana **aparece en ambos** tags sin moverla |
| `Super` + `Tab` | Volver al **tag anterior** |

**Idea de uso:** terminal en el tag 1, navegador en el 2, música en el 3, chat en el 4.

---

## 🖥️ Varios monitores

| Atajo | Qué hace |
|---|---|
| `Super` + `,` | Enfocar el monitor **anterior** (izquierda) |
| `Super` + `.` | Enfocar el monitor **siguiente** (derecha) |
| `Super` + `Shift` + `,` | **Enviar la ventana** al monitor anterior |
| `Super` + `Shift` + `.` | **Enviar la ventana** al monitor siguiente |

---

## 📏 Gaps — ✅ aquí SÍ están activos

El instalador aplica el parche **vanitygaps** a dwm 6.2, así que la separación entre
ventanas funciona desde el primer momento (a diferencia de dwl, que no trae gaps).

| Atajo | Qué hace |
|---|---|
| `Super` + `Ctrl` + `U` | **Aumentar** la separación entre ventanas |
| `Super` + `Ctrl` + `Shift` + `U` | **Disminuir** la separación |
| `Super` + `Ctrl` + `0` | **Activar / desactivar** gaps |
| `Super` + `Ctrl` + `Shift` + `0` | **Restablecer** los gaps a su valor inicial |

> Los valores iniciales (10 px) se cambian en `~/dwm/config.h`: `gappih`, `gappiv`, `gappoh` y `gappov`.

---

## 🔊 Teclas especiales (sin Super)

| Tecla | Qué hace |
|---|---|
| Subir volumen | +3 % (`amixer` / ALSA) |
| Bajar volumen | −3 % |
| Mute | Silenciar o restaurar |
| Brillo arriba | +5 % (`brightnessctl`) |
| Brillo abajo | −5 % |
| `Print` / `Impr Pant` | **Captura de pantalla** (`scrot`) → se guarda en `~/Pictures` |

---

## 🚪 Salir

| Atajo | Qué hace |
|---|---|
| `Super` + `Shift` + `E` | **Cerrar la sesión de dwm** (vuelves a lightdm) |

> 🔧 **Si dwm se congela:** `Ctrl` + `Alt` + `F1` para ir a una consola y ahí `sudo reboot`.

---

## 🖱️ Ratón sobre las ventanas

| Acción | Efecto |
|---|---|
| `Super` + **clic izquierdo** y arrastrar | **Mover** la ventana |
| `Super` + **clic central** | Alternar ventana **flotante** |
| `Super` + **clic derecho** y arrastrar | **Redimensionar** la ventana |

---

## 🖱️ Ratón sobre la barra

En dwm los clics de la barra **sí funcionan** (viven en el array `buttons[]` de `config.h`).

| Dónde | Clic izquierdo | Clic derecho | Clic central |
|---|---|---|---|
| **Símbolo del layout** | Alternar al layout anterior | Ir a monocle | — |
| **Título de la ventana** | — | — | Pasarla al área maestra (*zoom*) |
| **Zona de estado** (derecha) | — | — | Abrir una terminal (st) |
| **Número de tag** | Ir a ese tag | Ver ese tag junto al actual | — |
| **Número de tag** + `Super` | Mover la ventana a ese tag | Añadir/quitar la ventana de ese tag | — |

---

## 💾 Pendrives y discos duros

El instalador deja configurados **udisks2 + polkit + elogind** para que puedas montar
discos **sin contraseña** (si tu usuario está en el grupo `wheel`).

No hay gestor de archivos gráfico: todo se hace desde la terminal (o desde `lf`, que
corre dentro de `st`).

| Qué quieres | Comando |
|---|---|
| Ver los discos y particiones | `lsblk -f` |
| Ver qué dispositivos reconoce udisks2 | `udisksctl list` |
| **Montar** uno (sin contraseña) | `udisksctl mount -b /dev/sdb1` |
| **Desmontarlo** | `udisksctl unmount -b /dev/sdb1` |
| Ver dónde se montó | `/run/media/TU-USUARIO/` |

> La regla que lo permite está en `/etc/polkit-1/rules.d/49-udisks2-wheel.rules`.
> Hace falta **reiniciar la sesión** después de instalar para que el grupo `wheel` surta efecto.

---

## 🎨 Cambiar estos atajos

```bash
nano ~/dwm/config.h                   # 1. busca la tecla y cámbiala
cd ~/dwm && sudo make clean install   # 2. recompila e instala
# 3. Super + Shift + E para salir, y vuelve a entrar
```

> ⚠️ `sudo make clean install` recompila **solo el proyecto en cuya carpeta estés**.
> Para la barra: `cd ~/slstatus && sudo make clean install` y luego
> `pkill -x slstatus; sleep 1; slstatus &` para ver el cambio sin cerrar sesión.

| Archivo | Qué se cambia ahí |
|---|---|
| `~/dwm/config.h` | **Atajos**, colores, fuentes, gaps, reglas de ventanas |
| `~/slstatus/config.h` | Qué muestra la barra (CPU, RAM, wifi, batería, fecha) |
| `~/.config/dwm/autostart.sh` | Programas que arrancan con dwm |
| `~/.config/picom/picom.conf` | Transparencias y compositor |
| `~/.config/lf/lfrc` | Comportamiento del gestor de archivos `lf` |
| `/usr/local/bin/dwm-session` | Wrapper de sesión (`dbus-run-session dwm`) |
| `/etc/polkit-1/rules.d/49-udisks2-wheel.rules` | Permisos de montaje de discos |

---

## 🔗 Referencias

| Proyecto | Enlace |
|---|---|
| **dwm** | https://dwm.suckless.org |
| **slstatus** (contenido de la barra) | https://tools.suckless.org/slstatus |
| **vanitygaps** (parche de gaps) | https://dwm.suckless.org/patches/vanitygaps |
| **lf** (gestor de archivos) | https://github.com/gokcehan/lf |

Manuales en tu terminal: `man 1 dwm` · `man 1 st` · `man 1 dmenu` · `man 1 lf`
