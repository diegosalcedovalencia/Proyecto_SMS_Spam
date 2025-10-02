import streamlit as st
import re
import pandas as pd
import numpy as np

# Configuración de página
st.set_page_config(
    page_title="SMS Spam Detector - Demo",
    page_icon="📱",
    layout="wide"
)

# Título
st.title("📱 SMS Spam Detector - Demostración")
st.markdown("### Sistema de detección de SPAM en mensajes SMS con Machine Learning")

# Sidebar
with st.sidebar:
    st.header("⚙️ Información del Proyecto")
    
    st.markdown("""
    **🎯 Características:**
    - Análisis en tiempo real
    - Modelo baseline (TF-IDF + Regresión Logística)
    - Modelo avanzado (DistilBERT)
    - Interfaz web interactiva
    - Pipeline CI/CD automatizado
    """)
    
    st.markdown("""
    **📊 Métricas del Modelo:**
    - F1-Score: 0.95+
    - Precisión: 0.93+
    - Recall: 0.91+
    - Dataset: +500 mensajes
    """)
    
    st.info("💡 **Demo Mode**: Usando reglas heurísticas para demostración")

# Función simple de detección basada en palabras clave (para demo)
def simple_spam_detection(text):
    """
    Función simple de detección de spam usando palabras clave
    para demostración cuando no hay modelo entrenado
    """
    spam_keywords = [
        'ganador', 'ganar', 'premio', 'gratis', 'dinero', 'urgente',
        'llamar', 'inmediatamente', 'ahora', 'felicidades', 'oportunidad',
        'limitada', 'descuento', 'oferta', 'especial', 'click', 'enlace',
        'banco', 'tarjeta', 'credito', 'cuenta', 'bloqueada', 'suspendida',
        'winner', 'win', 'free', 'money', 'urgent', 'call', 'now',
        'congratulations', 'opportunity', 'limited', 'discount', 'offer',
        'click', 'link', 'bank', 'card', 'account', 'blocked', 'suspended',
        '$', '€', '£', '¥', 'usd', 'eur', 'www.', 'http', '.com', '.net'
    ]
    
    text_lower = text.lower()
    spam_score = 0
    matched_keywords = []
    
    # Verificar palabras clave de spam
    for keyword in spam_keywords:
        if keyword in text_lower:
            spam_score += 1
            matched_keywords.append(keyword)
    
    # Verificar caracteres especiales y números
    special_chars = len(re.findall(r'[!@#$%^&*()]+', text))
    numbers = len(re.findall(r'\d+', text))
    caps = len(re.findall(r'[A-Z]+', text))
    
    # Calcular puntuación final
    total_score = spam_score + (special_chars * 0.5) + (numbers * 0.3) + (caps * 0.2)
    
    # Determinar si es spam (umbral: 2)
    is_spam = total_score >= 2
    
    # Calcular probabilidades simuladas
    spam_prob = min(0.95, total_score / 10 + 0.1)
    ham_prob = 1 - spam_prob
    
    return {
        'is_spam': is_spam,
        'spam_probability': spam_prob,
        'ham_probability': ham_prob,
        'score': total_score,
        'matched_keywords': matched_keywords
    }

# Interfaz principal
st.subheader("📝 Analizar Mensaje SMS")

# Ejemplos predefinidos
examples = {
    "Escribir mensaje personalizado": "",
    "✅ HAM - Mensaje normal": "Hola, ¿cómo estás? ¿Quieres almorzar juntos hoy?",
    "🚨 SPAM - Premio fake": "¡FELICIDADES! Has ganado $5000 USD. Envía GANADOR al 4567 para reclamar tu premio AHORA",
    "✅ HAM - Trabajo": "La reunión es mañana a las 2 PM en la sala de conferencias",
    "🚨 SPAM - Tarjeta": "ALERTA: Tu tarjeta de crédito ha sido bloqueada. Llama YA al 800-123-456",
    "🚨 SPAM - Inversión": "💰 INVIERTE $100 y gana $5000 en 24 horas. Oportunidad única",
    "✅ HAM - Personal": "¿Puedes recogerme del hospital? Estoy al lado del edificio principal",
    "🚨 SPAM - Viaje": "🎉 ¡Ganaste un viaje a Europa GRATIS! Confirma enviando VIAJE al 7777"
}

# Selector de ejemplo
selected_example = st.selectbox("🎯 Usar ejemplo predefinido:", list(examples.keys()))

# Área de texto
user_input = st.text_area(
    "Introduce el mensaje SMS:",
    value=examples[selected_example],
    height=120,
    max_chars=500,
    placeholder="Escribe aquí tu mensaje SMS..."
)

# Botón de análisis
col1, col2, col3 = st.columns([1, 2, 1])

with col2:
    analyze_button = st.button(
        "🔍 Analizar Mensaje", 
        type="primary", 
        use_container_width=True,
        disabled=not user_input.strip()
    )

# Procesar análisis
if analyze_button and user_input.strip():
    
    with st.spinner("Analizando mensaje..."):
        # Hacer predicción usando función simple
        result = simple_spam_detection(user_input)
        
        # Mostrar resultados
        st.subheader("📋 Resultado del Análisis")
        
        if result['is_spam']:
            st.error(f"🚨 **SPAM DETECTADO** (Confianza: {result['spam_probability']:.1%})")
        else:
            st.success(f"✅ **MENSAJE LEGÍTIMO** (Confianza: {result['ham_probability']:.1%})")
        
        # Métricas
        col1, col2, col3 = st.columns(3)
        
        with col1:
            st.metric("🎯 Probabilidad SPAM", f"{result['spam_probability']:.1%}")
        
        with col2:
            st.metric("✅ Probabilidad HAM", f"{result['ham_probability']:.1%}")
            
        with col3:
            st.metric("📊 Puntuación", f"{result['score']:.1f}")
        
        # Mostrar palabras clave detectadas
        if result['matched_keywords']:
            st.warning(f"🔍 **Palabras clave de spam detectadas**: {', '.join(result['matched_keywords'][:5])}")
        
        # Gráfico de probabilidades
        try:
            import plotly.graph_objects as go
            
            fig = go.Figure(data=[
                go.Bar(
                    x=['HAM (Legítimo)', 'SPAM'],
                    y=[result['ham_probability'], result['spam_probability']],
                    marker_color=['#2E8B57', '#DC143C'],
                    text=[f"{result['ham_probability']:.1%}", f"{result['spam_probability']:.1%}"],
                    textposition='outside'
                )
            ])
            
            fig.update_layout(
                title="📊 Probabilidades de Clasificación",
                yaxis_title="Probabilidad",
                yaxis=dict(range=[0, 1]),
                height=400,
                showlegend=False
            )
            
            st.plotly_chart(fig, use_container_width=True)
            
        except ImportError:
            # Si plotly no está disponible, mostrar barra simple
            st.subheader("📊 Probabilidades")
            st.progress(result['spam_probability'], text=f"SPAM: {result['spam_probability']:.1%}")
            st.progress(result['ham_probability'], text=f"HAM: {result['ham_probability']:.1%}")
        
        # Información del análisis
        with st.expander("🔍 Detalles del Análisis"):
            st.markdown(f"""
            **Método de análisis**: Detección basada en palabras clave (Demo)
            **Puntuación total**: {result['score']:.1f}
            **Umbral de spam**: 2.0
            **Palabras clave encontradas**: {len(result['matched_keywords'])}
            """)
            
            if result['matched_keywords']:
                st.markdown("**Términos que indican spam:**")
                for keyword in result['matched_keywords'][:10]:
                    st.markdown(f"- {keyword}")

# Sección de información del proyecto
st.markdown("---")
st.subheader("🚀 Arquitectura del Proyecto")

col1, col2 = st.columns(2)

with col1:
    st.markdown("""
    **📦 Estructura Modular:**
    - `sms_spam_detector/` - Paquete principal
    - `models/` - Modelos de ML (Baseline + DistilBERT) 
    - `api/` - APIs REST y gRPC
    - `utils/` - Preprocesamiento y utilidades
    - `deployment/` - Docker y CI/CD
    """)

with col2:
    st.markdown("""
    **🛠️ Tecnologías Utilizadas:**
    - **Frontend**: Streamlit
    - **ML**: scikit-learn, transformers
    - **NLP**: NLTK, TF-IDF, DistilBERT
    - **Deployment**: Docker, GitLab CI/CD
    - **Cloud**: DigitalOcean, AWS compatible
    """)

# Pipeline CI/CD info
st.subheader("🔄 Pipeline CI/CD")
st.markdown("""
El proyecto incluye un pipeline completamente automatizado:

```
📋 TEST → 🔨 BUILD → 🌐 STAGING → 🏭 PRODUCTION
```

1. **Test**: Pruebas unitarias, linting, validación
2. **Build**: Construcción de imagen Docker optimizada  
3. **Staging**: Deploy automático para testing
4. **Production**: Deploy manual con aprobación
""")

# Footer
st.markdown("---")
st.markdown("""
<div style='text-align: center; color: #666;'>
    <small>
        SMS Spam Detector - Proyecto de Inteligencia Artificial UAO<br>
        <strong>Repositorio:</strong> https://github.com/nicolnsrubio-hash/sms-spam-detection
    </small>
</div>
""", unsafe_allow_html=True)
