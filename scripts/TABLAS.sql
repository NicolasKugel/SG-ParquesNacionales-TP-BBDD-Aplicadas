IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'TPBDG5')
BEGIN
    CREATE DATABASE TPBDG5;
END

GO

USE TPBDG5;

GO

CREATE TABLE Parque (
  id int PRIMARY KEY,
  codigo varchar(50) NOT NULL UNIQUE, -- Para identificar el parque de manera única (en la importación de datos)
  nombre varchar(255) NOT NULL,
  ubicacion varchar(255) NOT NULL,
  precio_entrada decimal NOT NULL,
  superficie_ha decimal(12,2) NOT NULL,
  tipo_parque char(2) NOT NULL,
);

CREATE TABLE TipoVisitante (
  id int PRIMARY KEY,
  descripcion varchar(255),
  descuento int,
);

CREATE TABLE Venta (
  id int PRIMARY KEY,
  moneda_id int NOT NULL,
  punto_venta int NOT NULL,
  numero int NOT NULL,
  fecha datetime2 NOT NULL,
  forma_pago varchar(255) NOT NULL,
  total decimal(18,2) NOT NULL,
);

CREATE TABLE Moneda (
    id int PRIMARY KEY,
    descripcion varchar(100),
    simbolo varchar(4) NOT NULL,
    cotizacion decimal NOT NULL,
);

CREATE TABLE Atraccion (
  id int PRIMARY KEY,
  nombre varchar(100) NOT NULL,
  descripcion varchar(255) NULL,
  duracion int NOT NULL,
  cupo_maximo int NOT NULL,
  costo decimal(18,2) NOT NULL,
  parque_id int NOT NULL,
);

CREATE TABLE LineaVenta (
  id int PRIMARY KEY,
  cantidad int NOT NULL,
  precio_unitario decimal(18,2) NOT NULL,
  fecha_de_acceso datetime2 NOT NULL,
  subtotal decimal(18,2) NOT NULL,
  venta_id int NOT NULL,
  visitante_id int NOT NULL,
  parque_id int NOT NULL,
  atraccion_id int NULL,
);

CREATE TABLE Visitante (
  id int PRIMARY KEY,
  nombre varchar(255) NOT NULL,
  apellido varchar(255) NOT NULL,
  dni varchar(255) UNIQUE NOT NULL,
  tipo_visitante_id int NOT NULL,
);

CREATE TABLE Guia (
  id int PRIMARY KEY,
  nombre varchar(255) NOT NULL,
  apellido varchar(255) NOT NULL,
  dni varchar(255) UNIQUE NOT NULL,
  titulo varchar(255) NULL,
  tipo_habilitacion varchar(255) NULL,
  especialidad varchar(255) NOT NULL,
  fecha_vigencia datetime2 NOT NULL,
);

CREATE TABLE AtraccionGuia (
  id int PRIMARY KEY,
  fecha_asignacion datetime2 NOT NULL,
  turno varchar(255) NOT NULL,
  guia_id int NOT NULL,
  atraccion_id int NOT NULL,
);

CREATE TABLE GuardaParque (
  id int PRIMARY KEY,
  nombre varchar(255) NOT NULL,
  apellido varchar(255) NOT NULL,
  dni varchar(255) NOT NULL UNIQUE,
  estado int NOT NULL -- 1: Activo, 0: Inactivo
);

CREATE TABLE AsignacionGuardaParque (
  id int PRIMARY KEY,
  fecha_inicio datetime2 NOT NULL,
  fecha_fin datetime2 NULL,
  motivo_egreso varchar(255) NULL,
  guarda_parque_id int NOT NULL,
  parque_id int NOT NULL,
);

CREATE TABLE Empresa (
  id int PRIMARY KEY,
  razon_social varchar(255) NOT NULL,
  cuit varchar(255) NOT NULL UNIQUE,
  tipo_actividad varchar(255) NOT NULL,
);

CREATE TABLE Concesion (
  id int PRIMARY KEY,
  fecha_inicio date NOT NULL,
  fecha_fin date NOT NULL,
  canon_mensual decimal(18,2) NOT NULL,
  empresa_id int NOT NULL,
  parque_id int NOT NULL,
);

CREATE TABLE PagoConcesion (
  id int PRIMARY KEY,
  fecha_pago datetime2 NULL, -- Día en que se realizó el pago
  periodo date NOT NULL, -- Período de la concesión a pagar
  estado varchar(255) NOT NULL,
  total decimal(18,2) NOT NULL,
  concesion_id int NOT NULL,
);

ALTER TABLE Venta ADD FOREIGN KEY (moneda_id) REFERENCES Moneda (id);

ALTER TABLE LineaVenta ADD FOREIGN KEY (venta_id) REFERENCES Venta (id);
ALTER TABLE LineaVenta ADD FOREIGN KEY (visitante_id) REFERENCES Visitante (id);
ALTER TABLE LineaVenta ADD FOREIGN KEY (parque_id) REFERENCES Parque (id);
ALTER TABLE LineaVenta ADD FOREIGN KEY (atraccion_id) REFERENCES Atraccion (id);

ALTER TABLE Atraccion ADD FOREIGN KEY (parque_id) REFERENCES Parque (id);

ALTER TABLE AtraccionGuia ADD FOREIGN KEY (atraccion_id) REFERENCES Atraccion (id);
ALTER TABLE AtraccionGuia ADD FOREIGN KEY (guia_id) REFERENCES Guia (id);

ALTER TABLE Visitante ADD FOREIGN KEY (tipo_visitante_id) REFERENCES TipoVisitante (id);

ALTER TABLE AsignacionGuardaParque ADD FOREIGN KEY (guarda_parque_id) REFERENCES GuardaParque (id);
ALTER TABLE AsignacionGuardaParque ADD FOREIGN KEY (parque_id) REFERENCES Parque (id);

ALTER TABLE Concesion ADD FOREIGN KEY (empresa_id) REFERENCES Empresa (id);
ALTER TABLE Concesion ADD FOREIGN KEY (parque_id) REFERENCES Parque (id);

ALTER TABLE PagoConcesion ADD FOREIGN KEY (concesion_id) REFERENCES Concesion (id);
