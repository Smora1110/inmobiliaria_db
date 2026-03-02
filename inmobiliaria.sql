DROP DATABASE IF EXISTS inmobiliaria_db;
CREATE DATABASE IF NOT EXISTS inmobiliaria_db;
USE inmobiliaria_db;

-- =========================
-- UBICACIÓN
-- =========================

CREATE TABLE pais (
    pais_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    codigo_iso CHAR(3) NOT NULL,
    UNIQUE (nombre),
    UNIQUE (codigo_iso)
);

CREATE TABLE ciudad (
    ciudad_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    pais_id INT NOT NULL,
    FOREIGN KEY (pais_id) REFERENCES pais(pais_id),
    UNIQUE (nombre, pais_id),
    INDEX idx_ciudad_pais (pais_id)
);

-- =========================
-- PERSONAS
-- =========================

CREATE TABLE tipo_documento (
    id_tipo_documento INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE persona (
    persona_id INT AUTO_INCREMENT PRIMARY KEY,
    id_tipo_documento INT,
    documento VARCHAR(20) NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    telefono VARCHAR(20),
    email VARCHAR(120),
    direccion VARCHAR(150),
    ciudad_id INT,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ciudad_id) REFERENCES ciudad(ciudad_id),
    FOREIGN KEY (id_tipo_documento) REFERENCES tipo_documento(id_tipo_documento),
    UNIQUE (documento),
    UNIQUE (email)
);


CREATE INDEX idx_persona_nombre_prefix ON persona(nombre(60));
CREATE INDEX idx_persona_documento ON persona(documento);

-- =========================
-- CLIENTES
-- =========================

CREATE TABLE estado_cliente (
    id_estado_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255)
);

CREATE TABLE cliente (
    persona_id INT PRIMARY KEY,
    tipo_cliente ENUM('comprador','arrendatario','ambos') NOT NULL,
    id_estado_cliente INT NOT NULL,
    observaciones TEXT,
    FOREIGN KEY (persona_id) REFERENCES persona(persona_id),
    FOREIGN KEY (id_estado_cliente) REFERENCES estado_cliente(id_estado_cliente)
);

-- =========================
-- AGENTES
-- =========================

CREATE TABLE estado_agente (
    id_estado_agente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255)
);

CREATE TABLE agente (
    persona_id INT PRIMARY KEY,
    codigo_agente VARCHAR(20) NOT NULL UNIQUE,
    fecha_ingreso DATE NOT NULL,
    porcentaje_comision_base DECIMAL(5,2) NOT NULL,
    id_estado_agente INT NOT NULL,
    FOREIGN KEY (persona_id) REFERENCES persona(persona_id),
    FOREIGN KEY (id_estado_agente) REFERENCES estado_agente(id_estado_agente)
);

-- =========================
-- PROPIEDADES
-- =========================

CREATE TABLE tipo_propiedad (
    tipo_propiedad_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE estado_propiedad (
    estado_propiedad_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE propiedad (
    propiedad_id INT AUTO_INCREMENT PRIMARY KEY,
    codigo_propiedad VARCHAR(30) NOT NULL UNIQUE,
    titulo VARCHAR(120) NOT NULL,
    descripcion TEXT,
    direccion VARCHAR(150) NOT NULL,
    ciudad_id INT NOT NULL,
    tipo_propiedad_id INT NOT NULL,
    estado_propiedad_id INT NOT NULL,
    precio_publicacion DECIMAL(12,2) NOT NULL,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ciudad_id) REFERENCES ciudad(ciudad_id),
    FOREIGN KEY (tipo_propiedad_id) REFERENCES tipo_propiedad(tipo_propiedad_id),
    FOREIGN KEY (estado_propiedad_id) REFERENCES estado_propiedad(estado_propiedad_id)
);


CREATE INDEX idx_propiedad_ciudad_estado
ON propiedad(ciudad_id, estado_propiedad_id);

CREATE INDEX idx_propiedad_tipo_estado_precio
ON propiedad(tipo_propiedad_id, estado_propiedad_id, precio_publicacion);

CREATE INDEX idx_propiedad_precio_ciudad
ON propiedad(precio_publicacion, ciudad_id);

-- =========================
-- HISTORIAL PROPIEDAD-AGENTE
-- =========================

CREATE TABLE propiedad_agente (
    propiedad_agente_id INT AUTO_INCREMENT PRIMARY KEY,
    propiedad_id INT NOT NULL,
    agente_id INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    FOREIGN KEY (propiedad_id) REFERENCES propiedad(propiedad_id),
    FOREIGN KEY (agente_id) REFERENCES agente(persona_id)
);

CREATE INDEX idx_pa_agente_activo
ON propiedad_agente(agente_id, fecha_fin);

CREATE INDEX idx_pa_propiedad_activa
ON propiedad_agente(propiedad_id, fecha_fin);

-- =========================
-- CONTRATOS
-- =========================

CREATE TABLE tipo_contrato (
    tipo_contrato_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE estado_contrato (
    estado_contrato_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE contrato (
    contrato_id INT AUTO_INCREMENT PRIMARY KEY,
    propiedad_id INT NOT NULL,
    agente_id INT NOT NULL,
    tipo_contrato_id INT NOT NULL,
    estado_contrato_id INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    valor_venta DECIMAL(14,2),
    canon_mensual DECIMAL(14,2),
    porcentaje_comision_aplicado DECIMAL(5,2),
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (propiedad_id) REFERENCES propiedad(propiedad_id),
    FOREIGN KEY (agente_id) REFERENCES agente(persona_id),
    FOREIGN KEY (tipo_contrato_id) REFERENCES tipo_contrato(tipo_contrato_id),
    FOREIGN KEY (estado_contrato_id) REFERENCES estado_contrato(estado_contrato_id),
    CHECK (
        (valor_venta IS NOT NULL AND canon_mensual IS NULL)
        OR
        (valor_venta IS NULL AND canon_mensual IS NOT NULL)
    )
);


CREATE INDEX idx_contrato_estado_fechas
ON contrato(estado_contrato_id, fecha_inicio, fecha_fin);

CREATE INDEX idx_contrato_agente_estado
ON contrato(agente_id, estado_contrato_id);

CREATE INDEX idx_contrato_tipo_fecha
ON contrato(tipo_contrato_id, fecha_inicio);

-- =========================
-- CONTRATO_CLIENTE
-- =========================

CREATE TABLE contrato_cliente (
    contrato_id INT NOT NULL,
    cliente_id INT NOT NULL,
    rol_cliente ENUM('comprador','arrendatario') NOT NULL,
    PRIMARY KEY (contrato_id, cliente_id),
    FOREIGN KEY (contrato_id) REFERENCES contrato(contrato_id) ON DELETE CASCADE,
    FOREIGN KEY (cliente_id) REFERENCES cliente(persona_id) ON DELETE CASCADE
);

CREATE INDEX idx_cc_rol ON contrato_cliente(rol_cliente);
CREATE INDEX idx_cc_cliente_rol ON contrato_cliente(cliente_id, rol_cliente);

-- =========================
-- TIPO PAGO
-- =========================

CREATE TABLE tipo_pago (
    tipo_pago_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

-- =========================
-- PAGOS
-- =========================

CREATE TABLE pago (
    pago_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    contrato_id INT NOT NULL,
    tipo_pago_id INT,
    monto DECIMAL(12,2) NOT NULL,
    fecha_pago DATE NOT NULL,
    numero_cuota INT,
    observacion VARCHAR(255),
    registrado_por INT NOT NULL,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (contrato_id) REFERENCES contrato(contrato_id),
    FOREIGN KEY (registrado_por) REFERENCES persona(persona_id),
    FOREIGN KEY (tipo_pago_id) REFERENCES tipo_pago(tipo_pago_id)
);

-- Índices optimizados
CREATE INDEX idx_pago_contrato_monto
ON pago(contrato_id, monto);

CREATE INDEX idx_pago_fecha_contrato
ON pago(fecha_pago, contrato_id);

CREATE INDEX idx_pago_contrato_cuota_monto
ON pago(contrato_id, numero_cuota, monto);

CREATE INDEX idx_pago_tipo_fecha
ON pago(tipo_pago_id, fecha_pago);

-- =========================
-- AUDITORÍA
-- =========================

CREATE TABLE log_sistema (
    log_id BIGINT AUTO_INCREMENT,
    tabla_afectada VARCHAR(50),
    accion VARCHAR(50),
    registro_id INT,
    valor_anterior JSON,
    valor_nuevo JSON,
    usuario_mysql VARCHAR(100),
    fecha_evento DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (log_id, fecha_evento)
)
PARTITION BY RANGE (YEAR(fecha_evento)) (
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION pmax VALUES LESS THAN MAXVALUE
);

CREATE INDEX idx_log_tabla_fecha
ON log_sistema(tabla_afectada, fecha_evento);

CREATE INDEX idx_log_usuario_fecha
ON log_sistema(usuario_mysql, fecha_evento);



-- =========================
-- VISTA PARA DEUDA
-- =========================

CREATE OR REPLACE VIEW vw_deuda_contrato AS
SELECT
    c.contrato_id,
    c.canon_mensual,
    IFNULL(SUM(p.monto),0) AS total_pagado,
    (c.canon_mensual - IFNULL(SUM(p.monto),0)) AS deuda_actual
FROM contrato c
LEFT JOIN pago p ON p.contrato_id = c.contrato_id
GROUP BY c.contrato_id;

-- =========================
-- REPOORTE PAGOS
-- =========================

CREATE TABLE reporte_mensual_pagos (
    reporte_id INT AUTO_INCREMENT PRIMARY KEY,
    fecha_reporte DATE NOT NULL,
    contrato_id INT NOT NULL,
    deuda_pendiente DECIMAL(14,2),
    fecha_generacion DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- LOGS ERRORES
-- =========================

CREATE TABLE log_errores (
    error_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    objeto VARCHAR(100),           
    tipo_objeto VARCHAR(50),        
    sqlstate_codigo VARCHAR(10),
    mensaje_error TEXT,
    usuario_mysql VARCHAR(100),
    fecha_error DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- INSERTS
-- =========================

-- =========================
-- PAISES
-- =========================
INSERT INTO pais (nombre, codigo_iso) VALUES
('Colombia','COL'),
('México','MEX');

-- =========================
-- CIUDADES
-- =========================
INSERT INTO ciudad (nombre, pais_id) VALUES
('Bogotá',1),
('Medellín',1),
('Ciudad de México',2);

-- =========================
-- TIPO DOCUMENTO
-- =========================
INSERT INTO tipo_documento (nombre) VALUES
('Cédula'),
('Pasaporte');

-- =========================
-- PERSONAS
-- =========================
INSERT INTO persona
(id_tipo_documento, documento, nombre, telefono, email, direccion, ciudad_id)
VALUES
(1,'1001','Carlos Ramírez','3001234567','carlos@mail.com','Calle 10 #20-30',1),
(1,'1002','Laura Gómez','3009876543','laura@mail.com','Carrera 50 #40-20',2),
(1,'1003','Andrés López','3015556677','andres@mail.com','Av Siempre Viva 123',1),
(1,'1004','Sofía Torres','3021112233','sofia@mail.com','Calle 80 #15-60',1);

-- =========================
-- ESTADOS CLIENTE
-- =========================
INSERT INTO estado_cliente (nombre, descripcion) VALUES
('Activo','Cliente activo'),
('Inactivo','Cliente inactivo');

-- =========================
-- CLIENTES
-- =========================
INSERT INTO cliente (persona_id, tipo_cliente, id_estado_cliente)
VALUES
(1,'arrendatario',1),
(2,'comprador',1),
(4,'ambos',1);

-- =========================
-- ESTADOS AGENTE
-- =========================
INSERT INTO estado_agente (nombre, descripcion) VALUES
('Activo','Agente activo'),
('Suspendido','Agente suspendido');

-- =========================
-- AGENTES
-- =========================
INSERT INTO agente
(persona_id, codigo_agente, fecha_ingreso, porcentaje_comision_base, id_estado_agente)
VALUES
(3,'AG001','2022-01-15',5.00,1);

-- =========================
-- TIPOS PROPIEDAD
-- =========================
INSERT INTO tipo_propiedad (nombre) VALUES
('Apartamento'),
('Casa'),
('Local Comercial');

-- =========================
-- ESTADOS PROPIEDAD
-- =========================
INSERT INTO estado_propiedad (nombre) VALUES
('Disponible'),
('Arrendada'),
('Vendida');

-- =========================
-- PROPIEDADES
-- =========================
INSERT INTO propiedad
(codigo_propiedad, titulo, descripcion, direccion, ciudad_id, tipo_propiedad_id, estado_propiedad_id, precio_publicacion)
VALUES
('PROP001','Apartamento Centro','Apartamento 2 habitaciones','Calle 12 #10-15',1,1,1,250000000),
('PROP002','Casa Campestre','Casa con jardín amplio','Km 5 vía Medellín',2,2,1,450000000);

-- =========================
-- HISTORIAL PROPIEDAD-AGENTE
-- =========================
INSERT INTO propiedad_agente
(propiedad_id, agente_id, fecha_inicio)
VALUES
(1,3,'2024-01-01'),
(2,3,'2024-02-01');

-- =========================
-- TIPOS CONTRATO
-- =========================
INSERT INTO tipo_contrato (nombre) VALUES
('Venta'),
('Arriendo');

-- =========================
-- ESTADOS CONTRATO
-- =========================
INSERT INTO estado_contrato (nombre) VALUES
('Activo'),
('Finalizado'),
('Cancelado');

-- =========================
-- CONTRATOS
-- =========================

-- Contrato de arriendo
INSERT INTO contrato
(propiedad_id, agente_id, tipo_contrato_id, estado_contrato_id,
fecha_inicio, fecha_fin, canon_mensual, porcentaje_comision_aplicado)
VALUES
(1,3,2,1,'2025-01-01','2025-12-31',1500000,5.00);

-- Contrato de venta
INSERT INTO contrato
(propiedad_id, agente_id, tipo_contrato_id, estado_contrato_id,
fecha_inicio, valor_venta, porcentaje_comision_aplicado)
VALUES
(2,3,1,1,'2025-02-01',450000000,5.00);

-- =========================
-- CONTRATO_CLIENTE
-- =========================

-- Arriendo: Carlos arrendatario
INSERT INTO contrato_cliente (contrato_id, cliente_id, rol_cliente)
VALUES
(1,1,'arrendatario');

-- Venta: Laura compradora
INSERT INTO contrato_cliente (contrato_id, cliente_id, rol_cliente)
VALUES
(2,2,'comprador');

-- =========================
-- PAGOS
-- =========================

-- Pagos arriendo contrato 1
INSERT INTO pago
(contrato_id, monto, fecha_pago, numero_cuota, registrado_por)
VALUES
(1,1500000,'2025-01-05',1,3),
(1,1500000,'2025-02-05',2,3),
(1,1500000,'2025-03-05',3,3);

-- Pago venta contrato 2
INSERT INTO pago
(contrato_id, monto, fecha_pago, registrado_por)
VALUES
(2,450000000,'2025-02-10',3);


-- ============================================================
 --  FUNCIONES
-- ============================================================

DELIMITER $$

-- ============================================================
--   1. Función: Calcular comisión de un contrato de venta
-- ============================================================
CREATE FUNCTION fn_calcular_comision_contrato(p_contrato_id INT)
RETURNS DECIMAL(14,2)
DETERMINISTIC
BEGIN
    DECLARE v_valor DECIMAL(14,2);
    DECLARE v_porcentaje DECIMAL(5,2);
    DECLARE v_comision DECIMAL(14,2);

   
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO log_errores(objeto,tipo_objeto,sqlstate_codigo,
                                mensaje_error,usuario_mysql)
        VALUES ('fn_calcular_comision_contrato','FUNCTION','45000',
                'Error calculando comisión',
                CURRENT_USER());
        RETURN 0;
    END;

    SELECT valor_venta, porcentaje_comision_aplicado
    INTO v_valor, v_porcentaje
    FROM contrato
    WHERE contrato_id = p_contrato_id
      AND valor_venta IS NOT NULL;

    SET v_comision = v_valor * (v_porcentaje / 100);

    RETURN IFNULL(v_comision,0);
END$$


-- ============================================================
--  2. Función: Calcular deuda pendiente de contrato de arriendo
-- ============================================================
CREATE FUNCTION fn_calcular_deuda_contrato(p_contrato_id INT)
RETURNS DECIMAL(14,2)
DETERMINISTIC
BEGIN
    DECLARE v_canon DECIMAL(14,2);
    DECLARE v_total_pagado DECIMAL(14,2);
    DECLARE v_deuda DECIMAL(14,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO log_errores(objeto,tipo_objeto,sqlstate_codigo,
                                mensaje_error,usuario_mysql)
        VALUES ('fn_calcular_deuda_contrato','FUNCTION','45000',
                'Error calculando deuda',
                CURRENT_USER());
        RETURN 0;
    END;

    SELECT canon_mensual
    INTO v_canon
    FROM contrato
    WHERE contrato_id = p_contrato_id
      AND canon_mensual IS NOT NULL;

    SELECT IFNULL(SUM(monto),0)
    INTO v_total_pagado
    FROM pago
    WHERE contrato_id = p_contrato_id;

    SET v_deuda = v_canon - v_total_pagado;

    RETURN IFNULL(v_deuda,0);
END$$


-- ============================================================
--   3. Función: Total de propiedades disponibles por tipo
-- ============================================================
CREATE FUNCTION fn_total_propiedades_disponibles(p_tipo_nombre VARCHAR(50))
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_total INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO log_errores(objeto,tipo_objeto,sqlstate_codigo,
                                mensaje_error,usuario_mysql)
        VALUES ('fn_total_propiedades_disponibles','FUNCTION','45000',
                'Error contando propiedades',
                CURRENT_USER());
        RETURN 0;
    END;

    SELECT COUNT(*)
    INTO v_total
    FROM propiedad p
    JOIN tipo_propiedad tp
        ON p.tipo_propiedad_id = tp.tipo_propiedad_id
    JOIN estado_propiedad ep
        ON p.estado_propiedad_id = ep.estado_propiedad_id
    WHERE tp.nombre = p_tipo_nombre
      AND ep.nombre = 'Disponible';

    RETURN IFNULL(v_total,0);
END$$

DELIMITER ;



-- ============================================================
--    TRIGGERS DE AUDITORÍA
-- ============================================================ 

DELIMITER $$

-- ------------------------------------------------------------
--   4. Trigger: Registrar cambio de estado de propiedad
-- ------------------------------------------------------------ 
CREATE TRIGGER trg_propiedad_cambio_estado
AFTER UPDATE ON propiedad
FOR EACH ROW
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO log_errores(objeto,tipo_objeto,sqlstate_codigo,
                                mensaje_error,usuario_mysql)
        VALUES ('trg_propiedad_cambio_estado','TRIGGER','45000',
                'Error en trigger cambio estado propiedad',
                CURRENT_USER());
    END;

    IF OLD.estado_propiedad_id <> NEW.estado_propiedad_id THEN
        INSERT INTO log_sistema
        (tabla_afectada, accion, registro_id,
         valor_anterior, valor_nuevo, usuario_mysql)
        VALUES
        (
            'propiedad',
            'UPDATE_ESTADO',
            NEW.propiedad_id,
            JSON_OBJECT('estado_propiedad_id', OLD.estado_propiedad_id),
            JSON_OBJECT('estado_propiedad_id', NEW.estado_propiedad_id),
            CURRENT_USER()
        );
    END IF;
END$$


-- ------------------------------------------------------------
--   5. Trigger: Registrar inserción de nuevo contrato
-- ------------------------------------------------------------ 
CREATE TRIGGER trg_nuevo_contrato
AFTER INSERT ON contrato
FOR EACH ROW
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO log_errores(objeto,tipo_objeto,sqlstate_codigo,
                                mensaje_error,usuario_mysql)
        VALUES ('trg_nuevo_contrato','TRIGGER','45000',
                'Error en trigger nuevo contrato',
                CURRENT_USER());
    END;

    INSERT INTO log_sistema
    (tabla_afectada, accion, registro_id,
     valor_anterior, valor_nuevo, usuario_mysql)
    VALUES
    (
        'contrato',
        'INSERT',
        NEW.contrato_id,
        NULL,
        JSON_OBJECT(
            'propiedad_id', NEW.propiedad_id,
            'agente_id', NEW.agente_id,
            'tipo_contrato_id', NEW.tipo_contrato_id
        ),
        CURRENT_USER()
    );
END$$

DELIMITER ;



-- ============================================================
--   SEGURIDAD: ROLES Y PRIVILEGIOS
-- ============================================================ 

CREATE ROLE rol_admin;
CREATE ROLE rol_agente;
CREATE ROLE rol_contador;

/* Admin: control total */
GRANT ALL PRIVILEGES ON inmobiliaria_db.* TO rol_admin;

/* Agente */
GRANT SELECT ON inmobiliaria_db.propiedad TO rol_agente;
GRANT SELECT ON inmobiliaria_db.cliente TO rol_agente;
GRANT SELECT ON inmobiliaria_db.persona TO rol_agente;
GRANT INSERT, SELECT ON inmobiliaria_db.contrato TO rol_agente;
GRANT INSERT, SELECT ON inmobiliaria_db.pago TO rol_agente;
GRANT SELECT ON inmobiliaria_db.vw_deuda_contrato TO rol_agente;

/* Contador */
GRANT SELECT ON inmobiliaria_db.contrato TO rol_contador;
GRANT SELECT ON inmobiliaria_db.pago TO rol_contador;
GRANT SELECT ON inmobiliaria_db.vw_deuda_contrato TO rol_contador;
GRANT SELECT, INSERT ON inmobiliaria_db.reporte_mensual_pagos TO rol_contador;

/* Crear usuarios */
CREATE USER 'admin_user'@'%' IDENTIFIED BY 'Admin123!';
CREATE USER 'agente_user'@'%' IDENTIFIED BY 'Agente123!';
CREATE USER 'contador_user'@'%' IDENTIFIED BY 'Contador123!';

GRANT rol_admin TO 'admin_user'@'%';
GRANT rol_agente TO 'agente_user'@'%';
GRANT rol_contador TO 'contador_user'@'%';

SET DEFAULT ROLE ALL TO
'admin_user'@'%',
'agente_user'@'%',
'contador_user'@'%';



--  ============================================================
--   EVENTO PROGRAMADO MENSUAL
--   ============================================================ 

SET GLOBAL event_scheduler = ON;

DELIMITER $$

CREATE EVENT ev_reporte_mensual_pagos
ON SCHEDULE
EVERY 1 MONTH
STARTS '2026-04-01 00:00:00'
DO
BEGIN

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO log_errores(objeto,tipo_objeto,sqlstate_codigo,
                                mensaje_error,usuario_mysql)
        VALUES ('ev_reporte_mensual_pagos','EVENT','45000',
                'Error generando reporte mensual',
                CURRENT_USER());
    END;

    INSERT INTO reporte_mensual_pagos
    (fecha_reporte, contrato_id, deuda_pendiente)

    SELECT
        CURDATE(),
        c.contrato_id,
        IFNULL(c.canon_mensual - IFNULL(SUM(p.monto),0),0)
    FROM contrato c
    LEFT JOIN pago p
        ON p.contrato_id = c.contrato_id
    WHERE c.estado_contrato_id = 1
    GROUP BY c.contrato_id;

END$$

DELIMITER ;


-- =========================
-- PRUEBAS
-- =========================

-- ============================================================
--   PRUEBAS FUNCIONES Y TRIGGERS
   
--  ============================================================ 



-- ============================================================
-- PRUEBAS DE FUNCIONES
-- ============================================================

-- 1.1 Calcular comisión contrato de venta 
SELECT
    2 AS contrato,
    fn_calcular_comision_contrato(2) AS comision_calculada;


-- 1.2 Calcular deuda contrato de arriendo 
SELECT
    1 AS contrato,
    fn_calcular_deuda_contrato(1) AS deuda_calculada;


-- 1.3 Total propiedades disponibles por tipo
SELECT
    'Apartamento' AS tipo,
    fn_total_propiedades_disponibles('Apartamento') AS total_disponibles;



-- ============================================================
-- PRUEBA TRIGGER CAMBIO DE ESTADO PROPIEDAD
-- ============================================================

-- Ver estado actual
SELECT propiedad_id, estado_propiedad_id
FROM propiedad
WHERE propiedad_id = 1;

-- Cambiar estado
UPDATE propiedad
SET estado_propiedad_id = 2
WHERE propiedad_id = 1;

-- Verificar registro en auditoría
SELECT *
FROM log_sistema
WHERE tabla_afectada = 'propiedad'
ORDER BY fecha_evento DESC
LIMIT 5;



-- ============================================================
-- PRUEBA TRIGGER NUEVO CONTRATO
-- ============================================================

-- Insertar nuevo contrato de arriendo
INSERT INTO contrato
(propiedad_id, agente_id, tipo_contrato_id,
 estado_contrato_id, fecha_inicio,
 canon_mensual, porcentaje_comision_aplicado)
VALUES
(1,3,2,1,'2025-06-01',1500000,5.00);

-- Verificar auditoría
SELECT *
FROM log_sistema
WHERE tabla_afectada = 'contrato'
ORDER BY fecha_evento DESC
LIMIT 5;



-- ============================================================
-- PRUEBA LOG DE ERRORES (FORZANDO ERROR)
-- ============================================================

-- Llamar función con contrato inexistente
SELECT fn_calcular_comision_contrato(9999);

-- Verificar log de errores
SELECT *
FROM log_errores
ORDER BY fecha_error DESC
LIMIT 5;