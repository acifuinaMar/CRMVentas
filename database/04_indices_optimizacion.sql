USE CRMVentas;
GO

/* ============================================================
   ÍNDICES NO AGRUPADOS PARA OPTIMIZACIÓN
   ============================================================ */

CREATE NONCLUSTERED INDEX IX_EtapaOportunidad_Kanban
ON dbo.Etapa_Oportunidad
(
    id_oportunidad,
    fecha_inicio_etapa DESC,
    id_etapa_oportunidad DESC
)
INCLUDE
(
    id_tipo_etapa,
    id_empleado_ventas,
    monto_potencial_etapa,
    importe_ponderado_etapa
);
GO

CREATE NONCLUSTERED INDEX IX_Oportunidad_Vendedor
ON dbo.Oportunidad
(
    id_empleado_vendedor
)
INCLUDE
(
    id_cliente,
    id_estado_oportunidad,
    id_resultado,
    fecha_inicio,
    fecha_cierre_real,
    monto_potencial,
    monto_ponderado,
    porcentaje_avance,
    activo
);
GO

CREATE NONCLUSTERED INDEX IX_Oportunidad_FechaInicio
ON dbo.Oportunidad
(
    fecha_inicio
)
INCLUDE
(
    id_cliente,
    id_empleado_vendedor,
    id_estado_oportunidad,
    id_resultado,
    monto_potencial,
    monto_ponderado,
    activo
);
GO

CREATE NONCLUSTERED INDEX IX_Oportunidad_Activas
ON dbo.Oportunidad
(
    activo,
    id_oportunidad DESC
)
INCLUDE
(
    numero_oportunidad,
    nombre_oportunidad,
    id_cliente,
    id_empleado_vendedor,
    monto_potencial,
    porcentaje_avance,
    fecha_inicio,
    fecha_cierre_prevista
);
GO

CREATE NONCLUSTERED INDEX IX_Actividad_FechaResponsable
ON dbo.Actividad
(
    fecha DESC,
    id_empleado_responsable
)
INCLUDE
(
    id_cliente,
    id_oportunidad,
    id_tipo_actividad,
    id_estado_actividad,
    id_prioridad,
    asunto
);
GO

CREATE NONCLUSTERED INDEX IX_Actividad_Oportunidad
ON dbo.Actividad
(
    id_oportunidad,
    fecha DESC
)
INCLUDE
(
    asunto,
    id_cliente,
    id_empleado_responsable,
    id_estado_actividad,
    id_prioridad
);
GO
