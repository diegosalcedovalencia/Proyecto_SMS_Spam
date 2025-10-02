#!/bin/bash

# =============================================================================
# SSH Key Generator for GitLab CI/CD Deployment
# =============================================================================
# Este script genera las claves SSH necesarias para el deployment automatizado
# y proporciona los valores exactos que necesitas configurar en GitLab CI/CD
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
SSH_KEY_NAME="sms_spam_deploy"
SSH_KEY_PATH="$HOME/.ssh/$SSH_KEY_NAME"
COMMENT="sms-spam-ci-cd-deploy-$(date +%Y%m%d)"

echo -e "${BLUE}==============================================================================${NC}"
echo -e "${BLUE}           SSH Key Generator for SMS Spam Detection CI/CD${NC}"
echo -e "${BLUE}==============================================================================${NC}"

# Función para mostrar ayuda
show_help() {
    echo -e "\n${YELLOW}Uso:${NC}"
    echo "  $0 [OPCIONES]"
    echo ""
    echo -e "${YELLOW}Opciones:${NC}"
    echo "  -h, --help              Mostrar esta ayuda"
    echo "  -s, --server SERVER_IP  IP del servidor para SSH_KNOWN_HOSTS"
    echo "  -k, --key-name NAME     Nombre personalizado para la clave SSH"
    echo ""
    echo -e "${YELLOW}Ejemplo:${NC}"
    echo "  $0 -s 192.168.1.100 -k my_deploy_key"
}

# Procesar argumentos
SERVER_IP=""
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
        -k|--key-name)
            SSH_KEY_NAME="$2"
            SSH_KEY_PATH="$HOME/.ssh/$SSH_KEY_NAME"
            shift 2
            ;;
        *)
            echo -e "${RED}Opción desconocida: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Verificar si ya existe una clave con el mismo nombre
if [[ -f "$SSH_KEY_PATH" ]]; then
    echo -e "${YELLOW}⚠️  La clave SSH '$SSH_KEY_NAME' ya existe.${NC}"
    read -p "¿Deseas sobrescribirla? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Operación cancelada.${NC}"
        exit 1
    fi
    rm -f "$SSH_KEY_PATH" "$SSH_KEY_PATH.pub"
fi

echo -e "\n${GREEN}🔐 Generando par de claves SSH...${NC}"

# Crear directorio .ssh si no existe
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Generar clave SSH
ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -C "$COMMENT" -N ""

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Clave SSH generada exitosamente!${NC}"
else
    echo -e "${RED}❌ Error al generar la clave SSH${NC}"
    exit 1
fi

echo -e "\n${BLUE}==============================================================================${NC}"
echo -e "${BLUE}                        CONFIGURACIÓN GITLAB CI/CD${NC}"
echo -e "${BLUE}==============================================================================${NC}"

echo -e "\n${YELLOW}📝 Variables para configurar en GitLab CI/CD:${NC}"
echo -e "   Ir a: ${BLUE}Settings → CI/CD → Variables${NC}"

# 1. SSH_PRIVATE_KEY
echo -e "\n${GREEN}1. SSH_PRIVATE_KEY${NC} (Protected ✅ | Masked ✅)"
echo -e "${YELLOW}   Copia exactamente este contenido:${NC}"
echo -e "${BLUE}---START SSH_PRIVATE_KEY---${NC}"
cat "$SSH_KEY_PATH"
echo -e "${BLUE}---END SSH_PRIVATE_KEY---${NC}"

# 2. SSH_KNOWN_HOSTS
echo -e "\n${GREEN}2. SSH_KNOWN_HOSTS${NC} (Protected ✅ | Masked ❌)"
if [[ -n "$SERVER_IP" ]]; then
    echo -e "${YELLOW}   Copia exactamente este contenido:${NC}"
    echo -e "${BLUE}---START SSH_KNOWN_HOSTS---${NC}"
    ssh-keyscan -H "$SERVER_IP" 2>/dev/null || echo -e "${RED}   ❌ Error: No se pudo conectar a $SERVER_IP${NC}"
    echo -e "${BLUE}---END SSH_KNOWN_HOSTS---${NC}"
else
    echo -e "${YELLOW}   Ejecuta este comando con la IP de tu servidor:${NC}"
    echo -e "${BLUE}   ssh-keyscan -H TU_SERVIDOR_IP${NC}"
fi

# 3. Clave pública para el servidor
echo -e "\n${GREEN}3. CLAVE PÚBLICA PARA EL SERVIDOR${NC}"
echo -e "${YELLOW}   Copia esta clave pública a tu servidor DigitalOcean:${NC}"
echo -e "${BLUE}---START PUBLIC KEY---${NC}"
cat "$SSH_KEY_PATH.pub"
echo -e "${BLUE}---END PUBLIC KEY---${NC}"

# 4. Variables adicionales
echo -e "\n${GREEN}4. OTRAS VARIABLES REQUERIDAS:${NC}"
cat << 'EOF'

DEPLOY_USER (Protected ✅ | Masked ❌)
   Valor: deploy

DEPLOY_HOST (Protected ✅ | Masked ❌)
   Valor: TU_SERVIDOR_IP_O_DOMINIO

STAGING_HOST (Protected ✅ | Masked ❌)
   Valor: TU_SERVIDOR_STAGING_IP (puede ser el mismo que DEPLOY_HOST)

APP_NAME (Protected ❌ | Masked ❌)
   Valor: sms-spam-detector

APP_PORT (Protected ❌ | Masked ❌)
   Valor: 8501

CONTAINER_NAME (Protected ❌ | Masked ❌)
   Valor: sms-spam-app

EOF

echo -e "\n${BLUE}==============================================================================${NC}"
echo -e "${BLUE}                      CONFIGURACIÓN DEL SERVIDOR${NC}"
echo -e "${BLUE}==============================================================================${NC}"

echo -e "\n${YELLOW}🚀 Comandos para configurar en tu servidor DigitalOcean:${NC}"

# Script para el servidor
cat << EOF > "$HOME/.ssh/server_setup_commands.sh"
#!/bin/bash
# Comandos para ejecutar en el servidor DigitalOcean

echo "=== Configurando SSH para usuario deploy ==="

# Crear directorio SSH para usuario deploy
sudo mkdir -p /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh

# Añadir clave pública (REEMPLAZAR con tu clave pública real)
echo "$(cat "$SSH_KEY_PATH.pub")" | sudo tee -a /home/deploy/.ssh/authorized_keys

# Establecer permisos correctos
sudo chmod 600 /home/deploy/.ssh/authorized_keys
sudo chown -R deploy:deploy /home/deploy/.ssh

# Añadir usuario deploy al grupo docker
sudo usermod -aG docker deploy

# Verificar configuración
echo "=== Verificando configuración ==="
sudo -u deploy ssh-keygen -F localhost >/dev/null 2>&1 && echo "SSH config OK" || echo "SSH config needs check"
sudo -u deploy docker version >/dev/null 2>&1 && echo "Docker access OK" || echo "Docker access needs check"

echo "=== Configuración completada ==="
EOF

chmod +x "$HOME/.ssh/server_setup_commands.sh"

echo -e "\n${GREEN}📄 Script generado: ${NC}$HOME/.ssh/server_setup_commands.sh"
echo -e "${YELLOW}   Copia y ejecuta este script en tu servidor DigitalOcean.${NC}"

echo -e "\n${GREEN}💾 Archivos generados:${NC}"
echo -e "   🔐 Clave privada: $SSH_KEY_PATH"
echo -e "   🔑 Clave pública:  $SSH_KEY_PATH.pub"
echo -e "   📜 Script servidor: $HOME/.ssh/server_setup_commands.sh"

echo -e "\n${BLUE}==============================================================================${NC}"
echo -e "${BLUE}                              PRÓXIMOS PASOS${NC}"
echo -e "${BLUE}==============================================================================${NC}"

echo -e "\n${YELLOW}✅ Checklist de configuración:${NC}"
echo -e "   □ 1. Configurar variables SSH en GitLab CI/CD"
echo -e "   □ 2. Configurar variables adicionales en GitLab CI/CD" 
echo -e "   □ 3. Ejecutar script en servidor DigitalOcean"
echo -e "   □ 4. Probar conexión SSH manual"
echo -e "   □ 5. Ejecutar pipeline CI/CD"

echo -e "\n${YELLOW}🧪 Comandos de prueba:${NC}"
echo -e "   # Probar conexión SSH local:"
if [[ -n "$SERVER_IP" ]]; then
    echo -e "   ${BLUE}ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no deploy@$SERVER_IP 'echo SSH OK'${NC}"
else
    echo -e "   ${BLUE}ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no deploy@TU_SERVIDOR_IP 'echo SSH OK'${NC}"
fi

echo -e "\n   # Probar Docker en servidor:"
if [[ -n "$SERVER_IP" ]]; then
    echo -e "   ${BLUE}ssh -i $SSH_KEY_PATH deploy@$SERVER_IP 'docker version'${NC}"
else
    echo -e "   ${BLUE}ssh -i $SSH_KEY_PATH deploy@TU_SERVIDOR_IP 'docker version'${NC}"
fi

echo -e "\n${GREEN}🎉 ¡Configuración SSH completada exitosamente!${NC}"
echo -e "${YELLOW}📚 Consulta ENVIRONMENT_VARIABLES.md para más detalles.${NC}"

exit 0
