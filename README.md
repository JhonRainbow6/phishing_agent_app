# AI Agent AntiPhishing

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![n8n](https://img.shields.io/badge/n8n-FF6D5A?style=for-the-badge&logo=n8n&logoColor=white)
![Ollama](https://img.shields.io/badge/Ollama-000000?style=for-the-badge&logo=ollama&logoColor=white)
![Llama 3.1](https://img.shields.io/badge/Llama_3.1_8B-0467DF?style=for-the-badge&logo=meta&logoColor=white)
![GCP](https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)
![MITRE ATT&CK](https://img.shields.io/badge/MITRE_ATT%26CK-Mobile-RED?style=for-the-badge)

Prototipo experimental de un **Agente de Ciberseguridad Autónomo basado en IA Agentica y RAG (Retrieval-Augmented Generation)** enfocado en la prevención, análisis y traducción de riesgos de ingeniería social en entornos móviles.

## 📌 Tabla de Contenidos

1. [Características Principales](#-Características-Principales)
2. [Arquitectura del Sistema](#-arquitectura-del-sistema)
3. [Organización de Carpetas Principales](#-organizacion-de-carpetas-principales)
4. [Componentes Clave](#-componentes-clave)
5. [Guía de Instalación y Despliegue](#-guía-de-instalación-y-despliegue)

## Características Principales

- **Análisis RAG en Tiempo Real:** Búsqueda semántica sobre 124 técnicas de la matriz MITRE ATT&CK for Mobile vectorizadas.
- **Inferencia Dedicada:** Razonamiento mediante el modelo de lenguaje abierto **Llama 3.1 8B**.
- **Interfaz Móvil Intuitiva:** Aplicación desarrollada en Flutter con diseño limpio y comunicación asíncrona vía Webhooks.
- **Reporte SOC Estructurado:** Evaluaciones categóricas formateadas con nivel de riesgo, tácticas, ID técnico y medidas de mitigación inmediatas.
  

## 🏗️ Arquitectura del Sistema

<img width="1056" height="698" alt="Arquitectura RAG" src="https://github.com/user-attachments/assets/96f5f6be-83ed-4e92-9a1e-934a4379add1" />


## 📂 Organización de Carpetas Principales

```text
phishing_agent_app/
├── android/                         # Módulo nativo Android (Gradle + Kotlin)
│   ├── app/                         # Módulo principal de la aplicación Android
│   └── n8n workflow/                # Integración con el Agente AI / Backend
│       └── phishing_rag_pipeline.json # Pipeline RAG de análisis de phishing en n8n
│   
├── lib/                             # Código fuente principal de la aplicación (Flutter / Dart)
│   ├── main.dart                    # Punto de entrada y vistas de la aplicación
│   └── api_service.dart             # Cliente HTTP para conexión con el Agente AI (Webhook)
│
├── test/                            # Pruebas unitarias y de widgets
│   └── widget_test.dart
│
├── ios/ / web/ / windows/ / macos/ # Módulos de soporte para otras plataformas
│
├── pubspec.yaml                     # Configuración de dependencias del proyecto Flutter
├── pubspec.lock                     # Versiones bloqueadas de dependencias
└── analysis_options.yaml            # Reglas de linter y análisis estático de Dart
```


## 🛠️ Componentes Clave

1. **`MainActivity.kt`**:
   - Ubicación: `app/src/main/kotlin/com/phishing_agent/app/MainActivity.kt`
   - Punto de entrada nativo que extiende de `FlutterActivity` para inicializar el Runtime de Flutter.

2. **`AndroidManifest.xml`**:
   - Ubicación: `app/src/main/AndroidManifest.xml`
   - Configura los permisos de red (`INTERNET`) y las actividades principales de la app.

3. **Pipeline RAG (`n8n workflow/`)**:
   - Ubicación: `android/n8n workflow/phishing_rag_pipeline.json`
   - Workflow en formato JSON importable en **n8n**, encargado del procesamiento RAG para la detección de phishing recibida desde el frontend.



## 🚀 Guía de Instalación y Despliegue
> [!NOTE]
> **Aclaración:** El despliegue del LLM así como del flujo en n8n para este proyecto se hizo mediante herramientas en la nube (Google Cloud Platform y Hostinger). Si tu maquina es lo suficientemente potente puedes optar por la opción local, aunque la configuración de red y comandos de instalación puede variar.

### 1. Servidor de Inferencia y Exposición del Servicio (GCP + Ollama + Cloudflare Tunnel)

1. **Servidor de Inferencia (GCP + Ollama)**

Crear una instancia VM en GCP Compute Engine con Linux (mínimo 16 GB RAM /8 vCPUs recomendadas).

Instalar Ollama y descargar los modelos necesarios:

```bash
curl -fsSL [https://ollama.com/install.sh](https://ollama.com/install.sh) | sh
ollama pull llama3.1:8b
ollama pull nomic-embed-text****
```

2. **Instalar Cloudflare CLI (`cloudflared`):**

Descargar e instalar el paquete oficial de Cloudflare en la VM:

```bash
 curl -L --output cloudflared.deb [https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb)
sudo dpkg -i cloudflared.deb
```

3. **Generar el Túnel Provisional (Quick Tunnel):**

Exponer el puerto local de Ollama (`11434`) hacia una URL HTTPS pública temporal mediante Cloudflare:

```bash
 cloudflared tunnel --url http://localhost:11434
```
Al ejecutar el comando, Cloudflare mostrará en la terminal un enlace con el dominio `https://<SUBDOMINIO_ALEATORIO>.trycloudflare.com`. **Copia esta URL**, ya que será la puerta de enlace segura utilizada por el orquestador sin exponer IPs públicas ni modificar reglas complejas de firewall.

---

### 2. Orquestador de Flujos (n8n + RAG)

1. Importa el archivo `n8n_workflows/phishing_rag_pipeline.json` dentro de tu instancia de **n8n** (local o en la nube).
2. Configura los credenciales/nodos de **Ollama Model** y **Ollama Embeddings** pegando la URL provista por el túnel de Cloudflare (`https://<SUBDOMINIO_ALEATORIO>.trycloudflare.com`).
3. Carga el dataset `dataset/mobile-attack.json` dentro del flujo para la ingesta inicial.
4. Activa el workflow y copia la **Production URL** generada en el nodo **Webhook**.

---

### 3. Aplicación Móvil (Flutter)
> [!IMPORTANT]
> Asegurate de tener Flutter SDK instalado en tu IDE.

1. Clona el repositorio e ingresa a la carpeta del proyecto móvil:
```bash
git clone [https://github.com/TU_USUARIO/phishing-agent-mobile.git](https://github.com/TU_USUARIO/phishing-agent-mobile.git)
cd phishing-agent-mobile/mobile_app
```

2. Instalación de dependencias
```bash
flutter pub get
```

3. En `lib/services/api_service.dart` asigna el Production URL de tu Webhook en n8n:
```bash
static const String _webhookUrl = '[https://tu-instancia-n8n.com/webhook/phishing-analysis](https://tu-instancia-n8n.com/webhook/phishing-analysis)';
```

4. Finalmente compila y ejecuta:
```bash
flutter run
```

Docente Director: Juan Guillermo Torres Hurtado

Programa: Ingeniería de Sistemas y Computación

Facultad: Facultad de Ingeniería, Universidad Católica de Colombia (Bogotá D.C.)
