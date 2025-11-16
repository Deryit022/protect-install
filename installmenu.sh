#!/usr/bin/env bash
# install-protect-menu.sh
# Menyediakan menu untuk memilih installprotect1..9 dari repo Deryit022/protect-install
# Gunakan dengan hati-hati. Review file yang diunduh sebelum menjalankan.

set -euo pipefail

REPO="https://raw.githubusercontent.com/Deryit022/protect-install/main"
DEST="/opt/protect-install"
SCRIPTS=(installprotect1.sh installprotect2.sh installprotect3.sh installprotect4.sh installprotect5.sh installprotect6.sh installprotect7.sh installprotect8.sh installprotect9.sh)

log() { printf "%s\n" "$*"; }

ensure_dir() {
  if [ ! -d "$DEST" ]; then
    sudo mkdir -p "$DEST"
    sudo chown "$USER":"$USER" "$DEST"
  fi
}

get_with_git() {
  if command -v git >/dev/null 2>&1; then
    if [ -d "$DEST/.git" ]; then
      log "Repo sudah ada di $DEST — melakukan git pull..."
      (cd "$DEST" && git pull --ff-only) || true
    else
      log "Meng-clone repo ke $DEST..."
      git clone "https://github.com/Deryit022/protect-install.git" "$DEST"
    fi
    return 0
  fi
  return 1
}

get_with_curl() {
  log "Mengunduh skrip satu per satu ke $DEST menggunakan curl..."
  ensure_dir
  for f in "${SCRIPTS[@]}"; do
    url="$REPO/$f"
    out="$DEST/$f"
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "$url" -o "$out" || { log "Gagal mengunduh $url"; return 1; }
    elif command -v wget >/dev/null 2>&1; then
      wget -qO "$out" "$url" || { log "Gagal mengunduh $url"; return 1; }
    else
      log "Tidak ada curl/wget. Install salah satu atau gunakan git."
      return 1
    fi
    chmod +x "$out"
  done
  return 0
}

prepare() {
  if get_with_git; then
    log "Sumber tersedia via git."
    return 0
  fi
  if get_with_curl; then
    log "Sumber berhasil diunduh via curl/wget."
    return 0
  fi
  log "Gagal mengakses sumber. Pastikan git atau curl/wget tersedia dan koneksi internet aktif."
  exit 1
}

show_menu() {
  cat <<EOF

Pilih instalasi:
  1) installprotect1
  2) installprotect2
  3) installprotect3
  4) installprotect4
  5) installprotect5
  6) installprotect6
  7) installprotect7
  8) installprotect8
  9) installprotect9
  0) Keluar

EOF
  printf "Masukkan pilihan (0-9): "
}

run_choice() {
  local idx=$1
  local script="$DEST/${SCRIPTS[$idx]}"
  if [ ! -f "$script" ]; then
    log "File $script tidak ditemukan. Mencoba persiapan ulang..."
    prepare
    if [ ! -f "$script" ]; then
      log "Masih gagal menemukan $script. Abort."
      return 1
    fi
  fi

  log "=== Menjalankan $script ==="
  # Tampilkan header kecil untuk review singkat
  log "Preview 20 baris pertama $script:"
  sed -n '1,20p' "$script" || true
  log "Jika sudah oke, skrip akan dieksekusi."

  # Eksekusi skrip dengan bash; gunakan sudo bila diperlukan untuk commands root
  # Menjalankan di subshell agar skrip dapat menggunakan exit tanpa mematikan menu
  (bash "$script")
  local rc=$?
  if [ $rc -ne 0 ]; then
    log "Skrip keluar dengan kode $rc"
  else
    log "Skrip selesai."
  fi
  return $rc
}

main_loop() {
  prepare
  while true; do
    show_menu
    read -r choice || { echo; break; }
    case "$choice" in
      0) log "Keluar."; exit 0 ;;
      [1-9])
        idx=$((choice-1))
        run_choice "$idx"
        log "=================================="
        ;;
      *)
        log "Input tidak valid. Masukkan angka 0-9."
        ;;
    esac
  done
}

# Mulai
main_loop
