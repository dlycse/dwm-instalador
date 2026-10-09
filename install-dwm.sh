#!/bin/sh
# ============================================================
# install-dwm v1.0 — X11 con dwm + slstatus + st (Void + Arch)
# ------------------------------------------------------------
set +e

VERSION="1.0"
BUILD="estable (Void + Arch)"

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

# enable_svc NOMBRE_VOID UNIDAD_ARCH
# Void (runit): enlaza /etc/sv/NOMBRE en /var/service. Arch (systemd): systemctl enable.
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
printf "  %sInicio de sesion (lightdm) al FINAL%s\n" "$DIM" "$R"

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
trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null' EXIT INT TERM
ok "Credencial sudo cacheada (se renueva sola durante la compilacion)"

hdr "DETECCION DEL SISTEMA"
# ---------- Deteccion de distro ----------
FAMILIA="unknown"
[ -f "$OS_RELEASE_FILE" ] && . "$OS_RELEASE_FILE"
case "${ID:-unknown}" in
  void) FAMILIA="void" ;;
  arch|manjaro|endeavouros|garuda|cachyos|arcolinux|parabola) FAMILIA="arch" ;;
  *) case "${ID_LIKE:-}" in *arch*) FAMILIA="arch" ;; *void*) FAMILIA="void" ;; esac ;;
esac
[ "$FAMILIA" = "unknown" ] && err "Solo compatible con Void Linux y Arch Linux (detectado: ${ID:-desconocido})."
if [ "$FAMILIA" = "arch" ] && [ ! -d /run/systemd/system ]; then
  err "Arch sin systemd (p. ej. Artix con OpenRC) no esta soportado por este script."
fi
if [ "$FAMILIA" = "void" ] && [ ! -d /etc/sv ]; then
  err "Void sin runit (/etc/sv) no esta soportado por este script."
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
  case "$1" in
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

# ==================== PAQUETES ====================
# Lista base comun (los nombres de Void y Arch se separan abajo).
if [ "$FAMILIA" = "void" ]; then
  hdr "PAQUETES - VOID LINUX"
  info "Sincronizando indice de paquetes..."
  sudo xbps-install -S >/dev/null 2>&1 || warn "No se pudo sincronizar (continuo con el indice local)"

  PKGS_VOID="
    base-devel git curl wget nano file ncurses
    libX11-devel libXft-devel libXinerama-devel freetype-devel fontconfig-devel
    xorg xinit dbus
    dmenu slock dunst picom feh
    alsa-utils brightnessctl scrot util-linux xdg-utils
    nerd-fonts lf mpv zathura zathura-pdf-poppler
    fastfetch btop cowsay chrony firefox
    lightdm lightdm-gtk3-greeter
    udisks2 polkit elogind polkit-gnome gvfs gvfs-mtp ntfs-3g exfatprogs
  "
  PKG_OK=""; PKG_NO=""
  for p in $PKGS_VOID; do
    if xbps-query -R "$p" >/dev/null 2>&1; then PKG_OK="$PKG_OK $p"; else PKG_NO="$PKG_NO $p"; fi
  done
  [ -n "$PKG_NO" ] && warn "No estan en los repos, se omiten:$PKG_NO"

  info "Instalando paquetes (lote)..."
  # shellcheck disable=SC2086
  if sudo xbps-install -Sy $PKG_OK; then
    ok "Paquetes instalados"
  else
    warn "El lote fallo: instalo uno a uno para no perder todo"
    for p in $PKG_OK; do
      sudo xbps-install -Sy "$p" >/dev/null 2>&1 || warn "No se pudo instalar: $p"
    done
  fi

else
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
    lightdm lightdm-gtk-greeter
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
fi

# ==================== SERVICIOS BASE ====================
hdr "SERVICIOS BASE"
enable_svc dbus dbus
enable_svc polkitd polkit
enable_svc udevd ""           # Arch: systemd-udevd ya corre solo
enable_svc elogind ""         # Arch: systemd-logind va incluido en systemd
enable_svc chronyd chronyd

if [ "$FAMILIA" = "void" ] && [ -e /var/service/acpid ]; then
  warn "elogind y acpid gestionan los mismos eventos ACPI; deshabilito acpid."
  sudo rm -f /var/service/acpid
fi

# Teclado de consola
if [ "$FAMILIA" = "void" ]; then
  set_kv /etc/rc.conf KEYMAP "$KB_CONSOLE"
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
sudo usermod -aG wheel,video,input "$REAL_USER"
ok "Grupos para $REAL_USER: wheel, video, input"
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
# Regla para el grupo wheel: montar, desmontar y expulsar con udisks2 sin contrasena.
# Se lee en orden: el 49 gana a las reglas por defecto (50). polkit recarga sola.
sudo mkdir -p /etc/polkit-1/rules.d
sudo tee /etc/polkit-1/rules.d/49-udisks2-wheel.rules >/dev/null <<'POLKIT_EOF'
// Permitir a los usuarios del grupo "wheel" montar/desmontar discos y pendrives
// con udisks2 SIN pedir contrasena. Funciona igual en Void (polkit + elogind)
// y en Arch (polkit + systemd-logind).
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
    if (permitidos.indexOf(action.id) >= 0 && subject.isInGroup("wheel")) {
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
for AGENTE in \
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
    /usr/lib64/polkit-gnome/polkit-gnome-authentication-agent-1 \
    /usr/libexec/polkit-gnome-authentication-agent-1; do
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
# Sesion dwm: la usan lightdm (desde /usr/share/xsessions/dwm.desktop) y startx.
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
  contrasena (si tu usuario esta en el grupo wheel).

  Donde quedan montados:
  /run/media/TU-USUARIO/....... pendrives y tarjetas (los monta udisks2)

  Comandos utiles:
  lsblk -f..................... ver los discos y sus particiones
  udisksctl mount -b /dev/sdb1  montar una particion concreta
  udisksctl unmount -b /dev/sdb1  desmontarla
  udisksctl status............. resumen de discos que reconoce udisks2

    Nota: Hace falta cerrar sesion (o reiniciar) despues de instalar para que
    el grupo wheel surta efecto.

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
  ok "En Arch el kernel se actualiza con: sudo pacman -Syu (ya se hizo arriba)"
fi

# ==================== INICIO DE SESION (ULTIMO BLOQUE) ====================
hdr "INICIO DE SESION"
printf "  %slightdm · bloque final v%s%s\n" "$DIM" "$VERSION" "$R"

# --- 0) La sesion tiene que existir antes de activar el greeter ---
for f in /usr/local/bin/dwm-session /usr/share/xsessions/dwm.desktop; do
  [ -f "$f" ] || err "Falta $f: no se activa lightdm."
done
ok "Sesion dwm verificada"

# --- 1) Quitar otros gestores de pantalla (no se desinstalan) ---
for DM in gdm sddm lxdm xdm ly greetd; do
  if [ "$FAMILIA" = "void" ]; then
    if [ -L "/var/service/$DM" ]; then
      sudo rm -f "/var/service/$DM"
      warn "$DM desactivado (no desinstalado)"
    fi
  else
    if systemctl is-enabled "$DM.service" >/dev/null 2>&1; then
      sudo systemctl disable "$DM.service" >/dev/null 2>&1
      warn "$DM desactivado (no desinstalado)"
    fi
  fi
done

# --- 2) Activar lightdm en el arranque ---
if [ "$FAMILIA" = "void" ]; then
  if [ -d /etc/sv/lightdm ]; then
    sudo ln -sfn /etc/sv/lightdm /var/service/
    ok "lightdm habilitado en runit"
  else
    err "No existe /etc/sv/lightdm: revisa que lightdm este instalado."
  fi
else
  sudo systemctl enable lightdm.service >/dev/null 2>&1 || err "No se pudo habilitar lightdm.service"
  ok "lightdm habilitado en systemd"
fi

# --- 3) Comprobacion ---
if [ "$FAMILIA" = "void" ]; then
  sleep 2
  if sudo sv status lightdm 2>/dev/null | grep -q '^run:'; then
    ok "lightdm esta CORRIENDO"
  else
    warn "lightdm no aparece corriendo: revisa 'sudo sv status lightdm' y /var/log/lightdm"
  fi
else
  if systemctl is-enabled lightdm.service >/dev/null 2>&1; then
    ok "lightdm habilitado (arrancara con el sistema)"
  else
    warn "lightdm no quedo habilitado: revisa 'systemctl status lightdm'"
  fi
fi

# ==================== RESUMEN ====================
hdr "INSTALACION COMPLETA"
printf "\n  %sUNICO PASO RESTANTE:%s\n\n" "$YEL$B" "$R"
printf "      %s%ssudo reboot%s\n\n" "$B" "$YEL" "$R"
echo " Tras reiniciar veras la pantalla de login de lightdm."
echo " Elige la sesion 'dwm' e inicia sesion con tu usuario."
echo
echo " Si NO aparece el login:"
if [ "$FAMILIA" = "void" ]; then
  echo "   Void:  sudo sv status lightdm"
  echo "          cat /var/log/lightdm/lightdm.log"
else
  echo "   Arch:  systemctl status lightdm"
  echo "          journalctl -u lightdm -b"
fi
echo " Tambien puedes entrar en una consola (Ctrl+Alt+F2) y escribir 'startx'."
echo
echo " Atajos:  Super+Enter terminal    Super+d menu"
echo "          Super+q cerrar          Super+w barra on/off"
echo "          Super+Shift+e salir de sesion"
echo " Chuleta completa: nano ~/Atajos.txt"
if [ -n "$KERNEL_NUEVO" ]; then
  warn "Reinicia para usar el kernel $KERNEL_NUEVO (verifica con 'uname -r')."
fi
line
ok "Instalacion v$VERSION completada. Realiza ${B}sudo reboot${R} para cargar todo sin problema."
rm -rf ~/dwm-instalador
exit 0
