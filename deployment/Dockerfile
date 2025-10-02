# Usar imagen base de Python 3.9
FROM python:3.9-slim

# Establecer el directorio de trabajo
WORKDIR /app

# Instalar dependencias del sistema necesarias
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copiar archivos de requisitos
COPY configs/requirements.txt .

# Actualizar pip e instalar dependencias de Python con CPU-only para PyTorch
RUN pip install --no-cache-dir --upgrade pip
# Instalar PyTorch CPU-only primero para acelerar la construcción
RUN pip install --no-cache-dir torch==2.0.1+cpu torchvision==0.15.2+cpu torchaudio==2.0.2+cpu --index-url https://download.pytorch.org/whl/cpu
# Instalar el resto de dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código fuente
COPY . .

# Crear directorio para modelos si no existe
RUN mkdir -p models logs results data

# Establecer variables de entorno
ENV PYTHONPATH=/app
ENV STREAMLIT_SERVER_PORT=8501
ENV STREAMLIT_SERVER_ADDRESS=0.0.0.0
ENV STREAMLIT_SERVER_HEADLESS=true
ENV STREAMLIT_BROWSER_GATHER_USAGE_STATS=false

# Exponer puerto para Streamlit
EXPOSE 8501

# Comando de salud para Docker
HEALTHCHECK CMD curl --fail http://localhost:8501/_stcore/health

# Comando por defecto para ejecutar la aplicación
CMD ["streamlit", "run", "sms_spam_detector/api/app_baseline_only.py", "--server.port=8501", "--server.address=0.0.0.0"]
