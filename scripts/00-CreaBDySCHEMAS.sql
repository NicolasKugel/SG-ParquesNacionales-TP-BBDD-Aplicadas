/*******************************************************************************
                       UNIVERSIDAD NACIONAL DE LA MATANZA
Integrantes: [Nicolás Kugel, Facundo Gargiulo, Valentin Martinez]
Descripción:  Creacion de Base de datos y Schemas
*******************************************************************************/
USE master;
GO

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

CREATE SCHEMA Personal;
GO
CREATE SCHEMA Concesiones;
GO
CREATE SCHEMA Parques;
GO
CREATE SCHEMA Ventas;
GO
CREATE SCHEMA Importacion;
GO
