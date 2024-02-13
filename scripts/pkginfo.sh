#!/usr/bin/env bash

# 更新系统 explicitly installed packages
# 包信息存储在 $backupDir
# 每次运行用 kdialog 来通知增加、移除和未改变三种状态

set -e

cacheDir="$HOME/.cache"
backupDir="$HOME/.dotfile/backup"
pkginfo="$backupDir/pkginfo.md"
scriptPath='$HOME/.dotfile/scripts/pkginfo.sh'

# Create backup directory if it doesn't exist
mkdir -p "$backupDir"

# Add script information to the generated file
echo "* This file is automatically generated by: \`$scriptPath\`" >"$pkginfo"
echo "" >>"$pkginfo"
echo "* Purpose: Describe explicitly installed packages and their descriptions." >>"$pkginfo"
echo "" >>"$pkginfo"

# Add table headers
echo "| 软件包 | 描述 |" >>"$pkginfo"
echo "| ------- | ---- |" >>"$pkginfo"

# Store the current package list in a temporary file
paru -Qe | awk '{print $1}' >"$cacheDir/current_packages.txt"

# Compare the current and previous package lists
if [ -f "$cacheDir/previous_packages.txt" ]; then
	sort "$cacheDir/previous_packages.txt" -o "$cacheDir/previous_packages.txt"
	sort "$cacheDir/current_packages.txt" -o "$cacheDir/current_packages.txt"

	comm -23 "$cacheDir/previous_packages.txt" "$cacheDir/current_packages.txt" >"$cacheDir/removed_packages.txt"
	comm -13 "$cacheDir/previous_packages.txt" "$cacheDir/current_packages.txt" >"$cacheDir/added_packages.txt"
else
	# If the previous package list doesn't exist, assume everything is added
	cp "$cacheDir/current_packages.txt" "$cacheDir/added_packages.txt"
	touch "$cacheDir/removed_packages.txt"
fi

# Save the current package list for future comparisons
mv "$cacheDir/current_packages.txt" "$cacheDir/previous_packages.txt"

# Check if there are changes and notify using kdialog
if [ -s "$cacheDir/added_packages.txt" ]; then
	added_packages=$(awk '{printf "<u>%s</u>\n", $0}' "$cacheDir/added_packages.txt")
	kdialog --title "软件包添加通知" --passivepopup "已添加的软件包:\n$added_packages" 5 --icon "package-install"
fi

if [ -s "$cacheDir/removed_packages.txt" ]; then
	removed_packages=$(awk '{printf "<u>%s</u>\n", $0}' "$cacheDir/removed_packages.txt")
	kdialog --title "软件包删除通知" --passivepopup "已删除的软件包:\n$removed_packages" 5 --icon "package-remove"
fi

if [ ! -s "$cacheDir/added_packages.txt" ] && [ ! -s "$cacheDir/removed_packages.txt" ]; then
	kdialog --title "cron脚本运行通知" --passivepopup "脚本(pkginfo.sh)已运行，未检测到软件包变更" 5 --icon "dialog-scripts"
fi

# Loop through installed packages and populate the table
while read -r package; do
	description=$(LANG=C paru -Qi "$package" | awk -F': ' '/^Description/ {print $2}')
	echo "| $package | $description |" >>"$pkginfo"
done < <(paru -Qe | awk '{print $1}')
