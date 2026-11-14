/*
===============================================================
04_tests/quality_checks_bronze.sql
Validación de la capa Bronze: conteo de filas
===============================================================
Qué hace:
    Compara la cantidad de filas cargadas en cada tabla del esquema
    'bronze' con la cantidad de filas de datos de su archivo CSV
    (sin contar el encabezado). Si coinciden muestra 'OK'; si no,
    'REVISAR'.

Cuándo ejecutarlo:
    Después de ejecutar bronze.load_bronze.

Nota:
    Las cantidades esperadas salen de los CSV del ejercicio. Si los
    archivos cambian, hay que actualizar estos números.
===============================================================
*/

USE DataWarehouse;
GO

SELECT
    tabla,
    filas_cargadas,
    filas_esperadas,
    CASE WHEN filas_cargadas = filas_esperadas
         THEN N'OK' ELSE N'REVISAR' END AS resultado
FROM (
    -- CRM
    SELECT N'bronze.crm_cust_info'     AS tabla,
           (SELECT COUNT(*) FROM bronze.crm_cust_info)     AS filas_cargadas,
           18494 AS filas_esperadas
    UNION ALL
    SELECT N'bronze.crm_prd_info',
           (SELECT COUNT(*) FROM bronze.crm_prd_info),
           397
    UNION ALL
    SELECT N'bronze.crm_sales_details',
           (SELECT COUNT(*) FROM bronze.crm_sales_details),
           60398
    -- ERP
    UNION ALL
    SELECT N'bronze.erp_cust_az12',
           (SELECT COUNT(*) FROM bronze.erp_cust_az12),
           18484
    UNION ALL
    SELECT N'bronze.erp_loc_a101',
           (SELECT COUNT(*) FROM bronze.erp_loc_a101),
           18484
    UNION ALL
    SELECT N'bronze.erp_px_cat_g1v2',
           (SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2),
           37
) AS validacion;
GO