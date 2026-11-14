/*
===============================================================
03_scripts/bronze/ddl_bronze.sql
DDL: crear las tablas de la capa Bronze
===============================================================
Qué hace:
    Crea (o recrea) las seis tablas del esquema 'bronze', una por cada
    archivo CSV de origen. Los nombres siguen la convención
    <sistema_origen>_<entidad>. Los datos se guardan tal como vienen,
    sin limpieza; la limpieza se hace en la capa Silver.

Cuándo ejecutarlo:
    Después de init_database.sql y antes de cargar datos.

Nota:
    Si una tabla ya existe, se elimina y se vuelve a crear, por lo que
    se pierden sus datos. Hay que volver a cargarlos con load_bronze.
===============================================================
*/

USE DataWarehouse;
GO

-- ---------------------------------------------------------------
-- CRM: información de clientes (origen: cust_info.csv)
-- ---------------------------------------------------------------
IF OBJECT_ID(N'bronze.crm_cust_info', N'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO

CREATE TABLE bronze.crm_cust_info (
    cst_id             INT,            -- id numérico del cliente
    cst_key            NVARCHAR(50),   -- clave de negocio del cliente
    cst_firstname      NVARCHAR(50),   -- nombre
    cst_lastname       NVARCHAR(50),   -- apellido
    cst_marital_status NVARCHAR(50),   -- estado civil (código)
    cst_gndr           NVARCHAR(50),   -- género (código)
    cst_create_date    DATE            -- fecha de creación del registro
);
GO

-- ---------------------------------------------------------------
-- CRM: información de productos (origen: prd_info.csv)
-- ---------------------------------------------------------------
IF OBJECT_ID(N'bronze.crm_prd_info', N'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info (
    prd_id       INT,            -- id numérico del producto
    prd_key      NVARCHAR(50),   -- clave de negocio del producto
    prd_nm       NVARCHAR(50),   -- nombre del producto
    prd_cost     INT,            -- costo del producto
    prd_line     NVARCHAR(50),   -- línea de producto (código)
    prd_start_dt DATE,           -- inicio de vigencia
    prd_end_dt   DATE            -- fin de vigencia (vacío si sigue vigente)
);
GO

-- ---------------------------------------------------------------
-- CRM: detalle de ventas (origen: sales_details.csv)
-- ---------------------------------------------------------------
IF OBJECT_ID(N'bronze.crm_sales_details', N'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num  NVARCHAR(50),   -- número de orden
    sls_prd_key  NVARCHAR(50),   -- clave del producto vendido
    sls_cust_id  INT,            -- id del cliente
    sls_order_dt INT,            -- fecha de orden en formato YYYYMMDD (se convierte a DATE en Silver)
    sls_ship_dt  INT,            -- fecha de envío (YYYYMMDD)
    sls_due_dt   INT,            -- fecha de vencimiento (YYYYMMDD)
    sls_sales    INT,            -- monto de la venta
    sls_quantity INT,            -- cantidad vendida
    sls_price    INT             -- precio unitario
);
GO

-- ---------------------------------------------------------------
-- ERP: datos adicionales de clientes (origen: CUST_AZ12.csv)
-- ---------------------------------------------------------------
IF OBJECT_ID(N'bronze.erp_cust_az12', N'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO

CREATE TABLE bronze.erp_cust_az12 (
    cid   NVARCHAR(50),   -- id del cliente en el ERP
    bdate DATE,           -- fecha de nacimiento
    gen   NVARCHAR(50)    -- género
);
GO

-- ---------------------------------------------------------------
-- ERP: ubicación de los clientes (origen: LOC_A101.csv)
-- ---------------------------------------------------------------
IF OBJECT_ID(N'bronze.erp_loc_a101', N'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO

CREATE TABLE bronze.erp_loc_a101 (
    cid   NVARCHAR(50),   -- id del cliente en el ERP
    cntry NVARCHAR(50)    -- país
);
GO

-- ---------------------------------------------------------------
-- ERP: categorías de productos (origen: PX_CAT_G1V2.csv)
-- ---------------------------------------------------------------
IF OBJECT_ID(N'bronze.erp_px_cat_g1v2', N'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id          NVARCHAR(50),   -- id de la categoría
    cat         NVARCHAR(50),   -- categoría
    subcat      NVARCHAR(50),   -- subcategoría
    maintenance NVARCHAR(50)    -- indica si requiere mantenimiento (Yes/No)
);
GO