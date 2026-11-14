<!--
00_setup/README.md
Guía de configuración: explica qué hay que instalar y en qué orden
ejecutar los scripts para dejar el almacén de datos funcionando.
-->

# Guía de configuración

## Requisitos previos

- **SQL Server** (edición Developer o Express).
- **SQL Server Management Studio (SSMS)**, o la extensión SQL Server (mssql) de VS Code, para ejecutar los scripts.
- **Git** y **GitHub Desktop** para clonar el repositorio.

## Pasos

1. Clonar este repositorio.
2. Ejecutar `03_scripts/init_database.sql`. Crea la base `DataWarehouse` y los esquemas `bronze`, `silver` y `gold`.
3. Ejecutar `03_scripts/bronze/ddl_bronze.sql`. Crea las tablas de la capa Bronze.
4. Ejecutar `03_scripts/bronze/proc_load_bronze.sql`. Crea el procedimiento `bronze.load_bronze`.
5. Cargar los datos, indicando la ruta de la carpeta `01_datasets` en tu equipo:

```sql
EXEC bronze.load_bronze @base_path = N'C:\ruta\sql-data-warehouse-project\01_datasets\';
```

6. Ejecutar `04_tests/quality_checks_bronze.sql` para verificar que los conteos de filas coinciden.

## Nota sobre la ruta de los archivos

`BULK INSERT` lee los archivos desde el equipo donde corre SQL Server, y el servicio de SQL Server necesita permiso de lectura sobre la carpeta. Si la carga falla con un error de acceso, mové `01_datasets` a una carpeta más simple, por ejemplo `C:\sql\01_datasets\`, y ajustá `@base_path`. La ruta debe terminar con `\`.