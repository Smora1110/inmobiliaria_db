/*
Tu tarea consiste en implementar consultas y estructuras SQL que automaticen la auditoría, apliquen transacciones y presenten la información en vistas analíticas.

    • Trigger 1: Crear un trigger que se active al actualizar el precio de una propiedad, registrando el cambio en una tabla auditoria_precios con:
    • id_auditoria.
    • id_propiedad.
    • precio_anterior.
    • precio_nuevo.
    • fecha_cambio, usuario.


    Trigger 2: Crear un trigger que evite eliminar una propiedad si está asociada a un contrato activo, mostrando un mensaje de error personalizado.
    • Transacción: Simular un proceso de arriendo con transacciones (START TRANSACTION, COMMIT, ROLLBACK), donde se actualiza el estado de la propiedad y se registra el contrato.
    • Vista: Crear una vista llamada vista_resumen_propiedades que muestre:
    • nombre_propiedad.
    • ciudad, estado.
    • precio.
    • nombre_agente
y si la propiedad está o no alquilada.
    • Consulta final: Mostrar las 10 últimas modificaciones registradas en la tabla auditoria_precios (ORDER BY fecha_cambio DESC LIMIT 10).
    
*/

-- TRIGGER 1

CREATE TABLE auditoria_precios (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    id_propiedad INT NOT NULL,
    precio_anterior DECIMAL(12,2) NOT NULL,
    precio_nuevo DECIMAL(12,2) NOT NULL,
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP,
    usuario VARCHAR(100) DEFAULT CURRENT_USER()
);
DELIMITER $$

CREATE TRIGGER trg_auditoria_precio
BEFORE UPDATE ON propiedad
FOR EACH ROW
BEGIN
    IF OLD.precio_publicacion <> NEW.precio_publicacion THEN
        INSERT INTO auditoria_precios
        (id_propiedad, precio_anterior, precio_nuevo, fecha_cambio, usuario)
        VALUES
        (
            NEW.propiedad_id,
            OLD.precio_publicacion,
            NEW.precio_publicacion,
            NOW(),
            CURRENT_USER()
        );
    END IF;
END$$

DELIMITER ;

-- TRIGGGER 2

DELIMITER $$

CREATE TRIGGER trg_prevent_delete_propiedad
BEFORE DELETE ON propiedad
FOR EACH ROW
BEGIN
    DECLARE v_contrato_activo INT;
    
    SELECT COUNT(*)
    INTO v_contrato_activo
    FROM contrato
    WHERE propiedad_id = OLD.propiedad_id
      AND estado_contrato_id = 1;
    
    IF v_contrato_activo > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La propiedad seleccionada tiene un contrato activo asociado.';
    END IF;
END$$

DELIMITER ;

-- TRANSACCIØN

CREATE PROCEDURE sp_proceso_arriendo(
    IN p_propiedad_id INT,
    IN p_cliente_id INT,
    IN p_agente_id INT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_canon_mensual DECIMAL(14,2)
)
BEGIN
    DECLARE v_exito BOOLEAN DEFAULT FALSE;
    DECLARE v_mensaje VARCHAR(255);
    
    START TRANSACTION;
    
    BEGIN
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SELECT 'Error en el proceso de arriendo' AS resultado, -1 AS contrato_id;
        END;
        
        UPDATE propiedad
        SET estado_propiedad_id = 2
        WHERE propiedad_id = p_propiedad_id;
        
        INSERT INTO contrato
        (propiedad_id, agente_id, tipo_contrato_id, estado_contrato_id,
         fecha_inicio, fecha_fin, canon_mensual, porcentaje_comision_aplicado)
        VALUES
        (p_propiedad_id, p_agente_id, 2, 1, p_fecha_inicio, p_fecha_fin, p_canon_mensual, 5.00);
        
        INSERT INTO contrato_cliente
        (contrato_id, cliente_id, rol_cliente)
        VALUES
        (LAST_INSERT_ID(), p_cliente_id, 'arrendatario');
        
        COMMIT;
        SET v_exito := TRUE;
        SET v_mensaje := 'Arriendo registrado exitosamente';
        
        SELECT v_mensaje AS resultado, LAST_INSERT_ID() AS contrato_id;
    END;
END$$

DELIMITER ;

-- VISTA

CREATE OR REPLACE VIEW vista_resumen_propiedades AS
SELECT
    p.titulo AS nombre_propiedad,
    c.nombre AS ciudad,
    ep.nombre AS estado,
    p.precio_publicacion AS precio,
    per.nombre AS nombre_agente,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM contrato co
            WHERE co.propiedad_id = p.propiedad_id
              AND co.estado_contrato_id = 1
              AND co.tipo_contrato_id = 2
        ) THEN 'Sí'
        ELSE 'No'
    END AS alquilada
FROM propiedad p
JOIN ciudad c ON p.ciudad_id = c.ciudad_id
JOIN estado_propiedad ep ON p.estado_propiedad_id = ep.estado_propiedad_id
LEFT JOIN propiedad_agente pa ON p.propiedad_id = pa.propiedad_id AND pa.fecha_fin IS NULL
LEFT JOIN agente a ON pa.agente_id = a.persona_id
LEFT JOIN persona per ON a.persona_id = per.persona_id;
SELECT 
    id_auditoria,
    id_propiedad,
    precio_anterior,
    precio_nuevo,
    fecha_cambio,
    usuario
FROM auditoria_precios
ORDER BY fecha_cambio DESC
LIMIT 10;