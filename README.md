# fiorisap

Servicio de archivado para DVR en Windows.

## Objetivo
Cuando el DVR llena su almacenamiento, suele sobrescribir o borrar videos antiguos. Este proyecto agrega un proceso externo para:

1. Mover videos antiguos a un dispositivo externo.
2. Ejecutarse solo una vez por día (idealmente a medianoche).
3. Registrar en log todo lo que se copió/movió.
4. Informar en log cuando una copia falla.

## Scripts

- `scripts/Archive-DvrVideos.ps1`:
  - Mueve archivos viejos desde una carpeta de grabación del DVR a un destino externo.
  - Mantiene la estructura de carpetas.
  - Guarda estado para evitar más de una ejecución efectiva por día.
  - Escribe log con éxitos y errores.

- `scripts/Register-DvrArchiveTask.ps1`:
  - Crea/actualiza una tarea de Windows Task Scheduler.
  - Ejecuta el archivado diario a las 00:00 con cuenta `SYSTEM`.

## Ejemplo de uso

### 1) Ejecutar manualmente (prueba)

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\scripts\Archive-DvrVideos.ps1 `
  -SourcePath "D:\DVR\Recordings" `
  -DestinationPath "E:\DVR-Backup" `
  -LogPath "C:\DvrArchive\logs\dvr-archive.log" `
  -StatePath "C:\DvrArchive\state\archive-state.json" `
  -MinFileAgeMinutes 180
```

### 2) Simulación sin mover archivos

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\scripts\Archive-DvrVideos.ps1 `
  -SourcePath "D:\DVR\Recordings" `
  -DestinationPath "E:\DVR-Backup" `
  -WhatIf
```

### 3) Registrar tarea diaria a medianoche

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\scripts\Register-DvrArchiveTask.ps1 `
  -ScriptPath "C:\Ruta\scripts\Archive-DvrVideos.ps1" `
  -SourcePath "D:\DVR\Recordings" `
  -DestinationPath "E:\DVR-Backup" `
  -TaskName "DVR-Video-Archive"
```

## Códigos de salida del archivado

- `0`: Éxito (o nada que mover).
- `1`: Error general no controlado.
- `2`: Ruta origen inválida/no disponible.
- `3`: Terminó con al menos un archivo fallido.

## Recomendaciones operativas

- Usar una unidad externa confiable con espacio suficiente.
- Validar permisos de lectura/escritura para la cuenta de la tarea (`SYSTEM` o una cuenta de servicio).
- Verificar periódicamente el archivo de log.
- Configurar monitoreo adicional sobre eventos de error (código `3` o líneas `[ERROR]`).
