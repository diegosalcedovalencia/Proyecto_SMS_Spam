#!/usr/bin/env python3
"""
Complete Project Test Suite
============================
Script para verificar todas las funcionalidades del proyecto
SMS Spam Detection incluyendo CI/CD, aplicación y modelos.
"""

import os
import sys
import json
import subprocess
from pathlib import Path
from datetime import datetime
import requests
import time

# Colores para output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_header(title):
    """Imprimir header colorido"""
    print(f"\n{Colors.CYAN}{Colors.BOLD}{'='*60}{Colors.END}")
    print(f"{Colors.CYAN}{Colors.BOLD}{title:^60}{Colors.END}")
    print(f"{Colors.CYAN}{Colors.BOLD}{'='*60}{Colors.END}\n")

def print_success(message):
    """Imprimir mensaje de éxito"""
    print(f"{Colors.GREEN}✅ {message}{Colors.END}")

def print_error(message):
    """Imprimir mensaje de error"""
    print(f"{Colors.RED}❌ {message}{Colors.END}")

def print_warning(message):
    """Imprimir mensaje de advertencia"""
    print(f"{Colors.YELLOW}⚠️  {message}{Colors.END}")

def print_info(message):
    """Imprimir mensaje informativo"""
    print(f"{Colors.BLUE}ℹ️  {message}{Colors.END}")

class ProjectTester:
    def __init__(self):
        self.project_root = Path.cwd()
        self.test_results = {
            'pipeline_cicd': {'passed': 0, 'failed': 0, 'warnings': 0},
            'cloud_deployment': {'passed': 0, 'failed': 0, 'warnings': 0},
            'infrastructure_security': {'passed': 0, 'failed': 0, 'warnings': 0},
            'documentation': {'passed': 0, 'failed': 0, 'warnings': 0}
        }
        self.start_time = datetime.now()

    def run_all_tests(self):
        """Ejecutar todos los tests"""
        print_header("🚀 COMPLETE PROJECT TESTING SUITE")
        print_info(f"Iniciando tests en: {self.project_root}")
        print_info(f"Fecha/Hora: {self.start_time.strftime('%Y-%m-%d %H:%M:%S')}")
        
        # 1. Funcionalidad del Pipeline CI/CD
        self.test_pipeline_cicd()
        
        # 2. Correcto Despliegue en la Nube
        self.test_cloud_deployment()
        
        # 3. Configuración de Infraestructura y Seguridad
        self.test_infrastructure_security()
        
        # 4. Documentación y Presentación
        self.test_documentation()
        
        # Reporte final
        self.generate_final_report()

    def test_pipeline_cicd(self):
        """Test 1: Funcionalidad del Pipeline CI/CD"""
        print_header("🔄 1. FUNCIONALIDAD DEL PIPELINE CI/CD")
        
        # 1.1 Verificar archivo .gitlab-ci.yml
        print_info("1.1 Verificando archivo .gitlab-ci.yml...")
        if self.check_file_exists('.gitlab-ci.yml'):
            content = self.read_file('.gitlab-ci.yml')
            if self.validate_gitlab_ci_content(content):
                print_success("Pipeline CI/CD configurado correctamente")
                self.test_results['pipeline_cicd']['passed'] += 1
            else:
                print_error("Pipeline CI/CD tiene configuración incompleta")
                self.test_results['pipeline_cicd']['failed'] += 1
        else:
            print_error("Archivo .gitlab-ci.yml no encontrado")
            self.test_results['pipeline_cicd']['failed'] += 1

        # 1.2 Verificar stages del pipeline
        print_info("1.2 Verificando stages del pipeline...")
        required_stages = ['test', 'build', 'deploy']
        content = self.read_file('.gitlab-ci.yml') or ""
        
        missing_stages = []
        for stage in required_stages:
            if f"stage: {stage}" not in content and f"stage:{stage}" not in content:
                missing_stages.append(stage)
        
        if not missing_stages:
            print_success("Todos los stages requeridos están presentes")
            self.test_results['pipeline_cicd']['passed'] += 1
        else:
            print_error(f"Stages faltantes: {', '.join(missing_stages)}")
            self.test_results['pipeline_cicd']['failed'] += 1

        # 1.3 Verificar jobs críticos
        print_info("1.3 Verificando jobs críticos del pipeline...")
        required_jobs = ['test-unit', 'build-docker', 'deploy-production']
        
        missing_jobs = []
        for job in required_jobs:
            if job not in content:
                missing_jobs.append(job)
        
        if not missing_jobs:
            print_success("Todos los jobs críticos están configurados")
            self.test_results['pipeline_cicd']['passed'] += 1
        else:
            print_warning(f"Jobs que podrían faltar: {', '.join(missing_jobs)}")
            self.test_results['pipeline_cicd']['warnings'] += 1

        # 1.4 Verificar configuración de Docker
        print_info("1.4 Verificando configuración de Docker...")
        docker_files = ['Dockerfile', 'Dockerfile.dev', 'deployment/docker-compose.prod.yml']
        
        docker_ok = True
        for docker_file in docker_files:
            if not self.check_file_exists(docker_file):
                print_error(f"Archivo Docker faltante: {docker_file}")
                docker_ok = False
        
        if docker_ok:
            print_success("Configuración de Docker completa")
            self.test_results['pipeline_cicd']['passed'] += 1
        else:
            self.test_results['pipeline_cicd']['failed'] += 1

        # 1.5 Test de sintaxis de Dockerfile
        print_info("1.5 Verificando sintaxis de Dockerfiles...")
        try:
            # Verificar que los Dockerfiles tienen estructura básica
            dockerfile_content = self.read_file('Dockerfile')
            if dockerfile_content and 'FROM' in dockerfile_content and 'CMD' in dockerfile_content:
                print_success("Dockerfile principal tiene sintaxis válida")
                self.test_results['pipeline_cicd']['passed'] += 1
            else:
                print_error("Dockerfile principal tiene problemas de sintaxis")
                self.test_results['pipeline_cicd']['failed'] += 1
        except Exception as e:
            print_error(f"Error verificando Dockerfile: {e}")
            self.test_results['pipeline_cicd']['failed'] += 1

    def test_cloud_deployment(self):
        """Test 2: Correcto Despliegue en la Nube"""
        print_header("☁️ 2. CORRECTO DESPLIEGUE EN LA NUBE")
        
        # 2.1 Verificar configuración de deployment
        print_info("2.1 Verificando archivos de deployment...")
        deployment_files = [
            'deployment/docker-compose.prod.yml',
            'deployment/scripts/setup-server.sh',
            'deployment/ENVIRONMENT_VARIABLES.md'
        ]
        
        deployment_ok = True
        for file in deployment_files:
            if self.check_file_exists(file):
                print_success(f"Archivo de deployment encontrado: {file}")
                self.test_results['cloud_deployment']['passed'] += 1
            else:
                print_error(f"Archivo de deployment faltante: {file}")
                self.test_results['cloud_deployment']['failed'] += 1
                deployment_ok = False

        # 2.2 Verificar scripts de automatización
        print_info("2.2 Verificando scripts de automatización...")
        scripts = [
            'deployment/scripts/generate-ssh-keys.sh',
            'deployment/scripts/validate-cicd-setup.sh',
            'deployment/scripts/setup-server.sh'
        ]
        
        for script in scripts:
            if self.check_file_exists(script):
                print_success(f"Script encontrado: {script}")
                self.test_results['cloud_deployment']['passed'] += 1
            else:
                print_warning(f"Script faltante: {script}")
                self.test_results['cloud_deployment']['warnings'] += 1

        # 2.3 Test de aplicación local
        print_info("2.3 Testeando aplicación localmente...")
        try:
            # Test health check
            result = subprocess.run([sys.executable, 'src/app.py', 'health'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0 and 'OK' in result.stdout:
                print_success("Health check de la aplicación funcional")
                self.test_results['cloud_deployment']['passed'] += 1
            else:
                print_error("Health check de la aplicación falló")
                self.test_results['cloud_deployment']['failed'] += 1
        except Exception as e:
            print_error(f"Error ejecutando health check: {e}")
            self.test_results['cloud_deployment']['failed'] += 1

        # 2.4 Verificar configuración de ambiente
        print_info("2.4 Verificando configuración de ambientes...")
        env_configs = [
            'deployment/docker-compose.dev.yml',
            'deployment/docker-compose.prod.yml'
        ]
        
        for env_config in env_configs:
            if self.check_file_exists(env_config):
                print_success(f"Configuración de ambiente: {env_config}")
                self.test_results['cloud_deployment']['passed'] += 1
            else:
                print_warning(f"Configuración de ambiente faltante: {env_config}")
                self.test_results['cloud_deployment']['warnings'] += 1

    def test_infrastructure_security(self):
        """Test 3: Configuración de Infraestructura y Seguridad"""
        print_header("🔒 3. CONFIGURACIÓN DE INFRAESTRUCTURA Y SEGURIDAD")
        
        # 3.1 Verificar configuraciones de seguridad en Docker
        print_info("3.1 Verificando configuraciones de seguridad en Docker...")
        
        docker_compose_content = self.read_file('deployment/docker-compose.prod.yml')
        if docker_compose_content:
            security_features = [
                'no-new-privileges:true',
                'read_only: true',
                'security_opt:',
                'healthcheck:'
            ]
            
            security_score = 0
            for feature in security_features:
                if feature in docker_compose_content:
                    security_score += 1
            
            if security_score >= 3:
                print_success(f"Configuración de seguridad Docker buena ({security_score}/4 features)")
                self.test_results['infrastructure_security']['passed'] += 1
            else:
                print_warning(f"Configuración de seguridad Docker mejorable ({security_score}/4 features)")
                self.test_results['infrastructure_security']['warnings'] += 1
        else:
            print_error("No se pudo verificar configuración de seguridad Docker")
            self.test_results['infrastructure_security']['failed'] += 1

        # 3.2 Verificar configuración de SSH
        print_info("3.2 Verificando configuración de SSH...")
        
        # Verificar si hay documentación de SSH
        env_vars_content = self.read_file('deployment/ENVIRONMENT_VARIABLES.md')
        if env_vars_content and 'SSH_PRIVATE_KEY' in env_vars_content:
            print_success("Documentación de configuración SSH encontrada")
            self.test_results['infrastructure_security']['passed'] += 1
        else:
            print_warning("Documentación de SSH incompleta")
            self.test_results['infrastructure_security']['warnings'] += 1

        # 3.3 Verificar .gitignore para secretos
        print_info("3.3 Verificando .gitignore para protección de secretos...")
        
        gitignore_content = self.read_file('.gitignore')
        if gitignore_content:
            sensitive_patterns = ['*.key', '*.pem', '.env', '__pycache__', '*.log']
            protected_patterns = 0
            
            for pattern in sensitive_patterns:
                if pattern in gitignore_content:
                    protected_patterns += 1
            
            if protected_patterns >= 3:
                print_success(f"Protección de secretos adecuada ({protected_patterns}/5 patterns)")
                self.test_results['infrastructure_security']['passed'] += 1
            else:
                print_warning(f"Protección de secretos mejorable ({protected_patterns}/5 patterns)")
                self.test_results['infrastructure_security']['warnings'] += 1
        else:
            print_error(".gitignore no encontrado")
            self.test_results['infrastructure_security']['failed'] += 1

        # 3.4 Verificar configuración de logging y monitoring
        print_info("3.4 Verificando configuración de logging y monitoring...")
        
        if docker_compose_content and 'logging:' in docker_compose_content:
            print_success("Configuración de logging encontrada")
            self.test_results['infrastructure_security']['passed'] += 1
        else:
            print_warning("Configuración de logging podría mejorarse")
            self.test_results['infrastructure_security']['warnings'] += 1

        # 3.5 Verificar limits de recursos
        print_info("3.5 Verificando limits de recursos...")
        
        if docker_compose_content and 'resources:' in docker_compose_content:
            print_success("Limits de recursos configurados")
            self.test_results['infrastructure_security']['passed'] += 1
        else:
            print_warning("Limits de recursos no configurados")
            self.test_results['infrastructure_security']['warnings'] += 1

    def test_documentation(self):
        """Test 4: Documentación y Presentación"""
        print_header("📚 4. DOCUMENTACIÓN Y PRESENTACIÓN")
        
        # 4.1 Verificar README principal
        print_info("4.1 Verificando README principal...")
        
        readme_content = self.read_file('README.md')
        if readme_content:
            required_sections = [
                'instalación', 'instalacion', 'install',
                'uso', 'usage', 'use',
                'ci/cd', 'pipeline',
                'deployment', 'despliegue'
            ]
            
            sections_found = 0
            content_lower = readme_content.lower()
            for section in required_sections:
                if section in content_lower:
                    sections_found += 1
                    break  # Solo contar una vez por categoría
            
            if len(readme_content) > 1000:  # README sustancial
                print_success("README principal completo y detallado")
                self.test_results['documentation']['passed'] += 1
            else:
                print_warning("README principal podría ser más detallado")
                self.test_results['documentation']['warnings'] += 1
        else:
            print_error("README.md no encontrado")
            self.test_results['documentation']['failed'] += 1

        # 4.2 Verificar documentación técnica
        print_info("4.2 Verificando documentación técnica...")
        
        technical_docs = [
            'deployment/GITLAB_CICD_MANUAL.md',
            'deployment/ENVIRONMENT_VARIABLES.md'
        ]
        
        docs_found = 0
        for doc in technical_docs:
            if self.check_file_exists(doc):
                print_success(f"Documentación técnica: {doc}")
                docs_found += 1
        
        if docs_found == len(technical_docs):
            self.test_results['documentation']['passed'] += 1
        else:
            print_warning(f"Documentación técnica incompleta ({docs_found}/{len(technical_docs)})")
            self.test_results['documentation']['warnings'] += 1

        # 4.3 Verificar comentarios en código
        print_info("4.3 Verificando comentarios en código...")
        
        app_content = self.read_file('src/app.py')
        if app_content:
            # Contar líneas de comentarios
            lines = app_content.split('\n')
            comment_lines = [line for line in lines if line.strip().startswith('#') or '"""' in line]
            total_lines = len([line for line in lines if line.strip()])
            
            if total_lines > 0:
                comment_ratio = len(comment_lines) / total_lines
                if comment_ratio > 0.15:  # 15% de comentarios
                    print_success(f"Código bien documentado ({comment_ratio:.1%} comentarios)")
                    self.test_results['documentation']['passed'] += 1
                else:
                    print_warning(f"Código podría tener más comentarios ({comment_ratio:.1%})")
                    self.test_results['documentation']['warnings'] += 1
            else:
                print_error("No se pudo analizar el código fuente")
                self.test_results['documentation']['failed'] += 1
        else:
            print_error("Archivo principal de aplicación no encontrado")
            self.test_results['documentation']['failed'] += 1

        # 4.4 Verificar estructura de archivos
        print_info("4.4 Verificando estructura de archivos y organización...")
        
        expected_dirs = ['src', 'deployment', 'configs']
        dirs_found = 0
        
        for directory in expected_dirs:
            if Path(directory).exists():
                dirs_found += 1
        
        if dirs_found >= 2:
            print_success(f"Estructura del proyecto bien organizada ({dirs_found}/{len(expected_dirs)} dirs)")
            self.test_results['documentation']['passed'] += 1
        else:
            print_warning(f"Estructura del proyecto mejorable ({dirs_found}/{len(expected_dirs)} dirs)")
            self.test_results['documentation']['warnings'] += 1

    def generate_final_report(self):
        """Generar reporte final de los tests"""
        print_header("📊 REPORTE FINAL DE TESTING")
        
        total_passed = sum(category['passed'] for category in self.test_results.values())
        total_failed = sum(category['failed'] for category in self.test_results.values())
        total_warnings = sum(category['warnings'] for category in self.test_results.values())
        total_tests = total_passed + total_failed + total_warnings
        
        print(f"{Colors.BOLD}Tiempo total de testing:{Colors.END} {datetime.now() - self.start_time}")
        print(f"{Colors.BOLD}Total de tests ejecutados:{Colors.END} {total_tests}")
        print(f"{Colors.GREEN}{Colors.BOLD}Tests pasados:{Colors.END} {total_passed}")
        print(f"{Colors.RED}{Colors.BOLD}Tests fallados:{Colors.END} {total_failed}")
        print(f"{Colors.YELLOW}{Colors.BOLD}Warnings:{Colors.END} {total_warnings}")
        
        # Detalle por categoría
        print(f"\n{Colors.BOLD}DETALLE POR CATEGORÍA:{Colors.END}")
        categories = {
            'pipeline_cicd': '🔄 Pipeline CI/CD',
            'cloud_deployment': '☁️  Cloud Deployment',
            'infrastructure_security': '🔒 Infrastructure & Security',
            'documentation': '📚 Documentation'
        }
        
        for category, name in categories.items():
            results = self.test_results[category]
            total_cat = results['passed'] + results['failed'] + results['warnings']
            if total_cat > 0:
                success_rate = (results['passed'] / total_cat) * 100
                print(f"{name}: {Colors.GREEN}{results['passed']}✅{Colors.END} "
                      f"{Colors.RED}{results['failed']}❌{Colors.END} "
                      f"{Colors.YELLOW}{results['warnings']}⚠️{Colors.END} "
                      f"({success_rate:.1f}% success)")
        
        # Evaluación general
        if total_tests > 0:
            success_rate = (total_passed / total_tests) * 100
            
            print(f"\n{Colors.BOLD}EVALUACIÓN GENERAL:{Colors.END}")
            if success_rate >= 80:
                print(f"{Colors.GREEN}{Colors.BOLD}✅ PROYECTO EXCELENTE{Colors.END}")
                print(f"   Tasa de éxito: {success_rate:.1f}%")
                print(f"   El proyecto está listo para producción 🚀")
            elif success_rate >= 60:
                print(f"{Colors.YELLOW}{Colors.BOLD}⚠️  PROYECTO BUENO{Colors.END}")
                print(f"   Tasa de éxito: {success_rate:.1f}%")
                print(f"   Necesita algunas mejoras menores ⚡")
            else:
                print(f"{Colors.RED}{Colors.BOLD}❌ PROYECTO NECESITA TRABAJO{Colors.END}")
                print(f"   Tasa de éxito: {success_rate:.1f}%")
                print(f"   Requiere correcciones importantes 🔧")
        
        # Recomendaciones
        print(f"\n{Colors.BOLD}RECOMENDACIONES:{Colors.END}")
        if total_failed > 0:
            print(f"{Colors.RED}• Resolver {total_failed} errores críticos antes de deployment{Colors.END}")
        if total_warnings > 0:
            print(f"{Colors.YELLOW}• Revisar {total_warnings} warnings para mejorar la calidad{Colors.END}")
        
        print(f"{Colors.BLUE}• Ejecutar tests regularmente durante el desarrollo{Colors.END}")
        print(f"{Colors.BLUE}• Mantener documentación actualizada{Colors.END}")
        print(f"{Colors.BLUE}• Realizar tests de seguridad periódicamente{Colors.END}")
        
        print(f"\n{Colors.CYAN}{Colors.BOLD}¡Testing completado!{Colors.END}")

    # Métodos auxiliares
    def check_file_exists(self, file_path):
        """Verificar si un archivo existe"""
        return Path(file_path).exists()

    def read_file(self, file_path):
        """Leer contenido de un archivo"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return f.read()
        except:
            return None

    def validate_gitlab_ci_content(self, content):
        """Validar contenido del archivo .gitlab-ci.yml"""
        if not content:
            return False
        
        required_elements = [
            'stages:',
            'image:',
            'script:',
            'before_script:',
        ]
        
        found_elements = 0
        for element in required_elements:
            if element in content:
                found_elements += 1
        
        return found_elements >= 3  # Al menos 3 de 4 elementos

if __name__ == "__main__":
    try:
        tester = ProjectTester()
        tester.run_all_tests()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Testing interrumpido por el usuario{Colors.END}")
    except Exception as e:
        print(f"\n{Colors.RED}Error durante el testing: {e}{Colors.END}")
