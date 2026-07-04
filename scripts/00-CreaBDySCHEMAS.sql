/*******************************************************************************
                       UNIVERSIDAD NACIONAL DE LA MATANZA 
Integrantes: [Nicol�s Kugel, Facundo Gargiulo, Valentin Martinez]
Descripci�n:  Creacion de Base de datos y Schemas
*******************************************************************************/
USE master;
GO

-- Si la base existe, forzar SINGLE_USER para cortar conexiones activas antes de dropear
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'TPBDG5')
BEGIN
    ALTER DATABASE TPBDG5 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE TPBDG5;
END
GO

CREATE DATABASE TPBDG5;
GO

USE TPBDG5;
GO

-- Schemas: validar existencia antes de crear (CREATE SCHEMA debe ir solo en el batch, por eso SQL dinámico)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Personal')
    EXEC('CREATE SCHEMA Personal');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Concesiones')
    EXEC('CREATE SCHEMA Concesiones');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Parques')
    EXEC('CREATE SCHEMA Parques');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Ventas')
    EXEC('CREATE SCHEMA Ventas');
GO