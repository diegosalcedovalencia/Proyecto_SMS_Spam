import mlflow
import mlflow.sklearn
import pandas as pd
from pathlib import Path
import sys
import yaml

# Agregar src al path
sys.path.append(str(Path(__file__).parent / "src"))

from baseline_model import BaselineModel


def init_simple_mlflow():
    """Inicialización simple de MLflow"""
    print("🔄 Inicializando MLflow...")
    
    # Crear directorio mlruns
    mlruns_dir = Path("mlruns")
    mlruns_dir.mkdir(exist_ok=True)
    
    # Configurar MLflow para usar directorio local
    mlflow.set_tracking_uri("./mlruns")
    
    # Crear experimento
    try:
        experiment_id = mlflow.create_experiment("SMS_Spam_Detection")
        print(f"✅ Experimento creado con ID: {experiment_id}")
    except mlflow.exceptions.MlflowException:
        print("✅ Experimento ya existe")
        mlflow.set_experiment("SMS_Spam_Detection")
    
    # Cargar configuración
    with open("config.yaml", "r", encoding="utf-8") as file:
        config = yaml.safe_load(file)
    
    # Cargar modelo entrenado
    try:
        baseline = BaselineModel()
        baseline.load_model()
        print("✅ Modelo baseline cargado")
        
        # Cargar datos de prueba
        data_dir = Path(config["paths"]["data_dir"])
        test_path = data_dir / "test_data.csv"
        test_df = pd.read_csv(test_path)
        
        # Evaluar modelo
        test_metrics = baseline.evaluate(test_df)
        print("✅ Modelo evaluado")
        
        # Registrar experimento en MLflow
        with mlflow.start_run(run_name="Baseline_SMS_Spam_Detector") as run:
            # Registrar parámetros
            baseline_config = config.get("baseline", {})
            mlflow.log_params({
                "model_type": "baseline",
                "algorithm": "TF-IDF + Logistic Regression", 
                "max_features": baseline_config.get("max_features", 8000),
                "C": baseline_config.get("C", 10.0),
                "solver": baseline_config.get("solver", "liblinear"),
            })
            
            # Registrar métricas
            mlflow.log_metrics({
                "test_f1_score": test_metrics.get("f1_score", 0),
                "test_accuracy": test_metrics.get("accuracy", 0),
                "test_precision": (test_metrics["classification_report"]["Ham"]["precision"] + 
                                test_metrics["classification_report"]["Spam"]["precision"]) / 2,
                "test_recall": (test_metrics["classification_report"]["Ham"]["recall"] + 
                              test_metrics["classification_report"]["Spam"]["recall"]) / 2,
            })
            
            # Registrar modelo
            mlflow.sklearn.log_model(
                sk_model=baseline.model,
                artifact_path="model",
                registered_model_name="SMS_Spam_Baseline_Model"
            )
            
            # Registrar artefactos adicionales
            import joblib
            temp_vectorizer = "temp_vectorizer.pkl"
            joblib.dump(baseline.vectorizer, temp_vectorizer)
            mlflow.log_artifact(temp_vectorizer, "artifacts")
            
            # Limpiar archivo temporal
            Path(temp_vectorizer).unlink()
            
            print(f"✅ Experimento registrado con Run ID: {run.info.run_id}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return
    
    print("\n" + "="*50)
    print("🎉 MLflow configurado exitosamente!")
    print("="*50)
    print("Para ver la interfaz web de MLflow, ejecuta:")
    print("mlflow ui")
    print(f"Luego abre: http://localhost:5000")
    print("="*50)


if __name__ == "__main__":
    init_simple_mlflow()
