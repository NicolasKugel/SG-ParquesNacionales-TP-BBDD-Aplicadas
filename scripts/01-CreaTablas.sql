USE master
GO
USE TPBDG5;
GO

--NO USAR TRIGGERS, NI DOUBLE, obviamente no cursores. 
--Atenti con la numeracion de archivos

CREATE TABLE Concesiones.Empresa (
  id int PRIMARY KEY,
  razon_social varchar(255) NOT NULL,
  cuit varchar(255) NOT NULL UNIQUE,
  tipo_actividad varchar(255) NOT NULL,
);

CREATE TABLE Concesiones.Concesion (
  id int PRIMARY KEY,
  fecha_inicio date NOT NULL,
  fecha_fin date NOT NULL,
  canon_mensual decimal(18,2) NOT NULL,
  empresa_id int NOT NULL,
  parque_id int NOT NULL,
);

CREATE TABLE Concesiones.PagoConcesion (
  id int PRIMARY KEY,
  fecha_pago date NULL, -- Día en que se realizó el pago
  periodo date NOT NULL, -- Período de la concesión a pagar
  estado varchar(255) NOT NULL,
  total decimal(18,2) NOT NULL,
  concesion_id int NOT NULL,
);

CREATE TABLE Parques.Entrada (
  id int PRIMARY KEY,
  precio_entrada decimal(18,2) NOT NULL,
  parque_id int NOT NULL,
  fecha_desde date NOT NULL
);

CREATE TABLE Parques.Atraccion (
  id int PRIMARY KEY,
  nombre varchar(255) NOT NULL,
  descripcion varchar(255) NULL,
  duracion time NOT NULL,
  cupo_maximo int NOT NULL,
  costo decimal(18,2) NOT NULL,
  parque_id int NOT NULL,
);

CREATE TABLE Parques.Parque (
  id int PRIMARY KEY,
  Codigo varchar(20) NOT NULL,
  nombre varchar(255) NOT NULL,
  ubicacion varchar(255) NOT NULL,
 -- precio_entrada decimal(18,2) NOT NULL, tenemos el precio en entrada ¬¬ 
  tipo_parque char(2) NOT NULL,
  superficie_ha decimal(12,2) NOT NULL,
);

CREATE TABLE Personal.GuardaParque (
  id int PRIMARY KEY,
  nombre varchar(255) NOT NULL,
  apellido varchar(255) NOT NULL,
  dni varchar(255) NOT NULL UNIQUE,
  estado int NOT NULL -- 1: Activo, 0: Inactivo
);

CREATE TABLE Personal.AsignacionGuardaParque (
  id int PRIMARY KEY,
  fecha_inicio date NOT NULL,
  fecha_fin date NULL,
  motivo_egreso varchar(255) NULL,
  guarda_parque_id int NOT NULL,
  parque_id int NOT NULL,
);

CREATE TABLE Personal.Guia (
  id int PRIMARY KEY,
  nombre varchar(255) NOT NULL,
  apellido varchar(255) NOT NULL,
  dni varchar(255) NOT NULL UNIQUE,
  titulo varchar(255) NULL,
  tipo_habilitacion varchar(255) NULL,
  especialidad varchar(255) NOT NULL,
);

CREATE TABLE Personal.AtraccionGuia (
  id int PRIMARY KEY,
  fecha_asignacion date NOT NULL,
  turno varchar(255) NOT NULL,
  atraccion_id int NOT NULL,
  guia_id int NOT NULL,
);

CREATE TABLE Ventas.Visitante (
  id int PRIMARY KEY,
  nombre varchar(255) NOT NULL,
  apellido varchar(255) NOT NULL,
  dni varchar(255) NOT NULL UNIQUE,
);

CREATE TABLE Ventas.TipoVisitante (
  id int PRIMARY KEY,
  descripcion varchar(255),
  descuento int,
);

CREATE TABLE Ventas.Venta (
  id int PRIMARY KEY,
  punto_venta int NOT NULL,
  numero int NOT NULL,
  fecha date NOT NULL,
  forma_pago varchar(255) NOT NULL,
  total decimal(18,2) NOT NULL,
  visitante_id int NOT NULL,
);

CREATE TABLE Ventas.LineaVenta (
  id int PRIMARY KEY,
  cantidad int NOT NULL,
  precio_unitario decimal(18,2) NOT NULL,
  subtotal decimal(18,2) NOT NULL,
  fecha_acceso date NOT NULL,
  venta_id int NOT NULL,
  tipo_visitante_id int NOT NULL,
  entrada_id int NULL,
  atraccion_id int NULL,
);



ALTER TABLE Concesiones.Concesion ADD CONSTRAINT FK_Concesion_Empresa

    FOREIGN KEY (empresa_id) REFERENCES Concesiones.Empresa (id);
 
ALTER TABLE Concesiones.Concesion ADD CONSTRAINT FK_Concesion_Parque

    FOREIGN KEY (parque_id) REFERENCES Parques.Parque (id);


ALTER TABLE Concesiones.PagoConcesion ADD CONSTRAINT FK_PagoConcesion_Concesion

    FOREIGN KEY (concesion_id) REFERENCES Concesiones.Concesion (id);
 
-- Personal.AsignacionGuardaParque

ALTER TABLE Personal.AsignacionGuardaParque ADD CONSTRAINT FK_AsignacionGuardaParque_GuardaParque

    FOREIGN KEY (guarda_parque_id) REFERENCES Personal.GuardaParque (id);
 
ALTER TABLE Personal.AsignacionGuardaParque ADD CONSTRAINT FK_AsignacionGuardaParque_Parque

    FOREIGN KEY (parque_id) REFERENCES Parques.Parque (id);
 
-- Ventas.Venta

ALTER TABLE Ventas.Venta ADD CONSTRAINT FK_Venta_Visitante

    FOREIGN KEY (visitante_id) REFERENCES Ventas.Visitante (id);
 
-- Parques.Entrada

ALTER TABLE Parques.Entrada ADD CONSTRAINT FK_Entrada_Parque

    FOREIGN KEY (parque_id) REFERENCES Parques.Parque (id);
 
-- Parques.Atraccion

ALTER TABLE Parques.Atraccion ADD CONSTRAINT FK_Atraccion_Parque

    FOREIGN KEY (parque_id) REFERENCES Parques.Parque (id);
 
-- Ventas.LineaVenta

ALTER TABLE Ventas.LineaVenta ADD CONSTRAINT FK_LineaVenta_Venta

    FOREIGN KEY (venta_id) REFERENCES Ventas.Venta (id);
 
ALTER TABLE Ventas.LineaVenta ADD CONSTRAINT FK_LineaVenta_TipoVisitante

    FOREIGN KEY (tipo_visitante_id) REFERENCES Ventas.TipoVisitante (id);
 
ALTER TABLE Ventas.LineaVenta ADD CONSTRAINT FK_LineaVenta_Entrada

    FOREIGN KEY (entrada_id) REFERENCES Parques.Entrada (id);
 
ALTER TABLE Ventas.LineaVenta ADD CONSTRAINT FK_LineaVenta_Atraccion

    FOREIGN KEY (atraccion_id) REFERENCES Parques.Atraccion (id);
 


ALTER TABLE Personal.AtraccionGuia ADD CONSTRAINT FK_AtraccionGuia_Atraccion

    FOREIGN KEY (atraccion_id) REFERENCES Parques.Atraccion (id);
 
ALTER TABLE Personal.AtraccionGuia ADD CONSTRAINT FK_AtraccionGuia_Guia

    FOREIGN KEY (guia_id) REFERENCES Personal.Guia (id);
 