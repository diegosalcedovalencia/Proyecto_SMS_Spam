# Manual Completo - GitLab CI/CD para SMS Spam Detection

Esta guía te lleva paso a paso desde cero hasta tener un pipeline CI/CD completamente funcional en GitLab.

## 📚 Índice

1. [Pre-requisitos](#-pre-requisitos)
2. [Configuración Inicial](#-configuración-inicial)
3. [Variables de Entorno](#-variables-de-entorno)
4. [Servidor DigitalOcean](#-servidor-digitalocean)
5. [SSH Keys](#-ssh-keys)
6. [Pipeline CI/CD](#-pipeline-cicd)
7. [Validación y Testing](#-validación-y-testing)
8. [Troubleshooting](#-troubleshooting)
9. [Monitoreo y Mantenimiento](#-monitoreo-y-mantenimiento)

## 🎯 Pre-requisitos

### ✅ Checklist Inicial
- [ ] Cuenta de GitLab con proyecto creado
- [ ] Servidor DigitalOcean (o similar) con Ubuntu 22.04+
- [ ] Git instalado localmente
- [ ] Docker instalado localmente
- [ ] Acceso SSH al servidor

### 🛠️ Herramientas Necesarias
```bash
# Verificar instalaciones locales
git --version
docker --version
ssh -V

# Si falta alguna herramienta, instalarla:
# Git: https://git-scm.com/downloads
# Docker: https://docs.docker.com/get-docker/
```

## 🏗️ Configuración Inicial

### 1. Clonar el Proyecto
```bash
# Clonar desde GitLab
git clone https://gitlab.com/tu_usuario/sms-spam-detection.git
cd sms-spam-detection
```

### 2. Verificar Estructura
```bash
# Verificar que todos los archivos necesarios existan
ls -la .gitlab-ci.yml
ls -la Dockerfile*
ls -la requirements.txt
ls -la src/app.py
ls -la deployment/
```

### 3. Ejecutar Validador de Configuración
```bash
# Hacer ejecutable el script
chmod +x deployment/scripts/validate-cicd-setup.sh

# Ejecutar validación inicial
./deployment/scripts/validate-cicd-setup.sh
```

## 🔐 Variables de Entorno

### 1. Generar SSH Keys Automáticamente
```bash
# Hacer ejecutable el script
chmod +x deployment/scripts/generate-ssh-keys.sh

# Generar keys con IP del servidor
./deployment/scripts/generate-ssh-keys.sh -s TU_SERVIDOR_IP

# O sin IP (configurar SSH_KNOWN_HOSTS manualmente)
./deployment/scripts/generate-ssh-keys.sh
```

### 2. Configurar Variables en GitLab

**Ir a:** `Tu Proyecto → Settings → CI/CD → Variables`

#### Variables SSH (CRÍTICAS)
| Variable | Valor | Protected | Masked | Descripción |
|----------|-------|-----------|--------|-------------|
| `SSH_PRIVATE_KEY` | `[Clave privada completa]` | ✅ | ✅ | Tu clave SSH privada |
| `SSH_KNOWN_HOSTS` | `[Resultado de ssh-keyscan]` | ✅ | ❌ | Fingerprint del servidor |

#### Variables de Servidor
| Variable | Ejemplo | Protected | Masked |
|----------|---------|-----------|--------|
| `DEPLOY_HOST` | `192.168.1.100` | ✅ | ❌ |
| `DEPLOY_USER` | `deploy` | ✅ | ❌ |
| `STAGING_HOST` | `192.168.1.100` | ✅ | ❌ |

#### Variables de Aplicación
| Variable | Valor | Protected | Masked |
|----------|-------|-----------|--------|
| `APP_NAME` | `sms-spam-detector` | ❌ | ❌ |
| `APP_PORT` | `8501` | ❌ | ❌ |
| `CONTAINER_NAME` | `sms-spam-app` | ❌ | ❌ |

### 3. Formato Correcto de SSH_PRIVATE_KEY

**⚠️ IMPORTANTE:** La clave privada debe incluir los headers y el `\n` al final:

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAlwAAAAdzc2gtcn
[... resto de la clave ...]
-----END OPENSSH PRIVATE KEY-----

```

## 🖥️ Servidor DigitalOcean

### 1. Configuración Inicial del Servidor
```bash
# Conectar al servidor como root
ssh root@TU_SERVIDOR_IP

# Ejecutar script de configuración
curl -fsSL https://raw.githubusercontent.com/tu-repo/setup-server.sh | bash

# O copiar y ejecutar el script manualmente
```

### 2. Script Manual de Configuración
```bash
#!/bin/bash
# Ejecutar en el servidor DigitalOcean

# Actualizar sistema
apt update && apt upgrade -y

# Instalar dependencias
apt install -y curl git ufw fail2ban

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Instalar Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Crear usuario deploy
useradd -m -s /bin/bash deploy
usermod -aG sudo,docker deploy

# Configurar firewall
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8501/tcp
ufw --force enable

# Configurar fail2ban
systemctl enable fail2ban
systemctl start fail2ban
```

### 3. Configurar SSH para Usuario Deploy
```bash
# En el servidor, como root:
sudo mkdir -p /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh

# Añadir tu clave pública (copiar desde generate-ssh-keys.sh output)
echo "tu_clave_publica_ssh_aqui" | sudo tee -a /home/deploy/.ssh/authorized_keys

# Establecer permisos correctos
sudo chmod 600 /home/deploy/.ssh/authorized_keys
sudo chown -R deploy:deploy /home/deploy/.ssh

# Probar acceso Docker para usuario deploy
sudo -u deploy docker version
```

## 🔑 SSH Keys

### 1. Test de Conexión SSH
```bash
# Desde tu máquina local
ssh -i ~/.ssh/sms_spam_deploy -o StrictHostKeyChecking=no deploy@TU_SERVIDOR_IP "echo 'SSH OK'"

# Si funciona, verás: SSH OK
# Si falla, revisar configuración
```

### 2. Debug Conexión SSH
```bash
# SSH con debug verbose
ssh -vvv -i ~/.ssh/sms_spam_deploy deploy@TU_SERVIDOR_IP

# Revisar logs en el servidor
sudo tail -f /var/log/auth.log
```

### 3. Problemas Comunes SSH

#### Permission denied (publickey)
```bash
# En el servidor, verificar permisos
ls -la /home/deploy/.ssh/
cat /home/deploy/.ssh/authorized_keys

# Corregir permisos si es necesario
sudo chown -R deploy:deploy /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh
sudo chmod 600 /home/deploy/.ssh/authorized_keys
```

#### Connection refused
```bash
# Verificar que SSH esté corriendo
sudo systemctl status ssh

# Verificar firewall
sudo ufw status
```

## 🚀 Pipeline CI/CD

### 1. Estructura del Pipeline

El pipeline `.gitlab-ci.yml` tiene 4 etapas:

```yaml
stages:
  - test          # Pruebas de código y lint
  - build         # Construcción de imagen Docker
  - deploy-staging # Deploy a staging
  - deploy-production # Deploy a producción
```

### 2. Jobs del Pipeline

#### Test Job
- Ejecuta tests unitarios
- Verifica calidad de código
- Valida requirements.txt

#### Build Job
- Construye imagen Docker
- La publica en GitLab Container Registry
- Solo se ejecuta en branch main/master

#### Deploy Staging
- Despliega a servidor de staging
- Se ejecuta automáticamente en main
- Ambiente para testing

#### Deploy Production
- Despliega a producción
- Requiere aprobación manual
- Solo desde branch main/master

### 3. Activar el Pipeline

```bash
# Hacer commit y push para activar pipeline
git add .
git commit -m "Configurar CI/CD pipeline"
git push origin main

# Monitorear pipeline en GitLab
# Ir a: Tu Proyecto → CI/CD → Pipelines
```

## ✅ Validación y Testing

### 1. Validación Completa
```bash
# Ejecutar validador con servidor
./deployment/scripts/validate-cicd-setup.sh -s TU_SERVIDOR_IP -k ~/.ssh/sms_spam_deploy

# Ejecutar sin validaciones opcionales
./deployment/scripts/validate-cicd-setup.sh --skip-docker --skip-ssh
```

### 2. Test Manual de Deployment
```bash
# Test local del Docker build
docker build -t sms-spam-test .
docker run -p 8501:8501 sms-spam-test

# Acceder a http://localhost:8501 para verificar
```

### 3. Test de Variables GitLab
```bash
# Añadir job temporal a .gitlab-ci.yml para debug
debug-vars:
  stage: test
  script:
    - echo "Registry: $CI_REGISTRY"
    - echo "Deploy Host: $DEPLOY_HOST"
    - echo "Deploy User: $DEPLOY_USER"
    # NO imprimir SSH_PRIVATE_KEY
```

## 🔧 Troubleshooting

### Problemas Comunes y Soluciones

#### 1. Pipeline Fails en SSH Connection
```bash
# Error: Permission denied (publickey)
# Solución:
1. Verificar SSH_PRIVATE_KEY en GitLab variables
2. Verificar formato correcto con \n al final
3. Verificar clave pública en servidor
4. Verificar SSH_KNOWN_HOSTS
```

#### 2. Docker Build Fails
```bash
# Error: requirements.txt not found
# Solución:
1. Verificar estructura de carpetas
2. Asegurar que requirements.txt esté en root
3. Revisar Dockerfile COPY paths
```

#### 3. Deploy Fails - Container Not Starting
```bash
# Error: Container exits immediately
# Solución:
1. Revisar logs: docker logs sms-spam-app
2. Verificar EXPOSE port en Dockerfile
3. Verificar CMD en Dockerfile
4. Test local: docker run -p 8501:8501 imagen
```

#### 4. Variables Not Found
```bash
# Error: $DEPLOY_HOST: unbound variable
# Solución:
1. Verificar variables configuradas en GitLab
2. Verificar spelling exacto de variables
3. Verificar que variables están en scope correcto
```

### Debug Step-by-Step

#### 1. Verificar Configuración Local
```bash
./deployment/scripts/validate-cicd-setup.sh -s TU_SERVIDOR_IP
```

#### 2. Test SSH Manual
```bash
ssh -i ~/.ssh/sms_spam_deploy deploy@TU_SERVIDOR_IP
```

#### 3. Test Docker Local
```bash
docker build -t sms-test .
docker run --rm -p 8501:8501 sms-test
```

#### 4. Revisar Logs Pipeline
```bash
# En GitLab:
# Tu Proyecto → CI/CD → Pipelines → [Click en pipeline] → [Click en job]
```

#### 5. Debug en Servidor
```bash
# Conectar al servidor
ssh -i ~/.ssh/sms_spam_deploy deploy@TU_SERVIDOR_IP

# Verificar Docker
docker ps -a
docker logs sms-spam-app

# Verificar archivos
ls -la /home/deploy/sms-spam-detection/
```

## 📊 Monitoreo y Mantenimiento

### 1. Monitoreo del Pipeline
```bash
# GitLab Pipeline Status Badge
# Añadir a README.md:
[![pipeline status](https://gitlab.com/tu_usuario/sms-spam-detection/badges/main/pipeline.svg)](https://gitlab.com/tu_usuario/sms-spam-detection/-/commits/main)
```

### 2. Logs de Aplicación
```bash
# Ver logs en tiempo real
ssh deploy@TU_SERVIDOR_IP
docker logs -f sms-spam-app

# Ver logs de deployment
journalctl -u docker -f
```

### 3. Backup y Restauración
```bash
# Backup de configuración
scp deploy@TU_SERVIDOR_IP:/home/deploy/sms-spam-detection/deployment/docker-compose.prod.yml ./backup/

# Backup de imágenes Docker
ssh deploy@TU_SERVIDOR_IP "docker save sms-spam-detector > /tmp/sms-spam-backup.tar"
scp deploy@TU_SERVIDOR_IP:/tmp/sms-spam-backup.tar ./backup/
```

### 4. Actualizaciones y Rollbacks
```bash
# Deploy manual (en caso de emergencia)
ssh deploy@TU_SERVIDOR_IP
cd /home/deploy/sms-spam-detection
git pull
docker-compose -f deployment/docker-compose.prod.yml up -d --build

# Rollback rápido
docker-compose -f deployment/docker-compose.prod.yml down
docker run -d --name sms-spam-app -p 8501:8501 registry.gitlab.com/tu_usuario/sms-spam-detection:previous-tag
```

## 🎉 Checklist Final

### Pre-deployment
- [ ] Variables SSH configuradas en GitLab
- [ ] Variables de aplicación configuradas
- [ ] SSH keys funcionando
- [ ] Servidor configurado correctamente
- [ ] Docker funcionando en servidor
- [ ] Usuario deploy con permisos correctos

### Post-deployment
- [ ] Pipeline ejecutándose sin errores
- [ ] Aplicación accesible en http://TU_SERVIDOR_IP:8501
- [ ] Logs sin errores críticos
- [ ] SSL/TLS configurado (opcional)
- [ ] Monitoreo configurado
- [ ] Backup automatizado

### Testing
- [ ] Test manual de SMS classification
- [ ] Test de actualizaciones automáticas
- [ ] Test de rollback
- [ ] Test de recuperación tras fallas

## 📞 Soporte y Recursos

### Documentación Adicional
- [Variables de Entorno Detalladas](./ENVIRONMENT_VARIABLES.md)
- [Scripts de Configuración](./scripts/)
- [Docker Compose Files](./docker-compose.*.yml)

### Comandos de Emergencia
```bash
# Parar todo
ssh deploy@TU_SERVIDOR_IP "docker-compose -f /home/deploy/sms-spam-detection/deployment/docker-compose.prod.yml down"

# Restart completo
ssh deploy@TU_SERVIDOR_IP "cd /home/deploy/sms-spam-detection && docker-compose -f deployment/docker-compose.prod.yml up -d --force-recreate"

# Ver estado
ssh deploy@TU_SERVIDOR_IP "docker ps && docker images"
```

---

## 🚀 ¡Listo para Producción!

Una vez completados todos los pasos, tendrás:

✅ **Pipeline CI/CD completamente automatizado**  
✅ **Deployment automático a staging y producción**  
✅ **Configuración segura con SSH keys**  
✅ **Monitoreo y logging configurado**  
✅ **Proceso de rollback definido**  
✅ **Documentación completa**

**¡Tu aplicación SMS Spam Detection está lista para el mundo!** 🎯
