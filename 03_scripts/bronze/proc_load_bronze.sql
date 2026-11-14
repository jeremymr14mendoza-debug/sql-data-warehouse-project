/*
===============================================================
03_scripts/bronze/proc_load_bronze.sql
Procedimiento almacenado: bronze.load_bronze
===============================================================
Qué hace:
    Carga los seis archivos CSV (CRM y ERP) en las tablas del esquema
    'bronze'. Para cada tabla hace TRUNCATE (vacía la tabla) y luego
    BULK INSERT (carga completa desde el archivo). Muestra mensajes de
    avance, el tiempo de cada carga y captura los errores.

Parámetro:
    @base_path  Ruta de la carpeta 01_datasets, terminada en '\',
                vista desde el equipo donde corre SQL Server. El servicio
                de SQL Server debe tener permiso de lectura sobre ella.

Uso:
    EXEC bronze.load_bronze
         @base_path = N'C:\sql\sql-data-warehouse-project\01_datasets\';

Cuándo ejecutarlo:
    Después de crear las tablas con ddl_bronze.sql.
===============================================================
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze
    @base_path NVARCHAR(260)
AS
BEGIN
    -- Variables para medir cuánto tarda cada tabla y la carga completa.
    DECLARE @start_time DATETIME, @end_time DATETIME,
            @batch_start_time DATETIME, @batch_end_time DATETIME;

    -- Variables de trabajo: la sentencia SQL dinámica, la tabla
    -- destino y el archivo de origen de la carga actual.
    DECLARE @sql NVARCHAR(MAX), @tabla NVARCHAR(100), @archivo NVARCHAR(200);

    -- Lista de cargas: orden, tabla destino y archivo CSV (relativo a @base_path).
    DECLARE @cargas TABLE (orden INT, tabla NVARCHAR(100), archivo NVARCHAR(200));
    INSERT INTO @cargas VALUES
        (1, N'bronze.crm_cust_info',     N'source_crm\cust_info.csv'),
        (2, N'bronze.crm_prd_info',      N'source_crm\prd_info.csv'),
        (3, N'bronze.crm_sales_details', N'source_crm\sales_details.csv'),
        (4, N'bronze.erp_cust_az12',     N'source_erp\CUST_AZ12.csv'),
        (5, N'bronze.erp_loc_a101',      N'source_erp\LOC_A101.csv'),
        (6, N'bronze.erp_px_cat_g1v2',   N'source_erp\PX_CAT_G1V2.csv');

    -- Si algo falla dentro del TRY, la ejecución salta al CATCH.
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT N'================================================';
        PRINT N'Cargando la capa Bronze';
        PRINT N'================================================';

        -- Recorre la lista de cargas, una por una, en orden.
        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT tabla, archivo FROM @cargas ORDER BY orden;
        OPEN cur;
        FETCH NEXT FROM cur INTO @tabla, @archivo;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @start_time = GETDATE();

            -- 1) Vaciar la tabla para no duplicar datos en cada carga.
            PRINT N'>> Truncando: ' + @tabla;
            SET @sql = N'TRUNCATE TABLE ' + @tabla;
            EXEC (@sql);

            -- 2) Cargar el CSV. FIRSTROW = 2 salta el encabezado;
            --    FIELDTERMINATOR = ',' separa las columnas;
            --    TABLOCK bloquea la tabla durante la carga (más rápido).
            --    BULK INSERT no acepta variables en la ruta, por eso
            --    se arma la sentencia como texto y se ejecuta con EXEC.
            PRINT N'>> Insertando datos en: ' + @tabla;
            SET @sql = N'BULK INSERT ' + @tabla
                     + N' FROM ''' + @base_path + @archivo + N''''
                     + N' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', TABLOCK)';
            EXEC (@sql);

            SET @end_time = GETDATE();
            PRINT N'>> Duración: '
                  + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + N' s';
            PRINT N'>> ------------';

            FETCH NEXT FROM cur INTO @tabla, @archivo;
        END;

        CLOSE cur;
        DEALLOCATE cur;

        SET @batch_end_time = GETDATE();
        PRINT N'================================================';
        PRINT N'Carga de Bronze completada. Duración total: '
              + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + N' s';
        PRINT N'================================================';
    END TRY
    BEGIN CATCH
        -- Si hubo un error, se muestra qué pasó en lugar de fallar en silencio.
        PRINT N'================================================';
        PRINT N'ERROR durante la carga de la capa Bronze';
        PRINT N'Mensaje: ' + ERROR_MESSAGE();
        PRINT N'Número: '  + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT N'Estado: '  + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT N'================================================';
    END CATCH;
END;
GO