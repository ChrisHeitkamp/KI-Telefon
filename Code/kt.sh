#!/usr/bin/env bash
# kt.sh – Schnellsteuerung für das KI-Telefon auf dem Raspberry Pi
#
# Einmalig einrichten:
#   chmod +x Code/kt.sh
#   ./Code/kt.sh install      # legt den systemd-Dienst an (Autostart beim Booten)
#
# Optional als Kurzbefehl "kt" überall verfügbar machen:
#   sudo ln -sf "$(pwd)/Code/kt.sh" /usr/local/bin/kt

set -euo pipefail

SERVICE="ki-telefon"
CODE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
REPO_DIR="$(dirname "$CODE_DIR")"
UNIT_FILE="/etc/systemd/system/${SERVICE}.service"

# Python aus einer venv nehmen, falls vorhanden, sonst System-Python
find_python() {
    for v in "$REPO_DIR/.venv" "$REPO_DIR/venv" "$CODE_DIR/.venv" "$CODE_DIR/venv"; do
        [[ -x "$v/bin/python" ]] && { echo "$v/bin/python"; return; }
    done
    command -v python3
}
PYTHON="$(find_python)"

usage() {
    cat <<EOF
KI-Telefon – Steuerung   (Dienst: $SERVICE)

  Dienst
    start        Dienst starten
    stop         Dienst stoppen
    restart      Dienst neu starten
    status       Status anzeigen
    enable       Autostart beim Booten an
    disable      Autostart beim Booten aus

  Logs
    log          Live-Log verfolgen (Strg+C zum Beenden)
    log-heute    Log von heute
    log-boot     Log seit dem letzten Booten
    log-fehler   Nur Fehler der letzten 24 h

  Entwicklung
    run          Im Vordergrund starten (Dienst vorher stoppen)
    update       git pull + Dienst neu starten
    sound        Soundkarten-Index anzeigen (Find_Soundcard_Index.py)

  System
    wlan         WLAN-Profile und aktive Verbindung anzeigen
    ip           IP-Adressen anzeigen
    temp         CPU-Temperatur
    install      systemd-Dienst anlegen + Autostart aktivieren
    uninstall    systemd-Dienst entfernen

  Python: $PYTHON
EOF
}

install_service() {
    local user; user="$(id -un)"
    echo "Lege $UNIT_FILE an (User: $user, Verzeichnis: $CODE_DIR)…"
    sudo tee "$UNIT_FILE" >/dev/null <<EOF
[Unit]
Description=KI-Telefon
After=network-online.target sound.target
Wants=network-online.target

[Service]
Type=simple
User=$user
SupplementaryGroups=audio gpio
WorkingDirectory=$CODE_DIR
ExecStart=$PYTHON -u $CODE_DIR/main.py
Restart=on-failure
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable --now "$SERVICE"
    echo "Fertig. Status:"
    systemctl --no-pager status "$SERVICE" || true
}

case "${1:-help}" in
    start)      sudo systemctl start "$SERVICE" && systemctl --no-pager status "$SERVICE" ;;
    stop)       sudo systemctl stop "$SERVICE" && echo "gestoppt" ;;
    restart)    sudo systemctl restart "$SERVICE" && systemctl --no-pager status "$SERVICE" ;;
    status)     systemctl --no-pager status "$SERVICE" ;;
    enable)     sudo systemctl enable "$SERVICE" ;;
    disable)    sudo systemctl disable "$SERVICE" ;;

    log)        journalctl -u "$SERVICE" -f -n 50 ;;
    log-heute)  journalctl -u "$SERVICE" --since today --no-pager ;;
    log-boot)   journalctl -u "$SERVICE" -b --no-pager ;;
    log-fehler) journalctl -u "$SERVICE" --since "24 hours ago" -p err --no-pager ;;

    run)        cd "$CODE_DIR" && exec "$PYTHON" -u main.py ;;
    update)     git -C "$REPO_DIR" pull && sudo systemctl restart "$SERVICE" && echo "aktualisiert + neu gestartet" ;;
    sound)      cd "$CODE_DIR" && "$PYTHON" Find_Soundcard_Index.py ;;

    wlan)       nmcli connection show; echo; nmcli device wifi list ;;
    ip)         hostname -I ;;
    temp)       vcgencmd measure_temp ;;
    install)    install_service ;;
    uninstall)  sudo systemctl disable --now "$SERVICE" || true
                sudo rm -f "$UNIT_FILE" && sudo systemctl daemon-reload && echo "Dienst entfernt" ;;

    help|-h|--help) usage ;;
    *) echo "Unbekannter Befehl: $1"; echo; usage; exit 1 ;;
esac
