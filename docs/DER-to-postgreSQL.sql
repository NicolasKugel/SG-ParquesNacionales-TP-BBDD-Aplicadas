CREATE TABLE "Parque" (
  "id" integer PRIMARY KEY,
  "nombre" varchar,
  "ubicacion" varchar,
  "tipo_parque" char(2),
  "superficie_ha" decimal,
  "latitud" decimal,
  "longitud" decimal,
  "perimetro" geography
);

CREATE TABLE "PrecioEntrada" (
  "id" integer PRIMARY KEY,
  "parque_id" integer,
  "tipo_visitante_id" int,
  "precio" decimal,
  "fecha_vigencia" date
);

CREATE TABLE "Venta" (
  "id" integrer PRIMARY KEY,
  "parque_id" integer,
  "tipo_vistante_id" integer,
  "punto_venta" int,
  "numero" int,
  "fecha" datetime,
  "forma_pago" varchar,
  "total" decimal
);

CREATE TABLE "LineaVenta" (
  "id" integrer PRIMARY KEY,
  "venta_id" integer,
  "atraccion_id" integer,
  "descripcion" varchar,
  "precio_unitario" decimal,
  "subtotal" decimal
);

CREATE TABLE "Atraccion" (
  "id" integer PRIMARY KEY,
  "parque_id" integer,
  "nombre" varchar,
  "tipo" varchar,
  "costo" decimal,
  "duracion_min" int,
  "cupo_maximo" int
);

CREATE TABLE "TipoVisitante" (
  "id" integer PRIMARY KEY,
  "descripcion" varchar
);

CREATE TABLE "Visitante" (
  "id" integer PRIMARY KEY,
  "tipo_visitante_id" integer,
  "nombre" varchar,
  "apellido" varchar,
  "dni" varchar
);

CREATE TABLE "Guia" (
  "id" integer PRIMARY KEY,
  "nombre" varchar,
  "apellido" varchar,
  "dni" varchar,
  "titulo" varchar,
  "especialidad" varchar,
  "vigencia_autorizacion" date
);

CREATE TABLE "HabilitacionGuia" (
  "id" integer PRIMARY KEY,
  "guia_id" integer,
  "descripcion" varchar,
  "fecha_vigencia" date
);

CREATE TABLE "AtraccionGuia" (
  "id" integer PRIMARY KEY,
  "atraccion_id" integer,
  "guia_id" integer,
  "fecha_asignacion" date,
  "turno" varchar
);

CREATE TABLE "GuardaParque" (
  "id" integer PRIMARY KEY,
  "nombre" varchar,
  "apellido" varchar,
  "dni" varchar,
  "contacto" varchar
);

CREATE TABLE "AsignacionGuardaParque" (
  "id" integer PRIMARY KEY,
  "guarda_parque_id" integer,
  "parque_id" integer,
  "fecha_inicio" date,
  "fecha_fin" date,
  "motivo_egreso" varchar,
  "activo" int
);

CREATE TABLE "Concesion" (
  "id" integer PRIMARY KEY,
  "empresa_id" integer,
  "parque_id" integer,
  "tipo_actividad" varchar,
  "fecha_inicio" date,
  "fecha_fin" date,
  "canon_mensual" decimal
);

CREATE TABLE "Empresa" (
  "id" integer PRIMARY KEY,
  "razon_social" varchar,
  "cuit" varchar,
  "contacto" varchar
);

CREATE TABLE "PagoCanon" (
  "id" integer PRIMARY KEY,
  "concesion_id" integer,
  "fecha_pago" date,
  "total" decimal
);

ALTER TABLE "PrecioEntrada" ADD FOREIGN KEY ("parque_id") REFERENCES "Parque" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "PrecioEntrada" ADD FOREIGN KEY ("tipo_visitante_id") REFERENCES "TipoVisitante" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "Venta" ADD FOREIGN KEY ("parque_id") REFERENCES "Parque" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "Venta" ADD FOREIGN KEY ("tipo_vistante_id") REFERENCES "TipoVisitante" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "LineaVenta" ADD FOREIGN KEY ("venta_id") REFERENCES "Venta" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "LineaVenta" ADD FOREIGN KEY ("atraccion_id") REFERENCES "Atraccion" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "Atraccion" ADD FOREIGN KEY ("parque_id") REFERENCES "Parque" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "Visitante" ADD FOREIGN KEY ("tipo_visitante_id") REFERENCES "TipoVisitante" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "HabilitacionGuia" ADD FOREIGN KEY ("guia_id") REFERENCES "Guia" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "AtraccionGuia" ADD FOREIGN KEY ("atraccion_id") REFERENCES "Atraccion" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "AtraccionGuia" ADD FOREIGN KEY ("guia_id") REFERENCES "Guia" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "AsignacionGuardaParque" ADD FOREIGN KEY ("guarda_parque_id") REFERENCES "GuardaParque" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "AsignacionGuardaParque" ADD FOREIGN KEY ("parque_id") REFERENCES "Parque" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "Concesion" ADD FOREIGN KEY ("empresa_id") REFERENCES "Empresa" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "Concesion" ADD FOREIGN KEY ("parque_id") REFERENCES "Parque" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "PagoCanon" ADD FOREIGN KEY ("concesion_id") REFERENCES "Concesion" ("id") DEFERRABLE INITIALLY IMMEDIATE;
