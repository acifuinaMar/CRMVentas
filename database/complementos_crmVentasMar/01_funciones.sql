USE CRMVentas;
GO

-- Calcular importe ponderado
CREATE OR ALTER FUNCTION dbo.fn_CalcularImportePonderado
(
    @monto DECIMAL(18,2),
    @porcentaje DECIMAL(5,2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    RETURN ISNULL(@monto, 0) * (ISNULL(@porcentaje, 0) / 100);
END;
GO
