#!/bin/bash

# =============================================
#   Pop!_OS - চার্জিং লিমিট কন্ট্রোলার
#   ✅ Reboot-proof  ✅ Sleep/Wake-proof
#   Ubuntu 24.04 / Pop!_OS 22.04
# =============================================

SERVICE_NAME="battery-limit"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
SLEEP_HOOK="/lib/systemd/system-sleep/battery-limit-hook"

# ─────────────────────────────────────────
# Root চেক
# ─────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  echo ""
  echo "❌ অনুগ্রহ করে sudo দিয়ে চালান:"
  echo "   sudo bash popos-battery.sh"
  echo ""
  exit 1
fi

# ─────────────────────────────────────────
# ব্যাটারি পাথ অটো-ডিটেক্ট (BAT0 / BAT1)
# ─────────────────────────────────────────
BAT_PATH=""
BAT_START_PATH=""
for bat in BAT0 BAT1; do
  CANDIDATE="/sys/class/power_supply/${bat}/charge_control_end_threshold"
  if [ -f "$CANDIDATE" ]; then
    BAT_PATH="$CANDIDATE"
    BAT_NAME="$bat"
    BAT_START_PATH="/sys/class/power_supply/${bat}/charge_control_start_threshold"
    break
  fi
done

if [ -z "$BAT_PATH" ]; then
  echo ""
  echo "❌ ব্যাটারি পাথ পাওয়া যায়নি!"
  echo "   আপনার ডিভাইস সাপোর্ট করে না অথবা পাথ ভিন্ন।"
  echo "   নিচের কমান্ড দিয়ে চেক করুন:"
  echo "   ls /sys/class/power_supply/"
  echo ""
  exit 1
fi

# ─────────────────────────────────────────
# system76-power conflict সতর্কতা
# ─────────────────────────────────────────
S76_ACTIVE=false
if systemctl is-active --quiet system76-power 2>/dev/null; then
  S76_ACTIVE=true
fi

# ─────────────────────────────────────────
# বর্তমান লিমিট
# ─────────────────────────────────────────
CURRENT=$(cat "$BAT_PATH")

# ─────────────────────────────────────────
# Helper: limit সেট + service + sleep hook
# ─────────────────────────────────────────
apply_limit() {
  local LIMIT=$1

  # এখনই প্রয়োগ
  echo "$LIMIT" > "$BAT_PATH"

  # systemd service → Reboot এর পরেও কাজ করবে
  cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Battery Charge Limit - ${LIMIT}% (${BAT_NAME})
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

  # Sleep hook → Wake/Resume এর পরেও কাজ করবে
  cat > "$SLEEP_HOOK" << EOF
#!/bin/bash
case "\$1" in
  post)
    echo ${LIMIT} > ${BAT_PATH} 2>/dev/null || true
    ;;
esac
EOF
  chmod +x "$SLEEP_HOOK"
}

# ─────────────────────────────────────────
# Helper: সব লিমিট রিসেট করুন
# ─────────────────────────────────────────
reset_limit() {
  # end threshold → 100
  echo "100" > "$BAT_PATH"

  # start threshold → 0 (যদি সাপোর্ট করে)
  if [ -f "$BAT_START_PATH" ]; then
    echo "0" > "$BAT_START_PATH" 2>/dev/null || true
  fi

  # systemd service বন্ধ ও মুছুন
  systemctl stop "$SERVICE_NAME" 2>/dev/null || true
  systemctl disable "$SERVICE_NAME" --quiet 2>/dev/null || true
  rm -f "$SERVICE_FILE"
  systemctl daemon-reload

  # sleep hook মুছুন
  rm -f "$SLEEP_HOOK"
}

# ─────────────────────────────────────────
# মেনু
# ─────────────────────────────────────────
while true; do
  echo ""
  echo "=============================================="
  echo "   Pop!_OS - চার্জিং লিমিট কন্ট্রোলার"
  echo "=============================================="
  echo ""
  echo "  ব্যাটারি   : ${BAT_NAME}"

  if [ "$S76_ACTIVE" = true ]; then
    echo "  ⚠️  system76-power চলছে (override হবে)"
  fi

  echo ""
  echo "  একটি অপশন সিলেক্ট করুন:"
  echo ""
  echo "  1)  60% লিমিট  (ব্যাটারি দীর্ঘস্থায়ী)"
  echo "  2)  70% লিমিট  (ব্যালেন্সড)"
  echo "  3)  80% লিমিট  (সবচেয়ে জনপ্রিয়)"
  echo "  4)  লিমিট রিসেট (কোনো লিমিট নেই — PC বুঝবে না)"
  echo "  5)  বর্তমান লিমিট দেখুন"
  echo "  6)  বাহির (Exit)"
  echo ""
  read -p "  আপনার পছন্দ (1-6): " choice
  echo ""

  case $choice in
    1) LIMIT=60
       apply_limit $LIMIT
       echo "=============================================="
       echo "  ✅ চার্জিং লিমিট ${LIMIT}% সেট করা হয়েছে!"
       echo "  ✅ Reboot এর পরেও সেটিং বজায় থাকবে।"
       echo "  ✅ Sleep/Wake এর পরেও সেটিং বজায় থাকবে।"
       echo "  ✅ পরিবর্তন করতে আবার script চালান।"
       echo "=============================================="
       echo ""
       ;;

    2) LIMIT=70
       apply_limit $LIMIT
       echo "=============================================="
       echo "  ✅ চার্জিং লিমিট ${LIMIT}% সেট করা হয়েছে!"
       echo "  ✅ Reboot এর পরেও সেটিং বজায় থাকবে।"
       echo "  ✅ Sleep/Wake এর পরেও সেটিং বজায় থাকবে।"
       echo "  ✅ পরিবর্তন করতে আবার script চালান।"
       echo "=============================================="
       echo ""
       ;;

    3) LIMIT=80
       apply_limit $LIMIT
       echo "=============================================="
       echo "  ✅ চার্জিং লিমিট ${LIMIT}% সেট করা হয়েছে!"
       echo "  ✅ Reboot এর পরেও সেটিং বজায় থাকবে।"
       echo "  ✅ Sleep/Wake এর পরেও সেটিং বজায় থাকবে।"
       echo "  ✅ পরিবর্তন করতে আবার script চালান।"
       echo "=============================================="
       echo ""
       ;;

    4) reset_limit
       echo "=============================================="
       echo "  ✅ সব চার্জিং লিমিট সম্পূর্ণ রিসেট হয়েছে!"
       echo "  ✅ PC আর কোনো লিমিট সম্পর্কে জানে না।"
       echo "  ✅ Reboot / Sleep এর পরেও লিমিট আসবে না।"
       echo "=============================================="
       echo ""
       ;;

    5) CURRENT=$(cat "$BAT_PATH")
       echo "=============================================="
       echo "  🔋 ব্যাটারি    : ${BAT_NAME}"
       echo "  📊 বর্তমান লিমিট: ${CURRENT}%"
       if [ -f "$SERVICE_FILE" ]; then
         echo "  ⚙️  Service     : চালু আছে (reboot-proof)"
       else
         echo "  ⚙️  Service     : বন্ধ (রিসেট করা)"
       fi
       if [ -f "$SLEEP_HOOK" ]; then
         echo "  😴 Sleep hook  : চালু আছে (wake-proof)"
       else
         echo "  😴 Sleep hook  : বন্ধ (রিসেট করা)"
       fi
       echo "=============================================="
       echo ""
       ;;

    6) echo "  👋 বাহির হচ্ছেন..."
       echo ""
       exit 0
       ;;

    *) echo "❌ ভুল অপশন! অনুগ্রহ করে 1 থেকে 6 এর মধ্যে দিন।"
       echo ""
       ;;
  esac
done
