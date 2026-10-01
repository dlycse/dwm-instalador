#!/bin/sh
# install-dwm.sh  (v0.7) 
# Instalador de dwm + rice personalizado (Void Linux)
#      + polkit/udisks2/elogind para montar HDD y pendrives sin contrasena
#      + exec dbus-run-session dwm (bus de sesion garantizado) 
# Uso: sh install-dwm.sh        (como usuario normal, NO como root)
# Solo revisar sintaxis: sh -n install-dwm.sh

set -e

# ----------------------------------------------------------------
# Colores y helpers de mensaje
# ----------------------------------------------------------------
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

info()  { printf "%b[+]%b %s\n" "$GREEN" "$RESET" "$1"; }
warn()  { printf "%b[!]%b %s\n" "$YELLOW" "$RESET" "$1"; }
error() { printf "%b[x]%b %s\n" "$RED" "$RESET" "$1"; }

# Escribe (desde stdin) el archivo $1 solo si no existe. Si ya existe se conserva
# la version del usuario y la nueva se guarda como "$1.nuevo" para comparar.
write_config() {
    if [ -f "$1" ]; then
        warn "$1 ya existe: se conserva tu version. La nueva quedo en $1.nuevo"
        mkdir -p "$(dirname "$1")"
        cat > "$1.nuevo"
    else
        mkdir -p "$(dirname "$1")"
        cat > "$1"
    fi
}

# Si una ejecucion anterior (con sudo make) dejo archivos de root en la carpeta,
# devuelvelos al usuario para que el proximo 'make' no falle.
fix_owner() {
    if [ "$(stat -c %U . 2>/dev/null)" != "$(id -un)" ] || \
       [ -n "$(find . -maxdepth 2 ! -user "$(id -un)" -print -quit 2>/dev/null)" ]; then
        info "Devolviendo la propiedad de $(pwd) a $(id -un)..."
        sudo chown -R "$(id -un):$(id -gn)" .
    fi
}

# Habilita un servicio runit. Acepta varios nombres candidatos y usa el primero
# que exista en /etc/sv (asi no depende de si el servicio se llama chrony/chronyd, etc).
enable_service() {
    for svc in "$@"; do
        if [ -d "/etc/sv/$svc" ]; then
            if [ ! -e "/var/service/$svc" ]; then
                sudo ln -s "/etc/sv/$svc" /var/service/ && info "Servicio habilitado: $svc"
            else
                info "Servicio ya habilitado: $svc"
            fi
            return 0
        fi
    done
    warn "No existe /etc/sv/$1 (servicio no disponible); se omite."
    return 0
}

# Deshabilita un servicio runit (si existe).
disable_service() {
    svc="$1"
    if [ -e "/var/service/$svc" ]; then
        sudo rm -f "/var/service/$svc" && warn "Servicio deshabilitado: $svc"
    fi
}
# ----------------------------------------------------------------
# Comprobaciones previas
# ----------------------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
    error "No ejecutes este script como root: los archivos quedarian en /root."
    error "Usa tu usuario normal (el script usa sudo cuando lo necesita)."
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    error "Falta 'sudo'. Instalalo y agrega tu usuario a sudoers (visudo) antes de continuar."
    exit 1
fi

# ----------------------------------------------------------------
# 0. Detectar distro (para avisar si no es Void)
# ----------------------------------------------------------------
DISTRO_ID="unknown"
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
fi

info "Distro detectada: $DISTRO_ID"

if [ "$DISTRO_ID" != "void" ]; then
    warn "Este script fue pensado para Void Linux (xbps)."
    warn "Detecte '$DISTRO_ID'. Los pasos de instalacion de paquetes probablemente fallen."
    printf "Continuar de todas formas? [y/N] "
    read -r CONTINUAR
    case "$CONTINUAR" in
        y|Y) ;;
        *) error "Cancelado por el usuario."; exit 1 ;;
    esac
fi

# ----------------------------------------------------------------
# Auto-deteccion de hardware
# ----------------------------------------------------------------
info "Detectando hardware..."

WIFI_IFACE=$(ip route 2>/dev/null | grep default | awk '{print $5}' | head -n1 || true)
if [ -z "$WIFI_IFACE" ]; then
    warn "No se pudo detectar interfaz de red activa, usando 'eth0' por defecto."
    WIFI_IFACE="eth0"
fi

BAT_NAME=$(ls /sys/class/power_supply/ 2>/dev/null | grep -E '^BAT' | head -n1 || true)
if [ -z "$BAT_NAME" ]; then
    warn "No se detecto bateria; no se mostrara en la barra."
    BAT_NAME="n/a"
fi

info "Interfaz de red: $WIFI_IFACE"
info "Bateria: ${BAT_NAME:-n/a}"

# ----------------------------------------------------------------
# 1. Variables de configuracion (edita a tu gusto)
# ----------------------------------------------------------------
DWM_REPO="https://git.suckless.org/dwm"
DWM_TAG="6.2"          # el parche vanitygaps es para 6.2; HEAD del repo va en 6.8+
DWM_BRANCH="v6.2-local"
SLSTATUS_REPO="https://git.suckless.org/slstatus"
VANITYGAPS_URL="https://dwm.suckless.org/patches/vanitygaps/dwm-vanitygaps-6.2.diff"

WALLPAPER_DIR="$HOME/Pictures"
WALLPAPER_PATH="$WALLPAPER_DIR/wallpaper.jpg"
# Wallpaper fijo (Empty Error - wallpapercave). Ojo: el archivo real es un PNG de
# 1280x800; se guarda con extension .jpg pero feh lo lee igual.
WALLPAPER_URL="https://wallpapercave.com/download/empty-error-wallpapers-wp8330753"

# El UNICO gestor de archivos es "lf" (terminal, Super+e). Este instalador NO
# instala ninguno grafico: si quieres uno, instalalo y configurelo tu mismo, p.ej.
#   sudo xbps-install -S pcmanfm
# Lo que si queda lista es la pila de montaje, que es independiente del gestor y
# permite montar sin contrasena desde la terminal o desde lf:
#   udisksctl mount -b /dev/sdb1

# ----------------------------------------------------------------
# 2. Paquetes necesarios
# ----------------------------------------------------------------
# 'git' es obligatorio (el script clona dwm y slstatus): en v2 se habia borrado de
# la lista y base-devel NO lo incluye, asi que en un sistema limpio fallaba el clone.
PAQUETES_BASE="
    base-devel file curl wget nano
    libX11-devel libXft-devel libXinerama-devel
    freetype-devel fontconfig-devel
    xorg xinit
    dmenu st slock dunst picom feh
    alsa-utils brightnessctl scrot util-linux xdg-utils
    nerd-fonts
    lf mpv zathura zathura-pdf-poppler
    fastfetch btop cowsay
    chrony firefox
    lightdm lightdm-gtk3-greeter
    dbus
"

# Pila para que aparezcan los dispositivos (HDD, pendrives, SD, MTP):
#   udevd      -> detecta el hardware (eudev)
#   udisks2    -> monta/desmonta por D-Bus (lo usa udisksctl desde la terminal)
#   polkit     -> decide si hace falta contrasena para montar
#   elogind    -> sesiones + XDG_RUNTIME_DIR + le dice a polkit quien eres.
#                OJO: el polkit de Void se compila con -Dsession_tracking=elogind,
#                o sea que sin elogind la regla subject.isInGroup("wheel") no es fiable.
#   gvfs       -> MTP (celulares), papelera, miniaturas
#   ntfs-3g / exfatprogs -> formatos de pendrives y discos de Windows
PAQUETES_DISCOS="udisks2 polkit elogind gvfs gvfs-mtp ntfs-3g exfatprogs polkit-gnome"

# Filtra una lista de paquetes: descarta los que no existen en los repos para que
# un nombre mal escrito no aborte toda la instalacion.
# Los avisos van a stderr (>&2) para que $(...) no los meta en la lista.
filter_pkgs() {
    OK=""
    for p in "$@"; do
        if xbps-query -R "$p" >/dev/null 2>&1; then
            OK="$OK $p"
        else
            warn "El paquete '$p' no existe en los repos; se omite." >&2
        fi
    done
    printf '%s' "$OK"
}

info "Instalando dependencias..."
# shellcheck disable=SC2086
LISTA=$(filter_pkgs $PAQUETES_BASE $PAQUETES_DISCOS)
if [ -z "$(printf '%s' "$LISTA" | tr -d ' ')" ]; then
    error "Ningun paquete valido para instalar; revisa tu conexion o tus repos."
    exit 1
fi
# shellcheck disable=SC2086
sudo xbps-install -Sy $LISTA

info "Habilitando servicios..."
enable_service udevd                     # dispositivos (pendrives, HDD)
enable_service dbus                      # bus del sistema (lo exige polkit/udisks2)
enable_service elogind                   # sesiones, XDG_RUNTIME_DIR, loginctl
enable_service polkitd                   # motor de polkit (reglas .rules)
enable_service chronyd chrony            # reloj en red
enable_service lightdm                   # pantalla de login

# elogind procesa los eventos ACPI de tapa/boton de encendido y choca con acpid
# (documentado en el Handbook de Void, seccion Power Management).
if [ -d /etc/sv/elogind ] && [ -e /var/service/acpid ]; then
    warn "elogind y acpid gestionan los mismos eventos ACPI; deshabilito acpid."
    disable_service acpid
fi

# ----------------------------------------------------------------
# 2b. Usuario en el grupo wheel (necesario para la regla de polkit)
# ----------------------------------------------------------------
if id -nG "$(id -un)" 2>/dev/null | tr ' ' '\n' | grep -qx wheel; then
    info "Tu usuario ya pertenece al grupo wheel."
else
    warn "Tu usuario NO esta en el grupo wheel: la regla de polkit no te aplicaria."
    printf "Anadir '%s' al grupo wheel? [S/n] " "$(id -un)"
    read -r ANADIR_WHEEL
    case "$ANADIR_WHEEL" in
        n|N) warn "Se omite. Anadelo tu luego con: sudo usermod -aG wheel $(id -un)" ;;
        *)   sudo usermod -aG wheel "$(id -un)"
             warn "Grupo wheel anadido. Debes CERRAR SESION Y VOLVER A ENTRAR (o reiniciar)"
             warn "para que los nuevos grupos surtan efecto." ;;
    esac
fi

# ----------------------------------------------------------------
# 2c. Zona horaria y reloj
# ----------------------------------------------------------------
info "Configuracion de zona horaria."
printf "Escribe tu pais (ej: Colombia, Mexico, Argentina, Espana).\nDeja vacio para usar Colombia por defecto: "
read -r PAIS_INPUT
PAIS_INPUT="${PAIS_INPUT:-Colombia}"

PAIS_NORM=$(printf '%s' "$PAIS_INPUT" | tr '[:upper:]' '[:lower:]' | \
    sed 's/á/a/g; s/é/e/g; s/í/i/g; s/ó/o/g; s/ú/u/g; s/ñ/n/g')

TZ_INPUT=""
case "$PAIS_NORM" in
    colombia)                          TZ_INPUT="America/Bogota" ;;
    mexico)                            TZ_INPUT="America/Mexico_City" ;;
    argentina)                         TZ_INPUT="America/Buenos_Aires" ;;
    chile)                             TZ_INPUT="America/Santiago" ;;
    peru)                              TZ_INPUT="America/Lima" ;;
    ecuador)                           TZ_INPUT="America/Guayaquil" ;;
    venezuela)                         TZ_INPUT="America/Caracas" ;;
    bolivia)                           TZ_INPUT="America/La_Paz" ;;
    paraguay)                          TZ_INPUT="America/Asuncion" ;;
    uruguay)                           TZ_INPUT="America/Montevideo" ;;
    panama)                            TZ_INPUT="America/Panama" ;;
    "costa rica")                      TZ_INPUT="America/Costa_Rica" ;;
    guatemala)                         TZ_INPUT="America/Guatemala" ;;
    honduras)                          TZ_INPUT="America/Tegucigalpa" ;;
    "el salvador")                     TZ_INPUT="America/El_Salvador" ;;
    nicaragua)                         TZ_INPUT="America/Managua" ;;
    "republica dominicana")            TZ_INPUT="America/Santo_Domingo" ;;
    cuba)                              TZ_INPUT="America/Havana" ;;
    "puerto rico")                     TZ_INPUT="America/Puerto_Rico" ;;
    brasil|brazil)                     TZ_INPUT="America/Sao_Paulo" ;;
    "estados unidos"|usa|eeuu)         TZ_INPUT="America/New_York" ;;
    canada)                            TZ_INPUT="America/Toronto" ;;
    espana|spain)                      TZ_INPUT="Europe/Madrid" ;;
    francia|france)                    TZ_INPUT="Europe/Paris" ;;
    alemania|germany)                  TZ_INPUT="Europe/Berlin" ;;
    italia|italy)                      TZ_INPUT="Europe/Rome" ;;
    "reino unido"|uk|"united kingdom") TZ_INPUT="Europe/London" ;;
    /*)                                TZ_INPUT="$PAIS_INPUT" ;;
    *)                                 TZ_INPUT="" ;;
esac

if [ -n "$TZ_INPUT" ] && [ -f "/usr/share/zoneinfo/$TZ_INPUT" ]; then
    info "Pais: $PAIS_INPUT -> Zona horaria: $TZ_INPUT"
    sudo ln -sf "/usr/share/zoneinfo/$TZ_INPUT" /etc/localtime
    sudo hwclock --systohc 2>/dev/null || warn "No se pudo sincronizar el reloj de hardware (se ignora)."
    # En Void, TIMEZONE en /etc/rc.conf sobrescribe /etc/localtime en cada arranque
    [ -f /etc/rc.conf ] || sudo touch /etc/rc.conf
    if grep -qE '^[#[:space:]]*TIMEZONE=' /etc/rc.conf 2>/dev/null; then
        sudo sed -i "s|^[#[:space:]]*TIMEZONE=.*|TIMEZONE=\"$TZ_INPUT\"|" /etc/rc.conf
    else
        printf 'TIMEZONE="%s"\n' "$TZ_INPUT" | sudo tee -a /etc/rc.conf >/dev/null
    fi
else
    warn "No reconoci '$PAIS_INPUT' como pais, y tampoco es una ruta valida de zona horaria."
    warn "Se deja la zona horaria sin cambios. Opciones disponibles con:"
    warn "  find /usr/share/zoneinfo -type f | sed 's#/usr/share/zoneinfo/##' | less"
fi

# ----------------------------------------------------------------
# 3. Clonar y compilar dwm
# ----------------------------------------------------------------
cd "$HOME"
if [ ! -d dwm ]; then
    info "Clonando dwm..."
    git clone "$DWM_REPO"
fi
cd dwm
fix_owner

info "Fijando dwm en el tag $DWM_TAG (version compatible con el parche vanitygaps)..."
git fetch --tags
# FIX: '-b' falla si la rama ya existe y el ||dev/null lo ocultaba. Con '-B' es idempotente.
git checkout -B "$DWM_BRANCH" "tags/$DWM_TAG"

info "Descargando parche vanitygaps..."
[ -f dwm-vanitygaps-6.2.diff ] || curl -fsSO "$VANITYGAPS_URL"

# FIX: el marcador ahora es un archivo propio (.vanitygaps-applied). Antes se usaba
# 'vanitygaps.c', que se crea aunque el parche falle a mitad, y dejaba dwm.c sin parchar.
if [ ! -f .vanitygaps-applied ]; then
    info "Aplicando parche vanitygaps (sobre fuentes limpias del tag $DWM_TAG)..."
    git checkout -- dwm.c config.def.h config.mk Makefile 2>/dev/null || true
    rm -f ./*.rej ./*.orig
    if patch -p1 -N --fuzz=3 < dwm-vanitygaps-6.2.diff; then
        touch .vanitygaps-applied
    else
        error "El parche no aplico. Revisa dwm.c.rej y avisame para depurarlo."
        error "Para reintentar limpio: cd ~/dwm && git checkout -- . && rm -f .vanitygaps-applied"
        exit 1
    fi
else
    info "Parche vanitygaps ya aplicado (se omite)."
fi

info "Escribiendo config.h de dwm..."
write_config config.h <<'EOF'
#include <X11/XF86keysym.h>
/* See LICENSE file for copyright and license details. */

/* appearance */
static const unsigned int borderpx  = 2;
static const unsigned int gappih    = 10;
static const unsigned int gappiv    = 10;
static const unsigned int gappoh    = 10;
static const unsigned int gappov    = 10;
static       int smartgaps          = 0;
static const unsigned int snap      = 32;
static const int showbar            = 1;
static const int topbar             = 1;
static const char *fonts[]          = { "JetBrainsMono Nerd Font:size=11" };
static const char dmenufont[]       = "JetBrainsMono Nerd Font:size=11";

static const char col_gray1[]       = "#1e1e2e";
static const char col_gray2[]       = "#313244";
static const char col_gray3[]       = "#cdd6f4";
static const char col_gray4[]       = "#ffffff";
static const char col_cyan[]        = "#89b4fa";
static const char *colors[][3]      = {
        /*               fg         bg         border   */
        [SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
        [SchemeSel]  = { col_gray4, col_gray1, col_cyan  },
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
        /* xprop(1): WM_CLASS(STRING) = instance, class ; WM_NAME(STRING) = title */
        /* class      instance    title       tags mask     isfloating   monitor */
        { "Gimp",     NULL,       NULL,       0,            1,           -1 },
        /* FIX: el WM_CLASS real de Firefox es "Firefox" (F mayuscula);
           con "firefox" la regla nunca coincidia. Verificalo con: xprop WM_CLASS */
        { "Firefox",  NULL,       NULL,       1 << 0,       0,           -1 },
};

/* layout(s) */
static const float mfact     = 0.50;
static const int nmaster     = 1;
static const int resizehints = 1;
/* lockfullscreen y refreshrate existen en dwm.c con sus valores por defecto (1 y 60) */

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
EOF

info "Compilando dwm (como usuario; solo la instalacion usa sudo)..."
make clean
make
sudo make install

# ----------------------------------------------------------------
# 4. Clonar y compilar slstatus
# ----------------------------------------------------------------
cd "$HOME"
if [ ! -d slstatus ]; then
    info "Clonando slstatus..."
    git clone "$SLSTATUS_REPO"
fi
cd slstatus
fix_owner

# Solo se agregan a la barra los modulos que existen en este equipo.
info "Escribiendo config.h de slstatus..."
{
    cat <<'EOF'
/* See LICENSE file for copyright and license details. */
const unsigned int interval = 1000;
static const char unknown_str[] = "n/a";
#define MAXLEN 2048

static const struct arg args[] = {
    /* funcion         format            argumento */
    /* CPU y RAM siempre visibles. Para la RAM en vez de porcentaje puedes usar
       ram_used (ej. "1.2 GiB") o ram_free; y para la CPU, cpu_freq (MHz). */
    { cpu_perc,       "CPU %s%% ",     NULL },
    { ram_perc,       "RAM %s%% ",     NULL },
EOF
    if [ -d "/sys/class/net/$WIFI_IFACE/wireless" ]; then
        printf '    { wifi_essid,     " %%s ",          "%s" },\n' "$WIFI_IFACE"
    fi
    if [ "$BAT_NAME" != "n/a" ]; then
        # FIX: el estado de la bateria necesita "%s" (antes se generaba "[%]" sin %s)
        printf '    { battery_state,  "[%%s]",          "%s" },\n' "$BAT_NAME"
        printf '    { battery_perc,   "BAT %%s%%%% ",     "%s" },\n' "$BAT_NAME"
    fi
    cat <<'EOF'
    { datetime,         "%s",            "%Y-%m-%d %I:%M %p" },
};
EOF
} | write_config config.h

info "Compilando slstatus (como usuario; solo la instalacion usa sudo)..."
make clean
make
sudo make install

# ----------------------------------------------------------------
# 5. polkit: montar discos y pendrives sin contrasena (grupo wheel)
# ----------------------------------------------------------------
# El directorio /etc/polkit-1/rules.d lo crea el paquete con permisos 0700 y dueno
# polkitd, asi que hay que escribir como root. Las reglas se leen en orden
# lexicografico: un numero bajo (49) gana a las reglas por defecto (50).
info "Creando regla de polkit para udisks2 (grupo wheel)..."
sudo mkdir -p /etc/polkit-1/rules.d
sudo tee /etc/polkit-1/rules.d/49-udisks2-wheel.rules >/dev/null <<'EOF'
// Permitir a los usuarios del grupo "wheel" montar/desmontar discos y pendrives
// con udisks2 SIN pedir contrasena (equivale a "sudo NOPASSWD" pero solo para eso).
//
// Requiere:
//   - paquetes: udisks2 polkit elogind
//   - servicios: udevd, dbus, elogind, polkitd  (ln -s /etc/sv/X /var/service/)
//   - tu usuario en el grupo wheel (id -nG)
//
// Los action.id terminados en "-other-seat" cubren el caso en que elogind no
// considere la sesion "local/activa" (pasa al entrar con startx sin logind).
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
EOF
sudo chown root:root /etc/polkit-1/rules.d/49-udisks2-wheel.rules
sudo chmod 0644 /etc/polkit-1/rules.d/49-udisks2-wheel.rules

# Recargar polkit para que lea la regla nueva sin reiniciar
if [ -d /var/service/polkitd ]; then
    sudo sv restart polkitd 2>/dev/null || warn "No pude reiniciar polkitd ahora; lo hara el reinicio."
fi

# Agente de autenticacion: dwm no trae ninguno, y sin el las acciones polkit que
# SI piden contrasena se quedarian colgadas sin ventana donde escribirla.
info "Agente polkit: se iniciara con la sesion (polkit-gnome)."

# ----------------------------------------------------------------
# 6. picom
# ----------------------------------------------------------------
info "Configurando picom..."
write_config "$HOME/.config/picom/picom.conf" <<'EOF'
backend = "xrender";
vsync = false;

opacity-rule = [
  "90:class_g = 'st-256color'"
];

shadow = false;
fading = false;
EOF

# ----------------------------------------------------------------
# 7. Gestor de archivos: lf (no se instala ninguno grafico)
# ----------------------------------------------------------------
# "lf" ya viene en PAQUETES_BASE y se configura en el paso 9c (~/.config/lf/lfrc).
# Se abre con Super+e dentro de una terminal st.
#
# Para montar pendrives y discos no hace falta ningun gestor grafico: la pila
# udisks2 + polkit + elogind del paso 5 permite montar sin contrasena.
#   lsblk -f                        ver discos y particiones
#   udisksctl mount -b /dev/sdb1    montar
#   udisksctl unmount -b /dev/sdb1  desmontar
# Quedan en /run/media/$USER/
#
# Si quieres un gestor grafico de todos modos, instalalo tu y anadele un atajo
# en ~/dwm/config.h:   sudo xbps-install -S pcmanfm
info "Gestor de archivos: lf (Super+e). Discos y pendrives: udisksctl mount -b /dev/sdXN"

# ----------------------------------------------------------------
# 8. Wallpaper
# ----------------------------------------------------------------
mkdir -p "$WALLPAPER_DIR"
if [ ! -f "$WALLPAPER_PATH" ]; then
    info "Descargando wallpaper..."
    wget -q -U "Mozilla/5.0" --referer="https://wallpapercave.com/" \
        -O "$WALLPAPER_PATH" "$WALLPAPER_URL" || true
    if ! file "$WALLPAPER_PATH" 2>/dev/null | grep -qi image; then
        warn "No se pudo descargar un wallpaper valido; se omite."
        warn "Copia tu propia imagen a $WALLPAPER_PATH y se usara al iniciar sesion."
        rm -f "$WALLPAPER_PATH"
    fi
fi

# Aplicarlo ya mismo si hay una sesion X corriendo
if [ -f "$WALLPAPER_PATH" ] && [ -n "$DISPLAY" ] && command -v feh >/dev/null 2>&1; then
    feh --bg-fill "$WALLPAPER_PATH" || true
fi

# ----------------------------------------------------------------
# 9. Autostart + wrapper de sesion (dbus-run-session)
# ----------------------------------------------------------------
info "Creando ~/.config/dwm/autostart.sh (programas que arrancan con dwm)..."
if [ ! -f "$HOME/.config/dwm/autostart.sh" ]; then
    {
        cat <<EOF
#!/bin/sh
# Programas que se inician con dwm. Edita libremente este archivo.
# Este script se ejecuta DENTRO del bus de sesion D-Bus (lo lanza dwm-session).

# Fondo de pantalla
[ -f "$WALLPAPER_PATH" ] && feh --bg-fill "$WALLPAPER_PATH" &

# Compositor, notificaciones y barra de estado
picom --config "$HOME/.config/picom/picom.conf" &
dunst &
slstatus &

EOF
        # Agente polkit: sin el, las acciones que piden contrasena no tienen donde mostrarla
        cat <<'EOF'
# Agente de autenticacion polkit: sin el, las acciones que piden contrasena no tienen donde mostrarla.
# Se busca el binario en varias rutas posibles (lib/lib64/libexec) para no depender de una fija.
if ! pgrep -f 'polkit.*authentication.*agent' >/dev/null 2>&1; then
    for AGENTE in \
        /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
        /usr/lib64/polkit-gnome/polkit-gnome-authentication-agent-1 \
        /usr/libexec/polkit-gnome-authentication-agent-1 \
        /usr/lib/polkit-gnome-authentication-agent-1 ; do
        if [ -x "$AGENTE" ]; then "$AGENTE" & break; fi
    done
    # Alternativa si no esta polkit-gnome pero si xfce-polkit
    if ! pgrep -f 'polkit.*authentication.*agent' >/dev/null 2>&1 && command -v xfce-polkit >/dev/null 2>&1; then
        xfce-polkit &
    fi
fi

EOF

    } > "$HOME/.config/dwm/autostart.sh"
    chmod +x "$HOME/.config/dwm/autostart.sh"
else
    warn "~/.config/dwm/autostart.sh ya existe; se conserva."
fi

# FIX clave: el autostart se lanza DESPUES de arrancar el bus de sesion, porque
# dunst y el agente polkit necesitan DBUS_SESSION_BUS_ADDRESS.
info "Creando wrapper de sesion (/usr/local/bin/dwm-session) con dbus-run-session..."
sudo tee /usr/local/bin/dwm-session >/dev/null <<'EOF'
#!/bin/sh
# Sesion dwm: la usan lightdm (desde /usr/share/xsessions/dwm.desktop) y startx.
#
# 1) Garantiza XDG_RUNTIME_DIR (lo crea elogind; esto es un plan B).
# 2) Arranca un bus de sesion D-Bus si no existe.
# 3) Dentro del bus: autostart.sh y al final 'exec dwm'.

if [ -z "$XDG_RUNTIME_DIR" ]; then
    XDG_RUNTIME_DIR="/run/user/$(id -u)"
    export XDG_RUNTIME_DIR
    [ -d "$XDG_RUNTIME_DIR" ] || mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null
    chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null
fi

# Evita recursividad si alguien apunta lightdm directo a dwm-session-inner
DWM_INNER="${DWM_SESSION_INNER:-/usr/local/bin/dwm-session-inner}"

if [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
    # lightdm ya arranco un bus de sesion: no hace falta dbus-run-session.
    exec "$DWM_INNER"
fi

if command -v dbus-run-session >/dev/null 2>&1; then
    # <<< la linea que pediste >>>
    exec dbus-run-session "$DWM_INNER"
fi

# Sin dbus: arrancamos igual, pero dunst y polkit pueden fallar.
exec "$DWM_INNER"
EOF
sudo chmod 0755 /usr/local/bin/dwm-session

sudo tee /usr/local/bin/dwm-session-inner >/dev/null <<'EOF'
#!/bin/sh
# Corre DENTRO del bus de sesion (lo invoca /usr/local/bin/dwm-session).
[ -n "$DISPLAY" ] && command -v dbus-update-activation-environment >/dev/null 2>&1 &&
    dbus-update-activation-environment DISPLAY XAUTHORITY XDG_RUNTIME_DIR 2>/dev/null

[ -x "$HOME/.config/dwm/autostart.sh" ] && "$HOME/.config/dwm/autostart.sh" &

exec dwm
EOF
sudo chmod 0755 /usr/local/bin/dwm-session-inner

# ----------------------------------------------------------------
# 9b. ~/.xinitrc (para poder usar "startx" ademas de lightdm)
# ----------------------------------------------------------------
if [ -f "$HOME/.xinitrc" ]; then
    info "Respaldando ~/.xinitrc existente en ~/.xinitrc.bak"
    cp "$HOME/.xinitrc" "$HOME/.xinitrc.bak"
fi
info "Creando ~/.xinitrc para que 'startx' use dwm..."
echo "exec /usr/local/bin/dwm-session" > "$HOME/.xinitrc"

# ----------------------------------------------------------------
# 9c. Configuracion de lf (abrir texto, imagenes, video, audio y PDF)
# ----------------------------------------------------------------
info "Configurando lf..."
write_config "$HOME/.config/lf/lfrc" <<'EOF'
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
EOF
# Nota: 'video/|audio/' (sin *) nunca coincide: los MIME son video/mp4, audio/mpeg, etc.

# Los dispositivos montados por udisks2 aparecen aqui:
mkdir -p "$HOME/.config/gtk-3.0"
info "Los pendrives montados aparecen en /run/media/$(id -un)/ y en /media."

# ----------------------------------------------------------------
# 10. Registrar sesion dwm en lightdm
# ----------------------------------------------------------------
info "Registrando sesion dwm en lightdm..."
sudo mkdir -p /usr/share/xsessions
sudo tee /usr/share/xsessions/dwm.desktop >/dev/null <<'EOF'
[Desktop Entry]
Name=dwm
Comment=Dynamic window manager (dwm + slstatus + picom)
Exec=/usr/local/bin/dwm-session
TryExec=/usr/local/bin/dwm-session
Type=Application
DesktopNames=dwm
X-LightDM-Session-Type=x11
EOF

# ----------------------------------------------------------------
# 11. Teclado (el usuario elige)
# ----------------------------------------------------------------
info "Configuracion de teclado."
KB_LAYOUT=""
KB_CONSOLA=""
while true; do
    printf "Selecciona la distribucion de teclado:\n"
    printf "  1) Ingles (us)\n"
    printf "  2) Espanol de Espana (es)\n"
    printf "  3) Latinoamericano (latam)\n"
    printf "  4) No cambiar\n"
    printf "Opcion [3]: "
    read -r OPCION_TECLADO
    OPCION_TECLADO="${OPCION_TECLADO:-3}"

    case "$OPCION_TECLADO" in
        1) KB_LAYOUT="us";    KB_CONSOLA="us";         break ;;
        2) KB_LAYOUT="es";    KB_CONSOLA="es";         break ;;
        3) KB_LAYOUT="latam"; KB_CONSOLA="la-latin1";  break ;;
        4) KB_LAYOUT="";      KB_CONSOLA="";           break ;;
        *) warn "Opcion no valida, elige 1, 2, 3 o 4." ;;
    esac
done

if [ -n "$KB_LAYOUT" ]; then
    info "Configurando teclado en '$KB_LAYOUT'..."

    # Aplicar de inmediato a la sesion X actual (si hay una corriendo)
    command -v setxkbmap >/dev/null 2>&1 && setxkbmap "$KB_LAYOUT" 2>/dev/null || true

    # Dejarlo fijo para Xorg (aplica tambien en la pantalla de login de lightdm)
    sudo mkdir -p /etc/X11/xorg.conf.d
    sudo tee /etc/X11/xorg.conf.d/00-keyboard.conf >/dev/null <<EOF
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "$KB_LAYOUT"
EndSection
EOF

    # Consola (TTY): KEYMAP en /etc/rc.conf + loadkeys ahora
    if [ -n "$KB_CONSOLA" ]; then
        # Validar que el keymap exista antes de escribirlo en rc.conf
        if find /usr/share/kbd/keymaps -name "${KB_CONSOLA}.map*" 2>/dev/null | grep -q .; then
            [ -f /etc/rc.conf ] || sudo touch /etc/rc.conf
            if grep -qE '^[#[:space:]]*KEYMAP=' /etc/rc.conf 2>/dev/null; then
                sudo sed -i "s|^[#[:space:]]*KEYMAP=.*|KEYMAP=\"$KB_CONSOLA\"|" /etc/rc.conf
            else
                printf 'KEYMAP="%s"\n' "$KB_CONSOLA" | sudo tee -a /etc/rc.conf >/dev/null
            fi
            command -v loadkeys >/dev/null 2>&1 && sudo loadkeys "$KB_CONSOLA" 2>/dev/null || true
        else
            warn "El keymap '$KB_CONSOLA' no existe en /usr/share/kbd/keymaps."
            warn "Lista los disponibles con: ls /usr/share/kbd/keymaps/i386/qwerty/"
            warn "Se omite el teclado de consola (el de Xorg si se configuro)."
        fi
    fi
else
    info "Se deja el layout de teclado actual sin cambios."
fi

# ----------------------------------------------------------------
# 12. Kernel (opcional): instalar la serie mas nueva de los repos
# ----------------------------------------------------------------
KERNEL_NUEVO=""
CUR_KERNEL="$(uname -r)"
CUR_SERIES="$(printf '%s' "$CUR_KERNEL" | cut -d. -f1,2)"
info "Kernel en uso: $CUR_KERNEL"

printf "Quieres instalar la serie de kernel mas nueva de los repos de Void? [s/N]: "
read -r ACT_KERNEL
case "$ACT_KERNEL" in
    s|S|si|Si|SI|y|Y)
        # FIX: en v2 se usaba 'awk {print $2}' sobre la salida de xbps-query -Rs,
        # pero ese campo no siempre es el pkgver (depende de si el paquete esta
        # instalado: la linea puede llevar "[*] " delante). Ahora se extrae el
        # patron directamente con grep -oE, que no depende de columnas.
        NEWEST_KERNEL=$(xbps-query --regex -Rs '^linux[0-9]+\.[0-9]+-[0-9]' 2>/dev/null \
            | grep -oE 'linux[0-9]+\.[0-9]+-[0-9][0-9._]*' \
            | sed 's/-[0-9][0-9._]*$//' | sort -uV | tail -n1)

        if [ -z "$NEWEST_KERNEL" ]; then
            warn "No pude consultar las series de kernel disponibles (revisa conexion y repos)."
            warn "Instalalo a mano, por ejemplo: sudo xbps-install -S linux-lts linux-lts-headers"
        elif [ "$NEWEST_KERNEL" = "linux$CUR_SERIES" ]; then
            info "Ya usas la serie mas nueva ($NEWEST_KERNEL)."
        else
            info "Serie mas nueva disponible: $NEWEST_KERNEL"
            BOOT_FREE_MB=$(df -Pm /boot 2>/dev/null | awk 'NR==2 {print $4}')
            if [ "${BOOT_FREE_MB:-0}" -lt 300 ]; then
                warn "Poco espacio libre en /boot (${BOOT_FREE_MB:-?} MB); se omite el kernel."
                warn "Libera kernels viejos: 'sudo vkpurge list' y 'sudo vkpurge rm <version>'."
            else
                warn "Es una serie mas nueva que la predeterminada y puede estar menos probada."
                warn "Tu kernel actual se conserva en el menu de arranque por si necesitas volver."
                if ! command -v grub-mkconfig >/dev/null 2>&1 && [ ! -d /boot/grub ]; then
                    warn "No detecte GRUB: verifica como actualizas tu menu de arranque."
                fi
                if sudo xbps-install -y "$NEWEST_KERNEL" "$NEWEST_KERNEL-headers"; then
                    # Genera initramfs y actualiza el menu de arranque
                    sudo xbps-reconfigure -f "$NEWEST_KERNEL" \
                        || warn "Fallo xbps-reconfigure de $NEWEST_KERNEL; revisa con: sudo xbps-reconfigure -f $NEWEST_KERNEL"
                    KERNEL_NUEVO="$NEWEST_KERNEL"
                    info "Kernel $NEWEST_KERNEL instalado; se usara despues de reiniciar."
                else
                    warn "No se pudo instalar $NEWEST_KERNEL; se deja el kernel actual."
                fi
            fi
        fi
        ;;
    *)
        info "Se deja el kernel actual sin cambios."
        ;;
esac

# ----------------------------------------------------------------
# 12b. Chuleta de atajos en TEXTO PLANO (para leerla con nano)
# ----------------------------------------------------------------
# Este archivo se genera AQUI, en la maquina, y NO existe en el repositorio:
#   - En GitHub solo se ve Atajos.md, con formato markdown bonito.
#   - En el equipo queda ~/Atajos.txt: texto plano, sin markdown ni acentos,
#     alineado con puntos y ajustado a 78 columnas, que es lo que de verdad
#     se lee bien en una terminal con 'nano ~/Atajos.txt'.
# El markdown no sirve en nano (las tablas | y los ** se ven como ruido),
# y el texto plano no sirve en GitHub (colapsa los espacios). Por eso van
# separados: cada uno en su sitio.
info "Creando la chuleta de atajos ~/Atajos.txt (leela con: nano ~/Atajos.txt)..."
write_config "$HOME/Atajos.txt" <<'ATAJOS_EOF'

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

  Con esos siete ya puedes manejarte. El resto lo vas aprendiendo sobre la
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
  barra........................ la linea de arriba (slstatus): tags, layout,
                                CPU, RAM, hora
  gaps......................... separacion entre ventanas (AQUI SI estan
                                activos)

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
  CPU, RAM, la red wifi, la bateria (si hay) y la fecha.

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
  Super+Ctrl+Shift+1..9........ la ventana aparece en ambos tags sin moverla
  Super+Tab.................... volver al tag anterior

  Idea de uso: terminal en el tag 1, navegador en el 2, musica en el 3, chat
  en el 4.

------------------------------------------------------------------------------
 GAPS - AQUI SI ESTAN ACTIVOS
------------------------------------------------------------------------------

  El instalador aplica el parche vanitygaps a dwm 6.2, asi que la separacion
  entre ventanas funciona desde el primer momento.

  Super+Ctrl+u................. aumentar la separacion entre ventanas
  Super+Ctrl+Shift+u........... disminuir la separacion
  Super+Ctrl+0................. activar o desactivar gaps
  Super+Ctrl+Shift+0........... restablecer los gaps a su valor inicial

  Los valores iniciales (10 px) se cambian en ~/dwm/config.h: gappih, gappiv,
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

  Super+Shift+e................ cerrar la sesion de dwm (vuelves a lightdm)

  Si dwm se congela: Ctrl+Alt+F1 para ir a una consola y ahi 'sudo reboot'.

------------------------------------------------------------------------------
 RATON SOBRE LAS VENTANAS
------------------------------------------------------------------------------

  Super+clic izquierdo......... mover la ventana (arrastrando)
  Super+clic central........... alternar ventana flotante
  Super+clic derecho........... redimensionar la ventana (arrastrando)

------------------------------------------------------------------------------
 RATON SOBRE LA BARRA
------------------------------------------------------------------------------

  En dwm los clics de la barra SI funcionan (van en el array buttons[] de
  config.h).

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

  El instalador deja configurado udisks2 + polkit + elogind para que puedas
  montar discos sin contrasena (si tu usuario esta en el grupo wheel).

  No hay gestor de archivos grafico: todo se hace desde la terminal (o desde
  lf, que corre dentro de st).

  Donde quedan montados:
  /run/media/TU-USUARIO/....... pendrives y tarjetas (los monta udisks2)
  /media/...................... otros puntos de montaje

  Comandos utiles:
  lsblk -f..................... ver los discos y sus particiones
  udisksctl mount -b /dev/sdb1  montar una particion concreta
  udisksctl unmount -b /dev/sdb1  desmontarla
  udisksctl list............... dispositivos que reconoce udisks2

    Nota: La regla que permite montar sin contrasena esta en
    /etc/polkit-1/rules.d/49-udisks2-wheel.rules. Hace falta reiniciar la
    sesion despues de instalar para que el grupo wheel surta efecto.

------------------------------------------------------------------------------
 CAMBIAR ESTOS ATAJOS
------------------------------------------------------------------------------

  Paso 1....................... editar ~/dwm/config.h y cambiar la tecla
  Paso 2....................... cd ~/dwm && sudo make clean install
  Paso 3....................... Super+Shift+e para salir y volver a entrar

    Si tambien cambiaste ~/slstatus/config.h:
      cd ~/slstatus && sudo make clean install
      pkill -x slstatus; sleep 1; slstatus &
    Asi la barra se actualiza sin cerrar sesion.

------------------------------------------------------------------------------
 ARCHIVOS PARA PERSONALIZAR
------------------------------------------------------------------------------

  ~/dwm/config.h............... atajos, colores, fuentes, gaps, reglas
  ~/slstatus/config.h.......... que muestra la barra (CPU, RAM, bateria...)
  ~/.config/dwm/autostart.sh... programas que arrancan con dwm
  ~/.config/picom/picom.conf... transparencias y compositor
  ~/.config/lf/lfrc............ gestor de archivos lf
  /usr/local/bin/dwm-session... wrapper de sesion (dbus-run-session)
  /etc/polkit-1/rules.d/....... permisos de montaje de discos

------------------------------------------------------------------------------
 REFERENCIAS
------------------------------------------------------------------------------

  dwm.......................... https://dwm.suckless.org
  slstatus (la barra).......... https://tools.suckless.org/slstatus
  vanitygaps (parche).......... https://dwm.suckless.org/patches/vanitygaps
  lf (archivos)................ https://github.com/gokcehan/lf

  Manuales en tu terminal: man 1 dwm | man 1 st | man 1 dmenu | man 1 lf

==============================================================================
ATAJOS_EOF

# ----------------------------------------------------------------
# 13. Verificacion final
# ----------------------------------------------------------------
echo
info "Comprobando la instalacion..."
[ -x /usr/local/bin/dwm ]      && info "  dwm:      $(dwm -v 2>/dev/null || echo instalado)" || warn "  dwm NO esta en /usr/local/bin"
[ -x /usr/local/bin/slstatus ] && info "  slstatus: instalado" || warn "  slstatus NO esta en /usr/local/bin"
for s in udevd dbus elogind polkitd lightdm; do
    if [ -e "/var/service/$s" ]; then
        estado=$(sudo sv status "$s" 2>/dev/null | head -n1)
        info "  servicio $s: ${estado:-habilitado (arrancara al reiniciar)}"
    else
        warn "  servicio $s: NO habilitado"
    fi
done
[ -f /etc/polkit-1/rules.d/49-udisks2-wheel.rules ] \
    && info "  regla polkit: /etc/polkit-1/rules.d/49-udisks2-wheel.rules" \
    || warn "  regla polkit: NO se creo"
[ -f "$HOME/Atajos.txt" ] \
    && info "  chuleta de atajos: ~/Atajos.txt (nano ~/Atajos.txt)" \
    || warn "  chuleta de atajos: NO se creo ~/Atajos.txt"

echo
info "¡Instalacion lista!"
if [ -n "$KERNEL_NUEVO" ]; then
    warn "Reinicia para usar $KERNEL_NUEVO y verifica con 'uname -r'."
fi
warn "REINICIA el equipo (o cierra sesion y vuelve a entrar) para aplicar:"
warn "  grupo wheel, zona horaria, teclado, dbus/elogind/polkitd/udevd y lightdm."
echo
info "Despues de reiniciar, comprueba que los pendrives funcionan:"
info "  sv status udevd dbus elogind polkitd      # servicios arriba"
info "  loginctl                                  # tu sesion registrada (elogind)"
info "  lsblk -f                                  # se ve el pendrive"
info "  udisksctl mount -b /dev/sdb1              # montar sin contrasena"
info "  ls /run/media/$(id -un)/                  # donde queda montado"
info "  pkcheck -a org.freedesktop.udisks2.filesystem-mount -p unix-process:pid:\$\$ 2>&1 | head -1"
echo
info "Archivos que puedes personalizar:"
info "  ~/dwm/config.h                     atajos, colores, fuentes, gaps"
info "  ~/slstatus/config.h                barra de estado"
info "  ~/.config/dwm/autostart.sh         programas que arrancan con dwm"
info "  ~/.config/picom/picom.conf         transparencias"
info "  ~/.config/lf/lfrc                  gestor de archivos de terminal"
info "  ~/Atajos.txt                       chuleta de atajos (nano ~/Atajos.txt)"
info "  /etc/polkit-1/rules.d/49-udisks2-wheel.rules   permisos de montaje"
info "Despues de editar los config.h: cd ~/dwm && sudo make clean install"
warn "Si no ves la sesion 'dwm' en el login: revisa /usr/share/xsessions/dwm.desktop"
