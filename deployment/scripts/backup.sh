#!/bin/bash

# ===============================================================
# Script de Backup Automático para SMS Spam Detection
# Crea backups de datos, configuraciones y logs
# ===============================================================

set -e

# Configuración
APP_NAME="sms-spam-detector"
APP_DIR="/opt/sms-spam-detector"
BACKUP_DIR="/opt/sms-spam-detector/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/${APP_NAME}_backup_$DATE.tar.gz"
RETENTION_DAYS=7

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones de logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Función principal
main() {
    log_info "🔄 Iniciando backup de $APP_NAME..."
    
    # Crear directorio de backup si no existe
    mkdir -p "$BACKUP_DIR"
    
    # Crear backup
    log_info "📦 Creando archivo de backup..."
    
    # Lista de elementos a incluir en el backup
    BACKUP_ITEMS=(
        "$APP_DIR/data"
        "$APP_DIR/logs"
        "/home/deploy/.ssh/authorized_keys"
        "/etc/logrotate.d/sms-spam-detector"
    )
    
    # Crear el archivo de backup
    tar -czf "$BACKUP_FILE" \
        --exclude='*.tmp' \
        --exclude='*.log.gz' \
        "${BACKUP_ITEMS[@]}" 2>/dev/null || {
        log_warning "Algunos archivos pueden no existir, continuando..."
    }
    
    # Verificar que el backup se creó correctamente
    if [[ -f "$BACKUP_FILE" ]]; then
        BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        log_success "Backup creado: $BACKUP_FILE ($BACKUP_SIZE)"
        
        # Crear metadatos del backup
        cat > "${BACKUP_FILE}.info" <<EOF
Backup Information
==================
Date: $(date)
App: $APP_NAME
Size: $BACKUP_SIZE
Files: ${#BACKUP_ITEMS[@]} directories/files
Retention: $RETENTION_DAYS days

Contents:
$(tar -tzf "$BACKUP_FILE" | head -10)
$(( $(tar -tzf "$BACKUP_FILE" | wc -l) > 10 )) && echo "... and more"
EOF
    else
        log_error "Error al crear el backup"
        exit 1
    fi
    
    # Limpiar backups antiguos
    log_info "🧹 Limpiando backups antiguos (>$RETENTION_DAYS días)..."
    find "$BACKUP_DIR" -name "${APP_NAME}_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    find "$BACKUP_DIR" -name "${APP_NAME}_backup_*.tar.gz.info" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    
    # Mostrar estadísticas
    BACKUP_COUNT=$(find "$BACKUP_DIR" -name "${APP_NAME}_backup_*.tar.gz" | wc -l)
    TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
    
    log_success "✅ Backup completado exitosamente"
    log_info "📊 Estadísticas:"
    echo "   • Backups actuales: $BACKUP_COUNT"
    echo "   • Tamaño total: $TOTAL_SIZE"
    echo "   • Último backup: $BACKUP_FILE"
}

# Función para restaurar desde backup
restore() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        log_error "Uso: $0 restore <archivo_backup>"
        exit 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Archivo de backup no encontrado: $backup_file"
        exit 1
    fi
    
    log_warning "⚠️  ADVERTENCIA: Esto sobrescribirá los datos actuales"
    read -p "¿Continuar con la restauración? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Restauración cancelada"
        exit 0
    fi
    
    log_info "🔄 Restaurando desde: $backup_file"
    
    # Parar la aplicación
    docker stop sms-spam-app 2>/dev/null || true
    
    # Restaurar archivos
    tar -xzf "$backup_file" -C / 2>/dev/null
    
    # Reiniciar la aplicación
    docker start sms-spam-app 2>/dev/null || true
    
    log_success "✅ Restauración completada"
}

# Función para listar backups
list_backups() {
    log_info "📋 Backups disponibles:"
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z $(ls -A "$BACKUP_DIR"/*.tar.gz 2>/dev/null) ]]; then
        log_warning "No hay backups disponibles"
        return
    fi
    
    echo ""
    printf "%-30s %-10s %-15s\n" "ARCHIVO" "TAMAÑO" "FECHA"
    printf "%-30s %-10s %-15s\n" "------" "------" "-----"
    
    for backup in "$BACKUP_DIR"/${APP_NAME}_backup_*.tar.gz; do
        if [[ -f "$backup" ]]; then
            size=$(du -h "$backup" | cut -f1)
            date=$(stat -c %y "$backup" | cut -d' ' -f1)
            filename=$(basename "$backup")
            printf "%-30s %-10s %-15s\n" "$filename" "$size" "$date"
        fi
    done
    
    echo ""
    log_info "Para restaurar: $0 restore $BACKUP_DIR/nombre_backup.tar.gz"
}

# Parsing de argumentos
case "${1:-backup}" in
    "backup")
        main
        ;;
    "restore")
        restore "$2"
        ;;
    "list")
        list_backups
        ;;
    *)
        echo "Uso: $0 [backup|restore <archivo>|list]"
        echo ""
        echo "Comandos:"
        echo "  backup          Crear nuevo backup (default)"
        echo "  restore <file>  Restaurar desde backup"
        echo "  list            Listar backups disponibles"
        exit 1
        ;;
esac
