#!/bin/bash

# エラー時に即終了
set -e

# 引数チェック
if [ $# -ne 1 ]; then
    echo "Usage: $0 <path_to_efi_file>"
    exit 1
fi

EFI_FILE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# OVMFファイルのパス（スクリプトと同じディレクトリ内にある前提）
OVMF_CODE="${SCRIPT_DIR}/OVMF_CODE.fd"
OVMF_VARS="${SCRIPT_DIR}/OVMF_VARS.fd"

# 存在チェック
if [ ! -f "$OVMF_CODE" ] || [ ! -f "$OVMF_VARS" ]; then
    echo "❌ OVMF_CODE.fd または OVMF_VARS.fd が ${SCRIPT_DIR} に存在しません。"
    exit 1
fi

# disk.imgの生成先をスクリプトディレクトリ内に設定
IMG_NAME="${SCRIPT_DIR}/disk.img"
MNT_DIR="${SCRIPT_DIR}/mnt"

# 1. イメージファイル作成
qemu-img create -f raw "$IMG_NAME" 200M

# 2. FAT32でフォーマット
mkfs.fat -n 'MIKAN OS' -s 2 -f 2 -R 32 -F 32 "$IMG_NAME"

# 3. マウントポイント作成 & マウント
mkdir -p "$MNT_DIR"
sudo mount -o loop "$IMG_NAME" "$MNT_DIR"

# 4. EFI/BOOT ディレクトリ作成 & .efi コピー
sudo mkdir -p "$MNT_DIR/EFI/BOOT"
sudo cp "$EFI_FILE" "$MNT_DIR/EFI/BOOT/BOOTX64.EFI"

# 5. アンマウント
sudo umount "$MNT_DIR"

# 6. QEMUで起動
qemu-system-x86_64 \
    -drive if=pflash,file="$OVMF_CODE" \
    -drive if=pflash,file="$OVMF_VARS" \
    -hda "$IMG_NAME"
