#!/system/bin/sh
BACKUP="/data/adb/modules/github-cf-proxy/backup"
MODULES="/data/adb/modules"

[ ! -d "$BACKUP" ] && { echo "无备份"; exit 1; }

for bak in "$BACKUP"/*.bak; do
    [ -f "$bak" ] || continue
    id=$(basename "$bak" .bak)
    [ -d "$MODULES/$id" ] && cp "$bak" "$MODULES/$id/module.prop" && echo "✓ $id"
done

echo "已恢复，请重启 KSU Manager"
