#!/bin/sh
# ============================================================
# install-dwm v1.06 — X11 con dwm + slstatus + st
# ============================================================
set +e

VERSION="1.06"
BUILD="Estable (Void + Arch + Fedora/Nobara + Debian · greetd + tuigreet)"

# Archivo de distro (se puede cambiar para pruebas)
OS_RELEASE_FILE="${OS_RELEASE_FILE:-/etc/os-release}"

# ---------- Estetica: solo visual, no cambia la logica ----------
# Colores 24-bit solo si la salida es una terminal (en logs/tuberias, texto plano).
if [ -t 1 ]; then
  ESC="$(printf '\033')"
  R="${ESC}[0m"; B="${ESC}[1m"; DIM="${ESC}[2m"
  RED="${ESC}[38;2;255;45;61m"; CYAN="${ESC}[38;2;119;226;242m"
  YEL="${ESC}[38;2;255;214;31m"; GRN="${ESC}[38;2;90;230;130m"; GREY="${ESC}[38;2;120;120;130m"
else
  R=""; B=""; DIM=""; RED=""; CYAN=""; YEL=""; GRN=""; GREY=""
fi
line(){ printf "%s%s%s\n" "$RED" "────────────────────────────────────────────────────────────" "$R"; }
# hdr TITULO: caja cyan de ancho fijo. El titulo va en ASCII (sin tildes)
# porque en sh ${#var} cuenta bytes y el ancho de la caja depende de eso.
hdr(){
  _pad=$((59 - 13 - ${#1})); [ "$_pad" -lt 1 ] && _pad=1
  printf "\n%s%s  ╔═══════════════════════════════════════════════════════════╗\n" "$CYAN" "$B"
  printf "  ║   ▓▒░  %s  ░▒▓%*s║\n" "$1" "$_pad" ""
  printf "  ╚═══════════════════════════════════════════════════════════╝%s\n" "$R"
}
banner(){
  printf "%s%s" "$RED" "$B"
  cat <<'BANNER'
  █▀▄ █░█░█ █▀▄▀█
  █▄▀ ▀▄▀▄▀ █░▀░█
BANNER
  printf "%s░▒▓ INSTALADOR DE DWM · X11 ▓▒░%s\n" "$CYAN" "$R"
  printf "%s  v%s · %s%s\n" "$GREY" "$VERSION" "$BUILD" "$R"
  line
}
info(){ printf "%s▸%s %s\n" "$CYAN" "$R" "$1"; }
warn(){ printf "  %s⚠%s %s\n" "$YEL" "$R" "$1"; }
ok(){   printf "  %s✓%s %s\n" "$GRN" "$R" "$1"; }
err(){  printf "  %s✗%s %s\n" "$RED" "$R" "$1"; exit 1; }
# confirm PREGUNTA: devuelve 0 si el usuario responde s/y. Usa ANS (no R: R es el color de reset).
confirm(){
  printf "  %s[?]%s %s [s/N]: " "$CYAN" "$R" "$1"
  read -r ANS
  case "$ANS" in s|S|y|Y|si|SI|yes|YES) return 0 ;; *) return 1 ;; esac
}

# Escribe (desde stdin) el archivo $1. Si ya existe, conserva el tuyo y deja
# la version nueva en "$1.nuevo" para que la compares.
write_config(){
  mkdir -p "$(dirname "$1")"
  if [ -f "$1" ]; then
    warn "$1 ya existe: se conserva tu version (la nueva queda en $1.nuevo)"
    cat > "$1.nuevo"
  else
    cat > "$1"
  fi
}

# Si una ejecucion anterior con sudo dejo archivos de root en la carpeta, se devuelven.
fix_owner(){
  if [ "$(stat -c %U . 2>/dev/null)" != "$REAL_USER" ] || \
     [ -n "$(find . -maxdepth 2 ! -user "$REAL_USER" -print -quit 2>/dev/null)" ]; then
    sudo chown -R "$REAL_USER:$REAL_USER" .
  fi
}

# set_kv ARCHIVO CLAVE VALOR: pone CLAVE="VALOR" (reemplaza o agrega)
set_kv(){
  [ -f "$1" ] || sudo touch "$1"
  if grep -q "^$2=" "$1" 2>/dev/null; then
    sudo sed -i "s|^$2=.*|$2=\"$3\"|" "$1"
  else
    echo "$2=\"$3\"" | sudo tee -a "$1" >/dev/null
  fi
}

# enable_svc NOMBRE_VOID UNIDAD_SYSTEMD
# Void (runit): enlaza /etc/sv/NOMBRE en /var/service. systemd (Arch, Fedora, Debian): systemctl enable.
# Un argumento vacio significa "no aplica en esta distro".
enable_svc(){
  if [ "$FAMILIA" = "void" ]; then
    [ -n "$1" ] || return 0
    if [ -d "/etc/sv/$1" ]; then
      sudo ln -sfn "/etc/sv/$1" /var/service/
      sudo sv start "$1" >/dev/null 2>&1
      ok "Servicio habilitado: $1"
    else
      warn "No existe /etc/sv/$1 (revisa que el paquete este instalado)"
    fi
  else
    [ -n "$2" ] || return 0
    if sudo systemctl enable --now "$2" >/dev/null 2>&1; then
      ok "Servicio habilitado: $2"
    else
      warn "No se pudo habilitar $2"
    fi
  fi
}

# Instala una lista de paquetes con el gestor de la distro (usa FAMILIA).
install_lote(){
  case "$FAMILIA" in
    void)   sudo xbps-install -Sy "$@" ;;
    arch)   sudo pacman -S --needed --noconfirm "$@" ;;
    fedora) sudo dnf install -y --skip-unavailable "$@" ;;
    debian) sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
  esac
}

# Un paquete es "disponible" si tiene candidato instalable (solo Debian; en Void y Arch
# se comprueba antes con xbps-query / pacman).
apt_disponible(){
  _c="$(apt-cache policy "$1" 2>/dev/null | awk '/Candidat|Candidate/{print $2; exit}')"
  [ -n "$_c" ] && [ "$_c" != "(ninguno)" ] && [ "$_c" != "(none)" ]
}

# ---------- Valores por defecto (se pueden cambiar con variables de entorno) ----------
FONT_SIZE="${FONT_SIZE:-}"
KB_LAYOUT="latam"
KB_CONSOLE="la-latin1"

DWM_REPO="https://git.suckless.org/dwm"
DWM_TAG="6.2"            # el parche vanitygaps es para 6.2
DWM_BRANCH="v6.2-local"
SLSTATUS_REPO="https://git.suckless.org/slstatus"
ST_REPO="https://git.suckless.org/st"
VANITYGAPS_URL="https://dwm.suckless.org/patches/vanitygaps/dwm-vanitygaps-6.2.diff"

# Mismo fondo que el instalador de dwl. El sitio exige User-Agent de navegador y referer.
WALLPAPER_URL="https://wallpaperaccess.com/download/anime-4k-laptop-8523463"
UA_NAVEGADOR="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

[ -t 1 ] && clear 2>/dev/null
banner
printf "  %sInicio de sesion (greetd + tuigreet) al FINAL%s\n" "$DIM" "$R"

# ---------- Usuario ----------
if [ "$(id -u)" -eq 0 ]; then
  err "No ejecutes el script como root: los archivos quedarian en /root. Usa tu usuario normal."
fi
command -v sudo >/dev/null 2>&1 || err "Falta 'sudo'. Instalalo y dale permisos a tu usuario antes de continuar."
REAL_USER="$(id -un)"
REAL_HOME="$HOME"
info "Usuario destino: $REAL_USER   HOME: $REAL_HOME"

# ---------- Credencial sudo viva durante toda la compilacion ----------
sudo -v || err "Necesitas privilegios de sudo para continuar."
( while :; do sudo -v; sleep 60; done ) >/dev/null 2>&1 &
SUDO_KEEPALIVE=$!
trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null' EXIT
trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null; exit 130' INT TERM
ok "Credencial sudo cacheada (se renueva sola durante la compilacion)"

hdr "DETECCION DEL SISTEMA"
# ---------- Deteccion de distro ----------
FAMILIA="unknown"
[ -f "$OS_RELEASE_FILE" ] && . "$OS_RELEASE_FILE"
case "${ID:-unknown}" in
  void) FAMILIA="void" ;;
  arch|manjaro|endeavouros|garuda|cachyos|arcolinux|parabola) FAMILIA="arch" ;;
  fedora|nobara) FAMILIA="fedora" ;;
  debian) FAMILIA="debian" ;;   # solo Debian: Ubuntu y Mint no estan probados
  *) case "${ID_LIKE:-}" in *arch*) FAMILIA="arch" ;; *void*) FAMILIA="void" ;; *fedora*) FAMILIA="fedora" ;; esac ;;
esac
[ "$FAMILIA" = "unknown" ] && err "Solo compatible con Void, Arch, Fedora/Nobara y Debian (detectado: ${ID:-desconocido})."

# Grupo de administradores: wheel en Void/Arch/Fedora, sudo en Debian.
if [ "$FAMILIA" = "debian" ]; then ADMIN_GROUP="sudo"; else ADMIN_GROUP="wheel"; fi

if [ "$FAMILIA" = "arch" ] && [ ! -d /run/systemd/system ]; then
  err "Arch sin systemd (p. ej. Artix con OpenRC) no esta soportado por este script."
fi
if [ "$FAMILIA" = "void" ] && [ ! -d /etc/sv ]; then
  err "Void sin runit (/etc/sv) no esta soportado por este script."
fi
if [ "$FAMILIA" = "fedora" ] || [ "$FAMILIA" = "debian" ]; then
  [ -d /run/systemd/system ] || err "Esta distro debe arrancar con systemd (no se detecto)."
fi
ok "Distro: ${PRETTY_NAME:-${ID:-desconocida}} (familia: $FAMILIA, init: $([ "$FAMILIA" = void ] && echo runit || echo systemd))"

# ---------- Espacio libre ----------
FREE_GB="$(df -BG --output=avail / 2>/dev/null | tail -n1 | tr -dc '0-9')"
if [ -n "$FREE_GB" ] && [ "$FREE_GB" -lt 10 ]; then
  warn "Solo quedan ${FREE_GB} GB libres en / (se recomiendan 10 GB)."
  confirm "Continuar igualmente?" || err "Cancelado. Libera espacio y vuelve a intentarlo."
else
  ok "Espacio libre: ${FREE_GB:-desconocido} GB"
fi

hdr "HARDWARE"
# ---------- Wifi ----------
WIFI_IFACE=""
for D in /sys/class/net/*; do
  if [ -d "$D/wireless" ]; then WIFI_IFACE="$(basename "$D")"; break; fi
done
if [ -n "$WIFI_IFACE" ]; then ok "Interfaz wifi: $WIFI_IFACE"; else warn "No se detecto wifi; no se mostrara en la barra."; fi

# ---------- Bateria ----------
BAT_NAME="$(ls /sys/class/power_supply/ 2>/dev/null | grep -E '^BAT' | head -n1)"
if [ -n "$BAT_NAME" ]; then ok "Bateria: $BAT_NAME"; else warn "No se detecto bateria; no se mostrara en la barra."; BAT_NAME="n/a"; fi

# ---------- Brillo ----------
HAY_BACKLIGHT=0
if [ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ]; then
  HAY_BACKLIGHT=1; ok "Control de brillo detectado."
else
  warn "No se detecto control de brillo; no se enlazaran las teclas de brillo."
fi

# ---------- Tamano de fuente segun la resolucion del monitor ----------
# Se puede forzar:  FONT_SIZE=13 sh install-dwm.sh
if [ -z "$FONT_SIZE" ]; then
  ANCHO=""
  for D in /sys/class/drm/card*-*; do
    [ -r "$D/status" ] || continue
    [ "$(cat "$D/status")" = "connected" ] || continue
    MODO="$(head -n1 "$D/modes" 2>/dev/null)"
    ANCHO="${MODO%%x*}"
    break
  done
  case "$ANCHO" in
    ''|*[!0-9]*) FONT_SIZE=11 ;;
    *) if [ "$ANCHO" -ge 3000 ]; then FONT_SIZE=15
       elif [ "$ANCHO" -ge 2400 ]; then FONT_SIZE=13
       else FONT_SIZE=11; fi ;;
  esac
fi
case "$FONT_SIZE" in ''|*[!0-9]*) FONT_SIZE=11 ;; esac
ok "Tamano de fuente: ${FONT_SIZE} pt"

hdr "CONFIGURACION"
# ---------- Teclado ----------
echo
printf "  %sSelecciona distribucion de teclado:%s\n" "$B" "$R"
printf "    %s1%s) us    %s2%s) es    %s3%s) latam\n" "$CYAN" "$R" "$CYAN" "$R" "$CYAN" "$R"
printf "  %sOpcion [3]:%s " "$CYAN" "$R"; read -r KB; KB="${KB:-3}"
case "$KB" in
  1) KB_LAYOUT="us";    KB_CONSOLE="us" ;;
  2) KB_LAYOUT="es";    KB_CONSOLE="es" ;;
  *) KB_LAYOUT="latam"; KB_CONSOLE="la-latin1" ;;
esac
ok "Teclado seleccionado: $KB_LAYOUT"

# ---------- Zona horaria ----------
echo
printf "  %s[?]%s Pais (ejemplo: Mexico, Paraguay, Bolivia, etc.) %s[vacio = America/Bogota]%s: " "$CYAN" "$R" "$GREY" "$R"
read -r TZIN
TZIN="${TZIN:-America/Bogota}"
resolv_tz(){
  case "$(printf '%s' "$1" | tr -d ' ')" in
    [Cc]olombia)                              echo "America/Bogota" ;;
    [Mm]exico|[Mm]éxico)                      echo "America/Mexico_City" ;;
    [Aa]rgentina)                             echo "America/Buenos_Aires" ;;
    [Ee]spana|[Ee]spaña|[Ss]pain)             echo "Europe/Madrid" ;;
    [Cc]hile)                                 echo "America/Santiago" ;;
    [Pp]eru|[Pp]erú)                          echo "America/Lima" ;;
    [Ee]cuador)                               echo "America/Guayaquil" ;;
    [Vv]enezuela)                             echo "America/Caracas" ;;
    [Uu]ruguay)                               echo "America/Montevideo" ;;
    [Bb]olivia)                               echo "America/La_Paz" ;;
    [Pp]araguay)                              echo "America/Asuncion" ;;
    [Gg]uatemala)                             echo "America/Guatemala" ;;
    [Cc]uba)                                  echo "America/Havana" ;;
    [Cc]osta[Rr]ica)                          echo "America/Costa_Rica" ;;
    [Pp]anama|[Pp]anamá)                      echo "America/Panama" ;;
    [Rr]epublica[Dd]ominicana)                echo "America/Santo_Domingo" ;;
    [Ee]stados[Uu]nidos|[Uu][Ss][Aa])         echo "America/New_York" ;;
    *)  # o lo busca tal cual en el arbol zoneinfo
        if [ -f "/usr/share/zoneinfo/$1" ]; then echo "$1"
        else find /usr/share/zoneinfo -type f 2>/dev/null | grep -i "/$1\$" | head -n1 | sed 's|.*/zoneinfo/||'; fi ;;
  esac
}
TZONE="$(resolv_tz "$TZIN")"
if [ -n "$TZONE" ] && [ -f "/usr/share/zoneinfo/$TZONE" ]; then
  sudo ln -sf "/usr/share/zoneinfo/$TZONE" /etc/localtime
  if [ "$FAMILIA" = "void" ]; then
    set_kv /etc/rc.conf TIMEZONE "$TZONE"      # en Void, rc.conf manda en cada arranque
  else
    sudo timedatectl set-timezone "$TZONE" 2>/dev/null || true
  fi
  ok "Zona horaria: $TZONE"
else
  warn "No encontre la zona '$TZIN'; se deja la que ya tenias"
fi

# ---------- Gestor de sesion ya instalado (lightdm, gdm, sddm...) ----------
# Igual que install-dwl: se pregunta si cambiar a greetd + tuigreet o conservar el que hay.
# Por defecto (Enter) se deja el que hay.
DM_FOUND=""
for DM in lightdm gdm gdm3 sddm xdm lxdm; do
  if [ -L "/var/service/$DM" ] || [ -f "/usr/lib/systemd/system/$DM.service" ] || command -v "$DM" >/dev/null 2>&1; then
    DM_FOUND="$DM_FOUND $DM"
  fi
done
DM_FOUND="${DM_FOUND# }"
USE_GREETD=1
GREETER_OK=1
if [ "$FAMILIA" = "debian" ]; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get update >/dev/null 2>&1
  apt_disponible tuigreet || GREETER_OK=0
fi
if [ "$GREETER_OK" = 0 ]; then
  USE_GREETD=0
  warn "tuigreet no esta en los repos de tu Debian: no se configura greetd."
  if [ -n "$DM_FOUND" ]; then
    ok "Se conserva tu gestor de sesion: $DM_FOUND. Elige dwm en su menu."
  else
    warn "No tienes gestor de sesion: instala lightdm (sudo apt install lightdm lightdm-gtk-greeter) para entrar a dwm."
  fi
elif [ -n "$DM_FOUND" ]; then
  echo
  warn "Ya tienes un gestor de sesion instalado: $DM_FOUND"
  if confirm "Cambiarlo a greetd + tuigreet? (N = dejar $DM_FOUND y elegir dwm en su menu)"; then
    USE_GREETD=1
    info "Se cambiara a greetd + tuigreet (el otro gestor se desactiva, no se desinstala)."
  else
    USE_GREETD=0
    ok "Se mantiene $DM_FOUND. greetd no se configura."
  fi
fi

# ==================== PAQUETES ====================
# Cada distro tiene su propia lista; los nombres cambian entre distros.
case "$FAMILIA" in

  void)
    hdr "PAQUETES - VOID LINUX"
    info "Sincronizando indice de paquetes..."
    sudo xbps-install -Sy xbps >/dev/null 2>&1 || warn "No se pudo actualizar xbps (continuo)"
  sudo xbps-install -S >/dev/null 2>&1 || warn "No se pudo sincronizar (continuo con el indice local)"

    PKGS_VOID="
      base-devel git curl wget nano file ncurses
      libX11-devel libXft-devel libXinerama-devel freetype-devel fontconfig-devel
      xorg xinit dbus
      dmenu slock dunst picom feh
      alsa-utils brightnessctl scrot util-linux xdg-utils
      nerd-fonts lf mpv zathura zathura-pdf-poppler
      fastfetch btop cowsay chrony firefox
      greetd tuigreet
      udisks2 polkit elogind polkit-gnome gvfs gvfs-mtp ntfs-3g exfatprogs
    "
    PKG_OK=""; PKG_NO=""
    for p in $PKGS_VOID; do
      if xbps-query -R "$p" >/dev/null 2>&1; then PKG_OK="$PKG_OK $p"; else PKG_NO="$PKG_NO $p"; fi
    done
    [ -n "$PKG_NO" ] && warn "No estan en los repos, se omiten:$PKG_NO"

    info "Instalando paquetes (lote)..."
    # shellcheck disable=SC2086
    if install_lote $PKG_OK; then
      ok "Paquetes instalados"
    else
      warn "El lote fallo: instalo uno a uno para no perder todo"
      for p in $PKG_OK; do
        install_lote "$p" >/dev/null 2>&1 || warn "No se pudo instalar: $p"
      done
    fi
    ;;

  arch)
    hdr "PAQUETES - ARCH LINUX"
    info "Sincronizando indice de paquetes..."
    sudo pacman -Sy --noconfirm >/dev/null 2>&1 || warn "No se pudo sincronizar la base de datos de pacman"

    PKGS_ARCH="
      base-devel git curl wget nano file ncurses
      libx11 libxft libxinerama freetype2 fontconfig
      xorg-server xorg-xinit dbus
      dmenu slock dunst picom feh
      alsa-utils brightnessctl scrot util-linux xdg-utils
      ttf-jetbrains-mono-nerd lf mpv zathura zathura-pdf-poppler
      fastfetch btop cowsay chrony firefox
      greetd greetd-tuigreet
      udisks2 polkit polkit-gnome gvfs gvfs-mtp ntfs-3g exfatprogs
    "
    PKG_OK=""; PKG_NO=""
    for p in $PKGS_ARCH; do
      if pacman -Si "$p" >/dev/null 2>&1 || pacman -Q "$p" >/dev/null 2>&1; then
        PKG_OK="$PKG_OK $p"
      else
        PKG_NO="$PKG_NO $p"
      fi
    done
    [ -n "$PKG_NO" ] && warn "No estan en los repos oficiales, se intentara por AUR:$PKG_NO"

    info "Instalando paquetes (lote)..."
    # shellcheck disable=SC2086
    if sudo pacman -Syu --needed --noconfirm $PKG_OK; then
      ok "Paquetes instalados"
    else
      warn "El lote fallo: instalo uno a uno para no perder todo"
      for p in $PKG_OK; do
        sudo pacman -S --needed --noconfirm "$p" >/dev/null 2>&1 || warn "No se pudo instalar: $p"
      done
    fi

    # Lo que no esta en los repos oficiales: se busca con un helper de AUR si hay uno
    if [ -n "$PKG_NO" ]; then
      for h in yay paru; do
        if command -v "$h" >/dev/null 2>&1; then
          info "Intentando por AUR con $h:$PKG_NO"
          # shellcheck disable=SC2086
          "$h" -S --needed --noconfirm $PKG_NO >/dev/null 2>&1 || warn "El AUR fallo para:$PKG_NO"
          break
        fi
      done
      if ! command -v yay >/dev/null 2>&1 && ! command -v paru >/dev/null 2>&1; then
        warn "No hay helper de AUR (yay/paru): instala a mano lo que falte de la lista de arriba"
      fi
    fi
    ;;

  fedora)
    # Fedora y Nobara (dnf). dwm no esta empaquetado: se compila desde fuente.
    hdr "PAQUETES - FEDORA / NOBARA"
    info "Actualizando el sistema y el indice de paquetes..."
    sudo dnf -y makecache >/dev/null 2>&1 || warn "No se pudo actualizar el indice de dnf (continuo)"

    # Nombres de Fedora: libX11-devel (cabeceras para compilar),
    # xorg-x11-server-Xorg/xinit (X11), chronyd (servicio), firefox.
    # Nerd Font: no esta en Fedora; se descarga en install_nerd_font (mas abajo).
    PKGS_FEDORA="
      @development-tools git curl wget nano file ncurses
      libX11-devel libXft-devel libXinerama-devel freetype-devel fontconfig-devel
      xorg-x11-server-Xorg xorg-x11-xinit dbus-x11
      dmenu slock dunst picom feh
      alsa-utils brightnessctl scrot util-linux xdg-utils
      lf mpv zathura zathura-pdf-poppler
      fastfetch btop cowsay chrony firefox
      greetd greetd-selinux tuigreet
      udisks2 polkit polkit-gnome gvfs gvfs-mtp ntfs-3g exfatprogs
    "
    info "Instalando paquetes (lote)..."
    # shellcheck disable=SC2086
    if install_lote $PKGS_FEDORA; then
      ok "Paquetes instalados"
    else
      warn "dnf reporto errores (revisa la salida de arriba); el resto se instalo"
    fi
    ;;

  debian)
    # Debian (apt). Solo Debian: Ubuntu y Mint no estan probados.
    hdr "PAQUETES - DEBIAN"
    info "Sincronizando indice de paquetes..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get update >/dev/null 2>&1 || warn "No se pudo sincronizar apt"

    # Nombres de Debian: build-essential, libx11-dev..., xserver-xorg (X11),
    # policykit-1-gnome (agente polkit), firefox-esr (firefox en Debian es esr),
    # fonts-jetbrains-mono (la Nerd Font se descarga en install_nerd_font).
    PKGS_DEBIAN="
      build-essential git curl wget nano file
      libx11-dev libxft-dev libxinerama-dev libfreetype-dev libfontconfig-dev
      xserver-xorg xinit dbus-x11
      dmenu slock dunst picom feh
      alsa-utils brightnessctl scrot util-linux xdg-utils
      fonts-jetbrains-mono lf mpv zathura zathura-pdf-poppler
      fastfetch btop cowsay chrony firefox-esr
      greetd tuigreet
      udisks2 policykit-1-gnome gvfs gvfs-backends ntfs-3g exfatprogs
    "
    PKG_OK=""; PKG_NO=""
    for p in $PKGS_DEBIAN; do
      if apt_disponible "$p"; then PKG_OK="$PKG_OK $p"; else PKG_NO="$PKG_NO $p"; fi
    done
    [ -n "$PKG_NO" ] && warn "No estan en los repos de tu version de Debian, se omiten:$PKG_NO"

    info "Instalando paquetes (lote)..."
    # shellcheck disable=SC2086
    if install_lote $PKG_OK; then
      ok "Paquetes instalados"
    else
      warn "El lote fallo: instalo uno a uno para no perder todo"
      for p in $PKG_OK; do
        install_lote "$p" >/dev/null 2>&1 || warn "No se pudo instalar: $p"
      done
    fi
    ;;
esac

# Nerd Font para Fedora y Debian: ninguna la empaqueta; se baja la release oficial
# de Nerd Fonts a ~/.local/share/fonts (sin tocarla si ya existe).
install_nerd_font(){
  case "$FAMILIA" in fedora|debian) ;; *) return 0 ;; esac
  NF_DIR="$REAL_HOME/.local/share/fonts/JetBrainsMonoNerd"
  if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then
    ok "JetBrainsMono Nerd Font ya instalada"
    return 0
  fi
  info "Descargando JetBrainsMono Nerd Font..."
  mkdir -p "$NF_DIR"
  if command -v unzip >/dev/null 2>&1 || install_lote unzip >/dev/null 2>&1; then
    if curl -fsSL --max-time 180 -o /tmp/JetBrainsMono.zip \
         "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" \
       && unzip -oq /tmp/JetBrainsMono.zip -d "$NF_DIR"; then
      rm -f /tmp/JetBrainsMono.zip
      fc-cache -f >/dev/null 2>&1
      ok "JetBrainsMono Nerd Font instalada en $NF_DIR"
      return 0
    fi
  fi
  rm -f /tmp/JetBrainsMono.zip
  warn "No pude instalar la Nerd Font: la barra usara una fuente de respaldo"
}
install_nerd_font

# En Arch y Void la Nerd Font ya viene de los repos (ttf-jetbrains-mono-nerd / nerd-fonts).
# Fedora/Debian: ver install_nerd_font arriba.

# ==================== SERVICIOS BASE ====================
hdr "SERVICIOS BASE"
# Nombre del servicio de chrony: "chronyd" en Void, Arch y Fedora; "chrony" en Debian.
CHRONY_UNIT="chronyd"; [ "$FAMILIA" = "debian" ] && CHRONY_UNIT="chrony"
enable_svc dbus dbus
enable_svc polkitd polkit
enable_svc udevd ""           # Arch/Fedora/Debian: systemd-udevd ya corre solo
enable_svc elogind ""         # Arch/Fedora/Debian: systemd-logind va incluido en systemd
enable_svc chronyd "$CHRONY_UNIT"

if [ "$FAMILIA" = "void" ] && [ -e /var/service/acpid ]; then
  warn "elogind y acpid gestionan los mismos eventos ACPI; deshabilito acpid."
  sudo rm -f /var/service/acpid
fi

# Teclado de consola
if [ "$FAMILIA" = "void" ]; then
  set_kv /etc/rc.conf KEYMAP "$KB_CONSOLE"
elif [ "$FAMILIA" = "debian" ]; then
  set_kv /etc/default/keyboard XKBLAYOUT "$KB_LAYOUT"   # Debian usa /etc/default/keyboard
else
  set_kv /etc/vconsole.conf KEYMAP "$KB_CONSOLE"
fi
sudo loadkeys "$KB_CONSOLE" 2>/dev/null || true
ok "Teclado de consola: $KB_CONSOLE"

# Teclado de Xorg (tambien aplica en la pantalla de login)
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/00-keyboard.conf >/dev/null <<EOF
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "$KB_LAYOUT"
EndSection
EOF
command -v setxkbmap >/dev/null 2>&1 && [ -n "$DISPLAY" ] && setxkbmap "$KB_LAYOUT" 2>/dev/null
ok "Teclado de Xorg: $KB_LAYOUT"

# ---------- Grupos del usuario (regla de polkit y hardware) ----------
sudo usermod -aG "$ADMIN_GROUP",video,input "$REAL_USER"
ok "Grupos para $REAL_USER: $ADMIN_GROUP, video, input"
warn "Los grupos se aplican al iniciar una sesion nueva (cierra sesion o reinicia)."

# ==================== DWM ====================
hdr "COMPILAR DWM"
cd "$REAL_HOME" || err "No existe $REAL_HOME"
[ -d dwm ] || git clone "$DWM_REPO" || err "No se pudo clonar dwm"
cd dwm || err "No se pudo entrar en $REAL_HOME/dwm"
fix_owner

info "Fijando dwm en el tag $DWM_TAG (compatible con vanitygaps)..."
git fetch --tags -q
git checkout -q -B "$DWM_BRANCH" "tags/$DWM_TAG" || err "No existe el tag $DWM_TAG en el repo de dwm"

info "Aplicando parche vanitygaps..."
[ -f dwm-vanitygaps-6.2.diff ] || curl -fsSO "$VANITYGAPS_URL" || err "No se pudo descargar el parche vanitygaps"
if [ ! -f .vanitygaps-applied ]; then
  git checkout -q -- dwm.c config.def.h config.mk Makefile 2>/dev/null
  rm -f ./*.rej ./*.orig
  if patch -p1 -N --fuzz=3 < dwm-vanitygaps-6.2.diff >/dev/null 2>&1; then
    touch .vanitygaps-applied
    ok "Parche vanitygaps aplicado"
  else
    err "El parche no aplico. Revisa dwm.c.rej. Para reintentar: cd ~/dwm && git checkout -- . && rm -f .vanitygaps-applied"
  fi
else
  ok "Parche vanitygaps ya aplicado (se omite)"
fi

info "Escribiendo config.h de dwm (paleta Tokyo Night)..."
CFG_TMP="$(mktemp)"
cat > "$CFG_TMP" <<'CFG_EOF'
#include <X11/XF86keysym.h>
/* See LICENSE file for copyright and license details. */

/* appearance */
static const unsigned int borderpx  = 2;
static const unsigned int gappih    = 4;
static const unsigned int gappiv    = 4;
static const unsigned int gappoh    = 4;
static const unsigned int gappov    = 4;
static       int smartgaps          = 0;
static const unsigned int snap      = 32;
static const int showbar            = 1;
static const int topbar             = 1;
static const char *fonts[]          = { "JetBrainsMono Nerd Font:size=11" };
static const char dmenufont[]       = "JetBrainsMono Nerd Font:size=11";

/* Paleta Tokyo Night, la misma que el instalador de dwl (dwlb y foot) */
static const char col_gray1[]       = "#1a1b26";  /* fondo */
static const char col_gray2[]       = "#3b4261";  /* borde normal */
static const char col_gray3[]       = "#c0caf5";  /* texto normal */
static const char col_gray4[]       = "#1a1b26";  /* texto sobre seleccion */
static const char col_cyan[]        = "#7dcfff";  /* seleccion y borde activo */
static const char *colors[][3]      = {
        /*               fg         bg         border   */
        [SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
        [SchemeSel]  = { col_gray4, col_cyan,  col_cyan  },
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
        /* xprop(1): WM_CLASS(STRING) = instance, class ; WM_NAME(STRING) = title */
        /* class      instance    title       tags mask     isfloating   monitor */
        { "Gimp",     NULL,       NULL,       0,            1,           -1 },
        /* El WM_CLASS real de Firefox es "Firefox" (F mayuscula). Verificalo con: xprop WM_CLASS */
        { "Firefox",  NULL,       NULL,       1 << 0,       0,           -1 },
};

/* layout(s) */
static const float mfact     = 0.50;
static const int nmaster     = 1;
static const int resizehints = 1;

#define FORCE_VSPLIT 1
#include "vanitygaps.c"

static const Layout layouts[] = {
        /* symbol     arrange function */
        { "[]=",      tile },
        { "><>",      NULL },
        { "[M]",      monocle },
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
        { MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
        { MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
        { MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
        { MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0";
static const char *dmenucmd[]   = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
static const char *termcmd[]    = { "st", NULL };
static const char *browsercmd[] = { "firefox", NULL };

static const Key keys[] = {
        /* modifier                     key        function        argument */
        { MODKEY,                       XK_d,          spawn,          {.v = dmenucmd } },
        { MODKEY,                       XK_Return,     spawn,          {.v = termcmd } },
        { MODKEY,                       XK_t,          spawn,          {.v = termcmd } },
        { MODKEY,                       XK_b,          spawn,          {.v = browsercmd } },
        { MODKEY,                       XK_e,          spawn,          SHCMD("st -e lf") },

        { MODKEY,                       XK_q,          killclient,     {0} },
        { MODKEY,                       XK_f,          setlayout,      {.v = &layouts[2]} },
        { MODKEY,                       XK_w,          togglebar,      {0} },
        { MODKEY|ShiftMask,             XK_t,          togglefloating, {0} },
        { MODKEY,                       XK_r,          setlayout,      {0} },

        { MODKEY,                       XK_j,          focusstack,     {.i = +1 } },
        { MODKEY,                       XK_k,          focusstack,     {.i = -1 } },
        { MODKEY,                       XK_h,          setmfact,       {.f = -0.05} },
        { MODKEY,                       XK_l,          setmfact,       {.f = +0.05} },
        { MODKEY,                       XK_Down,       focusstack,     {.i = +1 } },
        { MODKEY,                       XK_Up,         focusstack,     {.i = -1 } },

        { MODKEY,                       XK_i,          incnmaster,     {.i = +1 } },
        { MODKEY,                       XK_comma,      focusmon,       {.i = -1 } },
        { MODKEY,                       XK_period,     focusmon,       {.i = +1 } },
        { MODKEY|ShiftMask,             XK_comma,      tagmon,         {.i = -1 } },
        { MODKEY|ShiftMask,             XK_period,     tagmon,         {.i = +1 } },

        /* gaps (vanitygaps) */
        { MODKEY|ControlMask,           XK_u,          incrgaps,       {.i = +1 } },
        { MODKEY|ControlMask|ShiftMask, XK_u,          incrgaps,       {.i = -1 } },
        { MODKEY|ControlMask,           XK_0,          togglegaps,     {0} },
        { MODKEY|ControlMask|ShiftMask, XK_0,          defaultgaps,    {0} },

        /* multimedia */
        { 0, XF86XK_AudioRaiseVolume,   spawn, SHCMD("amixer set Master 3%+") },
        { 0, XF86XK_AudioLowerVolume,   spawn, SHCMD("amixer set Master 3%-") },
        { 0, XF86XK_AudioMute,          spawn, SHCMD("amixer set Master toggle") },
        { 0, XF86XK_MonBrightnessUp,    spawn, SHCMD("brightnessctl set +5%") },
        { 0, XF86XK_MonBrightnessDown,  spawn, SHCMD("brightnessctl set 5%-") },

        { 0,                            XK_Print,      spawn,          SHCMD("scrot ~/Pictures/%Y-%m-%d_%H-%M-%S.png") },

        { MODKEY,                       XK_space,      setlayout,      {0} },
        { MODKEY,                       XK_Tab,        view,           {0} },
        { MODKEY|ShiftMask,             XK_e,          quit,           {0} },

        TAGKEYS(                        XK_1,                      0)
        TAGKEYS(                        XK_2,                      1)
        TAGKEYS(                        XK_3,                      2)
        TAGKEYS(                        XK_4,                      3)
        TAGKEYS(                        XK_5,                      4)
        TAGKEYS(                        XK_6,                      5)
        TAGKEYS(                        XK_7,                      6)
        TAGKEYS(                        XK_8,                      7)
        TAGKEYS(                        XK_9,                      8)
};

/* button definitions */
static const Button buttons[] = {
        /* click                event mask      button          function        argument */
        { ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
        { ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
        { ClkWinTitle,          0,              Button2,        zoom,           {0} },
        { ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
        { ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
        { ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
        { ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
        { ClkTagBar,            0,              Button1,        view,           {0} },
        { ClkTagBar,            0,              Button3,        toggleview,     {0} },
        { ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
        { ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
CFG_EOF
sed -i "s/size=11/size=$FONT_SIZE/g" "$CFG_TMP"
[ "$HAY_BACKLIGHT" -eq 0 ] && sed -i '/XF86XK_MonBrightness/d' "$CFG_TMP"
write_config config.h < "$CFG_TMP"
rm -f "$CFG_TMP"

info "Compilando dwm..."
make clean >/dev/null 2>&1
make >/tmp/dwm-make.log 2>&1 || err "Fallo la compilacion de dwm (log: /tmp/dwm-make.log)"
sudo make install >/dev/null 2>&1 || err "Fallo 'make install' de dwm"
ok "dwm $DWM_TAG + vanitygaps instalado en /usr/local/bin/dwm"

# ==================== SLSTATUS ====================
hdr "COMPILAR SLSTATUS"
cd "$REAL_HOME" || err "No existe $REAL_HOME"
[ -d slstatus ] || git clone "$SLSTATUS_REPO" || err "No se pudo clonar slstatus"
cd slstatus || err "No se pudo entrar en $REAL_HOME/slstatus"
fix_owner

info "Escribiendo config.h de slstatus (barra como en la captura)..."
{
    cat <<'SL_EOF'
/* See LICENSE file for copyright and license details. */
const unsigned int interval = 1000;
static const char unknown_str[] = "n/a";
#define MAXLEN 2048

static const struct arg args[] = {
    /* funcion         format            argumento */
    /* Mismo orden que la barra de dwl: [CPU] [RAM] [VOL] ... hora.
       CPU = carga de 1 min (primer valor de /proc/loadavg), como en la captura. */
    { run_command,    "[CPU %s] ",     "cut -d' ' -f1 /proc/loadavg" },
    { ram_used,       "[RAM %s] ",     NULL },
    { run_command,    "[VOL %s] ",     "amixer get Master 2>/dev/null | grep -o '[0-9]*%' | head -n1" },
SL_EOF
    if [ -n "$WIFI_IFACE" ]; then
        printf '    { wifi_essid,     "[WIFI %%s] ",   "%s" },\n' "$WIFI_IFACE"
    fi
    if [ "$BAT_NAME" != "n/a" ]; then
        printf '    { battery_perc,   "[BAT %%s%%%%] ",  "%s" },\n' "$BAT_NAME"
    fi
    cat <<'SL_EOF'
    { datetime,       "%s",            "%H:%M %d/%m" },
};
SL_EOF
} | write_config config.h

info "Compilando slstatus..."
make clean >/dev/null 2>&1
make >/tmp/slstatus-make.log 2>&1 || err "Fallo la compilacion de slstatus (log: /tmp/slstatus-make.log)"
sudo make install >/dev/null 2>&1 || err "Fallo 'make install' de slstatus"
ok "slstatus instalado en /usr/local/bin/slstatus"

# ==================== ST (TERMINAL) ====================
hdr "COMPILAR ST (TERMINAL)"
# st no lee colores de Xresources: se compila con su config.h (paleta y fuente).
# La transparencia la pone picom (mas abajo), igual que alpha=0.75 en foot.
cd "$REAL_HOME" || err "No existe $REAL_HOME"
[ -d st ] || git clone "$ST_REPO" || err "No se pudo clonar st"
cd st || err "No se pudo entrar en $REAL_HOME/st"
fix_owner

ST_PX=$(( (FONT_SIZE * 4 + 1) / 3 ))   # puntos a pixeles (11 pt = 15 px)
ST_COLORS_TMP="$(mktemp)"
cat > "$ST_COLORS_TMP" <<'ST_EOF'
static const char *colorname[] = {
	/* 8 normal colors */
	"#15161e", "#f7768e", "#9ece6a", "#e0af68", "#7aa2f7", "#bb9af7", "#7dcfff", "#a9b1d6",

	/* 8 bright colors */
	"#414868", "#f7768e", "#9ece6a", "#e0af68", "#7aa2f7", "#bb9af7", "#7dcfff", "#c0caf5",

	[255] = 0,

	/* more colors can be added after 255 to use with DefaultXX */
	"#c0caf5", /* cursor */
	"#1a1b26", /* reverse cursor */
	"#c0caf5", /* default foreground colour */
	"#1a1b26", /* default background colour */
};
ST_EOF
info "Escribiendo config.h de st (JetBrains Mono ${ST_PX}px, paleta Tokyo Night)..."
ST_CFG_TMP="$(mktemp)"
awk -v colors="$ST_COLORS_TMP" -v px="$ST_PX" '
    /^static char \*font = / {
        print "static char *font = \"JetBrainsMono Nerd Font:pixelsize=" px ":antialias=true:autohint=true\";"
        next
    }
    /^static const char \*colorname\[\] = \{/ {
        while ((getline line < colors) > 0) print line
        close(colors)
        skip = 1
        next
    }
    skip && /^\};/ { skip = 0; next }
    !skip { print }
' config.def.h > "$ST_CFG_TMP"
rm -f "$ST_COLORS_TMP"
grep -q 'JetBrainsMono Nerd Font' "$ST_CFG_TMP" || err "No se pudo escribir la fuente en el config.h de st"
write_config config.h < "$ST_CFG_TMP"
rm -f "$ST_CFG_TMP"

info "Compilando st..."
make clean >/dev/null 2>&1
make >/tmp/st-make.log 2>&1 || err "Fallo la compilacion de st (log: /tmp/st-make.log)"
sudo make install >/dev/null 2>&1 || err "Fallo 'make install' de st"
ok "st instalado en /usr/local/bin/st"

# ==================== POLKIT (DISCOS SIN CONTRASENA) ====================
hdr "POLKIT - DISCOS Y PENDRIVES"
# Regla para el grupo de administradores (wheel o sudo): montar, desmontar y expulsar
# con udisks2 sin contrasena. Se lee en orden: el 49 gana a las reglas por defecto (50).
sudo mkdir -p /etc/polkit-1/rules.d
sudo tee /etc/polkit-1/rules.d/49-udisks2-wheel.rules >/dev/null <<'POLKIT_EOF'
// Permitir a los usuarios de los grupos "wheel" (Void, Arch, Fedora) o "sudo" (Debian)
// montar/desmontar discos y pendrives con udisks2 SIN pedir contrasena.
polkit.addRule(function(action, subject) {
    var permitidos = [
        "org.freedesktop.udisks2.filesystem-mount",
        "org.freedesktop.udisks2.filesystem-mount-system",
        "org.freedesktop.udisks2.filesystem-mount-other-seat",
        "org.freedesktop.udisks2.filesystem-mount-system-other-seat",
        "org.freedesktop.udisks2.eject-media",
        "org.freedesktop.udisks2.eject-media-other-seat",
        "org.freedesktop.udisks2.power-off-drive",
        "org.freedesktop.udisks2.power-off-drive-other-seat",
        "org.freedesktop.udisks2.encrypted-unlock",
        "org.freedesktop.udisks2.encrypted-unlock-other-seat",
        "org.freedesktop.udisks2.modify-device"
    ];
    if (permitidos.indexOf(action.id) >= 0 &&
        (subject.isInGroup("wheel") || subject.isInGroup("sudo"))) {
        return polkit.Result.YES;
    }
});
POLKIT_EOF
sudo chmod 0644 /etc/polkit-1/rules.d/49-udisks2-wheel.rules
ok "Regla de polkit: /etc/polkit-1/rules.d/49-udisks2-wheel.rules"

# ==================== PICOM, FONDO, TEMA, LF, ATAJOS ====================
hdr "TEMA: PICOM, FONDO Y LF"
# ---------- picom: transparencia de la terminal (75 %, como alpha=0.75 de foot) ----------
write_config "$REAL_HOME/.config/picom/picom.conf" <<'PICOM_EOF'
backend = "xrender";
vsync = false;

opacity-rule = [
  "75:class_g = 'st-256color'"
];

shadow = false;
fading = false;
PICOM_EOF
ok "Transparencia de la terminal: 75 % (picom)"

# ---------- lf: gestor de archivos en terminal ----------
write_config "$REAL_HOME/.config/lf/lfrc" <<'LF_EOF'
set ifs "\n"

cmd open ${{
    case $(file --mime-type -Lb "$f") in
        text/*|application/json|inode/x-empty)
            nano $fx ;;
        image/*)
            setsid -f feh --scale-down --auto-zoom $fx >/dev/null 2>&1 ;;
        video/*|audio/*)
            setsid -f mpv $fx >/dev/null 2>&1 ;;
        application/pdf)
            setsid -f zathura $fx >/dev/null 2>&1 ;;
        *)
            for f in $fx; do setsid -f xdg-open "$f" >/dev/null 2>&1; done ;;
    esac
}}
LF_EOF
ok "lf configurado: ~/.config/lf/lfrc"

# ---------- Fondo: igual que dwl. Solo se reemplaza si lo puso el instalador ----------
WALLPAPER_DIR="$REAL_HOME/Pictures"
WALLPAPER_PATH="$WALLPAPER_DIR/wallpaper.jpg"
WALLPAPER_MARK="$WALLPAPER_DIR/.wallpaper-instalador"
mkdir -p "$WALLPAPER_DIR"
if [ ! -f "$WALLPAPER_PATH" ]; then
  info "Descargando fondo por defecto..."
  if curl -fsSL --max-time 60 -A "$UA_NAVEGADOR" -e "https://wallpaperaccess.com/" \
       -o "$WALLPAPER_PATH.tmp" "$WALLPAPER_URL" 2>/dev/null \
     && [ -s "$WALLPAPER_PATH.tmp" ] && file -b "$WALLPAPER_PATH.tmp" | grep -qi image; then
    mv "$WALLPAPER_PATH.tmp" "$WALLPAPER_PATH"
    touch "$WALLPAPER_MARK"
    ok "Fondo guardado en $WALLPAPER_PATH"
  else
    rm -f "$WALLPAPER_PATH.tmp"
    warn "No se pudo descargar el fondo; copia tu imagen a $WALLPAPER_PATH"
  fi
else
  ok "Fondo existente conservado: $WALLPAPER_PATH"
fi
[ -n "$DISPLAY" ] && command -v feh >/dev/null 2>&1 && [ -f "$WALLPAPER_PATH" ] && feh --bg-fill "$WALLPAPER_PATH"

# ---------- Autostart: lo que arranca dentro de dwm ----------
hdr "SESION DWM"
if [ ! -f "$REAL_HOME/.config/dwm/autostart.sh" ]; then
  mkdir -p "$REAL_HOME/.config/dwm"
  {
    cat <<EOF
#!/bin/sh
# Programas que se inician con dwm. Edita libremente este archivo.
# Se ejecuta DENTRO del bus de sesion D-Bus (lo lanza dwm-session).

# Fondo de pantalla
[ -f "$WALLPAPER_PATH" ] && feh --bg-fill "$WALLPAPER_PATH" &

# Compositor, notificaciones y barra de estado
picom --config "$REAL_HOME/.config/picom/picom.conf" &
dunst &
slstatus &

EOF
    cat <<'AUTO_EOF'
# Agente de autenticacion polkit (para las acciones que piden contrasena)
# Nombres de Void/Arch/Fedora y de Debian (policykit-1-gnome).
for AGENTE in \
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
    /usr/lib64/polkit-gnome/polkit-gnome-authentication-agent-1 \
    /usr/libexec/polkit-gnome-authentication-agent-1 \
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1; do
    if [ -x "$AGENTE" ]; then "$AGENTE" & break; fi
done
AUTO_EOF
  } > "$REAL_HOME/.config/dwm/autostart.sh"
  chmod +x "$REAL_HOME/.config/dwm/autostart.sh"
  ok "Autostart: ~/.config/dwm/autostart.sh"
else
  ok "Autostart existente conservado: ~/.config/dwm/autostart.sh"
fi

# ---------- Wrapper de sesion (dbus-run-session) ----------
sudo tee /usr/local/bin/dwm-session >/dev/null <<'SESSION_EOF'
#!/bin/sh
# Sesion dwm: la usan greetd (via dwm-startx), otros gestores (dwm.desktop) y startx.
# Garantiza XDG_RUNTIME_DIR y un bus de sesion D-Bus; dentro corre autostart y dwm.

if [ -z "$XDG_RUNTIME_DIR" ]; then
    XDG_RUNTIME_DIR="/run/user/$(id -u)"
    export XDG_RUNTIME_DIR
    [ -d "$XDG_RUNTIME_DIR" ] || mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null
    chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null
fi

DWM_INNER="${DWM_SESSION_INNER:-/usr/local/bin/dwm-session-inner}"

if [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
    exec "$DWM_INNER"
fi
if command -v dbus-run-session >/dev/null 2>&1; then
    exec dbus-run-session "$DWM_INNER"
fi
exec "$DWM_INNER"
SESSION_EOF
sudo chmod 0755 /usr/local/bin/dwm-session

sudo tee /usr/local/bin/dwm-session-inner >/dev/null <<'INNER_EOF'
#!/bin/sh
# Corre DENTRO del bus de sesion (lo invoca /usr/local/bin/dwm-session).
if [ -n "$DISPLAY" ] && command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment DISPLAY XAUTHORITY XDG_RUNTIME_DIR 2>/dev/null
fi
[ -x "$HOME/.config/dwm/autostart.sh" ] && "$HOME/.config/dwm/autostart.sh" &
exec dwm
INNER_EOF
sudo chmod 0755 /usr/local/bin/dwm-session-inner
ok "Sesion: /usr/local/bin/dwm-session (dbus-run-session + dwm)"

# ~/.xinitrc para usar 'startx'
[ -f "$REAL_HOME/.xinitrc" ] && cp "$REAL_HOME/.xinitrc" "$REAL_HOME/.xinitrc.bak"
echo "exec /usr/local/bin/dwm-session" > "$REAL_HOME/.xinitrc"
ok "~/.xinitrc listo (para startx)"

# Entrada de sesion para el gestor de inicio
sudo mkdir -p /usr/share/xsessions
sudo tee /usr/share/xsessions/dwm.desktop >/dev/null <<'DESK_EOF'
[Desktop Entry]
Name=dwm
Comment=Dynamic window manager (dwm + slstatus + picom)
Exec=/usr/local/bin/dwm-session
TryExec=/usr/local/bin/dwm-session
Type=Application
DesktopNames=dwm
X-LightDM-Session-Type=x11
DESK_EOF
ok "Sesion registrada: /usr/share/xsessions/dwm.desktop"

# ---------- Chuleta de atajos (texto plano, para nano) ----------
hdr "CHULETA DE ATAJOS"
write_config "$REAL_HOME/Atajos.txt" <<'ATAJOS_EOF'

==============================================================================
 ATAJOS DE TECLADO - dwm + slstatus
==============================================================================
  Lista completa de los atajos que deja configurados el instalador.
  "Super" es la tecla del logo de Windows (en teclados Mac es Command).

------------------------------------------------------------------------------
 SI ACABAS DE INSTALAR, CON ESTO YA ALCANZA
------------------------------------------------------------------------------

  Super+Enter.................. abrir una terminal (st)
  Super+d...................... lanzador de programas (dmenu)
  Super+q...................... cerrar la ventana actual
  Super+e...................... gestor de archivos en terminal (lf)
  Super+b...................... navegador (Firefox)
  Super+Shift+e................ cerrar sesion (volver al login)

  Con esos seis ya puedes manejarte. El resto lo vas aprendiendo sobre la
  marcha.

------------------------------------------------------------------------------
 GLOSARIO RAPIDO
------------------------------------------------------------------------------

  tag.......................... un "escritorio virtual"; hay 9 y cada uno
                                guarda sus ventanas
  area maestra................. la ventana grande y principal del mosaico
  layout....................... la forma en que se reparten las ventanas
  monocle...................... una sola ventana ocupando toda la pantalla
  flotante..................... ventana fuera del mosaico; la mueves a mano
  barra........................ la linea de arriba: tags, layout, CPU, RAM,
                                volumen y hora (slstatus)
  gaps......................... separacion entre ventanas (ACTIVOS)

  dwm es un gestor de ventanas en mosaico: no apila ventanas como Windows, las
  reparte automaticamente por la pantalla.

------------------------------------------------------------------------------
 PROGRAMAS
------------------------------------------------------------------------------

  Super+d...................... lanzador de aplicaciones (dmenu)
  Super+Enter.................. terminal (st)
  Super+t...................... terminal (st), atajo alternativo
  Super+b...................... navegador (Firefox)
  Super+e...................... lf, gestor de archivos en terminal (dentro de
                                st)

    Nota: lf es el unico gestor de archivos; no se instala ninguno grafico.
    Para montar pendrives y discos usa udisksctl (seccion PENDRIVES Y DISCOS).

------------------------------------------------------------------------------
 VENTANAS
------------------------------------------------------------------------------

  Super+q...................... cerrar la ventana enfocada
  Super+j...................... enfocar la siguiente ventana
  Super+Abajo.................. enfocar la siguiente ventana (igual que
                                Super+j)
  Super+k...................... enfocar la ventana anterior
  Super+Arriba................. enfocar la ventana anterior (igual que
                                Super+k)
  Super+h...................... achicar el area maestra
  Super+l...................... agrandar el area maestra
  Super+i...................... una ventana mas en el area maestra
  Super+Shift+t................ volver la ventana flotante (o devolverla al
                                mosaico)

------------------------------------------------------------------------------
 BARRA (slstatus)
------------------------------------------------------------------------------

  Super+w...................... ocultar o mostrar la barra

  La barra la dibuja el propio dwm y su contenido lo genera slstatus. Muestra
  CPU (carga), RAM, volumen, la red wifi y la bateria (si hay), y la hora.

  Se cambia editando ~/slstatus/config.h y recompilando:
    cd ~/slstatus && sudo make clean install
    pkill -x slstatus; sleep 1; slstatus &
  (la ultima linea reinicia la barra sin cerrar sesion)

------------------------------------------------------------------------------
 LAYOUTS
------------------------------------------------------------------------------

  []=.......................... mosaico: area maestra + columna de ventanas
                                (el inicial)
  "><>"........................ flotante: cada ventana se mueve y redimensiona
                                a mano
  [M].......................... monocle: una sola ventana ocupando todo

  Super+r...................... alternar con el layout anterior
  Super+Space.................. alternar con el layout anterior (igual que
                                Super+r)
  Super+f...................... ir directo a monocle

    Nota: El simbolo del layout activo se ve a la izquierda en la barra. El
    flotante ("><>") no tiene tecla propia: se llega alternando con Super+r.

------------------------------------------------------------------------------
 TAGS (los 9 escritorios)
------------------------------------------------------------------------------

  Super+1 ... 9................ ir a ese tag
  Super+Shift+1 ... 9.......... mover la ventana actual a ese tag
  Super+Ctrl+1 ... 9........... ver ese tag junto con el actual
  Super+Ctrl+Shift+1..9........ anadir o quitar la ventana de ese tag
  Super+Tab.................... volver al tag anterior

  Idea de uso: terminal en el tag 1, navegador en el 2, musica en el 3, chat
  en el 4.

------------------------------------------------------------------------------
 GAPS - ACTIVOS
------------------------------------------------------------------------------

  El instalador aplica el parche vanitygaps a dwm 6.2, asi que la separacion
  entre ventanas funciona desde el primer momento.

  Super+Ctrl+u................. aumentar la separacion entre ventanas
  Super+Ctrl+Shift+u........... disminuir la separacion
  Super+Ctrl+0................. activar o desactivar gaps
  Super+Ctrl+Shift+0........... restablecer los gaps a su valor inicial

  Los valores iniciales (4 px) se cambian en ~/dwm/config.h: gappih, gappiv,
  gappoh y gappov.

------------------------------------------------------------------------------
 TECLAS ESPECIALES (sin Super)
------------------------------------------------------------------------------

  Subir volumen................ sube 3 % (amixer / ALSA)
  Bajar volumen................ baja 3 %
  Mute......................... silenciar o restaurar
  Brillo arriba................ sube 5 % (brightnessctl)
  Brillo abajo................. baja 5 %
  Print / Impr Pant............ captura de pantalla (scrot) en ~/Pictures

------------------------------------------------------------------------------
 SALIR
------------------------------------------------------------------------------

  Super+Shift+e................ cerrar la sesion de dwm (vuelves al login)

  Si dwm se congela: Ctrl+Alt+F2 para ir a una consola y ahi 'sudo reboot'.

------------------------------------------------------------------------------
 RATON SOBRE LAS VENTANAS
------------------------------------------------------------------------------

  Super+clic izquierdo......... mover la ventana (arrastrando)
  Super+clic central........... alternar ventana flotante
  Super+clic derecho........... redimensionar la ventana (arrastrando)

------------------------------------------------------------------------------
 RATON SOBRE LA BARRA
------------------------------------------------------------------------------

  clic izq. en el layout....... alternar con el layout anterior
  clic der. en el layout....... ir directo a monocle
  clic central en el titulo.... pasar esa ventana al area maestra (zoom)
  clic central en el estado.... abrir una terminal (st)
  clic izq. en un numero....... ir a ese tag
  clic der. en un numero....... ver ese tag junto con el actual
  Super+clic izq. en un num.... mover la ventana a ese tag
  Super+clic der. en un num.... anadir o quitar la ventana de ese tag

------------------------------------------------------------------------------
 PENDRIVES Y DISCOS DUROS
------------------------------------------------------------------------------

  El instalador deja configurado udisks2 + polkit para montar discos sin
  contrasena (si tu usuario esta en el grupo wheel o sudo).

  Donde quedan montados:
  /run/media/TU-USUARIO/....... pendrives y tarjetas (los monta udisks2)

  Comandos utiles:
  lsblk -f..................... ver los discos y sus particiones
  udisksctl mount -b /dev/sdb1  montar una particion concreta
  udisksctl unmount -b /dev/sdb1  desmontarla
  udisksctl status............. resumen de discos que reconoce udisks2

    Nota: Hace falta cerrar sesion (o reiniciar) despues de instalar para que
    el grupo surta efecto.

------------------------------------------------------------------------------
 CAMBIAR ESTOS ATAJOS
------------------------------------------------------------------------------

  Paso 1....................... editar ~/dwm/config.h y cambiar la tecla
  Paso 2....................... cd ~/dwm && sudo make clean install
  Paso 3....................... Super+Shift+e para salir y volver a entrar

------------------------------------------------------------------------------
 ARCHIVOS PARA PERSONALIZAR
------------------------------------------------------------------------------

  ~/dwm/config.h............... atajos, colores, fuentes, gaps, reglas
  ~/slstatus/config.h.......... que muestra la barra (CPU, RAM, volumen...)
  ~/st/config.h................ fuente y colores de la terminal
  ~/.config/dwm/autostart.sh... programas que arrancan con dwm
  ~/.config/picom/picom.conf... transparencia de la terminal
  ~/.config/lf/lfrc............ gestor de archivos lf
  /usr/local/bin/dwm-session... wrapper de sesion (dbus-run-session)
  /etc/polkit-1/rules.d/....... permisos de montaje de discos

------------------------------------------------------------------------------
 REFERENCIAS
------------------------------------------------------------------------------

  dwm.......................... https://dwm.suckless.org
  slstatus (la barra).......... https://tools.suckless.org/slstatus
  st (terminal)................ https://st.suckless.org
  vanitygaps (parche).......... https://dwm.suckless.org/patches/vanitygaps
  lf (archivos)................ https://github.com/gokcehan/lf

  Manuales en tu terminal: man 1 dwm | man 1 st | man 1 dmenu | man 1 lf

==============================================================================
ATAJOS_EOF
ok "Chuleta de atajos en ~/Atajos.txt"

# ==================== KERNEL (SOLO VOID) ====================
hdr "KERNEL"
KERNEL_NUEVO=""
info "Kernel actual: $(uname -r)"
if [ "$FAMILIA" = "void" ]; then
  if confirm "Buscar e instalar la serie de kernel mas reciente de los repos?"; then
    NEWEST_KERNEL="$(xbps-query --regex -Rs '^linux[0-9]+\.[0-9]+-[0-9]' 2>/dev/null \
        | grep -oE 'linux[0-9]+\.[0-9]+-[0-9][0-9._]*' \
        | sed 's/-[0-9][0-9._]*$//' | sort -uV | tail -n1)"
    CUR_SERIES="linux$(uname -r | cut -d. -f1,2)"
    if [ -z "$NEWEST_KERNEL" ]; then
      warn "No pude consultar las series de kernel (revisa conexion y repos)."
    elif [ "$NEWEST_KERNEL" = "$CUR_SERIES" ]; then
      ok "Ya tienes la serie mas reciente ($CUR_SERIES)"
    else
      info "Disponible: $NEWEST_KERNEL (tienes: $CUR_SERIES)"
      BOOT_FREE_MB="$(df -Pm /boot 2>/dev/null | awk 'NR==2 {print $4}')"
      if [ "${BOOT_FREE_MB:-0}" -lt 300 ]; then
        warn "Poco espacio en /boot (${BOOT_FREE_MB:-?} MB): se omite el kernel."
        warn "Libera kernels viejos: 'sudo vkpurge list' y 'sudo vkpurge rm <version>'."
      elif sudo xbps-install -y "$NEWEST_KERNEL" "$NEWEST_KERNEL-headers"; then
        sudo xbps-reconfigure -f "$NEWEST_KERNEL" >/dev/null 2>&1 || warn "Revisa: sudo xbps-reconfigure -f $NEWEST_KERNEL"
        KERNEL_NUEVO="$NEWEST_KERNEL"
        ok "Kernel $NEWEST_KERNEL instalado, se activa al reiniciar"
      else
        warn "No se pudo instalar $NEWEST_KERNEL; se mantiene $(uname -r)"
      fi
    fi
  else
    ok "Kernel sin cambios"
  fi
else
  ok "En esta distro el kernel se actualiza con el gestor de paquetes (ya se hizo arriba)"
fi

# ==================== INICIO DE SESION (greetd + tuigreet) ====================
# Debe quedar AL FINAL: usa dwm-session, dwm-startx y dwm.desktop, que ya existen aqui.
hdr "INICIO DE SESION"
printf "  %sgreetd / tuigreet · bloque final v%s%s\n" "$DIM" "$VERSION" "$R"

# Ejecuta un comando como root (sin timeout, a diferencia de install-dwl)
srun(){ sudo "$@"; }

# --- 0) Comprobaciones previas: la sesion tiene que existir YA ---
for f in /usr/local/bin/dwm-session /usr/share/xsessions/dwm.desktop; do
  [ -f "$f" ] || err "Falta $f: el bloque de inicio de sesion no puede continuar."
done
ok "Sesion dwm verificada antes de tocar greetd"

# --- 0b) Wrapper X11 para greetd ---
# greetd NO levanta un servidor X. dwm es X11, asi que tuigreet lanza este wrapper,
# que usa startx (xinit) para arrancar Xorg y dentro corre dwm-session.
sudo tee /usr/local/bin/dwm-startx >/dev/null <<'SX_EOF'
#!/bin/sh
# Lanza dwm (X11) desde greetd/tuigreet: startx levanta Xorg y ejecuta dwm-session.
exec startx /usr/local/bin/dwm-session -- "vt${XDG_VTNR:-1}"
SX_EOF
sudo chmod 0755 /usr/local/bin/dwm-startx
command -v startx >/dev/null 2>&1 || warn "No hay 'startx' (paquete xinit): dwm no arrancara desde tuigreet"
ok "Wrapper de inicio para greetd: /usr/local/bin/dwm-startx"

# --- 0c) FIX: detectar si tocar tty1 nos mataria la sesion ---
# En tty1 tu shell ES el servicio agetty-tty1; pararlo = suicidio.
ON_TTY1=0
CUR_TTY="$(tty 2>/dev/null || true)"
case "$CUR_TTY" in *tty1*) ON_TTY1=1 ;; esac
IN_SESSION=0
if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${XDG_SESSION_ID:-}" ]; then
  IN_SESSION=1
fi
[ "$ON_TTY1" -eq 1 ] && IN_SESSION=1
DEFERRED=0
FINAL_ERROR=0
if [ "$IN_SESSION" -eq 1 ]; then
  info "Sesion detectada en ${CUR_TTY:-tty?}: greetd se activara en el REINICIO (modo seguro)."
else
  info "Sin sesion en tty1 (${CUR_TTY:-sin tty}): greetd se puede arrancar ahora mismo."
fi

if [ "$USE_GREETD" = 1 ]; then

# --- 1) Quitar otros gestores de sesion (lightdm, gdm, sddm...) ---
# Si hay sesion en marcha NO se paran: matarian la sesion. Se hace al reiniciar.
for DM in lightdm gdm gdm3 sddm xdm lxdm ly; do
  if [ -L "/var/service/$DM" ] || [ -f "/usr/lib/systemd/system/$DM.service" ] || command -v "$DM" >/dev/null 2>&1; then
    if [ "$IN_SESSION" -eq 1 ]; then
      warn "Hay $DM instalado: se desactivara al reiniciar (no ahora, para no cortar tu sesion)"
    else
      info "Desactivando $DM (en su lugar se usa greetd)..."
      if [ "$FAMILIA" = "void" ]; then
        sudo sv down "$DM" >/dev/null 2>&1; sudo rm -f "/var/service/$DM"
      else
        sudo systemctl disable --now "$DM.service" >/dev/null 2>&1
      fi
      ok "$DM desactivado (no desinstalado)"
    fi
  fi
done

# --- 2) Binarios del greeter con ruta absoluta ---
GREETD_BIN=""
for b in /usr/bin/greetd /usr/local/bin/greetd /usr/sbin/greetd; do
  [ -x "$b" ] && GREETD_BIN="$b" && break
done
[ -z "$GREETD_BIN" ] && GREETD_BIN="$(command -v greetd 2>/dev/null)"
[ -z "$GREETD_BIN" ] && err "No se encuentra el binario greetd. Instala el paquete greetd."
info "Binario greetd: $GREETD_BIN"

TUIGREET_BIN=""
for b in /usr/bin/tuigreet /usr/local/bin/tuigreet; do
  [ -x "$b" ] && TUIGREET_BIN="$b" && break
done
[ -z "$TUIGREET_BIN" ] && TUIGREET_BIN="$(command -v tuigreet 2>/dev/null)"
if [ -n "$TUIGREET_BIN" ]; then
  ok "Greeter: $TUIGREET_BIN"
else
  warn "No se localiza tuigreet; se usara 'tuigreet' a secas (puede fallar con el PATH de runit)"
  TUIGREET_BIN="tuigreet"
fi

# --- 3) Usuario del greeter (lo crea el paquete greetd en la mayoria de distros) ---
case "$FAMILIA" in
  void)   GREETER_USER="greetd" ;;
  debian) GREETER_USER="_greetd" ;;
  *)      GREETER_USER="greeter" ;;
esac
info "Configurando usuario greeter '$GREETER_USER'..."
id -u "$GREETER_USER" >/dev/null 2>&1 || sudo useradd -r -s /sbin/nologin -d /var/lib/greetd "$GREETER_USER"
sudo usermod -aG tty,video,input "$GREETER_USER"
sudo mkdir -p /var/lib/greetd /etc/greetd
sudo chown "$GREETER_USER:$GREETER_USER" /var/lib/greetd 2>/dev/null
sudo chmod 700 /var/lib/greetd

# --- 4) Botones de apagar/reiniciar solo si hay loginctl ---
if command -v loginctl >/dev/null 2>&1; then
  POWER_FLAGS="--power-shutdown 'loginctl poweroff' --power-reboot 'loginctl reboot'"
  ok "loginctl presente: tuigreet con botones de apagar/reiniciar"
else
  POWER_FLAGS=""
  warn "Sin loginctl: tuigreet va sin botones de power"
fi

# --- 5) /etc/greetd/config.toml ---
sudo tee /etc/greetd/config.toml >/dev/null <<TOML
[terminal]
vt = 1

[default_session]
command = "$TUIGREET_BIN --cmd /usr/local/bin/dwm-startx --time --remember --asterisks $POWER_FLAGS"
user = "$GREETER_USER"
TOML
sudo chmod 644 /etc/greetd/config.toml
ok "/etc/greetd/config.toml escrito"

if [ "$FAMILIA" = "void" ]; then

  # --- 6a) Void (runit): servicio con ruta ABSOLUTA ---
  sudo mkdir -p /etc/sv/greetd
  sudo rm -f /etc/sv/greetd/down /var/service/greetd/down
  sudo tee /etc/sv/greetd/run >/dev/null <<RUN
#!/bin/sh
# greetd DEBE correr como ROOT: gestiona VTs, PAM y abre las sesiones.
# Ruta ABSOLUTA porque runit NO hereda el PATH de tu usuario.
sleep 2
rm -f /var/service/agetty-tty1
pkill -f '/usr/bin/agetty.*tty1' 2>/dev/null
sleep 1
exec $GREETD_BIN -c /etc/greetd/config.toml 2>&1
RUN
  sudo chmod 755 /etc/sv/greetd/run

  # --- 7a) Servicio de log para diagnosticar ---
  if command -v svlogd >/dev/null 2>&1; then
    sudo mkdir -p /etc/sv/greetd/log /var/log/greetd
    sudo tee /etc/sv/greetd/log/run >/dev/null <<'LOG'
#!/bin/sh
mkdir -p /var/log/greetd
exec svlogd -tt /var/log/greetd
LOG
    sudo chmod 755 /etc/sv/greetd/log/run
    ok "Log de greetd en /var/log/greetd/current"
  else
    warn "svlogd no disponible: sin log de greetd"
  fi

  # --- 8a0) Helper idempotente: activar greetd en tty1 ---
  sudo tee /usr/local/sbin/dwm-enable-greetd >/dev/null <<'EN'
#!/bin/sh
# Activa greetd en tty1 y retira agetty-tty1 y otros gestores de sesion.
# Idempotente: se ejecuta al apagar (rc.shutdown), al arrancar (rc.local) o a mano.
rm -f /var/service/agetty-tty1
pkill -f '/usr/bin/agetty.*tty1' 2>/dev/null
for dm in lightdm gdm sddm xdm lxdm; do
  rm -f "/var/service/$dm"
  command -v systemctl >/dev/null 2>&1 && systemctl disable "$dm.service" 2>/dev/null
done
sleep 0.5
ln -sfn /etc/sv/greetd /var/service/
exit 0
EN
  sudo chmod 755 /usr/local/sbin/dwm-enable-greetd

  # --- 8a) Si hay sesion en marcha, NO se toca /var/service ---
  if [ "$IN_SESSION" -eq 1 ]; then
    warn "Estas dentro de una sesion (${CUR_TTY:-tty?}): no se toca agetty ni /var/service"
    info "   Se programa el cambio para que se aplique solo, sin riesgo."
    for RC in /etc/rc.shutdown /etc/rc.local; do
      [ -f "$RC" ] || printf '#!/bin/sh\n# Creado por install-dwm\n' | sudo tee "$RC" >/dev/null
      if ! sudo grep -q 'dwm-enable-greetd' "$RC" 2>/dev/null; then
        printf '\n# install-dwm: greetd en tty1 a partir del proximo arranque\n[ -x /usr/local/sbin/dwm-enable-greetd ] && /usr/local/sbin/dwm-enable-greetd\n' | sudo tee -a "$RC" >/dev/null
      fi
      sudo chmod +x "$RC"
    done
    ok "Activacion programada en /etc/rc.shutdown y /etc/rc.local"
    DEFERRED=1
  else
    info "Paso 1/4: retirando agetty de tty1..."
    srun sv force-stop agetty-tty1 || true
    srun rm -f /var/service/agetty-tty1 || true
    info "Paso 2/4: habilitando greetd en /var/service..."
    srun ln -sfn /etc/sv/greetd /var/service/ || true
    [ -L /var/service/greetd ] || err "No se pudo crear /var/service/greetd"
    ok "greetd enlazado en /var/service"

    # runsvdir tarda hasta 5 s en crear supervise/
    i=0
    while [ "$i" -lt 40 ]; do
      [ -d /var/service/greetd/supervise ] && break
      i=$((i+1)); sleep 0.5
    done
    if [ -d /var/service/greetd/supervise ]; then
      info "Paso 3/4: arrancando greetd..."
      if pgrep -x greetd >/dev/null 2>&1; then
        srun sv restart greetd || srun sv start greetd || true
      else
        srun sv start greetd || true
      fi
    else
      warn "runsvdir no ha recogido el servicio todavia"
    fi

    info "Paso 4/4: verificando que greetd sigue vivo..."
    i=0; GREETD_UP=0
    while [ "$i" -lt 40 ]; do
      if pgrep -x greetd >/dev/null 2>&1; then GREETD_UP=1; break; fi
      i=$((i+1)); sleep 0.5
    done
    sudo sv status greetd 2>/dev/null || warn "sv no pudo consultar el estado"
    if [ "$GREETD_UP" -eq 1 ]; then
      ok "greetd esta CORRIENDO"
    else
      FINAL_ERROR=1
      warn "greetd NO arranco. Diagnostico:"
      [ -f /var/log/greetd/current ] && sudo tail -n 20 /var/log/greetd/current
      echo "  Prueba manual:  sudo sv down greetd; sudo $GREETD_BIN -c /etc/greetd/config.toml"
    fi
  fi

else

  # --- 6b) systemd (Arch, Fedora/Nobara y Debian) ---
  sudo mkdir -p /etc/systemd/system/greetd.service.d
  sudo tee /etc/systemd/system/greetd.service.d/10-wait-ready.conf >/dev/null <<INI
[Unit]
After=systemd-logind.service systemd-user-sessions.service systemd-udev-settle.service plymouth-quit-wait.service
Wants=systemd-logind.service
Conflicts=getty@tty1.service
INI
  sudo systemctl mask getty@tty1 2>/dev/null
  sudo systemctl set-default graphical.target 2>/dev/null
  # Otros gestores ocupan el alias display-manager.service: sin desactivarlos,
  # 'enable greetd' falla y al reiniciar vuelve el gestor viejo. 'disable' no corta la sesion.
  for DMX in lightdm gdm gdm3 sddm xdm lxdm ly; do
    sudo systemctl disable "$DMX.service" >/dev/null 2>&1 || true
  done
  if ! sudo systemctl enable --force greetd.service >/dev/null 2>&1; then
    FINAL_ERROR=1
    warn "No se pudo habilitar greetd.service (prueba: sudo systemctl enable --force greetd.service)"
  fi
  if [ "$IN_SESSION" -eq 1 ]; then
    warn "Sesion activa: greetd solo se HABILITA (sin restart). Arranca tras el reboot."
    DEFERRED=1
  else
    sudo systemctl enable --now greetd.service 2>/dev/null
    sudo systemctl restart greetd.service 2>/dev/null
    sleep 2
    info "Estado del servicio:"
    sudo systemctl status greetd.service --no-pager -l 2>/dev/null | head -n 12
    if systemctl is-active --quiet greetd.service; then
      ok "greetd esta activo (systemd)"
    else
      FINAL_ERROR=1
      warn "greetd no esta activo. Mira: journalctl -u greetd -b"
    fi
  fi
fi

else
  # El usuario eligio mantener su gestor: no se toca greetd ni los gestores actuales
  info "Login: greetd no se configura. Elige 'dwm' en el menu de sesion de tu gestor actual."
fi

# ==================== RESUMEN ====================
hdr "INSTALACION COMPLETA"
printf "\n  %sUNICO PASO RESTANTE:%s\n\n" "$YEL$B" "$R"
printf "      %s%ssudo reboot%s\n\n" "$B" "$YEL" "$R"
if [ "$USE_GREETD" = 0 ]; then
  if [ -n "$DM_FOUND" ]; then
    echo " Mantienes tu gestor de sesion ($DM_FOUND): greetd no se ha tocado."
    echo " Al reiniciar entra con ese gestor y elige 'dwm' en el menu de sesion."
  else
    echo " greetd no se configuro y no hay gestor de sesion: instala lightdm para entrar a dwm."
  fi
  echo
elif [ "$DEFERRED" -eq 1 ]; then
  echo " Modo seguro (estabas dentro de una sesion): el cambio se aplica al reiniciar."
  if [ "$FAMILIA" = "void" ]; then
    echo " Si quieres activarlo ya desde tty2+:  sudo /usr/local/sbin/dwm-enable-greetd"
  fi
  echo
else
  echo " greetd ya esta habilitado y verificado."
  echo " Tras reiniciar veras tuigreet directamente en tty1."
  echo
fi
if [ "$USE_GREETD" = 1 ]; then
  echo " Inicia sesion con tu usuario y entras a dwm."
  echo
  echo " Si NO aparece tuigreet tras el reboot:"
  if [ "$FAMILIA" = "void" ]; then
    echo "   Void:            sudo sv status greetd"
    echo "                    sudo tail -n 30 /var/log/greetd/current"
    echo "                    sudo /usr/local/sbin/dwm-enable-greetd"
  else
    echo "   Arch/Fedora/Debian: systemctl status greetd"
    echo "                       journalctl -u greetd -b"
  fi
  echo " (tty2..tty6 siguen con agetty: entra por ahi si hace falta)"
  echo
fi
echo " Atajos:  Super+Enter terminal    Super+d menu"
echo "          Super+q cerrar          Super+w barra on/off"
echo "          Super+Shift+e salir de sesion"
echo " Chuleta completa: nano ~/Atajos.txt"
if [ -n "$KERNEL_NUEVO" ]; then
  warn "Reinicia para usar el kernel $KERNEL_NUEVO (verifica con 'uname -r')."
fi
line
[ "${FINAL_ERROR:-0}" -eq 1 ] && err "Revisa los errores de arriba antes de reiniciar."
ok "Instalacion v$VERSION completada. Realiza ${B}sudo reboot${R} para cargar todo sin problema."
rm -rf ~/dwm-instalador
exit 0
