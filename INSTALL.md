# 🚀 Guía Rápida de Instalación - OCR Document Finder

## Paso 1: Azure (10 minutos)

1. **Ir a**: https://portal.azure.com
2. **Crear recurso** → Buscar "Form Recognizer" o "Document Intelligence"
3. **Configurar**:
   ```
   Nombre: bc-ocr-finder
   Región: West Europe (o la más cercana)
   Plan: F0 (gratis para pruebas) o S0 (producción)
   ```
4. **Crear** y esperar 2-3 minutos
5. **Ir a recurso** → "Keys and Endpoint"
6. **Copiar**:
   - ✅ Endpoint (ej: https://bc-ocr-finder.cognitiveservices.azure.com)
   - ✅ Key 1

## Paso 2: Business Central (5 minutos)

### A. Instalación de la App

1. **Abrir** Visual Studio Code
2. **Abrir carpeta** OCRDocumentFinder
3. **Modificar** `app.json`:
   ```json
   {
     "id": "GENERAR-NUEVO-GUID-AQUÍ",  // Cambiar por GUID único
     "publisher": "TuEmpresa",          // Cambiar por tu empresa
     ...
   }
   ```
4. **Compilar**: Presionar `F5` o `Ctrl+Shift+P` → "AL: Publish"

### B. Configuración

1. **En Business Central**, buscar: `Azure AI Configuration`
2. **Completar**:
   ```
   Endpoint URL: [pegar el endpoint de Azure]
   API Key: [pegar la Key 1 de Azure]
   Model ID: prebuilt-invoice (dejar por defecto)
   Enabled: ✓ Activar
   ```
3. **Test Connection** → Debe decir "Conexión exitosa"

## Paso 3: Primera Búsqueda (2 minutos)

1. **Buscar**: `OCR Document Finder`
2. **Seleccionar** un documento de Continia (con PDF)
3. **Buscar**: Ej. "TORNILLO" o algún código de producto
4. **Ver resultados** ✨

## ✅ Verificación Rápida

| Paso | Verificar | ✓ |
|------|-----------|---|
| 1 | Azure recurso creado | ☐ |
| 2 | Endpoint y Key copiados | ☐ |
| 3 | App instalada en BC | ☐ |
| 4 | Configuración completa | ☐ |
| 5 | Test Connection OK | ☐ |
| 6 | Primera búsqueda exitosa | ☐ |

## 🆘 Problemas Comunes

### "Error al conectar con Azure"
- ✅ Verificar Endpoint (sin "/" al final)
- ✅ Verificar API Key copiada correctamente
- ✅ Verificar conectividad a internet desde BC Server

### "Documento no tiene PDF adjunto"
- ✅ Verificar que el documento en Continia tiene PDF
- ✅ Calcular campos (F9) en la página del documento

### "Timeout esperando respuesta"
- ✅ Aumentar Timeout en configuración (120 → 180 segundos)
- ✅ Verificar tamaño del PDF (muy grande puede tardar)

## 📞 Soporte

- **Documentación completa**: Ver README.md
- **Logs**: Buscar "OCR Operation Log" en BC
- **Azure Portal**: https://portal.azure.com

---

**¡Listo! Ya puedes buscar líneas en tus facturas con OCR 🎉**
