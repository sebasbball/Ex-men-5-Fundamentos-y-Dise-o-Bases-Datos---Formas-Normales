/*
==============================================================================
PUNTO 1: ANÁLISIS Y NORMALIZACIÓN DE ArtistaCancion
==============================================================================

TABLA ORIGINAL PROPUESTA:
--------------------------
CREATE TABLE ArtistaCancion (
    IdInterprete INT,
    NombreInterprete NVARCHAR(50),
    IdPais INT,
    Pais NVARCHAR(50),
    IdCancion INT,
    TituloCancion NVARCHAR(50),
    Idiomas NVARCHAR(MAX), -- ejemplo: "Español, Inglés"
    Ritmo NVARCHAR(50)
)


a) FORMAS NORMALES QUE NO CUMPLE:
-----------------------------------

NO CUMPLE 1FN (Primera Forma Normal)
-----------------------------------------
VIOLACIÓN: El campo 'Idiomas' NO es atómico

JUSTIFICACIÓN:
Según la definición de atomicidad: "Un dato es atómico cuando NO puede ni 
debe dividirse en partes más pequeñas que tengan significado para el sistema."

El campo Idiomas NVARCHAR(MAX) almacena múltiples valores separados por comas 
(ejemplo: "Español, Inglés"). Esto viola la atomicidad porque:
- Cada idioma individual tiene significado propio para el sistema
- Se puede dividir en partes más pequeñas (idiomas individuales)
- Esta estructura dificulta las consultas, búsquedas y actualizaciones
- No se puede hacer un filtro eficiente por idioma específico

EJEMPLO DEL PROBLEMA:
Si queremos buscar todas las canciones en "Inglés", tendríamos que usar 
operaciones complejas con LIKE '%Inglés%' en lugar de una búsqueda simple.


NO CUMPLE 2FN (Segunda Forma Normal)
-----------------------------------------
CLAVE PRIMARIA INFERIDA: (IdInterprete, IdCancion)
Esta representa la relación entre un intérprete y una canción.

VIOLACIÓN: Existen dependencias parciales - atributos que dependen SOLO de 
PARTE de la clave primaria, no de la clave completa.

DEPENDENCIAS PARCIALES IDENTIFICADAS:

1. Atributos que dependen SOLO de IdInterprete:
   - NombreInterprete → IdInterprete
   - IdPais → IdInterprete  
   - Pais → IdInterprete

2. Atributos que dependen SOLO de IdCancion:
   - TituloCancion → IdCancion
   - Ritmo → IdCancion

JUSTIFICACIÓN:
Una dependencia parcial ocurre cuando un atributo no clave depende SOLO de 
una parte de la clave primaria, y no de la clave completa.

CONSECUENCIAS:
- Los datos del intérprete (NombreInterprete, IdPais, Pais) se repiten para 
  cada canción del mismo intérprete → REDUNDANCIA
- Los datos de la canción (TituloCancion, Ritmo) se repiten para cada 
  intérprete de la misma canción → REDUNDANCIA
- Esto causa anomalías de inserción, actualización y eliminación


NO CUMPLE 3FN (Tercera Forma Normal)
-----------------------------------------
VIOLACIÓN: Existe una dependencia transitiva

DEPENDENCIA TRANSITIVA IDENTIFICADA:
IdInterprete → IdPais → Pais

EXPLICACIÓN:
Una dependencia transitiva ocurre cuando un atributo no clave depende de 
otro atributo no clave (el cual, a su vez, depende de la clave primaria).

En este caso:
- 'Pais' depende funcionalmente de 'IdPais' (atributo no clave)
- 'IdPais' depende funcionalmente de 'IdInterprete' (parte de la clave)
- Por transitividad: 'Pais' depende indirectamente de la clave a través de 'IdPais'

CONSECUENCIAS:
- Si se actualiza el nombre de un país, debe actualizarse en TODOS los registros
- Alto riesgo de inconsistencia de datos
- Redundancia innecesaria del nombre del país


b) NORMALIZACIÓN HASTA 3FN:
-----------------------------
A continuación se presentan las tablas normalizadas que cumplen hasta 3FN
*/

-- =====================================================
-- SOLUCIÓN: TABLAS NORMALIZADAS HASTA 3FN
-- =====================================================

CREATE DATABASE Discografia;
GO

USE Discografia;
GO

-- TABLA 1: Pais
-- Elimina la dependencia transitiva
-- Cada país se almacena una sola vez
CREATE TABLE Pais (
    IdPais INT PRIMARY KEY,
    NombrePais NVARCHAR(50) NOT NULL
);

-- TABLA 2: Interprete
-- Elimina las dependencias parciales
-- Los datos del intérprete se almacenan una sola vez
CREATE TABLE Interprete (
    IdInterprete INT PRIMARY KEY,
    NombreInterprete NVARCHAR(50) NOT NULL,
    IdPais INT NOT NULL,
    CONSTRAINT FK_Interprete_Pais 
        FOREIGN KEY (IdPais) REFERENCES Pais(IdPais)
);

-- TABLA 3: Cancion
-- Elimina las dependencias parciales
-- Los datos de cada canción se almacenan una sola vez
CREATE TABLE Cancion (
    IdCancion INT PRIMARY KEY,
    TituloCancion NVARCHAR(50) NOT NULL,
    Ritmo NVARCHAR(50) NOT NULL
);

-- TABLA 4: Idioma
-- Resuelve el problema de atomicidad de 1FN
-- Cada idioma es una entidad independiente
CREATE TABLE Idioma (
    IdIdioma INT PRIMARY KEY,
    NombreIdioma NVARCHAR(50) NOT NULL UNIQUE
);

-- TABLA 5: CancionIdioma (Relación muchos a muchos)
-- Resuelve la violación de 1FN
-- Cada combinación canción-idioma es un registro atómico
CREATE TABLE CancionIdioma (
    IdCancion INT,
    IdIdioma INT,
    PRIMARY KEY (IdCancion, IdIdioma),
    CONSTRAINT FK_CancionIdioma_Cancion 
        FOREIGN KEY (IdCancion) REFERENCES Cancion(IdCancion),
    CONSTRAINT FK_CancionIdioma_Idioma 
        FOREIGN KEY (IdIdioma) REFERENCES Idioma(IdIdioma)
);

-- TABLA 6: InterpreteCancion (Relación muchos a muchos)
-- Representa la relación original entre intérpretes y canciones sin redundancia
CREATE TABLE InterpreteCancion (
    IdInterprete INT,
    IdCancion INT,
    FechaGrabacion DATE NULL,
    PRIMARY KEY (IdInterprete, IdCancion),
    CONSTRAINT FK_InterpreteCancion_Interprete 
        FOREIGN KEY (IdInterprete) REFERENCES Interprete(IdInterprete),
    CONSTRAINT FK_InterpreteCancion_Cancion 
        FOREIGN KEY (IdCancion) REFERENCES Cancion(IdCancion)
);

/*
RESULTADO DE LA NORMALIZACIÓN:
-------------------------------
Todas las tablas ahora cumplen 3FN:
   - Todos los datos son atómicos (1FN)
   - No existen dependencias parciales (2FN)
   - No existen dependencias transitivas (3FN)

VENTAJAS:
- Eliminación de redundancia
- Prevención de anomalías de actualización, inserción y eliminación
- Mayor integridad de datos
- Facilidad para consultas y mantenimiento
*/

-- Datos de ejemplo para verificar normalización
INSERT INTO Pais (IdPais, NombrePais) VALUES (1, 'Colombia'), (2, 'España'), (3, 'Estados Unidos');
INSERT INTO Interprete (IdInterprete, NombreInterprete, IdPais) VALUES (1, 'Shakira', 1), (2, 'Alejandro Sanz', 2);
INSERT INTO Cancion (IdCancion, TituloCancion, Ritmo) VALUES (1, 'La Tortura', 'Reggaeton'), (2, 'Hips Dont Lie', 'Pop');
INSERT INTO Idioma (IdIdioma, NombreIdioma) VALUES (1, 'Español'), (2, 'Inglés'), (3, 'Portugués');
INSERT INTO CancionIdioma (IdCancion, IdIdioma) VALUES (1, 1), (1, 2), (2, 2);
INSERT INTO InterpreteCancion (IdInterprete, IdCancion, FechaGrabacion) VALUES (1, 1, '2005-05-29'), (1, 2, '2006-02-03');

GO

/*
==============================================================================
PUNTO 2: ANÁLISIS BCNF - TABLA GRABACION
==============================================================================

TABLA ORIGINAL:
---------------
CREATE TABLE Grabacion (
    IdInterpretacion INT IDENTITY(1,1) NOT NULL,
    IdAlbum INT NOT NULL,
    IdFormato INT NOT NULL,
    CONSTRAINT pkGrabacion PRIMARY KEY (IdInterpretacion, IdAlbum, IdFormato)
)

REGLAS DE NEGOCIO:
------------------
- Una interpretación puede estar grabada en varios álbumes y en varios formatos
- En un mismo álbum, una interpretación solo debe existir una vez por formato


¿ESTÁ EN BCNF?
--------------
DEFINICIÓN BCNF: "Todo determinante debe ser clave"

ANÁLISIS DE DETERMINANTES:

La regla de negocio establece: "En un mismo álbum, una interpretación solo 
debe existir una vez por formato"

Esto implica la siguiente dependencia funcional:
(IdAlbum, IdInterpretacion) → IdFormato

VERIFICACIÓN:
- Determinante: (IdAlbum, IdInterpretacion)
- ¿Es superclave? NO
- Clave primaria actual: (IdInterpretacion, IdAlbum, IdFormato)

CONCLUSIÓN: NO ESTÁ EN BCNF


JUSTIFICACIÓN:
--------------
El determinante (IdAlbum, IdInterpretacion) determina funcionalmente a 
IdFormato, pero NO es una superclave de la tabla. Esto viola la definición 
de BCNF.

PROBLEMAS QUE CAUSA:
1. REDUNDANCIA: La misma combinación álbum-interpretación puede aparecer 
   con diferentes formatos
2. ANOMALÍAS DE ACTUALIZACIÓN: Si cambia el formato preferido para un 
   álbum-interpretación, hay que actualizar múltiples registros
3. CLAVE COMPUESTA ANTINATURAL: Usar IDENTITY en una clave compuesta es 
   problemático porque IDENTITY genera valores automáticos y no debería 
   formar parte de una clave compuesta con otros atributos de negocio


REESTRUCTURACIÓN CORRECTA EN BCNF:
-----------------------------------
*/

-- Tablas auxiliares necesarias
CREATE TABLE Interpretacion (
    IdInterpretacion INT PRIMARY KEY IDENTITY(1,1),
    TituloInterpretacion NVARCHAR(100) NOT NULL,
    Duracion TIME NULL
);

CREATE TABLE Album (
    IdAlbum INT PRIMARY KEY,
    TituloAlbum NVARCHAR(100) NOT NULL,
    AnioLanzamiento INT NULL
);

CREATE TABLE Formato (
    IdFormato INT PRIMARY KEY,
    NombreFormato NVARCHAR(50) NOT NULL,
    Descripcion NVARCHAR(200) NULL
);

-- Tabla Grabacion normalizada en BCNF
CREATE TABLE Grabacion (
    IdGrabacion INT PRIMARY KEY IDENTITY(1,1),
    IdInterpretacion INT NOT NULL,
    IdAlbum INT NOT NULL,
    IdFormato INT NOT NULL,
    FechaGrabacion DATE NULL,
    -- RESTRICCIÓN ÚNICA: garantiza la regla de negocio
    -- "En un álbum, una interpretación solo existe una vez por formato"
    CONSTRAINT UQ_Grabacion_Album_Interpretacion_Formato 
        UNIQUE (IdAlbum, IdInterpretacion, IdFormato),
    CONSTRAINT FK_Grabacion_Interpretacion 
        FOREIGN KEY (IdInterpretacion) REFERENCES Interpretacion(IdInterpretacion),
    CONSTRAINT FK_Grabacion_Album 
        FOREIGN KEY (IdAlbum) REFERENCES Album(IdAlbum),
    CONSTRAINT FK_Grabacion_Formato 
        FOREIGN KEY (IdFormato) REFERENCES Formato(IdFormato)
);

/*
JUSTIFICACIÓN DE LA SOLUCIÓN:
------------------------------
AHORA SÍ CUMPLE BCNF porque:
   - La clave primaria es simple (IdGrabacion)
   - Todos los atributos no clave dependen únicamente de la clave primaria
   - La restricción UNIQUE garantiza la regla de negocio sin violar BCNF
   - No hay determinantes que no sean superclave

VENTAJAS:
- Eliminación de redundancia
- Estructura más natural y mantenible
- Facilita las consultas y actualizaciones
- Cumple con las mejores prácticas de diseño de bases de datos
*/

-- Datos de ejemplo
INSERT INTO Album (IdAlbum, TituloAlbum, AnioLanzamiento) VALUES (1, 'Pies Descalzos', 1995), (2, 'Dónde Están los Ladrones', 1998);
INSERT INTO Formato (IdFormato, NombreFormato, Descripcion) VALUES (1, 'CD', NULL), (2, 'Vinilo', NULL), (3, 'Digital', NULL);
INSERT INTO Interpretacion (TituloInterpretacion, Duracion) VALUES ('Estoy Aquí', '00:03:52'), ('Antología', '00:04:47');
INSERT INTO Grabacion (IdInterpretacion, IdAlbum, IdFormato) 
VALUES (1, 1, 1), (1, 1, 3), (2, 2, 1), (2, 2, 2);

GO

/*
==============================================================================
PUNTO 3: ANÁLISIS 4FN Y 5FN - TABLA CAMPAÑA PROMOCIÓN
==============================================================================

TABLA PROPUESTA:
----------------
CREATE TABLE CampanaPromocion (
    IdCancion INT,
    IdInterprete INT,
    Plataforma NVARCHAR(50),
    Pais NVARCHAR(50),
    PRIMARY KEY (IdCancion, IdInterprete, Plataforma, Pais)
)

CONTEXTO:
---------
Una canción de un intérprete se promueve en varias plataformas y en varios 
países de forma INDEPENDIENTE.


a) ¿VIOLA LA 4FN?
-----------------
DEFINICIÓN 4FN: Una tabla está en 4FN si no contiene dependencias 
multivaloradas no triviales.

IDENTIFICACIÓN DE DEPENDENCIAS MULTIVALORADAS:

(IdCancion, IdInterprete) →→ Plataforma
(IdCancion, IdInterprete) →→ Pais

EXPLICACIÓN:
- Para una combinación canción-intérprete, existen MÚLTIPLES plataformas posibles
- Para una combinación canción-intérprete, existen MÚLTIPLES países posibles
- Estas dependencias son INDEPENDIENTES: la elección de plataformas NO afecta 
  la elección de países y viceversa

EJEMPLO DEL PROBLEMA:
---------------------
Si la canción "La Tortura" de Shakira se promociona en:
- Plataformas: Spotify, YouTube, Apple Music (3 plataformas)
- Países: Colombia, México, España, Argentina (4 países)

La tabla actual requiere: 3 × 4 = 12 registros

(1, 1, 'Spotify', 'Colombia')
(1, 1, 'Spotify', 'México')
(1, 1, 'Spotify', 'España')
(1, 1, 'Spotify', 'Argentina')
(1, 1, 'YouTube', 'Colombia')
... (y así hasta 12 registros en total)

CONCLUSIÓN: SÍ VIOLA 4FN

JUSTIFICACIÓN:
--------------
Existen dos dependencias multivaloradas independientes en la misma tabla, 
lo que causa:

- REDUNDANCIA MASIVA: Producto cartesiano de plataformas × países
- ANOMALÍAS DE INSERCIÓN: Agregar una plataforma nueva requiere insertarla 
  para TODOS los países existentes (3 países = 3 inserts)
- ANOMALÍAS DE ELIMINACIÓN: Eliminar un país requiere eliminar múltiples 
  registros (3 plataformas = 3 deletes)
- ANOMALÍAS DE ACTUALIZACIÓN: Si cambia el nombre de una plataforma, hay 
  que actualizar múltiples registros


b) NORMALIZACIÓN A 4FN Y 5FN:
------------------------------
*/

-- Tabla 1: Promoción por Plataforma
CREATE TABLE PromocionPlataforma (
    IdPromocionPlataforma INT PRIMARY KEY IDENTITY(1,1),
    IdCancion INT NOT NULL,
    IdInterprete INT NOT NULL,
    Plataforma NVARCHAR(50) NOT NULL,
    FechaInicio DATE NULL,
    FechaFin DATE NULL,
    CONSTRAINT UQ_PromocionPlataforma 
        UNIQUE (IdCancion, IdInterprete, Plataforma)
);

-- Tabla 2: Promoción por País
CREATE TABLE PromocionPais (
    IdPromocionPais INT PRIMARY KEY IDENTITY(1,1),
    IdCancion INT NOT NULL,
    IdInterprete INT NOT NULL,
    Pais NVARCHAR(50) NOT NULL,
    FechaInicio DATE NULL,
    FechaFin DATE NULL,
    CONSTRAINT UQ_PromocionPais 
        UNIQUE (IdCancion, IdInterprete, Pais)
);

/*
JUSTIFICACIÓN - CUMPLE 4FN:
---------------------------
Cada dependencia multivalorada está en su propia tabla
   - PromocionPlataforma maneja solo la dependencia →→ Plataforma
   - PromocionPais maneja solo la dependencia →→ Pais

Se eliminó la redundancia:
   - 3 plataformas = 3 registros en PromocionPlataforma
   - 4 países = 4 registros en PromocionPais
   - TOTAL: 7 registros (en lugar de 12)
   - Ahorro de espacio: 41.7% menos registros

Se eliminaron las anomalías:
   - Agregar una plataforma: 1 INSERT (antes: N inserts donde N = # países)
   - Agregar un país: 1 INSERT (antes: M inserts donde M = # plataformas)
   - Eliminar una plataforma: 1 DELETE (antes: N deletes)
   - Eliminar un país: 1 DELETE (antes: M deletes)


JUSTIFICACIÓN - CUMPLE 5FN:
---------------------------
No existen dependencias de join complejas
   - Cada tabla representa una relación simple y directa
   - No hay ciclos de dependencias

La descomposición es sin pérdida
   - Se puede reconstruir la información original mediante JOIN:
   
   SELECT pp.IdCancion, pp.IdInterprete, pp.Plataforma, ppais.Pais
   FROM PromocionPlataforma pp
   CROSS JOIN PromocionPais ppais
   WHERE pp.IdCancion = ppais.IdCancion 
     AND pp.IdInterprete = ppais.IdInterprete;

No se puede descomponer más
   - Cada tabla está en su forma más simple posible
   - Cualquier descomposición adicional perdería información semántica
   - Las tablas representan conceptos atómicos del negocio


VENTAJAS DE LA NORMALIZACIÓN 4FN Y 5FN:
---------------------------------------
- Máxima eliminación de redundancia
- Estructura óptima para operaciones CRUD
- Escalabilidad: fácil agregar nuevas plataformas o países
- Integridad de datos garantizada
- Consultas más eficientes
- Menor uso de espacio de almacenamiento
*/

-- Datos de ejemplo
INSERT INTO PromocionPlataforma (IdCancion, IdInterprete, Plataforma) 
VALUES 
    (1, 1, 'Spotify'),
    (1, 1, 'YouTube'),
    (1, 1, 'Apple Music');

INSERT INTO PromocionPais (IdCancion, IdInterprete, Pais) 
VALUES 
    (1, 1, 'Colombia'),
    (1, 1, 'México'),
    (1, 1, 'España'),
    (1, 1, 'Argentina');

GO

/*
==============================================================================
CONSULTAS DE VERIFICACIÓN
==============================================================================
*/

PRINT '========================================';
PRINT 'VERIFICACIÓN PUNTO 1: Normalización 3FN';
PRINT '========================================';
SELECT 
    i.NombreInterprete,
    c.TituloCancion,
    STRING_AGG(id.NombreIdioma, ', ') AS Idiomas,
    c.Ritmo,
    p.NombrePais
FROM InterpreteCancion ic
JOIN Interprete i ON ic.IdInterprete = i.IdInterprete
JOIN Cancion c ON ic.IdCancion = c.IdCancion
JOIN Pais p ON i.IdPais = p.IdPais
LEFT JOIN CancionIdioma ci ON c.IdCancion = ci.IdCancion
LEFT JOIN Idioma id ON ci.IdIdioma = id.IdIdioma
GROUP BY i.NombreInterprete, c.TituloCancion, c.Ritmo, p.NombrePais;

PRINT '';
PRINT '========================================';
PRINT 'VERIFICACIÓN PUNTO 2: Normalización BCNF';
PRINT '========================================';
SELECT 
    i.TituloInterpretacion,
    a.TituloAlbum,
    f.NombreFormato,
    g.FechaGrabacion
FROM Grabacion g
JOIN Interpretacion i ON g.IdInterpretacion = i.IdInterpretacion
JOIN Album a ON g.IdAlbum = a.IdAlbum
JOIN Formato f ON g.IdFormato = f.IdFormato;

PRINT '';
PRINT '========================================';
PRINT 'VERIFICACIÓN PUNTO 3: Normalización 4FN y 5FN';
PRINT '========================================';
PRINT 'Plataformas de promoción:';
SELECT * FROM PromocionPlataforma;

PRINT '';
PRINT 'Países de promoción:';
SELECT * FROM PromocionPais;

/*
CONCLUSIONES:
-------------
- Se aplicaron correctamente todos los niveles de normalización solicitados
- Se eliminó toda la redundancia de datos
- Se previenen anomalías de inserción, actualización y eliminación
- Las estructuras son escalables y mantenibles
- Se respetaron todas las reglas de negocio especificadas
*/