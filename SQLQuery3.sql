
-- VENTANA 2: ESTUDIANTE B
-- NIVEL READ UNCOMMITTED

USE MatriculacionUniversitaria;
GO

SET TRANSACTION ISOLATION LEVEL
READ UNCOMMITTED;

BEGIN TRANSACTION;

-- CONSULTAR CUPOS SIN ESPERAR COMMIT
SELECT asignatura_id,
       nombre_materia,
       cupos_disponibles
FROM Asignaturas
WHERE asignatura_id = 1;

COMMIT TRANSACTION;



-- VENTANA 2: VERIFICACION FINAL

SELECT asignatura_id,
       nombre_materia,
       cupos_disponibles
FROM Asignaturas
WHERE asignatura_id = 1;

-- RESTABLECER AISLAMIENTO NORMAL
SET TRANSACTION ISOLATION LEVEL
READ COMMITTED;
