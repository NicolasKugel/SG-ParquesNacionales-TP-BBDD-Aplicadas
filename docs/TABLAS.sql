IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'TPBDG5')
BEGIN
    CREATE DATABASE TPBDG5;
END

GO

USE TPBDG5;

GO
--Creacion de tablas y FK
--PARQUE NO VA CON VENTA
--PARQUE VA CON LINEA DE VENTA
-- VISITANTE -> LINEA DE VENTA <-- PARQUE 
--ATRACCION ESTA BIEN EN LINEA DE VENTA
--HACER YA LAS INSERTS 
CREATE TABLE Parque (
  id int PRIMARY KEY,
  nombre varchar(255),
  ubicacion varchar(255),
  precio_entrada decimal(18,2),--esta antes estaba en precioParque
  tipo_parque char(2),
  superficie_ha decimal(12,2),
  latitud decimal(11,8),
  longitud decimal(11,8),
  perimetro geography
);

CREATE TABLE TipoVisitante (
  id int PRIMARY KEY,
  descripcion varchar(255) --deberia de tener un descuento
  descuento decimal(5,2)
);

CREATE TABLE PrecioEntrada (
  id int PRIMARY KEY,
  parque_id int,
  tipo_visitante_id int,
 --sacamos precio de aca, lo ponemos en parque
  fecha_vigencia date
); 

CREATE TABLE Venta (
  id int IDENTITY(1,1) PRIMARY KEY,
  --parque_id int, --------/corregimos la logica para llevarlo a linea de venta y
  --tipo_vistante_id int, -/poder comprar entradas de parques distintos
  punto_venta int,
  numero int, -- deberia ser autoincremental ? por la logica de los doc de venta
  fecha datetime,--/NO, ya que esto va a hacer que no puedan existir 2 tickets
  forma_pago varchar(255),--/con el numero 1, como se espera en los documentos
  total decimal(18,2)--/ de venta
);

CREATE TABLE Atraccion (
  id int PRIMARY KEY,
  parque_id int,
  nombre varchar(255),
  tipo varchar(255),
  costo decimal(18,2),
  duracion_min int,
  cupo_maximo int
);

CREATE TABLE LineaVenta (
  id int PRIMARY KEY,
  parque_id int,
  vistante_id int,
  venta_id int,
  atraccion_id int,
  descripcion varchar(255),
  precio_unitario decimal(18,2),
  subtotal decimal(18,2)
);

CREATE TABLE Visitante (
  id int PRIMARY KEY,
  tipo_visitante_id int,  --en el der tiene que ir directo con venta
  nombre varchar(255),      --
  apellido varchar(255),
  dni varchar(255)
);

CREATE TABLE Guia (
  id int PRIMARY KEY,
  nombre varchar(255),
  apellido varchar(255),
  dni varchar(255),
  titulo varchar(255),
  especialidad varchar(255),
  vigencia_autorizacion date
);

CREATE TABLE HabilitacionGuia (
  id int PRIMARY KEY,
  guia_id int,
  descripcion varchar(255),
  fecha_vigencia date
);

CREATE TABLE AtraccionGuia (
  id integer PRIMARY KEY,
  atraccion_id integer,
  guia_id integer,
  fecha_asignacion date,
  turno varchar(255)
);

CREATE TABLE GuardaParque (
  id int PRIMARY KEY,
  nombre varchar(255),
  apellido varchar(255),
  dni varchar(255),
  contacto varchar(255)
);

CREATE TABLE AsignacionGuardaParque (
  id int PRIMARY KEY,
  guarda_parque_id int,
  parque_id int,
  fecha_inicio date,
  fecha_fin date,
  motivo_egreso varchar(255),
  activo int
);

CREATE TABLE Empresa (
  id int PRIMARY KEY,
  razon_social varchar(255),
  cuit varchar(255),
  contacto varchar(255)
);

CREATE TABLE Concesion (
  id int PRIMARY KEY,
  empresa_id int,
  parque_id int,
  tipo_actividad varchar(255),
  fecha_inicio date,
  fecha_fin date,
  canon_mensual decimal(18,2)
);

CREATE TABLE PagoCanon (
  id int PRIMARY KEY,
  concesion_id int,
  fecha_pago date,
  total decimal(18,2)
);



ALTER TABLE PrecioEntrada ADD FOREIGN KEY (parque_id) REFERENCES Parque (id);

ALTER TABLE PrecioEntrada ADD FOREIGN KEY (tipo_visitante_id) REFERENCES TipoVisitante (id);

ALTER TABLE LineaVenta ADD FOREIGN KEY (parque_id) REFERENCES Parque (id);

ALTER TABLE LineaVenta ADD FOREIGN KEY (visitante_id) REFERENCES Visitante (id);

ALTER TABLE LineaVenta ADD FOREIGN KEY (venta_id) REFERENCES Venta (id);

ALTER TABLE LineaVenta ADD FOREIGN KEY (atraccion_id) REFERENCES Atraccion (id);

ALTER TABLE Atraccion ADD FOREIGN KEY (parque_id) REFERENCES Parque (id);

ALTER TABLE Visitante ADD FOREIGN KEY (tipo_visitante_id) REFERENCES TipoVisitante (id);

ALTER TABLE HabilitacionGuia ADD FOREIGN KEY (guia_id) REFERENCES Guia (id);

ALTER TABLE AtraccionGuia ADD FOREIGN KEY (atraccion_id) REFERENCES Atraccion (id);

ALTER TABLE AtraccionGuia ADD FOREIGN KEY (guia_id) REFERENCES Guia (id);

ALTER TABLE AsignacionGuardaParque ADD FOREIGN KEY (guarda_parque_id) REFERENCES GuardaParque (id);

ALTER TABLE AsignacionGuardaParque ADD FOREIGN KEY (parque_id) REFERENCES Parque (id);

ALTER TABLE Concesion ADD FOREIGN KEY (empresa_id) REFERENCES Empresa (id);

ALTER TABLE Concesion ADD FOREIGN KEY (parque_id) REFERENCES Parque (id);

ALTER TABLE PagoCanon ADD FOREIGN KEY (concesion_id) REFERENCES Concesion (id);

--CADA FLECHA ES UN INNER JOIN :BY GONZALO :