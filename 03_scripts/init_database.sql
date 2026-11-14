/*
===============================================================
03_scripts/init_database.sql
Crear base de datos y esquemas
===============================================================
Qué hace:
    Crea la base de datos 'DataWarehouse' y los tres esquemas de la
    arquitectura Medallion: bronze (datos originales), silver (datos
    limpios) y gold (datos para análisis). Si la base ya existe, la
    elimina y la vuelve a crear desde cero.

Cuándo ejecutarlo:
    Es el primer script del proyecto; todos los demás dependen de él.

ADVERTENCIA:
    Ejecutarlo ELIMINA la base 'DataWarehouse' completa con todos sus
    datos. Úselo con precaución.
===============================================================
*/

-- Se trabaja desde la base 'master' porque no se puede eliminar
-- una base de datos mientras se está conectado a ella.
USE master;
GO

-- Si 'DataWarehouse' ya existe, se cierra cualquier otra conexión
-- abierta (modo SINGLE_USER) y se elimina.
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Crear la base de datos del almacén de datos.
CREATE DATABASE DataWarehouse;
GO

-- Cambiar a la base recién creada para crear los esquemas dentro de ella.
USE DataWarehouse;
GO

-- Capa Bronze: datos originales, tal como vienen de los CSV.
CREATE SCHEMA bronze;
GO

-- Capa Silver: datos limpios y transformados.
CREATE SCHEMA silver;
GO

-- Capa Gold: modelo analítico (dimensiones y hechos).
CREATE SCHEMA gold;
GO