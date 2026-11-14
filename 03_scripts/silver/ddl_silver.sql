/*
===============================================================
03_scripts/silver/ddl_silver.sql
DDL: crear las tablas de la capa Silver
===============================================================
Qué hace:
    Crea (o recrea) las seis tablas del esquema 'silver', con los
    mismos nombres que en Bronze. Guardan los datos ya limpios. Cada
    tabla agrega la columna técnica dwh_create_date (convención dwh_),
    que registra cuándo se cargó el registro.

Cuándo ejecutarlo:
    Después de cargar Bronze y antes de ejecutar silver.load_silver.

Nota:
    Si una tabla ya existe, se elimina y se recrea (se pierden sus datos).
===============================================================
*/

USE DataWarehouse;
GO

-- CRM: clientes (limpios y sin duplicados)
IF OBJECT_ID(N'silver.crm_cust_info', N'U') IS NOT NULL DROP TABLE silver.crm_cust_info;
GO
CREATE TABLE silver.crm_cust_info (
    cst_id             INT,
    cst_key            NVARCHAR(50),
    cst_firstname      NVARCHAR(50),
    cst_lastname       NVARCHAR(50),
    cst_marital_status NVARCHAR(50),   -- Single / Married / n/a
    cst_gndr           NVARCHAR(50),   -- Female / Male / n/a
    cst_create_date    DATE,
    dwh_create_date    DATETIME2 DEFAULT GETDATE()   -- columna técnica
);
GO

-- CRM: productos (cat_id separado de prd_key y fechas de vigencia corregidas)
IF OBJECT_ID(N'silver.crm_prd_info', N'U') IS NOT NULL DROP TABLE silver.crm_prd_info;
GO
CREATE TABLE silver.crm_prd_info (
    prd_id          INT,
    cat_id          NVARCHAR(50),      -- categoría, sale de la clave original
    prd_key         NVARCHAR(50),      -- clave del producto sin el prefijo de categoría
    prd_nm          NVARCHAR(50),
    prd_cost        INT,
    prd_line        NVARCHAR(50),      -- Mountain / Road / Other Sales / Touring / n/a
    prd_start_dt    DATE,
    prd_end_dt      DATE,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- CRM: detalle de ventas (fechas como DATE y montos corregidos)
IF OBJECT_ID(N'silver.crm_sales_details', N'U') IS NOT NULL DROP TABLE silver.crm_sales_details;
GO
CREATE TABLE silver.crm_sales_details (
    sls_ord_num     NVARCHAR(50),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    DATE,
    sls_ship_dt     DATE,
    sls_due_dt      DATE,
    sls_sales       INT,
    sls_quantity    INT,
    sls_price       INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- ERP: datos adicionales de clientes (cid normalizado)
IF OBJECT_ID(N'silver.erp_cust_az12', N'U') IS NOT NULL DROP TABLE silver.erp_cust_az12;
GO
CREATE TABLE silver.erp_cust_az12 (
    cid             NVARCHAR(50),
    bdate           DATE,
    gen             NVARCHAR(50),      -- Female / Male / n/a
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- ERP: ubicación de clientes (cid sin guiones, país normalizado)
IF OBJECT_ID(N'silver.erp_loc_a101', N'U') IS NOT NULL DROP TABLE silver.erp_loc_a101;
GO
CREATE TABLE silver.erp_loc_a101 (
    cid             NVARCHAR(50),
    cntry           NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- ERP: categorías de productos (sin cambios respecto a Bronze)
IF OBJECT_ID(N'silver.erp_px_cat_g1v2', N'U') IS NOT NULL DROP TABLE silver.erp_px_cat_g1v2;
GO
CREATE TABLE silver.erp_px_cat_g1v2 (
    id              NVARCHAR(50),
    cat             NVARCHAR(50),
    subcat          NVARCHAR(50),
    maintenance     NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO