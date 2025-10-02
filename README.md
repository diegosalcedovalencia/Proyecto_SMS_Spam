# SMS Spam Detection - Proyecto Completo con CI/CD

[![Pipeline Status](https://img.shields.io/badge/pipeline-passing-brightgreen)](https://gitlab.com/tu_usuario/sms-spam-detection/-/pipelines)
[![Docker](https://img.shields.io/badge/docker-enabled-blue)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/python-3.9+-green)](https://www.python.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Sistema de detección de SMS spam con modelo de machine learning, aplicación web interactiva y pipeline CI/CD completamente automatizado para deployment en DigitalOcean.

## 🚀 Características Principales

- **🤖 Detección de Spam Avanzada**: Modelos de Machine Learning entrenados para clasificar SMS
- **💻 Interfaz Web Interactiva**: Aplicación Streamlit fácil de usar
- **🐳 Containerización Completa**: Docker para todos los ambientes
- **🔄 CI/CD Automatizado**: Pipeline GitLab para staging y producción
- **📊 Monitoreo Integrado**: Logs y métricas de aplicación
- **🔒 Configuración Segura**: SSH keys y variables protegidas

## 📋 Tabla de Contenidos

- [Instalación Rápida](#-instalación-rápida)
- [Desarrollo Local](#-desarrollo-local)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Deployment en Producción](#-deployment-en-producción)
- [Uso de la Aplicación](#-uso-de-la-aplicación)
- [Arquitectura](#-arquitectura)
- [Contribuir](#-contribuir)

## ⚡ Instalación Rápida

### Opción 1: Demo Interactiva (RECOMENDADO) 🚀
```bash
# Clonar el repositorio
git clone https://github.com/nicolnsrubio-hash/sms-spam-detection.git
cd sms-spam-detection

# Instalar dependencias básicas
pip install streamlit pandas numpy

# Ejecutar aplicación de demostración
python -m streamlit run demo_app.py

# Acceder a http://localhost:8501
```

### Opción 2: Instalación Completa
```bash
# Instalar todas las dependencias
pip install -r requirements.txt

# Ejecutar aplicación completa (requiere modelos entrenados)
streamlit run src/app.py
```

### Opción 3: Docker (Producción)
```bash
# Ejecutar con Docker
docker-compose up -d

# Acceder a http://localhost:8501
```

## 💻 Desarrollo Local

### Estructura del Proyecto
```
sms-spam-detection/
├── demo_app.py                   # 🚀 APLICACIÓN DEMO (Ejecutar primero!)
├── sms_spam_detector/            # 📦 Paquete principal modular
│   ├── api/                      # APIs REST y gRPC
│   │   ├── app.py                # Aplicación Streamlit completa
│   │   ├── app_baseline_only.py  # Solo modelo baseline
│   │   ├── app_simple.py         # Versión simplificada
│   │   └── grpc_server.py        # Servidor gRPC
│   ├── models/                   # Modelos de Machine Learning
│   │   ├── baseline_model.py     # TF-IDF + Regresión Logística
│   │   ├── distilbert_model.py   # Modelo DistilBERT avanzado
│   │   └── trained/              # Modelos preentrenados
│   ├── utils/                    # Utilidades y preprocesamiento
│   │   ├── data_preprocessing.py # Limpieza y preparación de datos
│   │   └── mlflow_integration.py # Integración con MLFlow
│   ├── evaluation/               # Evaluación de modelos
│   │   └── model_evaluation.py   # Métricas y análisis
│   └── data/                     # Datasets organizados
│       ├── raw/                  # Datos originales
│       └── processed/            # Datos procesados
├── scripts/                      # Scripts de entrenamiento y evaluación
│   ├── train_models.py           # Entrenar todos los modelos
│   ├── train_distilbert.py       # Entrenar solo DistilBERT
│   └── evaluate_baseline_only.py # Evaluar modelo baseline
├── configs/                      # Configuraciones centralizadas
│   ├── config.yaml               # Configuración principal
│   ├── requirements.txt          # Dependencias específicas
│   └── setup.py                  # Setup del paquete
├── docs/                         # Documentación completa
│   ├── README.md                 # Documentación principal
│   ├── INSTALL.md                # Instrucciones de instalación
│   └── LICENSE                   # Licencia del proyecto
├── deployment/                   # Deployment y CI/CD
│   ├── docker-compose.yml        # Compose para desarrollo
│   ├── docker-compose.prod.yml   # Compose para producción
│   ├── Dockerfile.prod           # Imagen Docker optimizada
│   ├── scripts/                  # Scripts de automatización
│   │   ├── generate-ssh-keys.sh  # Generador de claves SSH
│   │   ├── validate-cicd-setup.sh # Validador de configuración
│   │   └── setup-server.sh       # Configuración de servidor
│   ├── ENVIRONMENT_VARIABLES.md  # Variables de entorno
│   └── GITLAB_CICD_MANUAL.md     # Manual completo CI/CD
├── src/                          # Aplicaciones adicionales
│   ├── app.py                    # App principal alternativa
│   └── app_fixed.py              # Versión corregida
├── .gitlab-ci.yml                # Pipeline CI/CD automatizado
├── Dockerfile                    # Imagen Docker principal
├── Dockerfile.dev                # Imagen para desarrollo
├── requirements.txt              # Dependencias Python principales
├── test_complete_project.py      # Tests completos del proyecto
└── test_project.py               # Tests básicos
```

### Desarrollo con Docker
```bash
# Desarrollo con hot-reload
docker-compose -f deployment/docker-compose.dev.yml up

# Ver logs
docker-compose -f deployment/docker-compose.dev.yml logs -f

# Ejecutar tests
docker-compose -f deployment/docker-compose.dev.yml exec app pytest tests/

# Acceder al contenedor
docker-compose -f deployment/docker-compose.dev.yml exec app bash
```

### Entrenar Modelos
```bash
# Entrenar modelo baseline
python -m src.models.baseline_model

# Entrenar modelo DistilBERT (requiere más recursos)
python -m src.models.distilbert_model

# Evaluar modelos
python -m src.utils.model_utils --evaluate
```

## 🔄 CI/CD Pipeline

### Pipeline GitLab Automático

El proyecto incluye un pipeline CI/CD completamente configurado con 4 etapas:

```yaml
stages:
  - test              # Tests unitarios y linting
  - build             # Build de imagen Docker
  - deploy-staging    # Deploy automático a staging
  - deploy-production # Deploy manual a producción
```

### 📋 Setup Rápido CI/CD

#### 1. Generar SSH Keys
```bash
# Ejecutar script automático
./deployment/scripts/generate-ssh-keys.sh -s TU_SERVIDOR_IP
```

#### 2. Configurar Variables en GitLab
Ir a: `Tu Proyecto → Settings → CI/CD → Variables`

**Variables SSH (CRÍTICAS):**
- `SSH_PRIVATE_KEY` (Protected ✅ | Masked ✅)
- `SSH_KNOWN_HOSTS` (Protected ✅ | Masked ❌)

**Variables de Servidor:**
- `DEPLOY_HOST` = IP de tu servidor
- `DEPLOY_USER` = `deploy`
- `STAGING_HOST` = IP de staging

**Variables de Aplicación:**
- `APP_NAME` = `sms-spam-detector`
- `APP_PORT` = `8501`
- `CONTAINER_NAME` = `sms-spam-app`

#### 3. Configurar Servidor
```bash
# Ejecutar en tu servidor DigitalOcean
./deployment/scripts/setup-server.sh
```

#### 4. Validar Configuración
```bash
# Validar que todo esté configurado correctamente
./deployment/scripts/validate-cicd-setup.sh -s TU_SERVIDOR_IP
```

#### 5. Activar Pipeline
```bash
git add .
git commit -m "Configure CI/CD pipeline"
git push origin main
```

🎉 **¡Pipeline automático activado!** Monitorea en GitLab: `Tu Proyecto → CI/CD → Pipelines`

### 📚 Documentación Detallada

Para setup avanzado y troubleshooting consulta:
- **[Manual Completo CI/CD](deployment/GITLAB_CICD_MANUAL.md)** - Guía paso a paso
- **[Variables de Entorno](deployment/ENVIRONMENT_VARIABLES.md)** - Configuración detallada
- **[Scripts de Automatización](deployment/scripts/)** - Herramientas de configuración

## 🌐 Deployment en Producción

### Ambientes Disponibles

1. **Development**: `docker-compose -f deployment/docker-compose.dev.yml up`
2. **Staging**: Deploy automático via pipeline
3. **Production**: Deploy manual via pipeline con aprobación

### Acceso a la Aplicación

Una vez desplegado, la aplicación estará disponible en:
- **Local**: http://localhost:8501
- **Staging**: http://tu-servidor-ip:8501
- **Production**: http://tu-dominio.com

### Monitoreo

```bash
# Ver logs de aplicación
ssh deploy@tu-servidor "docker logs -f sms-spam-app"

# Monitorear recursos
ssh deploy@tu-servidor "docker stats sms-spam-app"

# Backup automático
ssh deploy@tu-servidor "docker save sms-spam-detector > /tmp/backup.tar"
```

## 🎯 Uso de la Aplicación

### 📱 Aplicación de Demostración

La aplicación `demo_app.py` es perfecta para probar el sistema sin configuraciones complejas:

**🌟 Características:**
- ✅ **Sin dependencias pesadas**: Solo requiere Streamlit, Pandas, Numpy
- ✅ **Funciona inmediatamente**: No necesita modelos preentrenados
- ✅ **Detección inteligente**: Reglas heurísticas + palabras clave (ES/EN)
- ✅ **Interfaz completa**: Visualizaciones, métricas, ejemplos
- ✅ **Información del proyecto**: Arquitectura, CI/CD, tecnologías

**🚀 Ejecución rápida:**
```bash
pip install streamlit pandas numpy
python -m streamlit run demo_app.py
```

**📊 Funcionalidades incluidas:**
- Análisis en tiempo real de mensajes SMS
- 8 ejemplos predefinidos (HAM y SPAM)
- Detección por palabras clave en español e inglés
- Scoring inteligente con caracteres especiales
- Gráficos de probabilidades interactivos
- Información detallada del análisis

### 🏭 Interfaz Web Completa

1. **Clasificación Individual**: Introduce un SMS para clasificar
2. **Clasificación Masiva**: Carga archivo CSV con múltiples SMS
3. **Estadísticas**: Ver métricas de performance del modelo
4. **Configuración**: Seleccionar modelo y ajustar parámetros

### API Endpoints (Próximamente)

```bash
# Clasificar SMS individual
curl -X POST "http://tu-servidor:8501/api/classify" \
     -H "Content-Type: application/json" \
     -d '{"text": "Congratulations! You have won $1000!"}'

# Clasificación masiva
curl -X POST "http://tu-servidor:8501/api/classify-batch" \
     -F "file=@sms_data.csv"
```

## 🏗️ Arquitectura

### Arquitectura del Sistema
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Input    │───▶│   Streamlit App  │───▶│   ML Models     │
│                 │    │                  │    │                 │
│ - Single SMS    │    │ - Text Processing│    │ - Baseline      │
│ - CSV Upload    │    │ - Model Loading  │    │ - DistilBERT    │
│ - Config        │    │ - Result Display │    │ - Future Models │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### CI/CD Architecture
```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
│ Git Push    │───▶│ GitLab CI/CD │───▶│ Docker Build│───▶│ Deploy       │
│             │    │              │    │             │    │              │
│ - Code      │    │ - Test       │    │ - Image     │    │ - Staging    │
│ - Config    │    │ - Build      │    │ - Registry  │    │ - Production │
│ - Pipeline  │    │ - Deploy     │    │ - Security  │    │ - Monitoring │
└─────────────┘    └──────────────┘    └─────────────┘    └──────────────┘
```

### Modelos de ML

#### 1. Modelo Baseline (TF-IDF + Naive Bayes)
- **Rápido y eficiente**
- **Menor uso de memoria**
- **Buena precisión para casos básicos**

#### 2. Modelo DistilBERT (Transformer)
- **Mayor precisión**
- **Comprensión contextual**
- **Requiere más recursos**

## 🧪 Testing

### Ejecutar Tests
```bash
# Tests unitarios
pytest tests/ -v

# Tests con coverage
pytest tests/ --cov=src --cov-report=html

# Tests específicos
pytest tests/test_models.py -v

# Tests en Docker
docker-compose -f deployment/docker-compose.dev.yml exec app pytest tests/
```

### Tests Incluidos
- ✅ Tests de modelos ML
- ✅ Tests de procesamiento de datos
- ✅ Tests de API endpoints
- ✅ Tests de interfaz Streamlit
- ✅ Tests de integración CI/CD

## 🚨 Troubleshooting

### Problemas Comunes

#### Pipeline Falla en SSH
```bash
# Verificar variables SSH en GitLab
# Regenerar SSH keys si es necesario
./deployment/scripts/generate-ssh-keys.sh -s TU_SERVIDOR_IP
```

#### Docker Build Falla
```bash
# Verificar Dockerfile y dependencies
docker build -t test-build . --no-cache
docker run --rm test-build
```

#### Aplicación No Inicia
```bash
# Ver logs detallados
docker logs sms-spam-app
ssh deploy@servidor "docker logs -f sms-spam-app"
```

### Comandos de Emergencia
```bash
# Restart completo
ssh deploy@servidor "cd sms-spam-detection && docker-compose -f deployment/docker-compose.prod.yml restart"

# Rollback rápido
ssh deploy@servidor "docker run -d --name sms-spam-app-rollback -p 8501:8501 registry.gitlab.com/tu_usuario/sms-spam-detection:previous-tag"

# Verificar estado
ssh deploy@servidor "docker ps && docker images"
```

## 🤝 Contribuir

### Flujo de Desarrollo
1. Fork del repositorio
2. Crear branch feature: `git checkout -b feature/nueva-funcionalidad`
3. Commit cambios: `git commit -m 'Añadir nueva funcionalidad'`
4. Push a branch: `git push origin feature/nueva-funcionalidad`
5. Crear Pull Request

### Guidelines
- Seguir PEP 8 para código Python
- Añadir tests para nuevas funcionalidades
- Actualizar documentación
- Pipeline CI/CD debe pasar

### Desarrollo Local
```bash
# Setup desarrollo
git clone tu-fork
cd sms-spam-detection
python -m venv venv
source venv/bin/activate  # Linux/Mac
# o
venv\Scripts\activate     # Windows
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Pre-commit hooks
pre-commit install
```

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver [LICENSE](LICENSE) para más detalles.

## 📞 Soporte

### Documentación
- 📖 [Manual CI/CD Completo](deployment/GITLAB_CICD_MANUAL.md)
- 🔧 [Configuración de Variables](deployment/ENVIRONMENT_VARIABLES.md)
- 🚀 [Scripts de Automatización](deployment/scripts/)

### Contacto
- **Issues**: [GitLab Issues](https://gitlab.com/tu_usuario/sms-spam-detection/-/issues)
- **Email**: tu-email@domain.com
- **LinkedIn**: [Tu Perfil](https://linkedin.com/in/tu-perfil)

---

## 🎯 Roadmap

### Próximas Funcionalidades
- [ ] API REST completa
- [ ] Autenticación de usuarios
- [ ] Dashboard de administración
- [ ] Modelo ensemble
- [ ] Detección de spam multiidioma
- [ ] Integración con APIs de SMS

### Mejoras de Infrastructure
- [ ] Kubernetes deployment
- [ ] Monitoreo con Prometheus + Grafana
- [ ] SSL/TLS automático
- [ ] CDN para assets estáticos
- [ ] Base de datos para histórico

---

**🚀 ¡Gracias por usar SMS Spam Detection!**

*Sistema de detección de spam con CI/CD completamente automatizado - Desde desarrollo hasta producción en minutos* ⚡
