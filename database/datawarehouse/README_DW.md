# Data Warehouse - CRM Ventas

Esta carpeta contiene los archivos relacionados con la parte del Data Warehouse del proyecto CRM Ventas.

La idea de esta parte es separar la base principal del sistema y crear una base enfocada en reportes. La base principal `CRMVentas` guarda la informacion diaria del sistema, mientras que `CRMVentas_DW` se utiliza para analizar la informacion de oportunidades, clientes, empleados, etapas y fechas.

## Archivos incluidos

### 01_creacion_datawarehouse.sql

Este archivo crea la base de datos `CRMVentas_DW` y sus tablas principales.

Las tablas creadas son:

- `DimCliente`: guarda informacion basica de los clientes.
- `DimEmpleado`: guarda informacion de los empleados relacionados con las oportunidades.
- `DimEtapa`: guarda las etapas de seguimiento de una oportunidad.
- `DimFecha`: permite analizar la informacion por dia, mes y año.
- `FactOportunidades`: concentra la informacion principal de las oportunidades, como montos, avance, estado y resultado.

### 02_consultas_validacion_dw.sql

Este archivo contiene consultas para revisar que el Data Warehouse fue creado correctamente.

Las consultas permiten verificar:

- Las tablas creadas en el Data Warehouse.
- Las columnas de las dimensiones.
- Las columnas de la tabla de hechos.
- La cantidad de registros que tiene cada tabla.

Por el momento las tablas pueden aparecer con cero registros, porque esta parte solo corresponde a la estructura del Data Warehouse. La carga de informacion pertenece al proceso ETL.

## Orden de ejecucion

Para probar esta parte en SQL Server Management Studio, se recomienda ejecutar los archivos en este orden:

1. `01_creacion_datawarehouse.sql`
2. `02_consultas_validacion_dw.sql`

## Explicacion general

El Data Warehouse se creo para organizar la informacion de una forma mas util para reportes. En lugar de usar directamente las tablas operativas del sistema, se separo la informacion en dimensiones y una tabla de hechos.

Las dimensiones sirven para analizar la informacion desde diferentes puntos de vista, por ejemplo por cliente, empleado, etapa o fecha.

La tabla de hechos `FactOportunidades` guarda los datos principales que se quieren analizar, como montos, porcentaje de avance, estado y resultado de las oportunidades.

Esta estructura permite que mas adelante se puedan generar reportes para apoyar la toma de decisiones de la gerencia comercial.

## Responsable

Parte trabajada por Steve para el modulo de Data Warehouse.



