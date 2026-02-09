# Arquitectura Técnica - OCR Document Finder

## Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                      Business Central On-Prem v26                │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐         ┌──────────────────┐             │
│  │  User Interface  │◄────────┤   Continia CDC   │             │
│  │   (Pages)        │         │   Documents      │             │
│  └────────┬─────────┘         └──────────────────┘             │
│           │                                                      │
│           ▼                                                      │
│  ┌──────────────────┐         ┌──────────────────┐             │
│  │  Business Logic  │◄────────┤   Configuration  │             │
│  │   (Codeunits)    │         │   (Table 80100)  │             │
│  └────────┬─────────┘         └──────────────────┘             │
│           │                                                      │
│           │                   ┌──────────────────┐             │
│           └──────────────────►│  Operation Log   │             │
│                               │  (Table 80102)   │             │
│                               └──────────────────┘             │
│                                                                  │
└───────────────────┬──────────────────────────────────────────────┘
                    │
                    │ HTTPS POST (PDF Binary)
                    │ Header: Ocp-Apim-Subscription-Key
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Cloud Services                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │       Azure AI Document Intelligence (Form Recognizer)   │   │
│  │                                                           │   │
│  │   ┌──────────────┐    ┌──────────────┐    ┌──────────┐ │   │
│  │   │ OCR Engine   │───►│ Layout Model │───►│ Invoice  │ │   │
│  │   │              │    │              │    │ Model    │ │   │
│  │   └──────────────┘    └──────────────┘    └──────────┘ │   │
│  │                                                           │   │
│  │   Output: JSON with structured invoice data              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Flujo de Datos

### 1. Inicio de Búsqueda
```
Usuario → OCR Document Finder (Page 50102)
       → Selecciona Documento CDC
       → Ingresa texto de búsqueda
       → Click "Buscar con OCR"
```

### 2. Procesamiento
```
OCR Document Search (Codeunit 80101)
  │
  ├─► Extrae PDF de CDC Document
  │    └─► Campo "PDF File" (BLOB)
  │
  ├─► OCR Azure Doc Intelligence (Codeunit 80100)
  │    ├─► POST /formrecognizer/documentModels/prebuilt-invoice:analyze
  │    │    └─► Headers: Ocp-Apim-Subscription-Key, Content-Type: application/pdf
  │    │
  │    ├─► Response: Operation-Location header
  │    │
  │    └─► Polling GET (cada 2 segundos, max 60 intentos)
  │         └─► Espera status: "succeeded"
  │
  ├─► Parsea JSON Response
  │    └─► Extrae: analyzeResult.documents[0].fields.Items.valueArray
  │
  ├─► Busca coincidencias (case-insensitive)
  │    └─► En campos: Description, ProductCode, Quantity, UnitPrice, Amount
  │
  ├─► Genera resultados (Tabla Temporal 80101)
  │    └─► Con: Line No., Description, Amounts, Match Fields, Confidence
  │
  └─► Crea Log Entry (Tabla 80102)
       └─► Timestamp, Document, Search Text, Results, Time, User
```

### 3. Presentación de Resultados
```
OCR Search Results (Page 80101)
  │
  ├─► Lista de coincidencias
  │    └─► Colores según nivel de confianza
  │
  ├─► FactBox con detalle (Page 80104)
  │    └─► Info completa de línea seleccionada
  │
  └─► Acción: Export to Excel
       └─► Usa Excel Buffer para generar archivo
```

## Modelo de Datos

### Tabla 50100: OCR Azure AI Configuration
```
┌────────────────────┬──────────────┬─────────────────────────┐
│ Campo              │ Tipo         │ Descripción             │
├────────────────────┼──────────────┼─────────────────────────┤
│ Primary Key        │ Code[10]     │ Singleton ''            │
│ Endpoint URL       │ Text[250]    │ Azure endpoint          │
│ API Key            │ Text[100]    │ Azure key (masked)      │
│ Model ID           │ Text[50]     │ prebuilt-invoice        │
│ API Version        │ Text[20]     │ 2023-07-31              │
│ Timeout Seconds    │ Integer      │ 120 (default)           │
│ Enabled            │ Boolean      │ true/false              │
└────────────────────┴──────────────┴─────────────────────────┘
```

### Tabla 50101: OCR Search Results (Temporary)
```
┌────────────────────┬──────────────┬─────────────────────────┐
│ Campo              │ Tipo         │ Descripción             │
├────────────────────┼──────────────┼─────────────────────────┤
│ Entry No.          │ Integer      │ AutoIncrement PK        │
│ Line No.           │ Integer      │ Nº línea en documento   │
│ Description        │ Text[250]    │ Descripción del item    │
│ Product Code       │ Text[50]     │ Código producto         │
│ Quantity           │ Text[50]     │ Cantidad                │
│ Unit Price         │ Text[50]     │ Precio unitario         │
│ Amount             │ Text[50]     │ Importe total           │
│ Match Found In     │ Text[100]    │ Campos con coincidencia │
│ Confidence Score   │ Decimal      │ 0.00 - 1.00            │
│ Full Line Text     │ Text[2048]   │ Texto completo          │
└────────────────────┴──────────────┴─────────────────────────┘
```

### Tabla 50102: OCR Operation Log
```
┌─────────────────────┬──────────────┬──────────────────────────┐
│ Campo               │ Tipo         │ Descripción              │
├─────────────────────┼──────────────┼──────────────────────────┤
│ Entry No.           │ Integer      │ AutoIncrement PK         │
│ Document No.        │ Code[20]     │ CDC Document No.         │
│ Operation DateTime  │ DateTime     │ Timestamp                │
│ Operation Type      │ Option       │ Search/FullAnalysis/Test │
│ Search Text         │ Text[250]    │ Texto buscado            │
│ Results Found       │ Integer      │ # de coincidencias       │
│ Total Lines Analyzed│ Integer      │ Total líneas en doc      │
│ Status              │ Option       │ Success/Failed/Timeout   │
│ Error Message       │ Text[250]    │ Mensaje de error         │
│ Processing Time (ms)│ Integer      │ Tiempo en milisegundos   │
│ User ID             │ Code[50]     │ Usuario que ejecutó      │
└─────────────────────┴──────────────┴──────────────────────────┘
```

## Estructura JSON de Azure AI

### Request
```json
POST https://{endpoint}/formrecognizer/documentModels/prebuilt-invoice:analyze?api-version=2023-07-31
Headers:
  Ocp-Apim-Subscription-Key: {api-key}
  Content-Type: application/pdf
Body: {binary PDF data}
```

### Response (Polling)
```json
{
  "status": "succeeded",
  "createdDateTime": "2024-01-15T10:30:00Z",
  "lastUpdatedDateTime": "2024-01-15T10:30:15Z",
  "analyzeResult": {
    "apiVersion": "2023-07-31",
    "modelId": "prebuilt-invoice",
    "documents": [
      {
        "docType": "invoice",
        "fields": {
          "VendorName": { "content": "ACME Corp", "confidence": 0.98 },
          "InvoiceDate": { "content": "2024-01-15", "confidence": 0.95 },
          "Items": {
            "valueArray": [
              {
                "valueObject": {
                  "Description": { "content": "TORNILLO M8", "confidence": 0.97 },
                  "ProductCode": { "content": "TOR-M8-001", "confidence": 0.96 },
                  "Quantity": { "content": "100", "confidence": 0.99 },
                  "UnitPrice": { "content": "0.50", "confidence": 0.98 },
                  "Amount": { "content": "50.00", "confidence": 0.99 }
                }
              }
            ]
          }
        }
      }
    ]
  }
}
```

## Seguridad

### API Key Storage
- Almacenada en tabla con DataClassification: EndUserIdentifiableInformation
- Campo tipo ExtendedDatatype: Masked (oculta valor en UI)
- Solo visible para usuarios con permisos de configuración
- No se expone en logs

### HTTPS
- Todas las comunicaciones con Azure usan HTTPS
- Certificados verificados por HttpClient de BC

### Permisos en BC
```
Objeto              Permiso Necesario
──────────────────  ─────────────────────────
Configuration       Read + Write (Admin)
Search Execution    Execute (Users)
Results Viewing     Read (Users)
Operation Log       Read (Users), Delete (Admin)
```

## Performance

### Tiempos Estimados

| Escenario                    | Tiempo Aprox. |
|------------------------------|---------------|
| Documento 1-5 páginas        | 3-8 segundos  |
| Documento 10-20 páginas      | 10-20 segundos|
| Documento 50+ páginas        | 30-60 segundos|
| Timeout configurado          | 120 segundos  |

### Optimizaciones Implementadas

1. **Polling Inteligente**: Espera 2 segundos entre requests
2. **Progress Dialog**: Feedback visual al usuario
3. **Tabla Temporal**: Resultados en memoria (no disco)
4. **Logging Asíncrono**: No bloquea flujo principal
5. **Índices Optimizados**: En tablas de log para queries rápidos

### Limitaciones

- **No hay caché**: Cada búsqueda = nuevo análisis en Azure
- **No procesa en batch**: Un documento a la vez
- **Límite de Azure**: 
  - F0 tier: 500 páginas/mes
  - S0 tier: Sin límite (pago por uso)

## Testing

### Test Cases Críticos

1. ✅ Conexión Azure exitosa
2. ✅ Búsqueda con resultados
3. ✅ Búsqueda sin resultados
4. ✅ Timeout (documento muy grande)
5. ✅ Error de conexión
6. ✅ PDF corrupto
7. ✅ Documento sin PDF
8. ✅ Búsqueda case-insensitive
9. ✅ Exportación a Excel
10. ✅ Log correcto de operaciones

### Ambientes de Testing

- **Sandbox**: Desarrollo y pruebas funcionales
- **Pre-prod**: Testing de integración con datos reales
- **Producción**: Uso final

## Mantenimiento

### Logs a Revisar

1. **OCR Operation Log**: Todas las operaciones
2. **Event Log BC**: Errores de runtime
3. **Azure Portal**: Uso de API, errores de servicio

### Limpieza Recomendada

```al
// Ejecutar mensualmente
DELETE FROM "OCR Operation Log" 
WHERE "Operation DateTime" < CALCDATE('<-3M>', TODAY)
```

### Monitoreo

- Tasa de éxito de búsquedas (>95% esperado)
- Tiempo promedio de respuesta (<15 seg esperado)
- Errores recurrentes de Azure
- Uso mensual de páginas en Azure

## Roadmap Futuro

### Mejoras Planificadas (v1.1)

- [ ] Caché de resultados por documento
- [ ] Procesamiento batch de múltiples documentos
- [ ] Integración con modelos custom entrenados
- [ ] Búsqueda por expresiones regulares
- [ ] Vista previa del PDF con highlights
- [ ] API REST para integración externa

### Consideraciones Técnicas

- Migrar a .NET HttpClient para mejor performance
- Implementar queue de procesamiento con Job Queue
- Cache distribuido con Redis (si BC Cloud)
- Webhooks para notificaciones asíncronas

---

**Versión del Documento**: 1.0  
**Última Actualización**: 2024  
**Autor**: Equipo de Desarrollo BC
