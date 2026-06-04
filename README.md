# CRMVentas - Proyecto Final Base de Datos II

## Descripción General

CRMVentas es un sistema CRM (Customer Relationship Management) desarrollado para la empresa ficticia **Innovación S.A.** como proyecto final del curso **Base de Datos II** de la Universidad Mariano Gálvez de Guatemala.

El sistema permite gestionar clientes, oportunidades comerciales, actividades de seguimiento y reportes de ventas, proporcionando herramientas para el control y monitoreo del proceso comercial.

Adicionalmente incorpora mecanismos de auditoría, procesos ETL, Data Warehouse y alta disponibilidad mediante SQL Server Database Mirroring.

---

## Integrantes

| Nombre                              | Carné         |
| ----------------------------------- | ------------- |
| Maryori Elizabeth Acifuina Juárez   | 7690-23-6640  |
| Emmerson Steve Alvizures Palma      | 7690-23-12526 |
| Jimmy Andersón Hernández Valladares | 7690-23-16916 |
| Edwin Antonio Morales Melgar        | 7690-19-27494 |

**Curso:** Base de Datos II

**Sección:** B

**Docente:** Ing. Julio Roberto Gómez Orozco

---

# Objetivo del Proyecto

Desarrollar un sistema CRM que permita administrar de manera eficiente:

* Clientes potenciales y finales.
* Oportunidades comerciales.
* Actividades de seguimiento.
* Reportes comerciales.
* Procesos analíticos mediante Data Warehouse.
* Auditoría de cambios.
* Alta disponibilidad de la información.

---

# Tecnologías Utilizadas

## Backend

* Node.js
* Express.js

## Frontend

* HTML5
* CSS3
* JavaScript

## Base de Datos

* SQL Server

## Business Intelligence

* SQL Server Integration Services (SSIS)
* Data Warehouse

## Control de Versiones

* Git
* GitHub

---

# Funcionalidades Implementadas

## Gestión de Clientes

Permite:

* Crear clientes.
* Modificar clientes.
* Consultar clientes.
* Eliminar clientes.

---

## Gestión de Oportunidades

Permite:

* Crear oportunidades.
* Asignar vendedores responsables.
* Definir montos potenciales.
* Controlar porcentaje de avance.
* Gestionar estado de negociación.

---

## Pipeline de Ventas (Kanban)

Implementa un tablero visual para el seguimiento de oportunidades en las siguientes etapas:

* Toma de Decisión
* Proceso de Toma de Decisión
* Análisis de Proyecto
* Presentación de Cotización
* Validación de Cotización
* Acuerdo de Cierre

---

## Gestión de Actividades

Permite registrar:

* Llamadas telefónicas.
* Reuniones.
* Tareas.
* Notas.
* Visitas a clientes.
* Reclamos.

---

## Reportes

Incluye:

* Oportunidades por gestor comercial.
* Oportunidades por período.
* Oportunidades ganadas.
* Oportunidades perdidas.

---

## Auditoría

Se implementaron triggers para registrar:

* Inserciones.
* Actualizaciones.
* Eliminaciones.

Toda la información queda almacenada en una bitácora para fines de trazabilidad.

---

## ETL y Data Warehouse

Se implementó un proceso ETL para:

1. Extraer información desde la base transaccional CRMVentas.
2. Transformar los datos.
3. Cargar la información en el Data Warehouse CRMVentas_DW.

### Dimensiones

* DimCliente
* DimEmpleado
* DimEtapa
* DimFecha

### Tabla de Hechos

* FactOportunidades

---

## Alta Disponibilidad

Se implementó SQL Server Database Mirroring entre dos instancias:

* SQL1 (Principal)
* SQL2 (Mirror)

Permitiendo continuidad operativa mediante failover.

---

# Estructura del Proyecto

```text
CRMVentas
│
├── database/
│   ├── CRMVentas.sql
│   ├── CRMVentas_DW.sql
│   ├── StoredProcedures.sql
│   ├── Triggers.sql
│   └── Views.sql
│
├── backend/
│   ├── server.js
│   ├── routes/
│   └── config/
│
├── frontend/
│   ├── index.html
│   ├── clientes.html
│   ├── oportunidades.html
│   ├── actividades.html
│   └── reportes.html
│
└── README.md
```

# Evidencias del Proyecto

## Aplicación CRM

* Gestión de clientes.
* Gestión de oportunidades.
* Gestión de actividades.
* Pipeline Kanban.
* Reportes ejecutivos.

## Base de Datos

* Modelo Entidad Relación.
* Procedimientos almacenados.
* Triggers.
* Índices.
* Consultas optimizadas.

## Business Intelligence

* ETL.
* Data Warehouse.

## Alta Disponibilidad

* Database Mirroring.
* Failover manual validado.
