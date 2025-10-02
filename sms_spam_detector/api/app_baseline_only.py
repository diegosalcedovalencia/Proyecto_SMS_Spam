import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
import yaml
import json
from pathlib import Path
from typing import Dict, Any, Tuple, Optional
import sys
import os
import random

# Agregar el directorio principal al path
sys.path.append(str(Path(__file__).parent.parent.parent))

from sms_spam_detector.models.baseline_model import BaselineModel
from sms_spam_detector.utils.data_preprocessing import DataPreprocessor


class SpamDetectorApp:
    """
    Aplicación Streamlit para detección de spam en SMS (Solo Baseline Model)
    """
    
    def __init__(self):
        """Inicializa la aplicación"""
        # Configurar página solo una vez
        if 'page_configured' not in st.session_state:
            st.set_page_config(
                page_title="SMS Spam Detector - Baseline",
                page_icon="📱",
                layout="wide",
                initial_sidebar_state="expanded"
            )
            st.session_state.page_configured = True
        
        self.config = self.load_config()
        
        # Inicializar session state
        self._initialize_session_state()
        
    def _initialize_session_state(self):
        """Inicializa todas las variables de session state"""
        if 'message_text' not in st.session_state:
            st.session_state.message_text = ""
        if 'models_loaded' not in st.session_state:
            st.session_state.models_loaded = False
        if 'baseline_model' not in st.session_state:
            st.session_state.baseline_model = None
        if 'last_result' not in st.session_state:
            st.session_state.last_result = None
        if 'last_text_analyzed' not in st.session_state:
            st.session_state.last_text_analyzed = ""
        
    def load_config(self) -> Dict:
        """Carga la configuración desde archivo YAML"""
        # Buscar config.yaml en la carpeta configs
        config_path = Path(__file__).parent.parent.parent / "configs" / "config.yaml"
        if config_path.exists():
            with open(config_path, 'r', encoding='utf-8') as file:
                return yaml.safe_load(file)
        else:
            # Configuración por defecto si no existe el archivo
            return {
                'app': {
                    'title': 'SMS Spam Detector - Baseline',
                    'description': 'Detecta si un mensaje SMS es spam usando modelo baseline',
                    'max_input_length': 500
                },
                'evaluation': {'target_f1_score': 0.95},
                'paths': {'models_dir': 'sms_spam_detector/models/trained', 'results_dir': 'results_old'}
            }
    
    def load_models(self) -> bool:
        """Carga el modelo baseline"""
        try:
            baseline_model = BaselineModel()
            baseline_model.load_model()
            st.session_state.baseline_model = baseline_model
            st.session_state.models_loaded = True
            st.success("✅ Modelo Baseline cargado correctamente")
            return True
        except Exception as e:
            st.error(f"⚠️ No se pudo cargar el modelo Baseline: {e}")
            return False
    
    def predict_with_model(self, text: str) -> Tuple[str, float, Dict]:
        """Realiza predicción con el modelo baseline"""
        if st.session_state.baseline_model:
            try:
                # Limpiar el texto de entrada
                clean_text = st.session_state.baseline_model.vectorizer.transform([text])
                predictions = st.session_state.baseline_model.model.predict(clean_text)
                probabilities = st.session_state.baseline_model.model.predict_proba(clean_text)
                
                pred = predictions[0]
                prob = probabilities[0]
                
                result = "SPAM" if pred == 1 else "HAM"
                confidence = float(prob[pred])
                
                return result, confidence, {
                    'spam_probability': float(prob[1]) if len(prob) > 1 else 0.0,
                    'ham_probability': float(prob[0]) if len(prob) > 0 else 0.0,
                    'model_used': 'TF-IDF + Logistic Regression'
                }
            except Exception as e:
                st.error(f"Error en predicción: {e}")
                return "ERROR", 0.0, {}
        
        return "ERROR", 0.0, {}
    
    def create_probability_chart(self, details: Dict) -> go.Figure:
        """Crea gráfico de probabilidades"""
        if not details:
            return go.Figure()
        
        labels = ['HAM (No Spam)', 'SPAM']
        values = [details.get('ham_probability', 0), details.get('spam_probability', 0)]
        colors = ['#2E8B57', '#DC143C']  # Verde para HAM, Rojo para SPAM
        
        fig = go.Figure(data=[go.Bar(
            x=labels,
            y=values,
            marker_color=colors,
            text=[f'{v:.2%}' for v in values],
            textposition='outside'
        )])
        
        fig.update_layout(
            title="Probabilidades de Clasificación",
            xaxis_title="Clase",
            yaxis_title="Probabilidad",
            yaxis=dict(range=[0, 1]),
            height=400,
            showlegend=False
        )
        
        return fig
    
    def main_interface(self):
        """Interfaz principal de la aplicación"""
        st.title(self.config['app']['title'])
        st.markdown(self.config['app']['description'])
        
        # Sidebar para configuración
        with st.sidebar:
            st.header("⚙️ Configuración")
            
            # Cargar modelos
            if st.button("🔄 Cargar Modelo", type="primary"):
                with st.spinner("Cargando modelo..."):
                    self.load_models()
            
            st.markdown("---")
            
            # Mostrar información del proyecto
            with st.expander("ℹ️ Información del Proyecto"):
                st.markdown("""
                **SMS Spam Detector - Baseline Model**
                
                Este proyecto utiliza:
                - **Modelo Baseline**: TF-IDF + Regresión Logística
                - **Dataset**: SMS Spam Collection
                - **Objetivo**: F1-Score ≥ 0.95
                """)
        
        # Interfaz principal
        if not st.session_state.models_loaded:
            st.warning("⚠️ Primero debes cargar el modelo usando el botón en la barra lateral")
            return
        
        # Input del usuario
        st.subheader("📝 Analizar Mensaje SMS")
        
        # Ejemplos predefinidos
        examples_ham = [
            "Hola, ¿cómo estás? ¿Nos vemos para almorzar el sábado?",
            "Mamá, ya llegué a casa. Todo bien en el trabajo hoy.",
            "Recordatorio: reunión mañana a las 10am en la sala de juntas.",
            "Hi! How are you doing today? Want to grab coffee later?",
            "Thanks for your message. I'll get back to you soon."
        ]
        
        examples_spam = [
            "¡FELICIDADES! Has ganado $50,000 pesos. Haz clic aquí para reclamar",
            "OFERTA LIMITADA: iPhone 15 GRATIS. Solo hoy. Envía PREMIO al 4545",
            "CONGRATULATIONS! You've won a $1000 gift card! Click here to claim now",
            "FREE iPhone 14! Limited time offer. Text WIN to 12345 to claim your prize NOW!",
            "URGENT: Your account will be suspended. Verify your info immediately"
        ]
        
        # Inicializar session state para el texto
        if 'message_text' not in st.session_state:
            st.session_state.message_text = ""
        
        # Botones para ejemplos predefinidos
        st.write("🎯 **Ejemplos predefinidos:**")
        col1, col2, col3 = st.columns(3)
        
        with col1:
            if st.button("📝 HAM Aleatorio", help="Mensaje legítimo aleatorio"):
                st.session_state.message_text = random.choice(examples_ham)
                st.rerun()
        
        with col2:
            if st.button("🚨 SPAM Aleatorio", help="Mensaje spam aleatorio"):
                st.session_state.message_text = random.choice(examples_spam)
                st.rerun()
        
        with col3:
            if st.button("🗑️ Limpiar", help="Limpiar texto"):
                st.session_state.message_text = ""
                st.rerun()
        
        user_input = st.text_area(
            "Introduce el mensaje SMS a analizar:",
            value=st.session_state.message_text,
            height=100,
            max_chars=self.config['app']['max_input_length'],
            placeholder="Ejemplo: Free msg: Txt STOP to 85543 to stop receiving messages...",
            key="message_input"
        )
        
        # Actualizar session state cuando el usuario escriba algo
        if user_input != st.session_state.message_text:
            st.session_state.message_text = user_input
        
        col1, col2, col3 = st.columns([1, 2, 1])
        
        with col2:
            analyze_button = st.button("🔍 Analizar Mensaje", type="primary", use_container_width=True)
        
        if analyze_button and user_input.strip():
            # Realizar predicción y guardar en session state
            result, confidence, details = self.predict_with_model(user_input.strip())
            
            if result != "ERROR":
                # Guardar resultados en session state
                st.session_state.last_result = {
                    'result': result,
                    'confidence': confidence,
                    'details': details,
                    'text': user_input.strip()
                }
                st.session_state.last_text_analyzed = user_input.strip()
            else:
                st.session_state.last_result = None
                st.error("❌ Error al procesar el mensaje")
        
        # Mostrar resultados si existen
        if st.session_state.last_result and st.session_state.last_result['text'] == user_input.strip():
            result_data = st.session_state.last_result
            
            # Mostrar resultado principal
            st.subheader("📋 Resultado del Análisis")
            
            # Resultado con color
            if result_data['result'] == "SPAM":
                st.error(f"🚨 **SPAM DETECTADO** (Confianza: {result_data['confidence']:.1%})")
            else:
                st.success(f"✅ **MENSAJE LEGÍTIMO** (Confianza: {result_data['confidence']:.1%})")
            
            # Detalles en columnas
            col1, col2 = st.columns(2)
            
            with col1:
                st.metric(
                    "🎯 Probabilidad SPAM",
                    f"{result_data['details'].get('spam_probability', 0):.1%}",
                    delta=None
                )
            
            with col2:
                st.metric(
                    "✅ Probabilidad HAM",
                    f"{result_data['details'].get('ham_probability', 0):.1%}",
                    delta=None
                )
            
            # Gráfico de probabilidades
            if result_data['details']:
                try:
                    fig = self.create_probability_chart(result_data['details'])
                    st.plotly_chart(fig, use_container_width=True)
                except Exception as e:
                    st.warning(f"No se pudo generar el gráfico: {e}")
            
            # Información del modelo usado
            st.info(f"📊 Modelo utilizado: **{result_data['details'].get('model_used', 'Desconocido')}**")
        
        elif analyze_button:
            st.warning("⚠️ Por favor, introduce un mensaje para analizar")
    
    def run(self):
        """Ejecuta la aplicación"""
        self.main_interface()


def main():
    """Función principal"""
    app = SpamDetectorApp()
    app.run()


if __name__ == "__main__":
    main()
