import sys
from pathlib import Path
import yaml
import json

# Agregar src al path
sys.path.append(str(Path(__file__).parent / "src"))

from baseline_model import BaselineModel
from mlflow_integration import MLflowManager
import pandas as pd


def register_baseline_model():
    """Registra el modelo baseline ya entrenado en MLflow"""
    print("🔄 Registrando modelo baseline en MLflow...")
    
    # Cargar configuración
    with open("config.yaml", "r", encoding="utf-8") as file:
        config = yaml.safe_load(file)
    
    # Cargar modelo entrenado
    try:
        baseline = BaselineModel()
        baseline.load_model()
        print("✅ Modelo baseline cargado")
    except Exception as e:
        print(f"❌ Error cargando modelo: {e}")
        return
    
    # Cargar datos de prueba para métricas
    data_dir = Path(config["paths"]["data_dir"])
    test_path = data_dir / "test_data.csv"
    
    if not test_path.exists():
        print("❌ Datos de prueba no encontrados")
        return
    
    test_df = pd.read_csv(test_path)
    
    # Evaluar modelo
    test_metrics = baseline.evaluate(test_df)
    
    # Métricas de entrenamiento simuladas (ya que no las tenemos guardadas)
    train_metrics = {
        "train_f1": 1.0,  # F1 perfecto en training (como vimos antes)
        "n_samples": 85,  # Tamaño del conjunto de entrenamiento
        "n_features": 1502  # Características TF-IDF
    }
    
    # Inicializar MLflow
    mlflow_manager = MLflowManager("SMS_Spam_Detection")
    
    # Registrar experimento
    run_id = mlflow_manager.log_baseline_experiment(
        model=baseline.model,
        vectorizer=baseline.vectorizer,
        train_metrics=train_metrics,
        test_metrics=test_metrics,
        config=config
    )
    
    print(f"✅ Modelo registrado en MLflow con Run ID: {run_id}")
    print("🌐 Para ver la interfaz web, ejecuta: mlflow ui")


if __name__ == "__main__":
    register_baseline_model()
