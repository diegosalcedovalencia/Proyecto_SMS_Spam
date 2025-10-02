# ============================================================================
# CI/CD Setup Validator for SMS Spam Detection (Windows PowerShell)
# ============================================================================
# Este script valida que toda la configuración necesaria esté correctamente
# configurada antes de ejecutar el pipeline CI/CD
# ============================================================================

param(
    [string]$ServerIP = "",
    [string]$SSHKeyPath = "",
    [switch]$SkipSSH = $false,
    [switch]$SkipDocker = $false,
    [switch]$Help = $false
)

# Contadores para reporte
$CHECKS_TOTAL = 0
$CHECKS_PASSED = 0
$CHECKS_FAILED = 0
$WARNINGS = 0

function Show-Help {
    Write-Host @"

Uso:
  .\validate-cicd-setup.ps1 [OPCIONES]

Opciones:
  -ServerIP STRING        IP del servidor para validar conexión
  -SSHKeyPath STRING      Ruta a la clave SSH privada
  -SkipSSH               Omitir validaciones SSH
  -SkipDocker            Omitir validaciones Docker
  -Help                  Mostrar esta ayuda

Ejemplo:
  .\validate-cicd-setup.ps1 -ServerIP "192.168.1.100" -SSHKeyPath "C:\Users\user\.ssh\sms_spam_deploy"

"@
}

function Write-Info($message) {
    Write-Host "[INFO] $message" -ForegroundColor Blue
}

function Write-Success($message) {
    Write-Host "[PASS] $message" -ForegroundColor Green
    $script:CHECKS_PASSED++
}

function Write-Error($message) {
    Write-Host "[FAIL] $message" -ForegroundColor Red
    $script:CHECKS_FAILED++
}

function Write-Warning($message) {
    Write-Host "[WARN] $message" -ForegroundColor Yellow
    $script:WARNINGS++
}

function Start-Check {
    $script:CHECKS_TOTAL++
}

if ($Help) {
    Show-Help
    exit 0
}

Write-Host "=============================================================================="  -ForegroundColor Cyan
Write-Host "              CI/CD Setup Validator - SMS Spam Detection"  -ForegroundColor Cyan
Write-Host "=============================================================================="  -ForegroundColor Cyan

Write-Info "Iniciando validación de configuración CI/CD..."
Write-Host ""

# =============================================================================
# 1. VALIDACIONES LOCALES
# =============================================================================

Write-Host "📋 1. VALIDACIONES LOCALES" -ForegroundColor Yellow
Write-Host "══════════════════════════" -ForegroundColor Yellow

# 1.1 Verificar estructura del proyecto
Start-Check
Write-Info "Validando estructura del proyecto..."

$required_files = @(
    ".gitlab-ci.yml",
    "Dockerfile",
    "Dockerfile.dev",
    "requirements.txt",
    "src/app.py",
    "deployment/docker-compose.prod.yml"
)

$missing_files = @()
foreach ($file in $required_files) {
    if (-not (Test-Path $file)) {
        $missing_files += $file
    }
}

if ($missing_files.Count -eq 0) {
    Write-Success "Estructura del proyecto correcta"
} else {
    Write-Error "Archivos faltantes: $($missing_files -join ', ')"
}

# 1.2 Verificar .gitlab-ci.yml
Start-Check
Write-Info "Validando .gitlab-ci.yml..."

if (Test-Path ".gitlab-ci.yml") {
    $gitlab_content = Get-Content ".gitlab-ci.yml" -Raw
    $required_stages = @("test", "build", "deploy")
    $missing_stages = @()
    
    foreach ($stage in $required_stages) {
        if ($gitlab_content -notmatch "stage:\s*$stage") {
            $missing_stages += $stage
        }
    }
    
    if ($missing_stages.Count -eq 0) {
        Write-Success ".gitlab-ci.yml contiene todas las etapas necesarias"
    } else {
        Write-Error ".gitlab-ci.yml falta etapas: $($missing_stages -join ', ')"
    }
} else {
    Write-Error ".gitlab-ci.yml no encontrado"
}

# 1.3 Verificar Dockerfile
Start-Check
Write-Info "Validando Dockerfile..."

if (Test-Path "Dockerfile") {
    $dockerfile_content = Get-Content "Dockerfile" -Raw
    $dockerfile_checks = @(
        "FROM python:",
        "WORKDIR",
        "COPY requirements.txt",
        "RUN pip install",
        "COPY src/",
        "EXPOSE",
        "CMD"
    )
    
    $dockerfile_issues = @()
    foreach ($check in $dockerfile_checks) {
        if ($dockerfile_content -notmatch [regex]::Escape($check)) {
            $dockerfile_issues += $check
        }
    }
    
    if ($dockerfile_issues.Count -eq 0) {
        Write-Success "Dockerfile tiene estructura correcta"
    } else {
        Write-Warning "Dockerfile podría tener problemas: $($dockerfile_issues -join ', ')"
    }
} else {
    Write-Error "Dockerfile no encontrado"
}

# 1.4 Verificar requirements.txt
Start-Check
Write-Info "Validando requirements.txt..."

if (Test-Path "requirements.txt") {
    $requirements_content = Get-Content "requirements.txt" -Raw
    $required_deps = @("streamlit", "pandas", "scikit-learn", "joblib")
    $missing_deps = @()
    
    foreach ($dep in $required_deps) {
        if ($requirements_content -notmatch $dep) {
            $missing_deps += $dep
        }
    }
    
    if ($missing_deps.Count -eq 0) {
        Write-Success "requirements.txt contiene dependencias básicas"
    } else {
        Write-Warning "requirements.txt podrían faltar: $($missing_deps -join ', ')"
    }
} else {
    Write-Error "requirements.txt no encontrado"
}

# =============================================================================
# 2. VALIDACIONES SSH (Si no se omite)
# =============================================================================

if (-not $SkipSSH) {
    Write-Host ""
    Write-Host "🔐 2. VALIDACIONES SSH" -ForegroundColor Yellow
    Write-Host "═════════════════════" -ForegroundColor Yellow

    # 2.1 Verificar clave SSH local
    Start-Check
    Write-Info "Verificando clave SSH local..."

    if ($SSHKeyPath -and (Test-Path $SSHKeyPath)) {
        Write-Success "Clave SSH encontrada: $SSHKeyPath"
    } elseif (Test-Path "$env:USERPROFILE\.ssh\sms_spam_deploy") {
        Write-Success "Clave SSH encontrada: $env:USERPROFILE\.ssh\sms_spam_deploy"
    } else {
        Write-Error "Clave SSH no encontrada. Ejecuta: .\deployment\scripts\generate-ssh-keys.ps1"
    }

    # 2.2 Test de conexión (si se proporciona IP)
    if ($ServerIP) {
        Start-Check
        Write-Info "Test de conexión SSH se omitiría en Windows (requiere configuración adicional)"
        Write-Warning "Verifica conexión SSH manualmente desde terminal con SSH instalado"
    } else {
        Write-Warning "IP del servidor no proporcionada, omitiendo test de conexión SSH"
    }
} else {
    Write-Warning "Validaciones SSH omitidas (--SkipSSH)"
}

# =============================================================================
# 3. VALIDACIONES DOCKER (Si no se omite)
# =============================================================================

if (-not $SkipDocker) {
    Write-Host ""
    Write-Host "🐳 3. VALIDACIONES DOCKER" -ForegroundColor Yellow
    Write-Host "═════════════════════════" -ForegroundColor Yellow

    # 3.1 Verificar Docker instalado
    Start-Check
    Write-Info "Verificando Docker local..."

    try {
        $dockerVersion = docker --version
        Write-Success "Docker instalado: $dockerVersion"
    } catch {
        Write-Error "Docker no está instalado localmente"
        Write-Info "Instala Docker desde: https://docs.docker.com/get-docker/"
    }

    # 3.2 Verificar Docker Compose
    Start-Check
    Write-Info "Verificando Docker Compose..."

    try {
        $composeVersion = docker-compose --version
        Write-Success "Docker Compose instalado: $composeVersion"
    } catch {
        try {
            $composeVersion = docker compose version
            Write-Success "Docker Compose (plugin) instalado: $composeVersion"
        } catch {
            Write-Error "Docker Compose no está disponible"
        }
    }

    # 3.3 Test build local (opcional, puede tardar)
    Start-Check
    Write-Info "Omitiendo test de build Docker (puede tardar mucho)..."
    Write-Warning "Ejecuta manualmente: docker build -t sms-spam-test ."

} else {
    Write-Warning "Validaciones Docker omitidas (--SkipDocker)"
}

# =============================================================================
# 4. VALIDACIONES GITLAB
# =============================================================================

Write-Host ""
Write-Host "🦊 4. VALIDACIONES GITLAB CI/CD" -ForegroundColor Yellow
Write-Host "═══════════════════════════════" -ForegroundColor Yellow

# 4.1 Verificar git remoto GitLab
Start-Check
Write-Info "Verificando repositorio GitLab remoto..."

try {
    $remotes = git remote -v
    if ($remotes -match "gitlab") {
        $gitlab_url = git remote get-url origin
        Write-Success "Repositorio GitLab configurado: $gitlab_url"
    } else {
        Write-Error "No se encontró remoto de GitLab"
        Write-Info "Verifica que el origen esté configurado para GitLab"
    }
} catch {
    Write-Error "Error verificando repositorio git"
}

# 4.2 Verificar variables de entorno (simulado)
Start-Check
Write-Info "Verificando lista de variables de entorno necesarias..."

$required_vars = @(
    "SSH_PRIVATE_KEY (Protected + Masked)",
    "SSH_KNOWN_HOSTS (Protected)",
    "DEPLOY_HOST (Protected)",
    "DEPLOY_USER (Protected)",
    "STAGING_HOST (Protected)",
    "APP_NAME",
    "APP_PORT",
    "CONTAINER_NAME"
)

Write-Success "Variables requeridas identificadas:"
foreach ($var in $required_vars) {
    Write-Host "   • $var" -ForegroundColor Cyan
}

Write-Warning "Verifica manualmente estas variables en GitLab: Settings → CI/CD → Variables"

# =============================================================================
# 5. REPORTE FINAL
# =============================================================================

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "                              REPORTE FINAL" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "📊 RESUMEN DE VALIDACIONES:" -ForegroundColor Blue
Write-Host "   Total checks: $CHECKS_TOTAL" -ForegroundColor Cyan
Write-Host "   Passed: $CHECKS_PASSED" -ForegroundColor Green
Write-Host "   Failed: $CHECKS_FAILED" -ForegroundColor Red
Write-Host "   Warnings: $WARNINGS" -ForegroundColor Yellow

Write-Host ""
if ($CHECKS_FAILED -eq 0) {
    Write-Host "✅ CONFIGURACIÓN LISTA PARA CI/CD" -ForegroundColor Green
    Write-Host "   El proyecto está configurado correctamente para GitLab CI/CD"
    
    Write-Host ""
    Write-Host "📝 PRÓXIMOS PASOS:" -ForegroundColor Yellow
    Write-Host "   1. Configurar variables en GitLab CI/CD"
    Write-Host "   2. Configurar SSH keys en servidor"
    Write-Host "   3. Hacer push/commit para activar pipeline"
    Write-Host "   4. Monitorear ejecución del pipeline"
    
} else {
    Write-Host "❌ CONFIGURACIÓN INCOMPLETA" -ForegroundColor Red
    Write-Host "   Se encontraron $CHECKS_FAILED problemas que deben resolverse"
    
    Write-Host ""
    Write-Host "🛠️ ACCIONES REQUERIDAS:" -ForegroundColor Yellow
    Write-Host "   • Resolver todos los errores [FAIL] mostrados arriba"
    Write-Host "   • Revisar warnings [WARN] y resolver si es necesario"
    Write-Host "   • Ejecutar el script nuevamente para verificar"
}

if ($WARNINGS -gt 0) {
    Write-Host ""
    Write-Host "⚠️ Se encontraron $WARNINGS warnings" -ForegroundColor Yellow
    Write-Host "   Estos no bloquean el CI/CD pero deberían revisarse"
}

Write-Host ""
Write-Host "📚 RECURSOS ADICIONALES:" -ForegroundColor Blue
Write-Host "   • Documentación: deployment\ENVIRONMENT_VARIABLES.md"
Write-Host "   • Generar SSH keys: .\deployment\scripts\generate-ssh-keys.ps1"
Write-Host "   • Setup servidor: .\deployment\scripts\setup-server.sh"

Write-Host ""
Write-Host "🎯 Para más ayuda, consulta la documentación del proyecto" -ForegroundColor Cyan

# Exit code basado en resultados
if ($CHECKS_FAILED -eq 0) {
    exit 0
} else {
    exit 1
}
