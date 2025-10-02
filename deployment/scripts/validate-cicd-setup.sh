#!/bin/bash

# =============================================================================
# CI/CD Setup Validator for SMS Spam Detection
# =============================================================================
# Este script valida que toda la configuración necesaria esté correctamente
# configurada antes de ejecutar el pipeline CI/CD
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Contadores para reporte
CHECKS_TOTAL=0
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

# Función para mostrar ayuda
show_help() {
    echo -e "\n${YELLOW}Uso:${NC}"
    echo "  $0 [OPCIONES]"
    echo ""
    echo -e "${YELLOW}Opciones:${NC}"
    echo "  -h, --help              Mostrar esta ayuda"
    echo "  -s, --server SERVER_IP  IP del servidor para validar conexión"
    echo "  -k, --ssh-key PATH      Ruta a la clave SSH privada"
    echo "  --skip-ssh              Omitir validaciones SSH"
    echo "  --skip-docker           Omitir validaciones Docker"
    echo ""
    echo -e "${YELLOW}Ejemplo:${NC}"
    echo "  $0 -s 192.168.1.100 -k ~/.ssh/sms_spam_deploy"
}

# Función para logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((CHECKS_PASSED++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((CHECKS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNINGS++))
}

# Función para incrementar contador de checks
check_start() {
    ((CHECKS_TOTAL++))
}

# Variables por defecto
SERVER_IP=""
SSH_KEY_PATH="$HOME/.ssh/sms_spam_deploy"
SKIP_SSH=false
SKIP_DOCKER=false

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--server)
            SERVER_IP="$2"
            shift 2
            ;;
        -k|--ssh-key)
            SSH_KEY_PATH="$2"
            shift 2
            ;;
        --skip-ssh)
            SKIP_SSH=true
            shift
            ;;
        --skip-docker)
            SKIP_DOCKER=true
            shift
            ;;
        *)
            echo -e "${RED}Opción desconocida: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

echo -e "${CYAN}==============================================================================${NC}"
echo -e "${CYAN}              CI/CD Setup Validator - SMS Spam Detection${NC}"
echo -e "${CYAN}==============================================================================${NC}"

log_info "Iniciando validación de configuración CI/CD..."
echo ""

# =============================================================================
# 1. VALIDACIONES LOCALES
# =============================================================================

echo -e "${YELLOW}📋 1. VALIDACIONES LOCALES${NC}"
echo -e "${YELLOW}═══════════════════════════${NC}"

# 1.1 Verificar estructura del proyecto
check_start
log_info "Validando estructura del proyecto..."

required_files=(
    ".gitlab-ci.yml"
    "Dockerfile"
    "Dockerfile.dev"
    "requirements.txt"
    "src/app.py"
    "deployment/docker-compose.prod.yml"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        missing_files+=("$file")
    fi
done

if [[ ${#missing_files[@]} -eq 0 ]]; then
    log_success "Estructura del proyecto correcta"
else
    log_error "Archivos faltantes: ${missing_files[*]}"
fi

# 1.2 Verificar .gitlab-ci.yml
check_start
log_info "Validando .gitlab-ci.yml..."

if [[ -f ".gitlab-ci.yml" ]]; then
    # Verificar que contiene las etapas necesarias
    required_stages=("test" "build" "deploy")
    missing_stages=()
    
    for stage in "${required_stages[@]}"; do
        if ! grep -q "stage:.*$stage" .gitlab-ci.yml; then
            missing_stages+=("$stage")
        fi
    done
    
    if [[ ${#missing_stages[@]} -eq 0 ]]; then
        log_success ".gitlab-ci.yml contiene todas las etapas necesarias"
    else
        log_error ".gitlab-ci.yml falta etapas: ${missing_stages[*]}"
    fi
else
    log_error ".gitlab-ci.yml no encontrado"
fi

# 1.3 Verificar Dockerfile
check_start
log_info "Validando Dockerfile..."

if [[ -f "Dockerfile" ]]; then
    # Verificar contenido básico
    dockerfile_checks=(
        "FROM python:"
        "WORKDIR"
        "COPY requirements.txt"
        "RUN pip install"
        "COPY src/"
        "EXPOSE"
        "CMD"
    )
    
    dockerfile_issues=()
    for check in "${dockerfile_checks[@]}"; do
        if ! grep -q "$check" Dockerfile; then
            dockerfile_issues+=("$check")
        fi
    done
    
    if [[ ${#dockerfile_issues[@]} -eq 0 ]]; then
        log_success "Dockerfile tiene estructura correcta"
    else
        log_warning "Dockerfile podría tener problemas: ${dockerfile_issues[*]}"
    fi
else
    log_error "Dockerfile no encontrado"
fi

# 1.4 Verificar requirements.txt
check_start
log_info "Validando requirements.txt..."

if [[ -f "requirements.txt" ]]; then
    required_deps=("streamlit" "pandas" "scikit-learn" "joblib")
    missing_deps=()
    
    for dep in "${required_deps[@]}"; do
        if ! grep -q "$dep" requirements.txt; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        log_success "requirements.txt contiene dependencias básicas"
    else
        log_warning "requirements.txt podrían faltar: ${missing_deps[*]}"
    fi
else
    log_error "requirements.txt no encontrado"
fi

# =============================================================================
# 2. VALIDACIONES SSH
# =============================================================================

if [[ "$SKIP_SSH" != true ]]; then
    echo ""
    echo -e "${YELLOW}🔐 2. VALIDACIONES SSH${NC}"
    echo -e "${YELLOW}══════════════════════${NC}"

    # 2.1 Verificar clave SSH local
    check_start
    log_info "Verificando clave SSH local..."

    if [[ -f "$SSH_KEY_PATH" ]]; then
        # Verificar que es una clave válida
        if ssh-keygen -l -f "$SSH_KEY_PATH" >/dev/null 2>&1; then
            log_success "Clave SSH privada válida: $SSH_KEY_PATH"
        else
            log_error "Clave SSH privada inválida: $SSH_KEY_PATH"
        fi
    else
        log_error "Clave SSH no encontrada: $SSH_KEY_PATH"
        log_info "Ejecuta: ./deployment/scripts/generate-ssh-keys.sh"
    fi

    # 2.2 Verificar clave pública
    check_start
    log_info "Verificando clave SSH pública..."

    if [[ -f "$SSH_KEY_PATH.pub" ]]; then
        log_success "Clave SSH pública encontrada: $SSH_KEY_PATH.pub"
    else
        log_error "Clave SSH pública no encontrada: $SSH_KEY_PATH.pub"
    fi

    # 2.3 Test conexión al servidor (si se proporciona IP)
    if [[ -n "$SERVER_IP" ]]; then
        check_start
        log_info "Probando conexión SSH al servidor: $SERVER_IP"
        
        # Timeout de 10 segundos para la conexión
        if timeout 10 ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
           "deploy@$SERVER_IP" "echo 'SSH Connection OK'" >/dev/null 2>&1; then
            log_success "Conexión SSH exitosa al servidor"
        else
            log_error "No se pudo conectar por SSH al servidor"
            log_info "Verifica: IP correcta, usuario deploy, firewall, SSH key en servidor"
        fi
    else
        log_warning "IP del servidor no proporcionada, omitiendo test de conexión SSH"
    fi
else
    log_warning "Validaciones SSH omitidas (--skip-ssh)"
fi

# =============================================================================
# 3. VALIDACIONES DOCKER
# =============================================================================

if [[ "$SKIP_DOCKER" != true ]]; then
    echo ""
    echo -e "${YELLOW}🐳 3. VALIDACIONES DOCKER${NC}"
    echo -e "${YELLOW}═══════════════════════════${NC}"

    # 3.1 Verificar Docker instalado localmente
    check_start
    log_info "Verificando Docker local..."

    if command -v docker >/dev/null 2>&1; then
        docker_version=$(docker --version)
        log_success "Docker instalado: $docker_version"
    else
        log_error "Docker no está instalado localmente"
        log_info "Instala Docker desde: https://docs.docker.com/get-docker/"
    fi

    # 3.2 Verificar Docker Compose
    check_start
    log_info "Verificando Docker Compose..."

    if command -v docker-compose >/dev/null 2>&1; then
        compose_version=$(docker-compose --version)
        log_success "Docker Compose instalado: $compose_version"
    elif docker compose version >/dev/null 2>&1; then
        compose_version=$(docker compose version)
        log_success "Docker Compose (plugin) instalado: $compose_version"
    else
        log_error "Docker Compose no está disponible"
    fi

    # 3.3 Test build local
    check_start
    log_info "Probando build de imagen Docker..."
    
    if docker build -t sms-spam-test . >/dev/null 2>&1; then
        log_success "Build de imagen Docker exitoso"
        # Limpiar imagen de prueba
        docker rmi sms-spam-test >/dev/null 2>&1 || true
    else
        log_error "Fallo en build de imagen Docker"
        log_info "Revisa Dockerfile y dependencies en requirements.txt"
    fi

    # 3.4 Verificar Docker en servidor remoto (si SSH está configurado)
    if [[ -n "$SERVER_IP" && "$SKIP_SSH" != true && -f "$SSH_KEY_PATH" ]]; then
        check_start
        log_info "Verificando Docker en servidor remoto..."
        
        if timeout 15 ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
           "deploy@$SERVER_IP" "docker version" >/dev/null 2>&1; then
            log_success "Docker disponible en servidor remoto"
            
            # Verificar acceso del usuario deploy a Docker
            if timeout 10 ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no \
               "deploy@$SERVER_IP" "docker ps" >/dev/null 2>&1; then
                log_success "Usuario deploy tiene acceso a Docker"
            else
                log_error "Usuario deploy NO tiene acceso a Docker"
                log_info "Ejecuta en servidor: sudo usermod -aG docker deploy && sudo systemctl restart docker"
            fi
        else
            log_error "Docker no disponible en servidor remoto"
        fi
    fi
else
    log_warning "Validaciones Docker omitidas (--skip-docker)"
fi

# =============================================================================
# 4. VALIDACIONES GITLAB
# =============================================================================

echo ""
echo -e "${YELLOW}🦊 4. VALIDACIONES GITLAB CI/CD${NC}"
echo -e "${YELLOW}════════════════════════════════${NC}"

# 4.1 Verificar git remoto GitLab
check_start
log_info "Verificando repositorio GitLab remoto..."

if git remote -v | grep -q gitlab; then
    gitlab_url=$(git remote get-url origin)
    log_success "Repositorio GitLab configurado: $gitlab_url"
else
    log_error "No se encontró remoto de GitLab"
    log_info "Verifica que el origen esté configurado para GitLab"
fi

# 4.2 Verificar variables de entorno (simulado)
check_start
log_info "Verificando lista de variables de entorno necesarias..."

required_vars=(
    "SSH_PRIVATE_KEY (Protected + Masked)"
    "SSH_KNOWN_HOSTS (Protected)"
    "DEPLOY_HOST (Protected)"
    "DEPLOY_USER (Protected)"
    "STAGING_HOST (Protected)"
    "APP_NAME"
    "APP_PORT"
    "CONTAINER_NAME"
)

log_success "Variables requeridas identificadas:"
for var in "${required_vars[@]}"; do
    echo -e "   ${CYAN}• ${var}${NC}"
done

log_warning "Verifica manualmente estas variables en GitLab: Settings → CI/CD → Variables"

# =============================================================================
# 5. REPORTE FINAL
# =============================================================================

echo ""
echo -e "${CYAN}==============================================================================${NC}"
echo -e "${CYAN}                              REPORTE FINAL${NC}"
echo -e "${CYAN}==============================================================================${NC}"

echo ""
echo -e "${BLUE}📊 RESUMEN DE VALIDACIONES:${NC}"
echo -e "   Total checks: ${CYAN}$CHECKS_TOTAL${NC}"
echo -e "   Passed: ${GREEN}$CHECKS_PASSED${NC}"
echo -e "   Failed: ${RED}$CHECKS_FAILED${NC}"
echo -e "   Warnings: ${YELLOW}$WARNINGS${NC}"

echo ""
if [[ $CHECKS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✅ CONFIGURACIÓN LISTA PARA CI/CD${NC}"
    echo -e "   El proyecto está configurado correctamente para GitLab CI/CD"
    
    echo ""
    echo -e "${YELLOW}📝 PRÓXIMOS PASOS:${NC}"
    echo -e "   1. Configurar variables en GitLab CI/CD"
    echo -e "   2. Configurar SSH keys en servidor"
    echo -e "   3. Hacer push/commit para activar pipeline"
    echo -e "   4. Monitorear ejecución del pipeline"
    
else
    echo -e "${RED}❌ CONFIGURACIÓN INCOMPLETA${NC}"
    echo -e "   Se encontraron ${RED}$CHECKS_FAILED${NC} problemas que deben resolverse"
    
    echo ""
    echo -e "${YELLOW}🛠️  ACCIONES REQUERIDAS:${NC}"
    echo -e "   • Resolver todos los errores [FAIL] mostrados arriba"
    echo -e "   • Revisar warnings [WARN] y resolver si es necesario"
    echo -e "   • Ejecutar el script nuevamente para verificar"
fi

if [[ $WARNINGS -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  Se encontraron ${WARNINGS} warnings${NC}"
    echo -e "   Estos no bloquean el CI/CD pero deberían revisarse"
fi

echo ""
echo -e "${BLUE}📚 RECURSOS ADICIONALES:${NC}"
echo -e "   • Documentación: ${CYAN}deployment/ENVIRONMENT_VARIABLES.md${NC}"
echo -e "   • Generar SSH keys: ${CYAN}./deployment/scripts/generate-ssh-keys.sh${NC}"
echo -e "   • Setup servidor: ${CYAN}./deployment/scripts/setup-server.sh${NC}"

echo ""
echo -e "${CYAN}🎯 Para más ayuda, consulta la documentación del proyecto${NC}"

# Exit code basado en resultados
if [[ $CHECKS_FAILED -eq 0 ]]; then
    exit 0
else
    exit 1
fi
