# OCR Document Finder para Business Central

Integración de Azure AI Document Intelligence con Business Central On-Prem v26 y Continia Document Capture para búsqueda inteligente de líneas en documentos mediante OCR.

## 📋 Descripción

Esta aplicación permite buscar líneas específicas dentro de facturas de Continia Document Capture que tengan PDFs adjuntos, utilizando Azure AI Document Intelligence para el análisis OCR. Es ideal para localizar rápidamente información en facturas con muchas líneas (100+ líneas) sin tener que revisar manualmente todo el documento.

## ✨ Características

- 🔍 **Búsqueda inteligente OCR**: Encuentra líneas por descripción, código, cantidad, precio, etc.
- 📊 **Análisis completo**: Extrae y estructura todas las líneas del documento
- 📈 **Confianza del OCR**: Muestra nivel de confianza para cada resultado
- 📝 **Log de operaciones**: Registro completo de todas las búsquedas realizadas
- 📤 **Exportación a Excel**: Exporta resultados fácilmente
- 🚀 **Búsqueda rápida**: Desde la página de documentos de Continia
- 🔧 **Configurable**: Configuración flexible de timeout y modelos

## 🛠️ Requisitos Previos

### En Azure:
1. Suscripción de Azure activa
2. Recurso de Azure AI Document Intelligence (Form Recognizer)
   - Puede ser nivel gratuito (F0) para pruebas
   - Nivel S0 para producción

### En Business Central:
1. Business Central On-Prem versión 26
2. Continia Document Capture instalado y configurado
3. Documentos con PDFs adjuntos en Continia

## 📦 Instalación

### 1. Crear Recurso en Azure

1. Ir a [Azure Portal](https://portal.azure.com)
2. Crear nuevo recurso > AI + Machine Learning > Form Recognizer / Document Intelligence
3. Configurar:
   - **Nombre del recurso**: ej. `bc-ocr-docint`
   - **Región**: Elegir la más cercana
   - **Pricing tier**: F0 (gratis) o S0 (producción)
4. Crear recurso
5. Una vez creado, ir a "Keys and Endpoint"
6. Copiar:
   - **Endpoint**: `https://your-resource.cognitiveservices.azure.com`
   - **Key 1** o **Key 2**

### 2. Compilar e Instalar la App

```powershell
# En Visual Studio Code con AL Language Extension

# 1. Abrir la carpeta OCRDocumentFinder
# 2. Modificar app.json:
#    - Cambiar "id" por un GUID único
#    - Cambiar "publisher" por el nombre de tu empresa

# 3. Presionar F5 o ejecutar:
Ctrl+Shift+P > "AL: Publish"

# 4. O compilar manualmente:
alc.exe /project:"OCRDocumentFinder" /packagecachepath:"C:\path\to\cache"
```

### 3. Configurar en Business Central

1. Buscar "Azure AI Configuration" en Business Central
2. Ingresar datos de Azure:
   - **Endpoint URL**: Pegar el endpoint copiado de Azure
   - **API Key**: Pegar la key copiada
   - **Model ID**: Dejar `prebuilt-invoice` (o usar modelo custom)
   - **Enabled**: Activar
3. Presionar "Test Connection" para verificar

## 🚀 Uso

### Opción 1: Desde la Página Principal

1. Buscar "OCR Document Finder" en Business Central
2. Seleccionar documento de Continia (con PDF adjunto)
3. Ingresar texto a buscar (ej: "TORNILLO", "12345", "250.00")
4. Presionar "Buscar con OCR"
5. Revisar resultados en la ventana emergente

### Opción 2: Búsqueda Rápida desde Continia

1. Abrir un documento en Continia Document Capture
2. Presionar "Buscar con OCR" (botón en la cinta)
3. Ingresar texto a buscar
4. Ver resultados inmediatamente

### Opción 3: Búsqueda Directa

1. Desde un documento de Continia
2. Presionar "Búsqueda Rápida OCR"
3. Ingresar texto en el diálogo
4. Ver resultados

## 📊 Interpretación de Resultados

### Campos Mostrados:
- **Línea Nº**: Número de línea en el documento
- **Descripción**: Texto de la línea
- **Código Producto**: Código o referencia
- **Cantidad**: Cantidad del item
- **Precio Unitario**: Precio por unidad
- **Importe**: Total de la línea
- **Coincidencia en Campo(s)**: Dónde se encontró el texto buscado
- **Confianza %**: Nivel de confianza del OCR (>90% es excelente)

### Códigos de Color:
- 🟢 **Verde**: Alta confianza (>95%)
- 🟡 **Amarillo**: Confianza media (80-95%)
- 🔴 **Rojo**: Baja confianza (<80%)

## 📈 Registro y Auditoría

### Ver Log de Operaciones:
1. Buscar "OCR Operation Log"
2. Ver todas las búsquedas realizadas:
   - Fecha y hora
   - Documento analizado
   - Texto buscado
   - Resultados encontrados
   - Tiempo de procesamiento
   - Usuario que ejecutó

### Estadísticas:
- Total de operaciones
- Tasa de éxito
- Tiempo promedio de procesamiento
- Actividad por período

## ⚙️ Configuración Avanzada

### Modelos Disponibles:

#### Modelos Preentrenados:
- `prebuilt-invoice`: Facturas (recomendado)
- `prebuilt-receipt`: Recibos
- `prebuilt-businessCard`: Tarjetas de visita
- `prebuilt-idDocument`: Documentos de identidad

#### Modelo Personalizado:
Si tienes facturas con formato muy específico, puedes entrenar un modelo custom en Azure y usar su ID.

### Timeouts:
- Ajustar "Timeout Seconds" si los documentos son muy grandes
- Rango: 30-300 segundos
- Default: 120 segundos

## 🔧 Troubleshooting

### Error: "No se puede conectar con Azure"
- Verificar Endpoint URL (sin / al final)
- Verificar API Key
- Verificar acceso a internet desde BC Server
- Probar "Test Connection"

### Error: "El documento no tiene PDF adjunto"
- Verificar que el documento tiene PDF en Continia
- Campo "PDF File" debe tener valor

### Error: "Timeout esperando respuesta"
- Aumentar "Timeout Seconds" en configuración
- Documento puede ser muy grande
- Red lenta hacia Azure

### Resultados incorrectos o baja confianza
- PDF de mala calidad (escaneado borroso)
- Formato de factura muy complejo
- Considerar entrenar modelo custom

### No encuentra resultados
- Verificar ortografía del texto buscado
- Intentar búsquedas más genéricas
- Verificar que el texto existe en el PDF

## 💰 Costos de Azure

### Nivel Gratuito (F0):
- 500 páginas/mes gratis
- Suficiente para pruebas

### Nivel Standard (S0):
- $1.50 por 1000 páginas
- Recomendado para producción
- Factura de 10 páginas ≈ $0.015

### Optimización:
- Los resultados NO se cachean (cada búsqueda = 1 análisis)
- Para múltiples búsquedas en el mismo documento, considerar implementar caché

## 📝 Objetos Incluidos

### Tables:
- 50100: OCR Azure AI Configuration
- 50101: OCR Search Results (Temporary)
- 50102: OCR Operation Log

### Pages:
- 50100: OCR Azure AI Configuration
- 50101: OCR Search Results
- 50102: OCR Document Finder
- 50103: OCR Operation Log
- 50104: OCR Result Detail FactBox
- 50105: OCR Log Statistics FactBox

### Codeunits:
- 50100: OCR Azure Doc Intelligence
- 50101: OCR Document Search

### Page Extensions:
- 50100: CDC Document OCR Ext

## 🤝 Soporte

Para problemas o mejoras, contactar al desarrollador o equipo de IT.

## 📄 Licencia

Uso interno de la empresa. Todos los derechos reservados.

---

**Versión**: 1.0.0.0  
**Fecha**: 2024  
**Desarrollado para**: Business Central On-Prem v26 + Continia Document Capture
