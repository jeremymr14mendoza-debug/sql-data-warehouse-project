/*
===============================================================
04_tests/quality_checks_silver.sql
Validación de la capa Silver
===============================================================
Qué hace:
    1) Compara las filas de cada tabla de silver con las esperadas.
    2) Busca los problemas de calidad que Silver debía corregir
       (duplicados, espacios, valores sin normalizar, fechas y montos
       inválidos). En el segundo resultado, 'filas_problema' debe ser 0.

Cuándo ejecutarlo:
    Después de ejecutar silver.load_silver.
===============================================================
*/

USE DataWarehouse;
GO

-- 1) Conteo de filas ---------------------------------------------------
-- crm_cust_info baja de 18494 a 18484: se eliminan 4 filas sin id y 6 duplicados.
SELECT
    tabla, filas_cargadas, filas_esperadas,
    CASE WHEN filas_cargadas = filas_esperadas THEN N'OK' ELSE N'REVISAR' END AS resultado
FROM (
    SELECT N'silver.crm_cust_info' AS tabla,
           (SELECT COUNT(*) FROM silver.crm_cust_info) AS filas_cargadas, 18484 AS filas_esperadas
    UNION ALL SELECT N'silver.crm_prd_info',      (SELECT COUNT(*) FROM silver.crm_prd_info),      397
    UNION ALL SELECT N'silver.crm_sales_details', (SELECT COUNT(*) FROM silver.crm_sales_details), 60398
    UNION ALL SELECT N'silver.erp_cust_az12',     (SELECT COUNT(*) FROM silver.erp_cust_az12),     18484
    UNION ALL SELECT N'silver.erp_loc_a101',      (SELECT COUNT(*) FROM silver.erp_loc_a101),      18484
    UNION ALL SELECT N'silver.erp_px_cat_g1v2',   (SELECT COUNT(*) FROM silver.erp_px_cat_g1v2),   37
) AS conteo;
GO

-- 2) Calidad de datos (se espera 0 filas con problema en cada prueba) ----
SELECT
    prueba, filas_problema,
    CASE WHEN filas_problema = 0 THEN N'OK' ELSE N'REVISAR' END AS resultado
FROM (
    SELECT N'cust_info: id nulo o duplicado' AS prueba,
           (SELECT COUNT(*) FROM (SELECT cst_id FROM silver.crm_cust_info
                                  GROUP BY cst_id HAVING COUNT(*) > 1 OR cst_id IS NULL) d) AS filas_problema
    UNION ALL
    SELECT N'cust_info: espacios sobrantes en nombres',
           (SELECT COUNT(*) FROM silver.crm_cust_info
            WHERE cst_firstname != TRIM(cst_firstname) OR cst_lastname != TRIM(cst_lastname))
    UNION ALL
    SELECT N'cust_info: género o estado civil sin normalizar',
           (SELECT COUNT(*) FROM silver.crm_cust_info
            WHERE cst_gndr NOT IN (N'Male', N'Female', N'n/a')
               OR cst_marital_status NOT IN (N'Single', N'Married', N'n/a'))
    UNION ALL
    SELECT N'prd_info: fecha fin anterior al inicio',
           (SELECT COUNT(*) FROM silver.crm_prd_info WHERE prd_end_dt < prd_start_dt)
    UNION ALL
    SELECT N'prd_info: costo nulo o negativo',
           (SELECT COUNT(*) FROM silver.crm_prd_info WHERE prd_cost IS NULL OR prd_cost < 0)
    UNION ALL
    SELECT N'sales: fecha de orden posterior al envío o vencimiento',
           (SELECT COUNT(*) FROM silver.crm_sales_details
            WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt)
    UNION ALL
    SELECT N'sales: monto o precio nulo o <= 0',
           (SELECT COUNT(*) FROM silver.crm_sales_details
            WHERE sls_sales IS NULL OR sls_price IS NULL OR sls_sales <= 0 OR sls_price <= 0)
    UNION ALL
    SELECT N'sales: monto distinto de cantidad x precio',
           (SELECT COUNT(*) FROM silver.crm_sales_details
            WHERE sls_sales != sls_quantity * sls_price)
    UNION ALL
    SELECT N'az12: fecha de nacimiento futura',
           (SELECT COUNT(*) FROM silver.erp_cust_az12 WHERE bdate > GETDATE())
    UNION ALL
    SELECT N'az12: género sin normalizar',
           (SELECT COUNT(*) FROM silver.erp_cust_az12 WHERE gen NOT IN (N'Male', N'Female', N'n/a'))
    UNION ALL
    SELECT N'loc_a101: país sin normalizar',
           (SELECT COUNT(*) FROM silver.erp_loc_a101
            WHERE cntry IN (N'DE', N'US', N'USA') OR cntry != TRIM(cntry))
) AS calidad;
GO