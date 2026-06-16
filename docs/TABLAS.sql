IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'TPBDG5')
BEGIN
    CREATE DATABASE TPBDG5;
END

GO

USE TPBDG5;

GO

CREATE TABLE Parque (
  id int PRIMARY KEY,
  codigo varchar(255) UNIQUE, -- Para identificar el parque de manera única (en la importación de datos)
  nombre varchar(255),
  ubicacion varchar(255),
  precio_entrada decimal,
  superficie_ha decimal(12,2),
  tipo_parque char(2),
);

CREATE TABLE TipoVisitante (
  id int PRIMARY KEY,
  descripcion varchar(255),
  descuento int
);

CREATE TABLE Venta (
  id int PRIMARY KEY,
  moneda_id int,
  punto_venta int,
  numero int,
  fecha datetime2,
  forma_pago varchar(255),
  total decimal(18,2),

);

CREATE TABLE Moneda (
    id int PRIMARY KEY,
    descripcion varchar(100),
    simbolo varchar(4),
    cotizacion decimal,
);

CREATE TABLE Atraccion (
  id int PRIMARY KEY,
  parque_id int,
  nombre varchar(100),
  descripcion varchar(255),
  duracion int,
  cupo_maximo int,
  costo decimal(18,2),
);

CREATE TABLE LineaVenta (
  id int PRIMARY KEY,
  cantidad int,
  precio_unitario decimal(18,2),
  fecha_de_acceso datetime2,
  subtotal decimal(18,2)
  venta_id int,
  visitante_id int,
  parque_id int,
  atraccion_id int NULL,
);

CREATE TABLE Visitante (
  id int PRIMARY KEY,
  tipo_visitante_id int,
  nombre varchar(255),
  apellido varchar(255),
  dni varchar(255) UNIQUE
);

CREATE TABLE Guia (
  id int PRIMARY KEY,
  nombre varchar(255),
  apellido varchar(255),
  titulo varchar(255),
  tipo_habilitacion varchar(255),
  especialidad varchar(255),
  fecha_vigencia datetime2
);

CREATE TABLE AtraccionGuia (
  id int PRIMARY KEY,
  atraccion_id int,
  guia_id int,
  fecha_asignacion datetime2,
  turno varchar(255)
);

CREATE TABLE GuardaParque (
  id int PRIMARY KEY,
  nombre varchar(255),
  apellido varchar(255),
  dni varchar(255) UNIQUE,
  estado int
);

CREATE TABLE AsignacionGuardaParque (
  id int PRIMARY KEY,
  fecha_inicio datetime2,
  fecha_fin datetime2,
  motivo_egreso varchar(255),
  guarda_parque_id int,
  parque_id int,
);


CREATE TABLE Empresa (
  id int PRIMARY KEY,
  razon_social varchar(255),
  cuit varchar(255) UNIQUE,
  tipo_actividad varchar(255)
);

CREATE TABLE Concesion (
  id int PRIMARY KEY,
  fecha_inicio date,
  fecha_fin date,
  canon_mensual decimal(18,2),
  empresa_id int,
  parque_id int,
);

CREATE TABLE PagoConcesion (
  id int PRIMARY KEY,
  fecha_pago datetime2, -- Día en que se realizó el pago
  periodo date, -- Período de la concesión a pagar
  estado varchar,
  total decimal(18,2),
  concesion_id int,
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
