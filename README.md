<!--
README.md
Portada del proyecto: explica qué es, qué requisitos cumple, cómo está
organizada la arquitectura Medallion y cómo está estructurado el repositorio.
-->

# SQL Data Warehouse Project

Almacén de datos moderno en **SQL Server** con arquitectura Medallion (Bronze, Silver y Gold).
Consolida información de ventas de dos sistemas de origen (**CRM** y **ERP**, archivos CSV)
para generar reportes analíticos y apoyar la toma de decisiones.

Curso ISW-623 · Clase 09_02 · Arquitectura Medallion · Ejercicio 07 - ETL Datawarehouse Medallion

## Requisitos

- Importar información de dos sistemas de origen (ERP y CRM) mediante archivos CSV.
- Limpiar y resolver problemas de calidad de datos antes del análisis.
- Integrar ambas fuentes en un único modelo de datos orientado a consultas analíticas.
- Trabajar solo con el conjunto de datos más reciente (sin historial).
- Documentar el modelo para negocio y equipos de análisis.

## Arquitectura

| Capa | Esquema | Contenido |
| --- | --- | --- |
| Bronze | `bronze` | Datos originales, sin modificar (carga con `BULK INSERT`) |
| Silver | `silver` | Datos limpios y transformados |
| Gold | `gold` | Modelo analítico (dimensiones y hechos) |

## Estructura del repositorio

```
sql-data-warehouse-project/
├── 00_setup/        Guía de configuración
├── 01_datasets/     Seis archivos de origen (source_crm y source_erp)
├── 02_docs/         Convenciones de nombres, diagramas y notas
├── 03_scripts/
│   ├── init_database.sql   Crea la base de datos y los esquemas (ejecutar primero)
│   ├── bronze/             Carga de archivos sin procesar
│   ├── silver/             Limpieza y preparación
│   └── gold/               Tablas para el análisis
└── 04_tests/        Verificación de calidad de los datos
```

## Convenciones

Ver [02_docs/convenciones_nomenclatura.md](02_docs/convenciones_nomenclatura.md).