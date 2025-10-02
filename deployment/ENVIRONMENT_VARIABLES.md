# Variables de Entorno para CI/CD Pipeline

Esta guía describe todas las variables de entorno necesarias para configurar el pipeline CI/CD en GitLab.

## 📋 Variables Requeridas

### 🔐 Variables de Seguridad (Protected & Masked)

#### SSH & Deployment
```bash
# Clave privada SSH para conectar al servidor (Protected + Masked)
SSH_PRIVATE_KEY
# Contenido: -----BEGIN OPENSSH PRIVATE KEY-----\n<key_content>\n-----END OPENSSH PRIVATE KEY-----

# Known hosts del servidor para SSH (Protected)
SSH_KNOWN_HOSTS
# Contenido: servidor_ip ssh-rsa AAAAB3NzaC1yc2EAAAA...

# Usuario para deployment en el servidor (Protected)
DEPLOY_USER
# Valor: deploy

# IP o dominio del servidor de producción (Protected)
DEPLOY_HOST
# Valor: tu_servidor.digitalocean.com (o IP)

# IP o dominio del servidor de staging (Protected)
STAGING_HOST
# Valor: tu_staging_servidor.digitalocean.com (o IP)
```

#### Docker Registry
```bash
# Usuario del registry de GitLab (automático)
CI_REGISTRY_USER
# Valor: gitlab-ci-token (automático en GitLab)

# Password del registry de GitLab (automático)
CI_REGISTRY_PASSWORD
# Valor: $CI_JOB_TOKEN (automático en GitLab)

# URL del registry (automático)
CI_REGISTRY
# Valor: registry.gitlab.com/tu_usuario/tu_proyecto (automático)
```

### ⚙️ Variables de Configuración (No Protected)

#### Aplicación
```bash
# Nombre de la aplicación
APP_NAME
# Valor: sms-spam-detector

# Puerto de la aplicación
APP_PORT
# Valor: 8501

# Nombre del contenedor
CONTAINER_NAME
# Valor: sms-spam-app

# Ambiente de deployment
ENVIRONMENT
# Valor: production | staging
```

## 🛠️ Cómo Configurar las Variables en GitLab

### 1. Acceder a la configuración del proyecto
```
Tu Proyecto → Settings → CI/CD → Variables
```

### 2. Añadir cada variable con la configuración correcta

#### Variables SSH (CRÍTICO - Deben ser Protected + Masked)
1. **SSH_PRIVATE_KEY**
   - ✅ Protected: Sí
   - ✅ Masked: Sí
   - Valor: Tu clave privada SSH completa

2. **SSH_KNOWN_HOSTS**
   - ✅ Protected: Sí
   - ❌ Masked: No
   - Valor: Resultado de `ssh-keyscan tu_servidor`

#### Variables de Host (Protected)
3. **DEPLOY_HOST**
   - ✅ Protected: Sí
   - ❌ Masked: No
   - Valor: IP o dominio de tu servidor

4. **DEPLOY_USER**
   - ✅ Protected: Sí
   - ❌ Masked: No
   - Valor: deploy

5. **STAGING_HOST**
   - ✅ Protected: Sí
   - ❌ Masked: No
   - Valor: IP o dominio de staging (puede ser el mismo servidor)

#### Variables de Aplicación (No Protected)
6. **APP_NAME**
   - ❌ Protected: No
   - ❌ Masked: No
   - Valor: sms-spam-detector

7. **APP_PORT**
   - ❌ Protected: No
   - ❌ Masked: No
   - Valor: 8501

8. **CONTAINER_NAME**
   - ❌ Protected: No
   - ❌ Masked: No
   - Valor: sms-spam-app

## 🔧 Scripts de Configuración Automática

### Generar SSH Keys para Deployment
```bash
#!/bin/bash
# Ejecutar en tu máquina local

# 1. Generar par de claves SSH
ssh-keygen -t rsa -b 4096 -f ~/.ssh/sms_spam_deploy -C "sms-spam-deploy"

# 2. Mostrar clave privada (para SSH_PRIVATE_KEY)
echo "=== CLAVE PRIVADA (SSH_PRIVATE_KEY) ==="
cat ~/.ssh/sms_spam_deploy

# 3. Mostrar clave pública (para copiar al servidor)
echo "=== CLAVE PÚBLICA (copiar al servidor) ==="
cat ~/.ssh/sms_spam_deploy.pub

# 4. Generar SSH_KNOWN_HOSTS
echo "=== SSH_KNOWN_HOSTS ==="
ssh-keyscan TU_SERVIDOR_IP
```

### Configurar Clave Pública en el Servidor
```bash
#!/bin/bash
# Ejecutar en el servidor DigitalOcean

# Crear directorio SSH para usuario deploy
sudo mkdir -p /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh

# Añadir clave pública
echo "tu_clave_publica_ssh_aqui" | sudo tee -a /home/deploy/.ssh/authorized_keys

# Establecer permisos correctos
sudo chmod 600 /home/deploy/.ssh/authorized_keys
sudo chown -R deploy:deploy /home/deploy/.ssh

# Verificar configuración
sudo -u deploy ssh -T localhost
```

## ✅ Verificación de Configuración

### Checklist de Variables
- [ ] SSH_PRIVATE_KEY configurada (Protected + Masked)
- [ ] SSH_KNOWN_HOSTS configurada (Protected)
- [ ] DEPLOY_HOST configurada (Protected)
- [ ] DEPLOY_USER configurada (Protected)
- [ ] STAGING_HOST configurada (Protected)
- [ ] APP_NAME configurada
- [ ] APP_PORT configurada
- [ ] CONTAINER_NAME configurada

### Test de Conexión SSH
```bash
# Probar conexión SSH desde GitLab Runner
ssh -o StrictHostKeyChecking=no $DEPLOY_USER@$DEPLOY_HOST "echo 'SSH OK'"
```

### Test de Docker Registry
```bash
# Probar login al registry
echo $CI_REGISTRY_PASSWORD | docker login -u $CI_REGISTRY_USER --password-stdin $CI_REGISTRY
```

## 🚨 Seguridad - Mejores Prácticas

### ✅ DO
- Usar variables Protected para información sensible
- Usar variables Masked para secrets
- Rotar claves SSH regularmente
- Limitar acceso de variables a branches específicas
- Usar principio de menor privilegio

### ❌ DON'T
- Nunca poner secrets en el código fuente
- No usar variables no protegidas para información sensible
- No reutilizar la misma SSH key para múltiples proyectos
- No loggear el contenido de variables sensibles

## 🔍 Debugging

### Variables no definidas
```yaml
# Añadir al .gitlab-ci.yml para debug
debug-vars:
  stage: test
  script:
    - echo "Registry: $CI_REGISTRY"
    - echo "User: $CI_REGISTRY_USER"
    - echo "Deploy Host: $DEPLOY_HOST"
    - echo "Deploy User: $DEPLOY_USER"
    # NO imprimir SSH_PRIVATE_KEY o passwords
```

### Problemas comunes
1. **SSH connection refused**
   - Verificar firewall (puerto 22 abierto)
   - Verificar SSH_KNOWN_HOSTS
   - Verificar formato de SSH_PRIVATE_KEY

2. **Docker login failed**
   - Verificar CI_REGISTRY_PASSWORD
   - Verificar acceso al Container Registry

3. **Permission denied**
   - Verificar que usuario 'deploy' esté en grupo docker
   - Verificar permisos de ~/.ssh/authorized_keys

## 📞 Soporte

Si encuentras problemas:
1. Verificar logs del pipeline en GitLab CI/CD
2. Comprobar variables en Settings → CI/CD → Variables
3. Verificar conexión SSH manual al servidor
4. Revisar configuración del servidor con setup-server.sh
