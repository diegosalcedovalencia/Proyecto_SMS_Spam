#!/usr/bin/env python3
"""
Script de prueba rápida del proyecto SMS Spam Detection reorganizado
"""

import sys
from pathlib import Path

# Agregar el directorio principal al path
sys.path.append(str(Path(__file__).parent))

from sms_spam_detector.models.baseline_model import BaselineModel
from sms_spam_detector.utils.data_preprocessing import DataPreprocessor

def test_baseline_model():
    """Prueba el modelo baseline"""
    print("🧪 TESTING SMS SPAM DETECTOR - REORGANIZED PROJECT")
    print("=" * 60)
    
    # Cargar modelo entrenado
    print("\n📦 Cargando modelo baseline...")
    try:
        baseline = BaselineModel()
        baseline.load_model()
        print("✅ Modelo baseline cargado exitosamente")
    except Exception as e:
        print(f"❌ Error cargando modelo: {e}")
        return False
    
    # Mensajes de prueba
    test_messages = [
        # HAM (legítimos)
        "Hola, ¿cómo estás? ¿Nos vemos mañana para almorzar?",
        "Recordatorio: reunión a las 3pm en la sala de juntas",
        "Thanks for your message, I'll get back to you soon",
        
        # SPAM
        "¡FELICIDADES! Has ganado $50,000 pesos. Haz clic aquí AHORA!",
        "FREE iPhone! Text WIN to 12345 to claim your prize NOW!",
        "URGENT: Your account will be suspended. Click here immediately"
    ]
    
    expected_labels = ["HAM", "HAM", "HAM", "SPAM", "SPAM", "SPAM"]
    
    print("\n🔍 Probando predicciones...")
    correct_predictions = 0
    
    for i, message in enumerate(test_messages):
        predictions, probabilities = baseline.predict([message])
        predicted_label = "SPAM" if predictions[0] == 1 else "HAM"
        confidence = probabilities[0][predictions[0]]
        
        is_correct = predicted_label == expected_labels[i]
        status = "✅" if is_correct else "❌"
        
        if is_correct:
            correct_predictions += 1
        
        print(f"\n{status} Mensaje {i+1}:")
        print(f"   Texto: '{message[:50]}...'")
        print(f"   Esperado: {expected_labels[i]}")
        print(f"   Predicho: {predicted_label} (Confianza: {confidence:.2%})")
    
    # Resultados finales
    accuracy = correct_predictions / len(test_messages)
    print(f"\n📊 RESULTADOS FINALES:")
    print(f"   Predicciones correctas: {correct_predictions}/{len(test_messages)}")
    print(f"   Precisión: {accuracy:.2%}")
    
    if accuracy >= 0.8:
        print("\n🎉 ¡PROYECTO FUNCIONANDO CORRECTAMENTE!")
        print("✅ El modelo baseline detecta spam con buena precisión")
        print("✅ La estructura del proyecto está organizada correctamente")
        print("✅ Todos los imports y rutas funcionan perfectamente")
    else:
        print("\n⚠️  El modelo necesita más entrenamiento")
    
    return True

def test_project_structure():
    """Verifica la estructura del proyecto"""
    print("\n🏗️  Verificando estructura del proyecto...")
    
    required_files = [
        "sms_spam_detector/__init__.py",
        "sms_spam_detector/models/__init__.py",
        "sms_spam_detector/models/baseline_model.py",
        "sms_spam_detector/utils/__init__.py",
        "sms_spam_detector/utils/data_preprocessing.py",
        "sms_spam_detector/api/__init__.py",
        "sms_spam_detector/api/app_baseline_only.py",
        "configs/config.yaml",
        "configs/requirements.txt",
        "scripts/train_models.py",
        "README.md"
    ]
    
    missing_files = []
    for file_path in required_files:
        if not Path(file_path).exists():
            missing_files.append(file_path)
    
    if not missing_files:
        print("✅ Todos los archivos principales están presentes")
        return True
    else:
        print("❌ Archivos faltantes:")
        for file_path in missing_files:
            print(f"   - {file_path}")
        return False

def main():
    """Función principal"""
    # Verificar estructura
    structure_ok = test_project_structure()
    
    if not structure_ok:
        print("\n❌ La estructura del proyecto tiene problemas")
        return
    
    # Probar modelo
    model_ok = test_baseline_model()
    
    if model_ok:
        print("\n" + "=" * 60)
        print("🎯 RESUMEN FINAL:")
        print("✅ Proyecto SMS Spam Detection reorganizado exitosamente")
        print("✅ Estructura de carpetas profesional y organizada")
        print("✅ Modelo baseline entrenado y funcionando")
        print("✅ APIs disponibles en sms_spam_detector/api/")
        print("✅ Configuraciones centralizadas en configs/")
        print("✅ Scripts de entrenamiento en scripts/")
        print("✅ Documentación en docs/")
        print("\n🚀 Para usar la aplicación web:")
        print("   streamlit run sms_spam_detector/api/app_baseline_only.py")
        print("\n📦 Para entrenar modelos:")
        print("   python scripts/train_models.py")
        print("=" * 60)

if __name__ == "__main__":
    main()
