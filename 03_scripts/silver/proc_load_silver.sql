/*
===============================================================
03_scripts/silver/proc_load_silver.sql
Procedimiento almacenado: silver.load_silver
===============================================================
Qué hace:
    Carga las tablas del esquema 'silver' a partir de las del esquema
    'bronze', aplicando limpieza y transformaciones (ETL). Para cada
    tabla hace TRUNCATE y luego INSERT ... SELECT. Imprime el avance y
    el tiempo de cada tabla, y captura los errores.

Limpiezas principales:
    - Clientes: quita nulos y duplicados (se queda con el registro más
      reciente), recorta espacios y traduce códigos (M/F/S).
    - Productos: separa categoría y clave, rellena costos nulos con 0,
      traduce la línea y recalcula la fecha de fin de vigencia.
    - Ventas: convierte fechas inválidas en NULL y corrige montos y
      precios nulos o inconsistentes.
    - ERP: normaliza ids, fechas de nacimiento futuras, género y país.

Uso:
    EXEC silver.load_silver;

Cuándo ejecutarlo:
    Después de bronze.load_bronze y de crear las tablas con ddl_silver.sql.
===============================================================
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME,
            @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT N'================================================';
        PRINT N'Cargando la capa Silver';
        PRINT N'================================================';

        -- ---------------------------------------------------------
        -- CRM: clientes
        -- ---------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT N'>> Truncando: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;
        PRINT N'>> Insertando datos en: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
            cst_id, cst_key, cst_firstname, cst_lastname,
            cst_marital_status, cst_gndr, cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname),                       -- quita espacios sobrantes
            TRIM(cst_lastname),
            CASE UPPER(TRIM(cst_marital_status))       -- código -> descripción
                WHEN 'S' THEN 'Single'
                WHEN 'M' THEN 'Married'
                ELSE 'n/a'
            END,
            CASE UPPER(TRIM(cst_gndr))
                WHEN 'F' THEN 'Female'
                WHEN 'M' THEN 'Male'
                ELSE 'n/a'
            END,
            cst_create_date
        FROM (
            -- Numera los registros de cada cliente del más reciente al más
            -- antiguo; solo se conserva el número 1. Se descartan ids nulos.
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) AS t
        WHERE flag_last = 1;
        SET @end_time = GETDATE();
        PRINT N'>> Duración: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + N' s';
        PRINT N'>> ------------';

        -- ---------------------------------------------------------
        -- CRM: productos
        -- ---------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT N'>> Truncando: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;
        PRINT N'>> Insertando datos en: silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
            prd_id, cat_id, prd_key, prd_nm, prd_cost,
            prd_line, prd_start_dt, prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'),     -- categoría (coincide con erp_px_cat_g1v2.id)
            SUBSTRING(prd_key, 7, LEN(prd_key)),             -- clave del producto (coincide con las ventas)
            prd_nm,
            ISNULL(prd_cost, 0),                             -- costo nulo -> 0
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END,
            CAST(prd_start_dt AS DATE),
            -- La vigencia termina el día anterior al inicio de la siguiente
            -- versión del mismo producto (corrige fines anteriores al inicio).
            CAST(DATEADD(DAY, -1,
                 LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS DATE)
        FROM bronze.crm_prd_info;
        SET @end_time = GETDATE();
        PRINT N'>> Duración: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + N' s';
        PRINT N'>> ------------';

        -- ---------------------------------------------------------
        -- CRM: detalle de ventas
        -- ---------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT N'>> Truncando: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;
        PRINT N'>> Insertando datos en: silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num, sls_prd_key, sls_cust_id,
            sls_order_dt, sls_ship_dt, sls_due_dt,
            sls_sales, sls_quantity, sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            -- Fechas YYYYMMDD (entero) -> DATE; si son 0 o no tienen 8 dígitos -> NULL
            CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                 ELSE CAST(CAST(sls_order_dt AS NVARCHAR(8)) AS DATE) END,
            CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                 ELSE CAST(CAST(sls_ship_dt AS NVARCHAR(8)) AS DATE) END,
            CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                 ELSE CAST(CAST(sls_due_dt AS NVARCHAR(8)) AS DATE) END,
            -- Si el monto es nulo, <= 0 o no coincide con cantidad x precio,
            -- se recalcula como cantidad x precio.
            CASE WHEN sls_sales IS NULL OR sls_sales <= 0
                      OR sls_sales != sls_quantity * ABS(sls_price)
                 THEN sls_quantity * ABS(sls_price)
                 ELSE sls_sales END,
            sls_quantity,
            -- Si el precio es nulo o <= 0, se deriva del monto y la cantidad.
            CASE WHEN sls_price IS NULL OR sls_price <= 0
                 THEN sls_sales / NULLIF(sls_quantity, 0)
                 ELSE sls_price END
        FROM bronze.crm_sales_details;
        SET @end_time = GETDATE();
        PRINT N'>> Duración: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + N' s';
        PRINT N'>> ------------';

        -- ---------------------------------------------------------
        -- ERP: datos adicionales de clientes
        -- ---------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT N'>> Truncando: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;
        PRINT N'>> Insertando datos en: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
        SELECT
            -- Quita el prefijo 'NAS' para que coincida con cst_key del CRM
            CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) ELSE cid END,
            -- Fechas de nacimiento futuras no son válidas -> NULL
            CASE WHEN bdate > GETDATE() THEN NULL ELSE bdate END,
            CASE UPPER(TRIM(gen))
                WHEN 'F' THEN 'Female'
                WHEN 'FEMALE' THEN 'Female'
                WHEN 'M' THEN 'Male'
                WHEN 'MALE' THEN 'Male'
                ELSE 'n/a'
            END
        FROM bronze.erp_cust_az12;
        SET @end_time = GETDATE();
        PRINT N'>> Duración: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + N' s';
        PRINT N'>> ------------';

        -- ---------------------------------------------------------
        -- ERP: ubicación de clientes
        -- ---------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT N'>> Truncando: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;
        PRINT N'>> Insertando datos en: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101 (cid, cntry)
        SELECT
            REPLACE(cid, '-', ''),                           -- quita guiones para unir con el CRM
            CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                 WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                 ELSE TRIM(cntry)
            END
        FROM bronze.erp_loc_a101;
        SET @end_time = GETDATE();
        PRINT N'>> Duración: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + N' s';
        PRINT N'>> ------------';

        -- ---------------------------------------------------------
        -- ERP: categorías de productos (se copian sin cambios)
        -- ---------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT N'>> Truncando: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        PRINT N'>> Insertando datos en: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
        SELECT id, cat, subcat, maintenance
        FROM bronze.erp_px_cat_g1v2;
        SET @end_time = GETDATE();
        PRINT N'>> Duración: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + N' s';
        PRINT N'>> ------------';

        SET @batch_end_time = GETDATE();
        PRINT N'================================================';
        PRINT N'Carga de Silver completada. Duración total: '
              + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + N' s';
        PRINT N'================================================';
    END TRY
    BEGIN CATCH
        PRINT N'================================================';
        PRINT N'ERROR durante la carga de la capa Silver';
        PRINT N'Mensaje: ' + ERROR_MESSAGE();
        PRINT N'Número: '  + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT N'Estado: '  + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT N'================================================';
    END CATCH;
END;
GO