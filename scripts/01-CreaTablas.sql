USE TPBDG5;
GO

CREATE TABLE Concesiones.Empresa (
  id int IDENTITY(1,1) PRIMARY KEY,
  razon_social varchar(150) NOT NULL,
  cuit varchar(13) NOT NULL UNIQUE,
  tipo_actividad varchar(100) NOT NULL,
);

CREATE TABLE Concesiones.Concesion (
  id int IDENTITY(1,1) PRIMARY KEY,
  fecha_inicio date NOT NULL,
  fecha_fin date NOT NULL,
  canon_mensual decimal(18,2) NOT NULL,
  empresa_id int NOT NULL,
  parque_id int NOT NULL,
);

CREATE TABLE Concesiones.PagoConcesion (
  id int IDENTITY(1,1) PRIMARY KEY,
  fecha_pago date NULL,
  periodo date NOT NULL, 
  estado varchar(10) NOT NULL,
  total decimal(18,2) NOT NULL,
  concesion_id int NOT NULL,
);

CREATE TABLE Parques.Entrada (
  id int IDENTITY(1,1) PRIMARY KEY,
  precio_entrada decimal(18,2) NOT NULL,
  parque_id int NOT NULL,
  fecha_desde date NOT NULL
);

CREATE TABLE Parques.Atraccion (
  id int IDENTITY(1,1) PRIMARY KEY,
  nombre varchar(100) NOT NULL,
  descripcion varchar(500) NULL,
  duracion time NOT NULL,
  cupo_maximo int NOT NULL,
  costo decimal(18,2) NOT NULL,
  parque_id int NOT NULL,
);

CREATE TABLE Parques.Parque (
  id int IDENTITY(1,1) PRIMARY KEY,
  Codigo varchar(20) NOT NULL,
  nombre varchar(100) NOT NULL,
  ubicacion varchar(200) NOT NULL,
  tipo_parque char(2) NOT NULL,
  superficie_ha decimal(12,2) NOT NULL,
);

CREATE TABLE Personal.GuardaParque (
  id int IDENTITY(1,1) PRIMARY KEY,
  nombre varchar(100) NOT NULL,
  apellido varchar(100) NOT NULL,
  dni varchar(15) NOT NULL UNIQUE,
  estado int NOT NULL 
);

CREATE TABLE Personal.AsignacionGuardaParque (
  id int IDENTITY(1,1) PRIMARY KEY,
  fecha_inicio date NOT NULL,
  fecha_fin date NULL,
  motivo_egreso varchar(200) NULL,
  guarda_parque_id int NOT NULL,
  parque_id int NOT NULL,
);

CREATE TABLE Personal.Guia (
  id int IDENTITY(1,1) PRIMARY KEY,
  nombre varchar(100) NOT NULL,
  apellido varchar(100) NOT NULL,
  dni varchar(15) NOT NULL UNIQUE,
  titulo varchar(150) NULL,
  tipo_habilitacion varchar(100) NULL,
  especialidad varchar(100) NOT NULL,
);

CREATE TABLE Personal.AtraccionGuia (
  id int IDENTITY(1,1) PRIMARY KEY,
  fecha_asignacion date NOT NULL,
  turno varchar(10) NOT NULL,
  atraccion_id int NOT NULL,
  guia_id int NOT NULL,
);

CREATE TABLE Ventas.Visitante (
  id int IDENTITY(1,1) PRIMARY KEY,
  nombre varchar(100) NOT NULL,
  apellido varchar(100) NOT NULL,
  dni varchar(15) NOT NULL UNIQUE,
);

CREATE TABLE Ventas.TipoVisitante (
  id int IDENTITY(1,1) PRIMARY KEY,
  descripcion varchar(100),
  descuento int,
);

CREATE TABLE Ventas.Venta (
  id int IDENTITY(1,1) PRIMARY KEY,
  punto_venta int NOT NULL,
  numero int NOT NULL,
  fecha date NOT NULL,
  forma_pago varchar(50) NOT NULL,
  total decimal(18,2) NOT NULL,
  visitante_id int NOT NULL,
);

CREATE TABLE Ventas.LineaVenta (
  id int IDENTITY(1,1) PRIMARY KEY,
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

ALTER TABLE Personal.AsignacionGuardaParque ADD CONSTRAINT FK_AsignacionGuardaParque_GuardaParque

    FOREIGN KEY (guarda_parque_id) REFERENCES Personal.GuardaParque (id);

ALTER TABLE Personal.AsignacionGuardaParque ADD CONSTRAINT FK_AsignacionGuardaParque_Parque

    FOREIGN KEY (parque_id) REFERENCES Parques.Parque (id);

ALTER TABLE Ventas.Venta ADD CONSTRAINT FK_Venta_Visitante

    FOREIGN KEY (visitante_id) REFERENCES Ventas.Visitante (id);

ALTER TABLE Parques.Entrada ADD CONSTRAINT FK_Entrada_Parque

    FOREIGN KEY (parque_id) REFERENCES Parques.Parque (id);

ALTER TABLE Parques.Atraccion ADD CONSTRAINT FK_Atraccion_Parque

    FOREIGN KEY (parque_id) REFERENCES Parques.Parque (id);

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

ALTER TABLE Concesiones.PagoConcesion ADD CONSTRAINT CK_PagoConcesion_Estado
    CHECK (estado IN ('Pagado', 'Atrasado', 'Pendiente'));

ALTER TABLE Personal.GuardaParque ADD CONSTRAINT CK_GuardaParque_Estado
    CHECK (estado IN (0, 1));

ALTER TABLE Personal.AtraccionGuia ADD CONSTRAINT CK_AtraccionGuia_Turno
    CHECK (turno IN ('Mañana', 'Tarde', 'Noche'));

ALTER TABLE Ventas.Venta ADD CONSTRAINT CK_Venta_FormaPago
    CHECK (forma_pago IN ('Efectivo', 'Tarjeta de débito', 'Tarjeta de crédito', 'Transferencia'));
