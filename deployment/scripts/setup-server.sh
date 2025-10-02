#!/bin/bash

# ===============================================================
# Script de Configuración Inicial del Servidor DigitalOcean
# Para SMS Spam Detection Pipeline CI/CD
# ===============================================================

set -e  # Salir si cualquier comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para verificar si el script se ejecuta como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script debe ejecutarse como root (sudo)"
        exit 1
    fi
}

# Función principal
main() {
    log_info "🚀 Iniciando configuración del servidor DigitalOcean..."
    log_info "📋 Este script configurará:"
    echo "   - Docker y Docker Compose"
    echo "   - GitLab Runner"
    echo "   - Firewall UFW"
    echo "   - Usuario de deployment"
    echo "   - Configuraciones de seguridad"
    
    read -p "¿Continuar con la instalación? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Instalación cancelada."
        exit 0
    fi

    # 1. Actualizar sistema
    log_info "📦 Actualizando paquetes del sistema..."
    apt-get update -y
    apt-get upgrade -y
    apt-get install -y \
        curl \
        wget \
        git \
        unzip \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        ufw \
        fail2ban

    # 2. Instalar Docker
    log_info "🐳 Instalando Docker..."
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update -y
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        systemctl enable docker
        systemctl start docker
        log_success "Docker instalado exitosamente"
    else
        log_info "Docker ya está instalado"
    fi

    # 3. Instalar Docker Compose (standalone)
    log_info "🔧 Instalando Docker Compose..."
    if ! command -v docker-compose &> /dev/null; then
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        log_success "Docker Compose instalado exitosamente"
    else
        log_info "Docker Compose ya está instalado"
    fi

    # 4. Crear usuario de deployment
    log_info "👤 Configurando usuario de deployment..."
    DEPLOY_USER="deploy"
    if ! id -u "$DEPLOY_USER" &>/dev/null; then
        useradd -m -s /bin/bash "$DEPLOY_USER"
        usermod -aG docker "$DEPLOY_USER"
        usermod -aG sudo "$DEPLOY_USER"
        log_success "Usuario '$DEPLOY_USER' creado y añadido a grupos docker y sudo"
    else
        log_info "Usuario '$DEPLOY_USER' ya existe"
        usermod -aG docker "$DEPLOY_USER"
    fi

    # 5. Configurar SSH para el usuario deploy
    log_info "🔑 Configurando SSH para deployment..."
    DEPLOY_HOME="/home/$DEPLOY_USER"
    mkdir -p "$DEPLOY_HOME/.ssh"
    chmod 700 "$DEPLOY_HOME/.ssh"
    
    # Crear archivo authorized_keys si no existe
    touch "$DEPLOY_HOME/.ssh/authorized_keys"
    chmod 600 "$DEPLOY_HOME/.ssh/authorized_keys"
    chown -R "$DEPLOY_USER:$DEPLOY_USER" "$DEPLOY_HOME/.ssh"

    log_warning "⚠️  IMPORTANTE: Debes añadir tu clave SSH pública al archivo:"
    echo "   $DEPLOY_HOME/.ssh/authorized_keys"
    echo ""
    log_info "💡 Puedes hacerlo ejecutando:"
    echo "   echo 'tu_clave_publica_ssh' >> $DEPLOY_HOME/.ssh/authorized_keys"

    # 6. Instalar GitLab Runner
    log_info "🏃 Instalando GitLab Runner..."
    if ! command -v gitlab-runner &> /dev/null; then
        curl -L --output /usr/local/bin/gitlab-runner "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64"
        chmod +x /usr/local/bin/gitlab-runner
        useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash || true
        gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
        gitlab-runner start
        log_success "GitLab Runner instalado exitosamente"
        
        log_warning "⚠️  CONFIGURACIÓN PENDIENTE: Registrar GitLab Runner"
        echo "   Ejecuta: gitlab-runner register"
        echo "   URL: tu_gitlab_url"
        echo "   Token: tu_registration_token"
        echo "   Executor: docker"
        echo "   Default image: alpine:latest"
    else
        log_info "GitLab Runner ya está instalado"
    fi

    # 7. Configurar firewall UFW
    log_info "🔥 Configurando firewall UFW..."
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 8501/tcp  # Puerto de Streamlit
    ufw allow 9501/tcp  # Puerto de Streamlit staging
    ufw allow 80/tcp    # HTTP
    ufw allow 443/tcp   # HTTPS
    ufw --force enable
    log_success "Firewall configurado correctamente"

    # 8. Configurar fail2ban
    log_info "🛡️  Configurando fail2ban..."
    systemctl enable fail2ban
    systemctl start fail2ban
    log_success "fail2ban configurado y activo"

    # 9. Configurar límites del sistema
    log_info "⚙️  Configurando límites del sistema..."
    cat >> /etc/security/limits.conf <<EOF
# SMS Spam Detection App limits
deploy soft nofile 65536
deploy hard nofile 65536
gitlab-runner soft nofile 65536
gitlab-runner hard nofile 65536
EOF

    # 10. Crear directorio de aplicación
    log_info "📁 Creando directorio de aplicación..."
    APP_DIR="/opt/sms-spam-detector"
    mkdir -p "$APP_DIR"
    chown -R "$DEPLOY_USER:$DEPLOY_USER" "$APP_DIR"
    
    # Crear estructura de directorios
    sudo -u "$DEPLOY_USER" mkdir -p "$APP_DIR"/{logs,data,backups}
    log_success "Directorio de aplicación creado: $APP_DIR"

    # 11. Configurar logrotate
    log_info "📝 Configurando rotación de logs..."
    cat > /etc/logrotate.d/sms-spam-detector <<EOF
$APP_DIR/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 $DEPLOY_USER $DEPLOY_USER
    postrotate
        docker restart sms-spam-app 2>/dev/null || true
    endscript
}
EOF

    # 12. Crear script de monitoreo
    log_info "📊 Creando script de monitoreo..."
    cat > /usr/local/bin/monitor-app.sh <<'EOF'
#!/bin/bash
# Monitor para la aplicación SMS Spam Detection

APP_NAME="sms-spam-app"
LOG_FILE="/opt/sms-spam-detector/logs/monitor.log"

# Función de logging
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Verificar si el contenedor está corriendo
if ! docker ps | grep -q "$APP_NAME"; then
    log_message "ERROR: Contenedor $APP_NAME no está corriendo"
    
    # Intentar reiniciar
    log_message "INFO: Intentando reiniciar $APP_NAME"
    if docker start "$APP_NAME" 2>/dev/null; then
        log_message "SUCCESS: Contenedor reiniciado exitosamente"
    else
        log_message "ERROR: No se pudo reiniciar el contenedor"
        exit 1
    fi
fi

# Verificar salud de la aplicación
if ! curl -f http://localhost:8501/_stcore/health &>/dev/null; then
    log_message "WARNING: Health check falló para $APP_NAME"
else
    log_message "INFO: Aplicación saludable"
fi
EOF

    chmod +x /usr/local/bin/monitor-app.sh
    chown "$DEPLOY_USER:$DEPLOY_USER" /usr/local/bin/monitor-app.sh

    # 13. Configurar cron para monitoreo
    log_info "⏰ Configurando cron para monitoreo..."
    (crontab -u "$DEPLOY_USER" -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/monitor-app.sh") | crontab -u "$DEPLOY_USER" -

    # 14. Mostrar información final
    log_success "🎉 ¡Configuración del servidor completada!"
    echo ""
    log_info "📋 RESUMEN DE CONFIGURACIÓN:"
    echo "   ✅ Docker y Docker Compose instalados"
    echo "   ✅ GitLab Runner instalado"
    echo "   ✅ Usuario de deployment: $DEPLOY_USER"
    echo "   ✅ Firewall UFW configurado"
    echo "   ✅ fail2ban activo"
    echo "   ✅ Directorio de aplicación: $APP_DIR"
    echo "   ✅ Monitoreo automático configurado"
    echo ""
    log_warning "📝 TAREAS PENDIENTES:"
    echo "   1. Añadir clave SSH pública a: $DEPLOY_HOME/.ssh/authorized_keys"
    echo "   2. Registrar GitLab Runner: gitlab-runner register"
    echo "   3. Configurar variables de entorno en GitLab CI/CD"
    echo ""
    log_info "🔧 COMANDOS ÚTILES:"
    echo "   • Ver logs de Docker: docker logs sms-spam-app"
    echo "   • Reiniciar aplicación: docker restart sms-spam-app"
    echo "   • Ver estado del firewall: ufw status"
    echo "   • Ver logs de monitoreo: tail -f $APP_DIR/logs/monitor.log"
    echo ""
    log_info "🌐 La aplicación estará disponible en:"
    echo "   • Producción: http://$(curl -s ifconfig.me):8501"
    echo "   • Staging: http://$(curl -s ifconfig.me):9501"
}

# Verificar permisos y ejecutar
check_root
main "$@"
