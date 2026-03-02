# Sistema de Gestión Inmobiliaria – inmobiliaria_db

Sebastian Andres Mora Valenzuela

## Descripción General

Este proyecto consiste en el diseño e implementación de una base de datos relacional para una empresa inmobiliaria que gestiona:

- Venta de propiedades  
- Arriendo de propiedades  
- Clientes y agentes  
- Contratos  
- Pagos  
- Auditoría del sistema  
- Reportes automáticos  

El objetivo fue construir una base de datos normalizada, optimizada, segura y automatizada, aplicando buenas prácticas de modelado relacional y diseño de bases de datos.

---

## Modelo de Empresa Planteado

Se modeló una empresa inmobiliaria donde:

- Una persona puede ser cliente, agente o ambas cosas.
- Existen contratos de venta y contratos de arriendo.
- Los pagos están asociados a contratos.
- Se lleva historial de qué agente gestiona cada propiedad.
- Se controla la seguridad mediante roles diferenciados.
- Se registran automáticamente eventos importantes.
- Se generan reportes mensuales automáticos de deudas.

El diseño busca simular una empresa real con separación clara de responsabilidades y control de la información.

---

## Decisiones de Diseño

### 1. Separación persona → cliente / agente

Se creó una tabla base `persona` que contiene los datos generales (documento, nombre, contacto, ciudad).  

Luego se crearon:

- `cliente`, que referencia a `persona`
- `agente`, que referencia a `persona`

Esto permite que una misma persona pueda:

- Comprar o arrendar propiedades
- Convertirse en agente
- Cumplir ambos roles

Esta decisión evita duplicación de datos y mantiene consistencia estructural.

---

### 2. Estados normalizados

En lugar de utilizar ENUM para todos los estados, se crearon tablas independientes:

- `estado_cliente`
- `estado_agente`
- `estado_propiedad`
- `estado_contrato`

Esto permite:

- Agregar nuevos estados sin modificar la estructura.
- Mantener integridad referencial.
- Facilitar la escalabilidad del sistema.

---

### 3. Tabla intermedia contrato_cliente

Un contrato puede involucrar más de un cliente (por ejemplo, dos compradores en una venta).  

Por ello se creó una tabla puente:

`contrato_cliente (contrato_id, cliente_id, rol_cliente)`

Esto permite manejar correctamente relaciones muchos-a-muchos y especificar el rol del cliente dentro del contrato.

---

### 4. Historial propiedad_agente

Se creó la tabla `propiedad_agente` para registrar:

- Qué agente gestionó una propiedad
- Desde cuándo
- Hasta cuándo

Esto permite mantener trazabilidad comercial y análisis histórico.

---

## Proceso de Normalización hasta 3FN

El diseño del modelo siguió las reglas de normalización hasta Tercera Forma Normal (3FN).

### Primera Forma Normal (1FN)

Se aseguró que:

- Cada columna contiene valores atómicos.
- No existen listas dentro de un mismo campo.
- Cada tabla posee una clave primaria.

Ejemplo:  
En lugar de almacenar múltiples clientes en una sola columna del contrato, se creó la tabla `contrato_cliente`.

---

### Segunda Forma Normal (2FN)

Se garantizó que:

- Todas las columnas dependan completamente de la clave primaria.
- No existan dependencias parciales en tablas con claves compuestas.

Ejemplo:  
En `contrato_cliente`, la clave primaria es compuesta (`contrato_id`, `cliente_id`).  
El campo `rol_cliente` depende de ambos, no solo de uno.

---

### Tercera Forma Normal (3FN)

Se eliminaron dependencias transitivas.

Ejemplo:

En lugar de almacenar el nombre del país directamente en la tabla `persona`, se modeló:

`persona → ciudad → pais`

Así:

- `persona` referencia `ciudad`
- `ciudad` referencia `pais`

Esto evita redundancia.

Otro ejemplo:

En lugar de guardar el nombre del estado en `contrato`, se guarda `estado_contrato_id` que referencia la tabla `estado_contrato`.

Esto garantiza consistencia y evita duplicación de información.

---

## Estructura General del Sistema

### Ubicación
- pais  
- ciudad  

### Personas
- tipo_documento  
- persona  
- cliente  
- agente  

### Propiedades
- tipo_propiedad  
- estado_propiedad  
- propiedad  
- propiedad_agente  

### Contratos
- tipo_contrato  
- estado_contrato  
- contrato  
- contrato_cliente  

### Pagos
- tipo_pago  
- pago  

### Control y Auditoría
- log_sistema (particionada por año)  
- log_errores  
- reporte_mensual_pagos  
- vw_deuda_contrato (vista)  

---

## Instalación

### 1. Crear la base de datos

```sql
CREATE DATABASE inmobiliaria_db;
USE inmobiliaria_db;
```

### 2. Ejecutar el script completo en este orden

1. Creación de tablas
2. Creación de índices
3. Creación de vista
4. Funciones
5. Triggers
6. Roles y usuarios
7. Evento programado
8. Inserts de prueba

### 3. Activar el scheduler de eventos

```sql
SET GLOBAL event_scheduler = ON;
```

---

## Ejemplos de Consultas

### Calcular comisión de un contrato de venta

```sql
SELECT fn_calcular_comision_contrato(2);
```

### Calcular deuda pendiente de un contrato

```sql
SELECT fn_calcular_deuda_contrato(1);
```

### Ver propiedades disponibles por tipo

```sql
SELECT fn_total_propiedades_disponibles('Apartamento');
```

### Ver auditoría del sistema

```sql
SELECT *
FROM log_sistema
ORDER BY fecha_evento DESC;
```

### Ver deudas actuales

```sql
SELECT *
FROM vw_deuda_contrato;
```

### Validar uso de índices

```sql
EXPLAIN
SELECT *
FROM propiedad
WHERE ciudad_id = 1
AND estado_propiedad_id = 1;
```

---

## Seguridad Implementada

Se crearon tres roles:

- **rol_admin**
- **rol_agente**
- **rol_contador**

Cada uno con privilegios diferenciados:

- El administrador tiene control total.
- El agente puede registrar contratos y pagos, pero no modificar propiedades directamente.
- El contador puede consultar contratos, pagos y reportes.

Esto simula separación real de funciones dentro de una empresa.

---

## Automatización y Auditoría

Se implementaron:

- Triggers que registran cambios de estado de propiedades.
- Trigger que registra la creación de nuevos contratos.
- Manejo de errores estructurado en la tabla log_errores.
- Evento mensual que genera automáticamente un reporte de pagos pendientes.
- Particionamiento por año en la tabla log_sistema para mejorar rendimiento.

---

## Características Técnicas Implementadas

- Normalización hasta Tercera Forma Normal (3FN)
- Integridad referencial
- Índices estratégicos
- Triggers de auditoría
- Funciones personalizadas
- Manejo estructurado de errores
- Particionamiento
- Evento programado mensual
- Seguridad basada en roles

---

## Conclusión

Este proyecto implementa un modelo de base de datos sólido para una empresa inmobiliaria, aplicando principios de:

- Diseño estructurado
- Escalabilidad
- Seguridad
- Automatización
- Optimización de consultas
- Control de auditoría

El resultado es una base de datos que podría evolucionar fácilmente hacia una aplicación empresarial real.

