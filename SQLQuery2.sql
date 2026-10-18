-- EJERCICIO 1: Creación del esquema de base de datos para la Gestión de Concurrencia y
-- Consistencia en el Sistema de Matriculación Universitaria.

CREATE DATABASE MatriculacionUniversitaria;
GO

USE MatriculacionUniversitaria;
GO

-- Tabla Estudiantes

CREATE TABLE Estudiantes (
    estudiante_id INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(100) NOT NULL,
    cedula VARCHAR(10) NOT NULL UNIQUE,
    facultad VARCHAR(100) NOT NULL
);


-- Tabla Asignaturas

CREATE TABLE Asignaturas (
    asignatura_id INT PRIMARY KEY IDENTITY(1,1),
    nombre_materia VARCHAR(100) NOT NULL,
    docente VARCHAR(100) NOT NULL,
    cupos_disponibles INT NOT NULL,
    CONSTRAINT CK_Cupos
        CHECK (cupos_disponibles >= 0)
);


-- Tabla Registros_Matricula


CREATE TABLE Registros_Matricula (
    registro_id INT PRIMARY KEY IDENTITY(1,1),
    estudiante_id INT NOT NULL,
    asignatura_id INT NOT NULL,
    fecha_registro DATETIME NOT NULL
        DEFAULT GETDATE(),
    estado VARCHAR(20) NOT NULL,

    CONSTRAINT FK_Estudiante
        FOREIGN KEY (estudiante_id)
        REFERENCES Estudiantes(estudiante_id),

    CONSTRAINT FK_Asignatura
        FOREIGN KEY (asignatura_id)
        REFERENCES Asignaturas(asignatura_id),

    CONSTRAINT CK_Estado
        CHECK (estado IN ('CONFIRMADA', 'PENDIENTE'))
);

-- Verificacion de Tablas

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- 2.	Aplicación de transacciones con propiedades ACID 
-- Transacción A: Uso de COMMIT


-- LITERAL 2: TRANSACCIONES ACID
-- PASO 1: INSERTAR DATOS DE PRUEBA

USE MatriculacionUniversitaria;
GO

INSERT INTO Estudiantes (nombre, cedula, facultad)
VALUES
('Juan Perez', '0601234567', 'Ingenieria'),
('Maria Lopez', '0602345678', 'Ingenieria');

INSERT INTO Asignaturas
(nombre_materia, docente, cupos_disponibles)
VALUES
('Base de Datos', 'Carlos Ramirez', 5),
('Programacion', 'Ana Torres', 10),
('Matematicas', 'Luis Gomez', 8);

-- VERIFICAR DATOS INSERTADOS

SELECT * FROM Estudiantes;
SELECT * FROM Asignaturas;

-- COMMIT


-- TRANSACCION A: USO DE COMMIT

BEGIN TRANSACTION;

-- 1. Registrar la matricula del estudiante 1
INSERT INTO Registros_Matricula
(estudiante_id, asignatura_id, estado)
VALUES (1, 1, 'CONFIRMADA');

-- 2. Disminuir un cupo de Base de Datos
UPDATE Asignaturas
SET cupos_disponibles = cupos_disponibles - 1
WHERE asignatura_id = 1
  AND cupos_disponibles > 0;

-- 3. Confirmar la transaccion
COMMIT TRANSACTION;


-- Verificacion COMMIT


-- VERIFICACION DE LA TRANSACCION A

SELECT * FROM Registros_Matricula;

SELECT * FROM Asignaturas
WHERE asignatura_id = 1;


-- 2.2. Transacción B: Uso de ROLLBACK

-- TRANSACCION B: USO DE ROLLBACK
-- PASO 1: VERIFICAR DATOS ACTUALES

USE MatriculacionUniversitaria;
GO

SELECT * FROM Estudiantes;

SELECT * FROM Registros_Matricula;

SELECT * FROM Asignaturas;

-- INiciar Transaccion


-- PASO 2: INICIAR TRANSACCION

BEGIN TRANSACTION;

-- INSERTAR MATRICULA DEL ESTUDIANTE 2
INSERT INTO Registros_Matricula
(estudiante_id, asignatura_id, estado)
VALUES (2, 1, 'PENDIENTE');

-- VERIFICAR REGISTRO TEMPORAL
SELECT * FROM Registros_Matricula;

-- Simular ROLLBACK


-- PASO 3: SIMULAR ERROR
-- NO SE REALIZA EL UPDATE DE CUPOS

-- CANCELAR LA TRANSACCION
ROLLBACK TRANSACTION;

-- COMPROBAR QUE SE DESHIZO LA MATRICULA
SELECT * FROM Registros_Matricula;


--2.3. Transacción C: Matrícula Multimateria


-- LITERAL 2: TRANSACCION C
-- MATRICULA MULTIMATERIA

USE MatriculacionUniversitaria;
GO

-- PASO 1: CONSULTAR CUPOS ORIGINALES

SELECT asignatura_id,
       nombre_materia,
       cupos_disponibles
FROM Asignaturas;


-- PASO 2: INICIAR TRANSACCION

BEGIN TRANSACTION;

-- RESTAR UN CUPO A BASE DE DATOS
UPDATE Asignaturas
SET cupos_disponibles = cupos_disponibles - 1
WHERE asignatura_id = 1;

-- RESTAR UN CUPO A PROGRAMACION
UPDATE Asignaturas
SET cupos_disponibles = cupos_disponibles - 1
WHERE asignatura_id = 2;

-- VERIFICAR LOS CAMBIOS TEMPORALES
SELECT * FROM Asignaturas;

-- Provocar error tercera materia

-- PASO 3: PROVOCAR ERROR
-- INTENTAR ACTUALIZAR MATERIA INEXISTENTE

UPDATE Asignaturas
SET cupos_disponibles = cupos_disponibles - 1
WHERE asignatura_id = 999;

-- SI NO SE ACTUALIZA NINGUNA FILA,
-- GENERAR UN ERROR CONTROLADO

IF @@ROWCOUNT = 0
BEGIN
    THROW 50001,
          'ERROR: La materia 999 no existe.',
          1;
END;


-- PASO 4: CANCELAR LA TRANSACCION
-- DESHACER TODOS LOS CAMBIOS

IF @@TRANCOUNT > 0
BEGIN
    ROLLBACK TRANSACTION;
END;

-- VERIFICAR LOS CUPOS FINALES
SELECT asignatura_id,
       nombre_materia,
       cupos_disponibles
FROM Asignaturas;


-- LITERAL 3: CONTROL DE CONCURRENCIA
-- NIVEL 1: READ UNCOMMITTED

USE MatriculacionUniversitaria;
GO

SELECT asignatura_id,
       nombre_materia,
       cupos_disponibles
FROM Asignaturas
WHERE asignatura_id = 1;


-- VENTANA 1: ESTUDIANTE A
-- INICIAR TRANSACCION

BEGIN TRANSACTION;

-- DISMINUIR UN CUPO SIN CONFIRMAR
UPDATE Asignaturas
SET cupos_disponibles = cupos_disponibles - 1
WHERE asignatura_id = 1
  AND cupos_disponibles > 0;

-- VERIFICAR CAMBIO TEMPORAL
SELECT *
FROM Asignaturas
WHERE asignatura_id = 1;

-- NO EJECUTAR COMMIT TODAVIA



-- VENTANA 1: CANCELAR LOS CAMBIOS

ROLLBACK TRANSACTION;

-- COMPROBAR QUE LOS CUPOS REGRESARON
SELECT asignatura_id,
       nombre_materia,
       cupos_disponibles
FROM Asignaturas
WHERE asignatura_id = 1;
