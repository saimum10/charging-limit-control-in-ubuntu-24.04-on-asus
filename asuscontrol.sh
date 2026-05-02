#!/bin/bash

# =============================================
#   ASUS TUF FX505GM - Charging Limit Control
#   Ubuntu 24.04
# =============================================

BAT_PATH="/sys/class/power_supply/BAT0/charge_control_end_threshold"
SERVICE_NAME="battery-limit"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# Root check
if [ "$EUID" -ne 0 ]; then
  echo ""
  echo "  Please run with sudo:"
  echo "  sudo bash asuscontrol.sh"
  echo ""
  exit 1
fi

# Battery path check
if [ ! -f "$BAT_PATH" ]; then
  echo ""
  echo "  ERROR: Battery path not found."
  echo "  Your device may not support this feature."
  echo ""
  exit 1
fi

set_limit() {
  LIMIT=$1

  # Apply immediately
  echo "$LIMIT" > "$BAT_PATH"

  # Create systemd service
  cat > "$SERVICE_FILE" << EOF
[Unit]
Description=ASUS Battery Charge Limit - ${LIMIT}%
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo ${LIMIT} > ${BAT_PATH}'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable "$SERVICE_NAME" --quiet 2>/dev/null
  systemctl restart "$SERVICE_NAME"

  echo ""
  echo "  Charging limit set to ${LIMIT}%."
  echo "  This setting will persist after reboot."
  echo ""
}

limit_off() {
  # Reset threshold to default (100%)
  echo "100" > "$BAT_PATH"

  # Disable and delete service completely
  systemctl stop "$SERVICE_NAME" 2>/dev/null
  systemctl disable "$SERVICE_NAME" --quiet 2>/dev/null
  rm -f "$SERVICE_FILE"
  systemctl daemon-reload

  echo ""
  echo "  Charging limit removed."
  echo "  Battery will charge to 100% normally."
  echo ""
}

view_limit() {
  CURRENT=$(cat "$BAT_PATH")
  echo ""
  if systemctl is-enabled "$SERVICE_NAME" --quiet 2>/dev/null; then
    echo "  Current charging limit: ${CURRENT}%"
  else
    echo "  Charging limit: Off (${CURRENT}%)"
  fi
  echo ""
}

# Main menu
while true; do
  echo ""
  echo "  ====================================="
  echo "   ASUS TUF FX505GM - Control Panel"
  echo "  ====================================="
  echo ""
  echo "  1) Set Charging Limit - 60%"
  echo "  2) Set Charging Limit - 70%"
  echo "  3) Set Charging Limit - 80%"
  echo "  4) Charging Limit Off"
  echo "  5) View Charging Limit"
  echo "  0) Exit"
  echo ""
  read -p "  Your choice (0-5): " choice

  case $choice in
    1) set_limit 60 ;;
    2) set_limit 70 ;;
    3) set_limit 80 ;;
    4) limit_off ;;
    5) view_limit ;;
    0)
      echo ""
      echo "  Exiting..."
      echo ""
      exit 0
      ;;
    *)
      echo ""
      echo "  Invalid option. Please enter 0-5."
      ;;
  esac
done
