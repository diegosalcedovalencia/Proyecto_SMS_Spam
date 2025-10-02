#!/usr/bin/env python3
"""
Script principal para entrenar todos los modelos del proyecto SMS Spam Detection
Ejecuta secuencialmente: preprocesamiento, baseline, DistilBERT y evaluación
"""

import sys
import time
from pathlib import Path

# Agregar el directorio principal al path
sys.path.append(str(Path(__file__).parent.parent))

def main():
    """Función principal que ejecuta todo el pipeline de entrenamiento"""
    start_time = time.time()
    
    print("🚀 Iniciando pipeline completo de entrenamiento de modelos SMS Spam Detection")
    print("=" * 80)
    
    try:
        # 1. Preprocesamiento de datos
        print("\n📊 PASO 1: Preprocesamiento de datos")
        print("-" * 50)
        from sms_spam_detector.utils.data_preprocessing import main as preprocess_main
        preprocess_main()
        
        # 2. Entrenamiento del modelo baseline
        print("\n🔄 PASO 2: Entrenamiento del modelo Baseline (TF-IDF + Regresión Logística)")
        print("-" * 50)
        from sms_spam_detector.models.baseline_model import main as baseline_main
        baseline_main()
        
        # 3. Entrenamiento del modelo DistilBERT
        print("\n🤖 PASO 3: Entrenamiento del modelo DistilBERT")
        print("-" * 50)
        from sms_spam_detector.models.distilbert_model import main as distilbert_main
        distilbert_main()
        
        # 4. Evaluación y comparación
        print("\n📈 PASO 4: Evaluación y comparación de modelos")
        print("-" * 50)
        from sms_spam_detector.evaluation.model_evaluation import main as evaluation_main
        evaluation_main()
        
        # Resumen final
        end_time = time.time()
        total_time = end_time - start_time
        
        print("\n" + "=" * 80)
        print("✅ PIPELINE COMPLETADO EXITOSAMENTE!")
        print(f"⏱️  Tiempo total de ejecución: {total_time:.2f} segundos ({total_time/60:.1f} minutos)")
        print("\n📁 Archivos generados:")
        print("   • Datos procesados: sms_spam_detector/data/processed/train_data.csv, test_data.csv")
        print("   • Modelo Baseline: sms_spam_detector/models/trained/baseline_model.pkl, tfidf_vectorizer.pkl")
        print("   • Modelo DistilBERT: sms_spam_detector/models/trained/distilbert_spam_classifier/")
        print("   • Resultados: results_old/evaluation_results.json")
        print("   • Gráficos: results_old/model_comparison.png, confusion_matrices.png")
        print("\n🌐 Para usar la aplicación web:")
        print("   streamlit run sms_spam_detector/api/app.py")
        print("\n🐳 O con Docker:")
        print("   docker-compose -f deployment/docker-compose.yml up")
        print("=" * 80)
        
    except Exception as e:
        print(f"\n❌ ERROR EN EL PIPELINE: {e}")
        print("Revisa los logs para más detalles.")
        sys.exit(1)


if __name__ == "__main__":
    main()
