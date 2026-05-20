// Use DBML to define your database structure
// Docs: https://dbml.dbdiagram.io/docs

// Módulo A - Parques
Table Parque {
  id integer [primary key]
  nombre varchar
  ubicacion varchar
  tipo_parque char(2)
  superficie_ha decimal
  latitud decimal
  longitud decimal
  perimetro geography
}


//Módulo B - Ventas
Table PrecioEntrada {
  id integer [primary key]
  parque_id integer [Ref: > Parque.id]
  tipo_visitante_id int [Ref: > TipoVisitante.id]
  precio decimal
  fecha_vigencia date
}

Table Venta {
  id integrer [primary key]
  parque_id integer [Ref: > Parque.id]
  tipo_vistante_id integer [Ref: > TipoVisitante.id]
  punto_venta int
  numero int
  fecha datetime
  forma_pago varchar
  total decimal
}

Table LineaVenta {
  id integrer [primary key]
  venta_id integer [Ref: > Venta.id]
  atraccion_id integer [Ref: > Atraccion.id]
  descripcion varchar
  precio_unitario decimal
  subtotal decimal
}


// Módulo C - Atracciones
Table Atraccion {
  id integer [primary key]
  parque_id integer [Ref: > Parque.id]
  nombre varchar
  // Si manejamos nomeclatura de tipo podemos dejarlo como un VAR con limite de carácteres
  tipo varchar
  costo decimal
  duracion_min int
  cupo_maximo int

  checks {
    //           Trekking - Playa - Buceo
    // `tipo in ("TRKK", "PLYA", "BCEO")`
  }
}

// Módulo D - Visitantes
Table TipoVisitante {
  id integer [primary key]
  descripcion varchar
}

Table Visitante {
  id integer [primary key]
  tipo_visitante_id integer [Ref: > TipoVisitante.id]
  nombre varchar
  apellido varchar
  dni varchar
}

// Módulo E - Personal
Table Guia {
  id integer [primary key]
  nombre varchar
  apellido varchar
  dni varchar
  titulo varchar
  especialidad varchar
  vigencia_autorizacion date
}

Table HabilitacionGuia {
  id integer [primary key]
  guia_id integer [Ref: > Guia.id]
  descripcion varchar
  fecha_vigencia date
}

Table AtraccionGuia {
  id integer [primary key]
  atraccion_id integer [Ref: > Atraccion.id]
  guia_id integer [Ref: > Guia.id]
  fecha_asignacion date
  turno varchar // Mañana / Tarde
}

Table GuardaParque{
  id integer [primary key]
  nombre varchar
  apellido varchar
  dni varchar
  contacto varchar
}

Table AsignacionGuardaParque {
  id integer [primary key]
  guarda_parque_id integer [Ref: > GuardaParque.id]
  parque_id integer [Ref: > Parque.id]
  fecha_inicio date
  fecha_fin date
  motivo_egreso varchar
  activo int
}


// Módulo F - Concesiones
Table Concesion {
  id integer [primary key]
  empresa_id integer [Ref: > Empresa.id]
  parque_id integer [Ref: > Parque.id]
  tipo_actividad varchar
  fecha_inicio date
  fecha_fin date
  canon_mensual decimal
}

Table Empresa {
  id integer [primary key]
  razon_social varchar
  cuit varchar
  contacto varchar
}

Table PagoCanon {
  id integer [primary key]
  concesion_id integer [Ref: > Concesion.id]
  fecha_pago date
  total decimal
}
