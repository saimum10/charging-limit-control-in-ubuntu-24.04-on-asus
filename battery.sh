#!/bin/bash

# =============================================
#   ASUS TUF FX505GM - চার্জিং লিমিট কন্ট্রোল
#   Ubuntu 24.04
# =============================================

BAT_PATH="/sys/class/power_supply/BAT0/charge_control_end_threshold"
SERVICE_NAME="battery-limit"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# Root চেক
if [ "$EUID" -ne 0 ]; then
  echo ""
  echo "❌ অনুগ্রহ করে sudo দিয়ে চালান:"
  echo "   sudo bash asus-battery.sh"
  echo ""
  exit 1
fi

# ব্যাটারি পাথ চেক
if [ ! -f "$BAT_PATH" ]; then
  echo ""
  echo "❌ ব্যাটারি পাথ পাওয়া যায়নি!"
  echo "   আপনার ডিভাইস সাপোর্ট করে না অথবা পাথ ভিন্ন।"
  echo ""
  exit 1
fi

# বর্তমান লিমিট দেখান
CURRENT=$(cat "$BAT_PATH")

echo ""
echo "============================================"
echo "   ASUS TUF - চার্জিং লিমিট কন্ট্রোলার"
echo "============================================"
echo ""
echo "  বর্তমান লিমিট: ${CURRENT}%"
echo ""
echo "  একটি অপশন সিলেক্ট করুন:"
echo ""
echo "  1)  60% লিমিট  (ব্যাটারি দীর্ঘস্থায়ী)"
echo "  2)  70% লিমিট  (ব্যালেন্সড)"
echo "  3)  80% লিমিট  (সবচেয়ে জনপ্রিয়)"
echo "  4)  লিমিট বন্ধ  (100% - সম্পূর্ণ চার্জ)"
echo ""
read -p "  আপনার পছন্দ (1-4): " choice
echo ""

case $choice in
  1) LIMIT=60 ;;
  2) LIMIT=70 ;;
  3) LIMIT=80 ;;
  4) LIMIT=100 ;;
  *)
    echo "❌ ভুল অপশন! অনুগ্রহ করে 1 থেকে 4 এর মধ্যে দিন।"
    echo ""
    exit 1
    ;;
esac

# এখনই প্রয়োগ করুন
echo "$LIMIT" > "$BAT_PATH"

# systemd service তৈরি/আপডেট করুন
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

# Service রিলোড ও চালু করুন
systemctl daemon-reload
systemctl enable "$SERVICE_NAME" --quiet 2>/dev/null
systemctl restart "$SERVICE_NAME"

# সফলতার বার্তা
echo "============================================"
if [ "$LIMIT" -eq 100 ]; then
  echo "  ✅ চার্জিং লিমিট বন্ধ করা হয়েছে (100%)"
else
  echo "  ✅ চার্জিং লিমিট ${LIMIT}% সেট করা হয়েছে!"
fi
echo "  ✅ Reboot এর পরেও এই সেটিং বজায় থাকবে।"
echo "  ✅ পরিবর্তন করতে আবার script চালান।"
echo "============================================"
echo ""
