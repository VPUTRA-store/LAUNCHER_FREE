#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
#  VP LAUNCHER FREE
#  Jalan di Termux. Fitur: Auto Launch + Atur Delay
# =====================================================

DELAY_DETIK=10   # jeda antar Roblox saat dibuka
PAKET=()         # daftar aplikasi Roblox yang terdeteksi

# Perintah root. Redfinger harus sudah di-root.
if command -v su >/dev/null 2>&1; then
  SU="su -c"
else
  SU="sh -c"
fi

# su bisa mengacaukan layar Termux (Enter tidak berfungsi, tulisan miring).
fix_tty() { stty sane 2>/dev/null; }
rt() {
  $SU "$1" </dev/null
  local r=$?
  fix_tty
  return $r
}

# ---------- Tampilan ----------
lebar() {
  local c
  c=$({ stty size </dev/tty; } 2>/dev/null | cut -d' ' -f2)
  if ! [[ "$c" =~ ^[0-9]+$ ]] || [ "$c" -lt 10 ]; then
    c="${COLUMNS:-40}"
  fi
  echo "$c"
}

garis() {
  local w
  w=$(lebar)
  [ "$w" -gt 31 ] && w=31
  printf '%*s\n' "$((w - 1))" '' | tr ' ' '-'
}

tulis() {
  printf '%s\n' "$1" | fold -s -w "$(( $(lebar) - 1 ))"
}

header() {
  fix_tty
  clear
  garis
  echo "VP LAUNCHER FREE"
  garis
  echo
}

tunggu_enter() {
  fix_tty
  echo
  read -r -p "Enter = kembali: " _
}

# ---------- Roblox ----------
cari_roblox() {
  PAKET=()
  while IFS= read -r p; do
    [ -n "$p" ] && PAKET+=("$p")
  done < <(rt "pm list packages" 2>/dev/null | tr -d '\r' | grep -i '^package:com\.roblox' | cut -d: -f2 | sort)
  fix_tty
}

buka() {
  local p="$1" out
  out=$(rt "am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -p $p" 2>&1)
  if printf '%s' "$out" | grep -qi 'error'; then
    rt "monkey -p $p -c android.intent.category.LAUNCHER 1" >/dev/null 2>&1
  fi
}

jeda() {
  echo "   jeda ${DELAY_DETIK} detik..."
  sleep "$DELAY_DETIK"
}

auto_launch() {
  header
  cari_roblox
  if [ ${#PAKET[@]} -eq 0 ]; then
    tulis "Tidak ada Roblox (com.roblox) yang terdeteksi."
    tunggu_enter
    return
  fi

  echo "Terdeteksi ${#PAKET[@]} Roblox:"
  for p in "${PAKET[@]}"; do echo " - $p"; done
  echo

  local i=0
  for p in "${PAKET[@]}"; do
    i=$((i + 1))
    echo "[$i/${#PAKET[@]}] Membuka $p"
    buka "$p"
    if [ $i -lt ${#PAKET[@]} ]; then jeda; fi
  done
  echo
  echo "Semua Roblox sudah dibuka."
  tunggu_enter
}

# ---------- Delay ----------
atur_delay() {
  local d
  header
  tulis "ATUR DELAY antar Roblox saat dibuka"
  tulis "(rekomendasi 5-10 detik)"
  echo
  echo "Delay sekarang: ${DELAY_DETIK} detik"
  read -r -p "Delay baru (detik): " d
  if [ -z "$d" ]; then
    echo "Tidak diubah."
  elif [[ "$d" =~ ^[0-9]+$ ]] && [ "$d" -ge 1 ] && [ "$d" -le 120 ]; then
    DELAY_DETIK=$d
    echo "Delay diatur ke ${DELAY_DETIK} detik."
    if [ "$d" -lt 5 ]; then
      tulis "Peringatan: di bawah 5 detik berisiko membuat cloud crash."
    fi
  else
    tulis "Harus angka 1 sampai 120."
  fi
  tunggu_enter
}

# ---------- Menu utama (langsung tampil, tanpa key) ----------
while true; do
  header
  echo "Delay : ${DELAY_DETIK} detik"
  echo
  echo "1. AUTO LAUNCH"
  echo "2. ATUR DELAY"
  echo "3. KELUAR"
  echo
  read -r -p "Pilih: " PILIH

  case "$PILIH" in
    1) auto_launch ;;
    2) atur_delay ;;
    3)
      echo "Sampai jumpa!"
      exit 0
      ;;
    *)
      echo "Pilihan tidak ada."
      sleep 1
      ;;
  esac
done
