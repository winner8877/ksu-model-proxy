#!/system/bin/sh

MODDIR=${0%/*}
LOG="$MODDIR/proxy.log"
BACKUP_DIR="$MODDIR/backup"
CF_WORKER="https://qazqqaazz.dpdns.org"

log() {
    echo "[$(date +%m-%d/%H:%M)] $1" >> "$LOG"
}

url_encode() {
    echo "$1" | sed \
        -e 's/%/%25/g' \
        -e 's/&/%26/g' \
        -e 's/=/%3D/g' \
        -e 's/?/%3F/g' \
        -e 's/ /%20/g' \
        -e 's/:/%3A/g' \
        -e 's/\//%2F/g' \
        -e 's/+/%2B/g'
}

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
sleep 15

log "=== CF Worker 代理启动 ==="
log "Worker: $CF_WORKER"
mkdir -p "$BACKUP_DIR"

for module_path in /data/adb/modules/*; do
    [ -d "$module_path" ] || continue
    
    module_id=$(basename "$module_path")
    prop_file="$module_path/module.prop"
    
    [ "$module_id" = "github-cf-proxy" ] && continue
    [ ! -f "$prop_file" ] && continue
    
    current_url=$(grep "^updateJson=" "$prop_file" 2>/dev/null | cut -d'=' -f2-)
    [ -z "$current_url" ] && continue
    
    # 只处理含 github 的链接
    echo "$current_url" | grep -qi "github" || continue
    
    # 跳过已处理的（防止重复代理）
    case "$current_url" in
        *"qazqqaazz.dpdns.org"*)
            log "[$module_id] 已代理，跳过"
            continue
            ;;
    esac
    
    log "[$module_id] 原始: ${current_url:0:60}..."
    
    # 备份（仅首次）
    if [ ! -f "$BACKUP_DIR/${module_id}.bak" ]; then
        cp "$prop_file" "$BACKUP_DIR/${module_id}.bak"
    fi
    
    # 构建 Worker URL
    encoded=$(url_encode "$current_url")
    new_url="${CF_WORKER}/?url=${encoded}"
    
    # 替换
    sed -i "s|^updateJson=.*|updateJson=${new_url}|" "$prop_file"
    log "[$module_id] 已指向 Worker"
    
    sleep 0.2
done

log "=== 扫描完成 ==="