# fiorisap

Fiori sapui5 inicio.

## Reporte Z de auditoría SOST para SAP ECP

Se agregó un ejemplo práctico de reporte ABAP para auditoría de correos enviados en SAP ECP usando la misma fuente funcional de `SOST`:

- Programa: `abap/ZECP_AUDIT_SOST.prog.abap`
- Estrategia: lectura de `SOOS` (estado/envío) + `SOOD` (metadatos del documento)
- Filtros clave: fecha de creación, estado, usuario emisor, destinatario y asunto
- Salida: ALV con funciones estándar para exportación y análisis

> Nota: Los nombres de campos y estados pueden variar por release/support package. Validar en SE11 para tu sistema ECP antes de transportar a QA/PRD.
