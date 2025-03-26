DESCRIBE historial_ventas;
-- Configuración recomendada para servidor MySQL
SET GLOBAL max_connections = 300;             -- Aumentar de 200 a 300
SET GLOBAL wait_timeout = 600;                -- Aumentar de 300 a 600 segundos
SET GLOBAL interactive_timeout = 600;         -- Aumentar de 300 a 600 segundos
SET GLOBAL connect_timeout = 30;              -- Aumentar de 10 a 30 segundos
SET GLOBAL net_read_timeout = 120;            -- Aumentar de 60 a 120 segundos
SET GLOBAL net_write_timeout = 120;           -- Aumentar de 60 a 120 segundos

-- Mostrar los valores actuales para verificar
SHOW VARIABLES LIKE 'wait_timeout';
SHOW VARIABLES LIKE 'interactive_timeout';
SHOW VARIABLES LIKE 'max_allowed_packet';

-- Crear base de datos si no existe y seleccionarla
CREATE DATABASE IF NOT EXISTS Proyecto_Prueba CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE Proyecto_Prueba;

-- Eliminar procedimientos almacenados y funciones existentes
DROP PROCEDURE IF EXISTS CrearUsuario;
DROP PROCEDURE IF EXISTS ActualizarUsuario;
DROP PROCEDURE IF EXISTS InactivarUsuario;
DROP PROCEDURE IF EXISTS CrearCliente;
DROP PROCEDURE IF EXISTS LeerClientes;
DROP PROCEDURE IF EXISTS ActualizarCliente;
DROP PROCEDURE IF EXISTS InactivarCliente;
DROP PROCEDURE IF EXISTS ReactivarCliente;
DROP PROCEDURE IF EXISTS CrearInmueble;
DROP PROCEDURE IF EXISTS ActualizarInmueble;
DROP PROCEDURE IF EXISTS CrearProveedor;
DROP PROCEDURE IF EXISTS LeerProveedores;
DROP PROCEDURE IF EXISTS ObtenerProveedores;
DROP PROCEDURE IF EXISTS ActualizarProveedor;
DROP PROCEDURE IF EXISTS InactivarProveedor;
DROP PROCEDURE IF EXISTS ReactivarProveedor;
DROP PROCEDURE IF EXISTS BuscarProveedores;
DROP PROCEDURE IF EXISTS CrearEmpleado;
DROP PROCEDURE IF EXISTS LeerEmpleados;
DROP PROCEDURE IF EXISTS ActualizarEmpleado;
DROP PROCEDURE IF EXISTS InactivarEmpleado;
DROP PROCEDURE IF EXISTS BuscarClientePorRFC;
DROP PROCEDURE IF EXISTS BuscarClientePorNombre;
DROP PROCEDURE IF EXISTS BuscarInmueblePorCliente;
DROP PROCEDURE IF EXISTS CrearUsuarioEmpleado;
DROP PROCEDURE IF EXISTS LeerEmpleadosConUsuarios;
DROP PROCEDURE IF EXISTS ObtenerEmpleadoUsuario;
DROP PROCEDURE IF EXISTS ActualizarUsuarioEmpleado;
DROP PROCEDURE IF EXISTS InactivarUsuarioEmpleado;
DROP PROCEDURE IF EXISTS ReactivarUsuarioEmpleado;
DROP PROCEDURE IF EXISTS CrearVenta;
DROP PROCEDURE IF EXISTS ObtenerVentas;
DROP PROCEDURE IF EXISTS AsignarProveedorAInmueble;
DROP PROCEDURE IF EXISTS ActualizarCostoServiciosInmueble;
DROP PROCEDURE IF EXISTS EliminarServicioProveedor;
DROP PROCEDURE IF EXISTS ObtenerServiciosProveedorPorInmueble;
DROP PROCEDURE IF EXISTS RecalcularFinanzasInmuebles;
DROP PROCEDURE IF EXISTS ActualizarUtilidadVenta;
DROP PROCEDURE IF EXISTS ObtenerEstadisticasVentas;
DROP PROCEDURE IF EXISTS AnalisisRentabilidadPorTipo;
DROP FUNCTION IF EXISTS EncriptarContraseña;
DROP PROCEDURE IF EXISTS CambiarEstadoVenta;
-- Eliminar tablas respetando dependencias
DROP TABLE IF EXISTS historial_usuarios;
DROP TABLE IF EXISTS historial_proveedores;
DROP TABLE IF EXISTS historial_proveedores_detallado;
DROP TABLE IF EXISTS historial_ventas;
DROP TABLE IF EXISTS comisiones_pagadas;
DROP TABLE IF EXISTS inmuebles_imagenes;
DROP TABLE IF EXISTS inmuebles_clientes_interesados;
DROP TABLE IF EXISTS cliente_inmueble;
DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS inmueble_proveedor_servicio;
DROP TABLE IF EXISTS inmuebles;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS empleados;
DROP TABLE IF EXISTS proveedores;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS direcciones;
DROP TABLE IF EXISTS estados;

-- Crear tabla de estados con IDs fijos
CREATE TABLE estados (
    id_estado INT PRIMARY KEY,
    nombre_estado VARCHAR(20) NOT NULL UNIQUE
);

-- Insertar estados predefinidos, incluyendo los nuevos para ventas
INSERT INTO estados (id_estado, nombre_estado) 
VALUES 
    (1, 'activo'),
    (2, 'inactivo'),
    (3, 'disponible'),
    (4, 'vendido'),
    (5, 'rentado'),
    (6, 'en_negociacion'),
    (7, 'venta_en_proceso'),
    (8, 'venta_completada'),
    (9, 'venta_cancelada')
ON DUPLICATE KEY UPDATE nombre_estado = VALUES(nombre_estado);

-- Crear tabla de direcciones
CREATE TABLE direcciones (
    id_direccion INT AUTO_INCREMENT PRIMARY KEY,
    calle VARCHAR(100) NOT NULL,
    numero VARCHAR(20),
    colonia VARCHAR(100),
    ciudad VARCHAR(100) NOT NULL,
    estado_geografico VARCHAR(100) NOT NULL,
    codigo_postal VARCHAR(10),
    referencias TEXT,
    id_estado INT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
);

-- Crear tabla de usuarios
CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    nombre_usuario VARCHAR(100) NOT NULL,
    correo_cliente VARCHAR(100),
    contraseña_usuario VARCHAR(255) NOT NULL,
    imagen_perfil VARCHAR(255) NULL,
    id_estado INT DEFAULT 1,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultima_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX idx_nombre_usuario (nombre_usuario),
    INDEX idx_usuarios_correo (correo_cliente),
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
);

-- Crear tabla de historial de usuarios
CREATE TABLE historial_usuarios (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_estado_anterior INT,
    id_estado_nuevo INT NOT NULL,
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_estado_anterior) REFERENCES estados(id_estado),
    FOREIGN KEY (id_estado_nuevo) REFERENCES estados(id_estado)
);

-- Crear tabla de clientes
CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido_paterno VARCHAR(100) NOT NULL,
    apellido_materno VARCHAR(100),
    id_direccion INT,
    telefono_cliente VARCHAR(20),
    rfc VARCHAR(13) NOT NULL,
    curp VARCHAR(18) NOT NULL,
    tipo_cliente ENUM('comprador', 'arrendatario', 'ambos') NOT NULL DEFAULT 'comprador',
    correo_cliente VARCHAR(100),
    id_estado INT DEFAULT 1,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE INDEX idx_clientes_correo (correo_cliente),
    FOREIGN KEY (id_direccion) REFERENCES direcciones(id_direccion),
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
);

-- Crear tabla de proveedores
CREATE TABLE proveedores (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    nombre_empresa VARCHAR(150) NOT NULL,
    nombre_contacto VARCHAR(100) NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    correo VARCHAR(100) NOT NULL,
    tipo_servicio VARCHAR(100) NOT NULL,
    id_estado INT DEFAULT 1,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX idx_proveedores_correo (correo),
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
);

-- Crear tabla de historial de proveedores
CREATE TABLE historial_proveedores (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    id_proveedor INT NOT NULL,
    id_estado_anterior INT,
    id_estado_nuevo INT NOT NULL,
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usuario_modificacion INT,
    FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor) ON DELETE CASCADE,
    FOREIGN KEY (id_estado_anterior) REFERENCES estados(id_estado),
    FOREIGN KEY (id_estado_nuevo) REFERENCES estados(id_estado),
    FOREIGN KEY (usuario_modificacion) REFERENCES usuarios(id_usuario)
);

-- Crear tabla de historial detallado de proveedores
CREATE TABLE historial_proveedores_detallado (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    id_proveedor INT NOT NULL,
    campo_modificado VARCHAR(50) NOT NULL,
    valor_anterior TEXT,
    valor_nuevo TEXT,
    usuario_modificacion INT,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor) ON DELETE CASCADE,
    FOREIGN KEY (usuario_modificacion) REFERENCES usuarios(id_usuario)
);

-- Crear tabla de empleados
CREATE TABLE empleados (
    id_empleado INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    clave_sistema VARCHAR(20) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido_paterno VARCHAR(100) NOT NULL,
    apellido_materno VARCHAR(100),
    correo VARCHAR(100) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    cargo VARCHAR(100) NOT NULL,
    sueldo_actual DECIMAL(10,2) NOT NULL,
    fecha_contratacion DATE NOT NULL,
    imagen_empleado VARCHAR(255) NULL,
    id_estado INT DEFAULT 1,
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    INDEX idx_empleados_usuario (id_usuario)
);

-- Crear tabla de inmuebles con la columna margen_utilidad
CREATE TABLE inmuebles (
    id_inmueble INT AUTO_INCREMENT PRIMARY KEY,
    nombre_inmueble VARCHAR(100) NOT NULL,
    id_direccion INT,
    monto_total DECIMAL(12,2) NOT NULL,
    tipo_inmueble ENUM('casa', 'departamento', 'terreno', 'oficina', 'bodega', 'otro') NOT NULL DEFAULT 'casa',
    tipo_operacion ENUM('venta', 'renta') NOT NULL DEFAULT 'venta',
    precio_venta DECIMAL(12,2) DEFAULT NULL,
    precio_renta DECIMAL(12,2) DEFAULT NULL,
    id_estado INT DEFAULT 3,
    id_cliente INT,
    id_empleado INT,
    caracteristicas TEXT,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    costo_cliente DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Costo que pide el cliente por su propiedad',
    costo_servicios DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Costo de servicios de proveedores',
    comision_agencia DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Comisión para la agencia (30% del costo cliente)',
    comision_agente DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Comisión para el agente (3% del costo cliente)',
    precio_venta_final DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Suma total de todos los costos',
    margen_utilidad DECIMAL(5,2) DEFAULT 0.00 COMMENT 'Porcentaje de ganancia sobre el precio final',
    FOREIGN KEY (id_direccion) REFERENCES direcciones(id_direccion),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON DELETE SET NULL,
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado),
    FOREIGN KEY (id_empleado) REFERENCES empleados(id_empleado)
);

-- Crear tabla para clientes interesados
CREATE TABLE inmuebles_clientes_interesados (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_inmueble INT NOT NULL,
    id_cliente INT NOT NULL,
    fecha_interes TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    comentarios TEXT,
    FOREIGN KEY (id_inmueble) REFERENCES inmuebles(id_inmueble),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

-- Crear tabla para imágenes de inmuebles
CREATE TABLE inmuebles_imagenes (
    id_imagen INT AUTO_INCREMENT PRIMARY KEY,
    id_inmueble INT NOT NULL,
    ruta_imagen VARCHAR(255) NOT NULL,
    descripcion VARCHAR(100),
    es_principal BOOLEAN DEFAULT FALSE,
    fecha_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_inmueble) REFERENCES inmuebles(id_inmueble)
);

-- Crear tabla para relacionar clientes con inmuebles
CREATE TABLE cliente_inmueble (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_inmueble INT NOT NULL,
    fecha_adquisicion DATE NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_inmueble) REFERENCES inmuebles(id_inmueble),
    CONSTRAINT unique_inmueble UNIQUE (id_inmueble)
);

-- Crear tabla de ventas con el estado por defecto 'venta_en_proceso'
CREATE TABLE IF NOT EXISTS ventas (
    id_venta INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_inmueble INT NOT NULL,
    fecha_venta DATE NOT NULL,
    ingreso DECIMAL(15,2) NOT NULL COMMENT 'Dinero obtenido por la venta',
    comision_proveedores DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    utilidad_bruta DECIMAL(15,2) GENERATED ALWAYS AS (ingreso - comision_proveedores) STORED,
    utilidad_neta DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    id_estado INT DEFAULT 7, -- 'venta_en_proceso' por defecto
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_inmueble) REFERENCES inmuebles(id_inmueble),
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
);

-- Crear tabla para relacionar inmuebles con proveedores
CREATE TABLE inmueble_proveedor_servicio (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_inmueble INT NOT NULL,
    id_proveedor INT NOT NULL,
    servicio_detalle VARCHAR(255) NOT NULL,
    costo DECIMAL(12,2) NOT NULL,
    comision DECIMAL(12,2) GENERATED ALWAYS AS (costo * 0.30) STORED,
    fecha_asignacion DATE NOT NULL,
    fecha_servicio DATE,
    id_estado INT DEFAULT 1,
    FOREIGN KEY (id_inmueble) REFERENCES inmuebles(id_inmueble),
    FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor),
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
);

-- Crear tabla para historial de ventas
CREATE TABLE historial_ventas (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    campo_modificado VARCHAR(50) NOT NULL,
    valor_anterior TEXT,
    valor_nuevo TEXT,
    usuario_modificacion INT,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta) ON DELETE CASCADE,
    FOREIGN KEY (usuario_modificacion) REFERENCES usuarios(id_usuario)
);

-- Crear tabla para seguimiento de comisiones pagadas
CREATE TABLE comisiones_pagadas (
    id_comision INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    id_empleado INT,
    tipo_comision ENUM('agencia', 'agente') NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    fecha_pago DATE NOT NULL,
    id_estado INT DEFAULT 1,
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta),
    FOREIGN KEY (id_empleado) REFERENCES empleados(id_empleado),
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
);

-- Índices para mejorar el rendimiento
CREATE INDEX idx_inmueble_proveedor ON inmueble_proveedor_servicio(id_inmueble);
CREATE INDEX idx_proveedor_inmueble ON inmueble_proveedor_servicio(id_proveedor);
CREATE INDEX idx_cliente_inmueble_cliente ON cliente_inmueble(id_cliente);
CREATE INDEX idx_usuarios_estado ON usuarios(id_estado);
CREATE INDEX idx_inmuebles_cliente ON inmuebles(id_cliente);
CREATE INDEX idx_inmuebles_estado ON inmuebles(id_estado);
CREATE INDEX idx_clientes_estado ON clientes(id_estado);
CREATE INDEX idx_proveedores_estado ON proveedores(id_estado);
CREATE INDEX idx_empleados_estado ON empleados(id_estado);
CREATE INDEX idx_inmuebles_empleado ON inmuebles(id_empleado);
CREATE INDEX idx_inmuebles_clientes_interesados ON inmuebles_clientes_interesados(id_inmueble, id_cliente);
CREATE INDEX idx_inmuebles_imagenes ON inmuebles_imagenes(id_inmueble);
CREATE INDEX idx_historial_proveedores ON historial_proveedores(id_proveedor);
CREATE INDEX idx_historial_proveedores_detallado ON historial_proveedores_detallado(id_proveedor);
CREATE INDEX idx_ventas_cliente ON ventas(id_cliente);
CREATE INDEX idx_ventas_inmueble ON ventas(id_inmueble);
CREATE INDEX idx_ventas_fecha ON ventas(fecha_venta);
CREATE INDEX idx_ventas_fecha_estado ON ventas(fecha_venta, id_estado);
CREATE INDEX idx_comisiones_venta ON comisiones_pagadas(id_venta);
CREATE INDEX idx_historial_ventas_venta ON historial_ventas(id_venta);

-- Definir triggers
DELIMITER //

-- Trigger para validar correo de usuario
CREATE TRIGGER validar_correo_usuario
BEFORE INSERT ON usuarios
FOR EACH ROW
BEGIN
    IF NEW.correo_cliente IS NOT NULL AND 
       NEW.correo_cliente <> '' AND
       NEW.correo_cliente NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Correo electrónico de usuario inválido';
    END IF;
END //

-- Trigger para validar teléfono de cliente
CREATE TRIGGER validar_telefono_cliente
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
    IF NEW.telefono_cliente IS NOT NULL AND 
       NEW.telefono_cliente NOT REGEXP '^[+]?[0-9]{10,15}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Número de teléfono inválido';
    END IF;
END //

-- Trigger para validar correo de cliente
CREATE TRIGGER validar_correo_cliente
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
    IF NEW.correo_cliente IS NOT NULL AND 
       NEW.correo_cliente NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Correo electrónico inválido';
    END IF;
END //

-- Trigger para validar correo de proveedor
CREATE TRIGGER validar_correo_proveedor
BEFORE INSERT ON proveedores
FOR EACH ROW
BEGIN
    IF NEW.correo NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Correo electrónico del proveedor inválido';
    END IF;
END //

-- Trigger para validar teléfono de proveedor
CREATE TRIGGER validar_telefono_proveedor
BEFORE INSERT ON proveedores
FOR EACH ROW
BEGIN
    IF NEW.telefono NOT REGEXP '^[+]?[0-9]{10,15}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Número de teléfono del proveedor inválido';
    END IF;
END //

-- Trigger después de insertar un servicio
CREATE TRIGGER despues_insertar_servicio
AFTER INSERT ON inmueble_proveedor_servicio
FOR EACH ROW
BEGIN
    CALL ActualizarCostoServiciosInmueble(NEW.id_inmueble);
END //

-- Trigger después de actualizar un servicio
CREATE TRIGGER despues_actualizar_servicio
AFTER UPDATE ON inmueble_proveedor_servicio
FOR EACH ROW
BEGIN
    IF NEW.id_inmueble != OLD.id_inmueble THEN
        CALL ActualizarCostoServiciosInmueble(OLD.id_inmueble);
    END IF;
    CALL ActualizarCostoServiciosInmueble(NEW.id_inmueble);
END //

-- Trigger después de eliminar un servicio
CREATE TRIGGER despues_eliminar_servicio
AFTER DELETE ON inmueble_proveedor_servicio
FOR EACH ROW
BEGIN
    CALL ActualizarCostoServiciosInmueble(OLD.id_inmueble);
END //

DELIMITER ;

-- Definir funciones y procedimientos almacenados
DELIMITER //

-- Función para encriptar contraseñas
CREATE FUNCTION EncriptarContraseña(p_contraseña VARCHAR(255)) 
RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
    DECLARE salt VARCHAR(255);
    SET salt = SUBSTRING(MD5(RAND()), 1, 10);
    RETURN SHA2(CONCAT(p_contraseña, salt), 512);
END //

-- Procedimiento para crear usuario
CREATE PROCEDURE CrearUsuario(
    IN p_nombre VARCHAR(100), 
    IN p_apellido VARCHAR(100), 
    IN p_nombre_usuario VARCHAR(100), 
    IN p_contraseña VARCHAR(255),
    IN p_correo_cliente VARCHAR(100),
    IN p_imagen_perfil VARCHAR(255),
    OUT p_id_usuario_out INT
)
BEGIN
    DECLARE usuario_existente INT;
    DECLARE v_id_estado_activo INT DEFAULT 1;

    IF LENGTH(p_contraseña) < 8 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La contraseña debe tener al menos 8 caracteres';
    END IF;

    SELECT COUNT(*) INTO usuario_existente 
    FROM usuarios 
    WHERE nombre_usuario = p_nombre_usuario;

    IF usuario_existente > 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre de usuario ya existe';
    END IF;

    START TRANSACTION;
    
    INSERT INTO usuarios (
        nombre, apellido, nombre_usuario, contraseña_usuario, correo_cliente, imagen_perfil, id_estado
    ) VALUES (
        p_nombre, p_apellido, p_nombre_usuario, EncriptarContraseña(p_contraseña), p_correo_cliente, p_imagen_perfil, v_id_estado_activo
    );

    SET p_id_usuario_out = LAST_INSERT_ID();

    INSERT INTO historial_usuarios (
        id_usuario, id_estado_anterior, id_estado_nuevo
    ) VALUES (
        p_id_usuario_out, NULL, v_id_estado_activo
    );

    COMMIT;
END //

-- Procedimiento para actualizar usuario
CREATE PROCEDURE ActualizarUsuario(
    IN p_id_usuario INT, 
    IN p_nombre VARCHAR(100), 
    IN p_apellido VARCHAR(100), 
    IN p_nombre_usuario VARCHAR(100), 
    IN p_contraseña VARCHAR(255),
    IN p_correo_cliente VARCHAR(100),
    IN p_imagen_perfil VARCHAR(255)
)
BEGIN
    DECLARE estado_actual_id INT;
    
    SELECT id_estado INTO estado_actual_id
    FROM usuarios 
    WHERE id_usuario = p_id_usuario;
    
    IF estado_actual_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no encontrado';
    END IF;
    
    IF estado_actual_id = 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede actualizar un usuario inactivo';
    END IF;

    IF EXISTS (
        SELECT 1 
        FROM usuarios 
        WHERE nombre_usuario = p_nombre_usuario 
          AND id_usuario <> p_id_usuario
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nombre de usuario ya en uso';
    END IF;

    START TRANSACTION;

    UPDATE usuarios SET 
        nombre = p_nombre, 
        apellido = p_apellido, 
        nombre_usuario = p_nombre_usuario,
        correo_cliente = p_correo_cliente,
        imagen_perfil = p_imagen_perfil,
        contraseña_usuario = CASE 
            WHEN p_contraseña IS NOT NULL AND p_contraseña <> '' 
            THEN EncriptarContraseña(p_contraseña)
            ELSE contraseña_usuario
        END
    WHERE id_usuario = p_id_usuario;

    COMMIT;
END //

-- Procedimiento para inactivar usuario
CREATE PROCEDURE InactivarUsuario(IN p_id_usuario INT)
BEGIN
    DECLARE estado_actual_id INT;
    DECLARE v_id_estado_inactivo INT DEFAULT 2;

    SELECT id_estado INTO estado_actual_id
    FROM usuarios 
    WHERE id_usuario = p_id_usuario;

    IF estado_actual_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no encontrado';
    END IF;

    IF estado_actual_id = 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario ya está inactivo';
    END IF;

    START TRANSACTION;

    UPDATE usuarios 
    SET id_estado = v_id_estado_inactivo
    WHERE id_usuario = p_id_usuario;

    INSERT INTO historial_usuarios (
        id_usuario, id_estado_anterior, id_estado_nuevo
    ) VALUES (
        p_id_usuario, estado_actual_id, v_id_estado_inactivo
    );

    COMMIT;
END //

-- Procedimiento para crear cliente
CREATE PROCEDURE CrearCliente(
    IN p_nombre VARCHAR(100),
    IN p_apellido_paterno VARCHAR(100),
    IN p_apellido_materno VARCHAR(100),
    IN p_direccion_calle VARCHAR(100),
    IN p_direccion_numero VARCHAR(20),
    IN p_direccion_colonia VARCHAR(100),
    IN p_direccion_ciudad VARCHAR(100),
    IN p_direccion_estado_geografico VARCHAR(100),
    IN p_direccion_codigo_postal VARCHAR(10),
    IN p_direccion_referencias TEXT,
    IN p_telefono_cliente VARCHAR(20),
    IN p_rfc VARCHAR(13),
    IN p_curp VARCHAR(18),
    IN p_correo_cliente VARCHAR(100),
    IN p_tipo_cliente ENUM('comprador', 'arrendatario', 'ambos'),
    OUT p_id_cliente_out INT
)
BEGIN
    DECLARE v_id_direccion INT;
    DECLARE v_id_estado_activo INT DEFAULT 1;
    
    IF NOT (p_rfc REGEXP '^[A-Z&Ñ]{3,4}[0-9]{6}[A-Z0-9]{3}$') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de RFC inválido';
    END IF;
    
    IF NOT (p_curp REGEXP '^[A-Z][AEIOUX][A-Z]{2}[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[HM](AS|BC|BS|CC|CL|CM|CS|CH|DF|DG|GT|GR|HG|JC|MC|MN|MS|NT|NL|OC|PL|QT|QR|SP|SL|SR|TC|TS|TL|VZ|YN|ZS|NE)[B-DF-HJ-NP-TV-Z]{3}[0-9A-Z][0-9]$') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de CURP inválido';
    END IF;
    
    START TRANSACTION;
    
    INSERT INTO direcciones (
        calle, numero, colonia, ciudad, estado_geografico, codigo_postal, referencias, id_estado
    ) VALUES (
        p_direccion_calle, p_direccion_numero, p_direccion_colonia, p_direccion_ciudad, 
        p_direccion_estado_geografico, p_direccion_codigo_postal, p_direccion_referencias, v_id_estado_activo
    );
    
    SET v_id_direccion = LAST_INSERT_ID();
    
    INSERT INTO clientes (
        nombre, apellido_paterno, apellido_materno, id_direccion, telefono_cliente, 
        rfc, curp, tipo_cliente, correo_cliente, id_estado
    ) VALUES (
        p_nombre, p_apellido_paterno, p_apellido_materno, v_id_direccion, p_telefono_cliente, 
        UPPER(p_rfc), UPPER(p_curp), COALESCE(p_tipo_cliente, 'comprador'), p_correo_cliente, v_id_estado_activo
    );
    
    SET p_id_cliente_out = LAST_INSERT_ID();
    
    COMMIT;
END //

-- Procedimiento para leer clientes
CREATE PROCEDURE LeerClientes()
BEGIN
    SELECT 
        c.id_cliente,
        c.nombre,
        c.apellido_paterno,
        c.apellido_materno,
        c.id_direccion,
        c.telefono_cliente,
        c.rfc,
        c.curp,
        c.tipo_cliente,
        c.correo_cliente,
        c.id_estado,
        c.fecha_registro,
        d.calle,
        d.numero,
        d.colonia,
        d.ciudad,
        d.estado_geografico,
        d.codigo_postal,
        d.referencias,
        e.nombre_estado AS estado_cliente
    FROM clientes c
    LEFT JOIN direcciones d ON c.id_direccion = d.id_direccion
    LEFT JOIN estados e ON c.id_estado = e.id_estado
    WHERE c.id_estado = 1;
END //

-- Procedimiento para actualizar cliente
CREATE PROCEDURE ActualizarCliente(
    IN p_id_cliente INT,
    IN p_nombre VARCHAR(100),
    IN p_apellido_paterno VARCHAR(100),
    IN p_apellido_materno VARCHAR(100),
    IN p_telefono_cliente VARCHAR(20),
    IN p_rfc VARCHAR(13),
    IN p_curp VARCHAR(18),
    IN p_correo_cliente VARCHAR(100),
    IN p_direccion_calle VARCHAR(100),
    IN p_direccion_numero VARCHAR(20),
    IN p_direccion_colonia VARCHAR(100),
    IN p_direccion_ciudad VARCHAR(100),
    IN p_direccion_estado_geografico VARCHAR(100),
    IN p_direccion_codigo_postal VARCHAR(10),
    IN p_direccion_referencias TEXT,
    IN p_tipo_cliente ENUM('comprador', 'arrendatario', 'ambos')
)
BEGIN
    DECLARE v_id_direccion INT;
    DECLARE v_estado_actual INT;
    
    SELECT id_direccion, id_estado INTO v_id_direccion, v_estado_actual
    FROM clientes 
    WHERE id_cliente = p_id_cliente;
    
    IF v_id_direccion IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente no encontrado';
    END IF;
    
    IF v_estado_actual != 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede actualizar un cliente inactivo';
    END IF;
    
    IF NOT (p_rfc REGEXP '^[A-Z&Ñ]{3,4}[0-9]{6}[A-Z0-9]{3}$') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de RFC inválido';
    END IF;
    
    IF NOT (p_curp REGEXP '^[A-Z][AEIOUX][A-Z]{2}[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[HM](AS|BC|BS|CC|CL|CM|CS|CH|DF|DG|GT|GR|HG|JC|MC|MN|MS|NT|NL|OC|PL|QT|QR|SP|SL|SR|TC|TS|TL|VZ|YN|ZS|NE)[B-DF-HJ-NP-TV-Z]{3}[0-9A-Z][0-9]$') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de CURP inválido';
    END IF;
    
    START TRANSACTION;
    
    UPDATE direcciones SET
        calle = p_direccion_calle,
        numero = p_direccion_numero,
        colonia = p_direccion_colonia,
        ciudad = p_direccion_ciudad,
        estado_geografico = p_direccion_estado_geografico,
        codigo_postal = p_direccion_codigo_postal,
        referencias = p_direccion_referencias
    WHERE id_direccion = v_id_direccion;
    
    UPDATE clientes SET
        nombre = p_nombre,
        apellido_paterno = p_apellido_paterno,
        apellido_materno = p_apellido_materno,
        telefono_cliente = p_telefono_cliente,
        rfc = UPPER(p_rfc),
        curp = UPPER(p_curp),
        tipo_cliente = COALESCE(p_tipo_cliente, 'comprador'),
        correo_cliente = p_correo_cliente
    WHERE id_cliente = p_id_cliente;
    
    COMMIT;
END //

-- Procedimiento para inactivar cliente
CREATE PROCEDURE InactivarCliente(IN p_id_cliente INT)
BEGIN
    DECLARE v_id_estado_inactivo INT DEFAULT 2;
    DECLARE v_estado_actual INT;
    
    SELECT id_estado INTO v_estado_actual
    FROM clientes 
    WHERE id_cliente = p_id_cliente;
    
    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente no encontrado';
    END IF;
    
    IF v_estado_actual = 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente ya está inactivo';
    END IF;
    
    START TRANSACTION;
    
    UPDATE clientes 
    SET id_estado = v_id_estado_inactivo
    WHERE id_cliente = p_id_cliente;
    
    COMMIT;
END //

-- Procedimiento para reactivar cliente
CREATE PROCEDURE ReactivarCliente(IN p_id_cliente INT)
BEGIN
    DECLARE v_id_estado_activo INT DEFAULT 1;
    DECLARE v_estado_actual INT;
    
    SELECT id_estado INTO v_estado_actual
    FROM clientes 
    WHERE id_cliente = p_id_cliente;
    
    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente no encontrado';
    END IF;
    
    IF v_estado_actual = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente ya está activo';
    END IF;
    
    START TRANSACTION;
    
    UPDATE clientes 
    SET id_estado = v_id_estado_activo
    WHERE id_cliente = p_id_cliente;
    
    COMMIT;
END //

-- Procedimiento para crear inmueble
CREATE PROCEDURE CrearInmueble(
    IN p_nombre_inmueble VARCHAR(100),
    IN p_direccion_calle VARCHAR(100),
    IN p_direccion_numero VARCHAR(20),
    IN p_direccion_colonia VARCHAR(100),
    IN p_direccion_ciudad VARCHAR(100),
    IN p_direccion_estado_geografico VARCHAR(100),
    IN p_direccion_codigo_postal VARCHAR(10),
    IN p_direccion_referencias TEXT,
    IN p_monto_total DECIMAL(12,2),
    IN p_tipo_inmueble ENUM('casa', 'departamento', 'terreno', 'oficina', 'bodega', 'otro'),
    IN p_tipo_operacion ENUM('venta', 'renta'),
    IN p_precio_venta DECIMAL(12,2),
    IN p_precio_renta DECIMAL(12,2),
    IN p_id_estado INT,
    IN p_id_cliente INT,
    IN p_id_empleado INT,
    IN p_caracteristicas TEXT,
    IN p_costo_cliente DECIMAL(12,2),
    IN p_costo_servicios DECIMAL(12,2),
    OUT p_id_inmueble_out INT
)
BEGIN
    DECLARE v_id_direccion INT;
    DECLARE v_id_estado INT DEFAULT 3;
    DECLARE v_comision_agencia DECIMAL(12,2);
    DECLARE v_comision_agente DECIMAL(12,2);
    DECLARE v_precio_venta_final DECIMAL(12,2);
    DECLARE v_margen_utilidad DECIMAL(5,2);
    
    SET v_comision_agencia = IFNULL(p_costo_cliente, 0) * 0.30;
    SET v_comision_agente = IFNULL(p_costo_cliente, 0) * 0.03;
    SET v_precio_venta_final = IFNULL(p_costo_cliente, 0) + IFNULL(p_costo_servicios, 0) + v_comision_agencia + v_comision_agente;
    SET v_margen_utilidad = IF(v_precio_venta_final > 0, ((v_comision_agencia + v_comision_agente) / v_precio_venta_final) * 100, 0);
    
    START TRANSACTION;
    
    INSERT INTO direcciones (
        calle, numero, colonia, ciudad, estado_geografico, codigo_postal, referencias, id_estado
    ) VALUES (
        p_direccion_calle, p_direccion_numero, p_direccion_colonia, p_direccion_ciudad, 
        p_direccion_estado_geografico, p_direccion_codigo_postal, p_direccion_referencias, 1
    );
    
    SET v_id_direccion = LAST_INSERT_ID();
    
    IF p_id_estado IS NOT NULL THEN
        SET v_id_estado = p_id_estado;
    END IF;
    
    INSERT INTO inmuebles (
        nombre_inmueble, id_direccion, monto_total, tipo_inmueble, tipo_operacion, 
        precio_venta, precio_renta, id_estado, id_cliente, id_empleado, caracteristicas,
        costo_cliente, costo_servicios, comision_agencia, comision_agente, precio_venta_final, margen_utilidad
    ) VALUES (
        p_nombre_inmueble, v_id_direccion, p_monto_total, COALESCE(p_tipo_inmueble, 'casa'), 
        COALESCE(p_tipo_operacion, 'venta'), p_precio_venta, p_precio_renta, v_id_estado, 
        p_id_cliente, p_id_empleado, p_caracteristicas,
        p_costo_cliente, p_costo_servicios, v_comision_agencia, v_comision_agente, v_precio_venta_final, v_margen_utilidad
    );
    
    SET p_id_inmueble_out = LAST_INSERT_ID();
    
    COMMIT;
END //

-- Procedimiento para actualizar inmueble
CREATE PROCEDURE ActualizarInmueble(
    IN p_id_inmueble INT,
    IN p_nombre_inmueble VARCHAR(100),
    IN p_direccion_calle VARCHAR(100),
    IN p_direccion_numero VARCHAR(20),
    IN p_direccion_colonia VARCHAR(100),
    IN p_direccion_ciudad VARCHAR(100),
    IN p_direccion_estado_geografico VARCHAR(100),
    IN p_direccion_codigo_postal VARCHAR(10),
    IN p_direccion_referencias TEXT,
    IN p_monto_total DECIMAL(12,2),
    IN p_tipo_inmueble ENUM('casa', 'departamento', 'terreno', 'oficina', 'bodega', 'otro'),
    IN p_tipo_operacion ENUM('venta', 'renta'),
    IN p_precio_venta DECIMAL(12,2),
    IN p_precio_renta DECIMAL(12,2),
    IN p_id_estado INT,
    IN p_id_cliente INT,
    IN p_id_empleado INT,
    IN p_caracteristicas TEXT,
    IN p_costo_cliente DECIMAL(12,2),
    IN p_costo_servicios DECIMAL(12,2)
)
BEGIN
    DECLARE v_id_direccion INT;
    DECLARE v_comision_agencia DECIMAL(12,2);
    DECLARE v_comision_agente DECIMAL(12,2);
    DECLARE v_precio_venta_final DECIMAL(12,2);
    DECLARE v_margen_utilidad DECIMAL(5,2);
    
    SET v_comision_agencia = IFNULL(p_costo_cliente, 0) * 0.30;
    SET v_comision_agente = IFNULL(p_costo_cliente, 0) * 0.03;
    SET v_precio_venta_final = IFNULL(p_costo_cliente, 0) + IFNULL(p_costo_servicios, 0) + v_comision_agencia + v_comision_agente;
    SET v_margen_utilidad = IF(v_precio_venta_final > 0, ((v_comision_agencia + v_comision_agente) / v_precio_venta_final) * 100, 0);

    SELECT id_direccion INTO v_id_direccion
    FROM inmuebles 
    WHERE id_inmueble = p_id_inmueble;

    IF v_id_direccion IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inmueble no encontrado';
    END IF;

    START TRANSACTION;

    UPDATE direcciones SET
        calle = p_direccion_calle,
        numero = p_direccion_numero,
        colonia = p_direccion_colonia,
        ciudad = p_direccion_ciudad,
        estado_geografico = p_direccion_estado_geografico,
        codigo_postal = p_direccion_codigo_postal,
        referencias = p_direccion_referencias
    WHERE id_direccion = v_id_direccion;

    UPDATE inmuebles SET
        nombre_inmueble = p_nombre_inmueble,
        monto_total = p_monto_total,
        tipo_inmueble = COALESCE(p_tipo_inmueble, 'casa'),
        tipo_operacion = COALESCE(p_tipo_operacion, 'venta'),
        precio_venta = p_precio_venta,
        precio_renta = p_precio_renta,
        id_estado = p_id_estado,
        id_cliente = p_id_cliente,
        id_empleado = p_id_empleado,
        caracteristicas = p_caracteristicas,
        costo_cliente = p_costo_cliente,
        costo_servicios = p_costo_servicios,
        comision_agencia = v_comision_agencia,
        comision_agente = v_comision_agente,
        precio_venta_final = v_precio_venta_final,
        margen_utilidad = v_margen_utilidad
    WHERE id_inmueble = p_id_inmueble;

    COMMIT;
END //

-- Procedimiento para crear proveedor
CREATE PROCEDURE CrearProveedor(
    IN p_nombre VARCHAR(100), 
    IN p_nombre_empresa VARCHAR(150), 
    IN p_nombre_contacto VARCHAR(100), 
    IN p_direccion VARCHAR(255), 
    IN p_telefono VARCHAR(15), 
    IN p_correo VARCHAR(100), 
    IN p_tipo_servicio VARCHAR(100),
    IN p_usuario_modificacion INT,
    OUT p_id_proveedor_out INT
)
BEGIN
    DECLARE v_id_estado_activo INT DEFAULT 1;
    
    IF p_correo NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Correo electrónico del proveedor inválido';
    END IF;
    
    IF p_telefono NOT REGEXP '^[+]?[0-9]{10,15}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Número de teléfono del proveedor inválido';
    END IF;

    START TRANSACTION;
    
    INSERT INTO proveedores (
        nombre, nombre_empresa, nombre_contacto, direccion, telefono, correo, tipo_servicio, id_estado
    ) VALUES (
        p_nombre, p_nombre_empresa, p_nombre_contacto, p_direccion, p_telefono, p_correo, p_tipo_servicio, v_id_estado_activo
    );
    
    SET p_id_proveedor_out = LAST_INSERT_ID();
    
    INSERT INTO historial_proveedores (
        id_proveedor, id_estado_anterior, id_estado_nuevo, usuario_modificacion
    ) VALUES (
        p_id_proveedor_out, NULL, v_id_estado_activo, p_usuario_modificacion
    );
    
    COMMIT;
END //

-- Procedimiento para leer proveedores
CREATE PROCEDURE LeerProveedores()
BEGIN
    SELECT 
        p.id_proveedor,
        p.nombre,
        p.nombre_empresa,
        p.nombre_contacto,
        p.direccion,
        p.telefono,
        p.correo,
        p.tipo_servicio,
        p.id_estado,
        p.fecha_creacion,
        p.fecha_modificacion,
        e.nombre_estado AS estado_proveedor
    FROM proveedores p
    LEFT JOIN estados e ON p.id_estado = e.id_estado
    WHERE p.id_estado = 1;
END //

-- Procedimiento para obtener todos los proveedores
CREATE PROCEDURE ObtenerProveedores()
BEGIN
    SELECT 
        p.id_proveedor,
        p.nombre,
        p.nombre_empresa,
        p.nombre_contacto,
        p.direccion,
        p.telefono,
        p.correo,
        p.tipo_servicio,
        p.id_estado,
        p.fecha_creacion,
        p.fecha_modificacion,
        e.nombre_estado AS estado_proveedor
    FROM proveedores p
    LEFT JOIN estados e ON p.id_estado = e.id_estado;
END //

-- Procedimiento para actualizar proveedor
CREATE PROCEDURE ActualizarProveedor(
    IN p_id_proveedor INT,
    IN p_nombre VARCHAR(100),
    IN p_nombre_empresa VARCHAR(150),
    IN p_nombre_contacto VARCHAR(100),
    IN p_direccion VARCHAR(255),
    IN p_telefono VARCHAR(15),
    IN p_correo VARCHAR(100),
    IN p_tipo_servicio VARCHAR(100),
    IN p_usuario_modificacion INT
)
BEGIN
    DECLARE v_estado_actual INT;
    DECLARE v_nombre_actual VARCHAR(100);
    DECLARE v_empresa_actual VARCHAR(150);
    DECLARE v_contacto_actual VARCHAR(100);
    DECLARE v_direccion_actual VARCHAR(255);
    DECLARE v_telefono_actual VARCHAR(15);
    DECLARE v_correo_actual VARCHAR(100);
    DECLARE v_servicio_actual VARCHAR(100);

    SELECT id_estado, nombre, nombre_empresa, nombre_contacto, direccion, telefono, correo, tipo_servicio
    INTO v_estado_actual, v_nombre_actual, v_empresa_actual, v_contacto_actual, v_direccion_actual, v_telefono_actual, v_correo_actual, v_servicio_actual
    FROM proveedores 
    WHERE id_proveedor = p_id_proveedor;
    
    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proveedor especificado no existe';
    END IF;
    
    IF v_estado_actual != 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede actualizar un proveedor inactivo';
    END IF;
    
    IF p_correo NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Correo electrónico del proveedor inválido';
    END IF;
    
    IF p_telefono NOT REGEXP '^[+]?[0-9]{10,15}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Número de teléfono del proveedor inválido';
    END IF;

    IF EXISTS (
        SELECT 1 
        FROM proveedores 
        WHERE correo = p_correo 
        AND id_proveedor != p_id_proveedor
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El correo ya está en uso por otro proveedor';
    END IF;

    START TRANSACTION;
    
    UPDATE proveedores 
    SET nombre = p_nombre,
        nombre_empresa = p_nombre_empresa,
        nombre_contacto = p_nombre_contacto,
        direccion = p_direccion,
        telefono = p_telefono,
        correo = p_correo,
        tipo_servicio = p_tipo_servicio,
        fecha_modificacion = CURRENT_TIMESTAMP
    WHERE id_proveedor = p_id_proveedor;

    IF v_nombre_actual != p_nombre THEN
        INSERT INTO historial_proveedores_detallado (id_proveedor, campo_modificado, valor_anterior, valor_nuevo, usuario_modificacion)
        VALUES (p_id_proveedor, 'nombre', v_nombre_actual, p_nombre, p_usuario_modificacion);
    END IF;
    IF v_empresa_actual != p_nombre_empresa THEN
        INSERT INTO historial_proveedores_detallado (id_proveedor, campo_modificado, valor_anterior, valor_nuevo, usuario_modificacion)
        VALUES (p_id_proveedor, 'nombre_empresa', v_empresa_actual, p_nombre_empresa, p_usuario_modificacion);
    END IF;
    IF v_contacto_actual != p_nombre_contacto THEN
        INSERT INTO historial_proveedores_detallado (id_proveedor, campo_modificado, valor_anterior, valor_nuevo, usuario_modificacion)
        VALUES (p_id_proveedor, 'nombre_contacto', v_contacto_actual, p_nombre_contacto, p_usuario_modificacion);
    END IF;
    IF v_direccion_actual != p_direccion THEN
        INSERT INTO historial_proveedores_detallado (id_proveedor, campo_modificado, valor_anterior, valor_nuevo, usuario_modificacion)
        VALUES (p_id_proveedor, 'direccion', v_direccion_actual, p_direccion, p_usuario_modificacion);
    END IF;
    IF v_telefono_actual != p_telefono THEN
        INSERT INTO historial_proveedores_detallado (id_proveedor, campo_modificado, valor_anterior, valor_nuevo, usuario_modificacion)
        VALUES (p_id_proveedor, 'telefono', v_telefono_actual, p_telefono, p_usuario_modificacion);
    END IF;
    IF v_correo_actual != p_correo THEN
        INSERT INTO historial_proveedores_detallado (id_proveedor, campo_modificado, valor_anterior, valor_nuevo, usuario_modificacion)
        VALUES (p_id_proveedor, 'correo', v_correo_actual, p_correo, p_usuario_modificacion);
    END IF;
    IF v_servicio_actual != p_tipo_servicio THEN
        INSERT INTO historial_proveedores_detallado (id_proveedor, campo_modificado, valor_anterior, valor_nuevo, usuario_modificacion)
        VALUES (p_id_proveedor, 'tipo_servicio', v_servicio_actual, p_tipo_servicio, p_usuario_modificacion);
    END IF;
    
    COMMIT;
END //

-- Procedimiento para inactivar proveedor
CREATE PROCEDURE InactivarProveedor(
    IN p_id_proveedor INT,
    IN p_usuario_modificacion INT
)
BEGIN
    DECLARE v_id_estado_inactivo INT DEFAULT 2;
    DECLARE v_estado_actual INT;
    
    SELECT id_estado INTO v_estado_actual
    FROM proveedores 
    WHERE id_proveedor = p_id_proveedor;
    
    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Proveedor no encontrado';
    END IF;
    
    IF v_estado_actual = v_id_estado_inactivo THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proveedor ya está inactivo';
    END IF;
    
    START TRANSACTION;
    
    UPDATE proveedores 
    SET id_estado = v_id_estado_inactivo,
        fecha_modificacion = CURRENT_TIMESTAMP
    WHERE id_proveedor = p_id_proveedor;
    
    INSERT INTO historial_proveedores (
        id_proveedor, id_estado_anterior, id_estado_nuevo, usuario_modificacion
    ) VALUES (
        p_id_proveedor, v_estado_actual, v_id_estado_inactivo, p_usuario_modificacion
    );
    
    INSERT INTO historial_proveedores_detallado (
        id_proveedor, campo_modificado, valor_anterior, valor_nuevo, usuario_modificacion
    ) VALUES (
        p_id_proveedor, 'id_estado', v_estado_actual, v_id_estado_inactivo, p_usuario_modificacion
    );
    
    COMMIT;
END //

-- Procedimiento para reactivar proveedor
CREATE PROCEDURE ReactivarProveedor(
    IN p_id_proveedor INT,
    IN p_usuario_modificacion INT
)
BEGIN
    DECLARE v_id_estado_activo INT DEFAULT 1;
    DECLARE v_estado_actual INT;
    
    SELECT id_estado INTO v_estado_actual
    FROM proveedores 
    WHERE id_proveedor = p_id_proveedor;
    
    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Proveedor no encontrado';
    END IF;
    
    IF v_estado_actual = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proveedor ya está activo';
    END IF;
    
    START TRANSACTION;
    
    UPDATE proveedores 
    SET id_estado = v_id_estado_activo,
        fecha_modificacion = CURRENT_TIMESTAMP
    WHERE id_proveedor = p_id_proveedor;
    
    INSERT INTO historial_proveedores (
        id_proveedor, id_estado_anterior, id_estado_nuevo, usuario_modificacion
    ) VALUES (
        p_id_proveedor, v_estado_actual, v_id_estado_activo, p_usuario_modificacion
    );
    
    INSERT INTO historial_proveedores_detallado (
        id_proveedor, campo_modificado, valor_anterior, valor_nuevo, usuario_modificacion
    ) VALUES (
        p_id_proveedor, 'id_estado', v_estado_actual, v_id_estado_activo, p_usuario_modificacion
    );
    
    COMMIT;
END //

-- Procedimiento para buscar proveedores
CREATE PROCEDURE BuscarProveedores(IN p_termino_busqueda VARCHAR(100))
BEGIN
    SELECT 
        p.id_proveedor,
        p.nombre,
        p.nombre_empresa,
        p.nombre_contacto,
        p.direccion,
        p.telefono,
        p.correo,
        p.tipo_servicio,
        p.id_estado,
        p.fecha_creacion,
        p.fecha_modificacion,
        e.nombre_estado AS estado_proveedor
    FROM proveedores p
    LEFT JOIN estados e ON p.id_estado = e.id_estado
    WHERE 
        p.nombre LIKE CONCAT('%', p_termino_busqueda, '%') OR
        p.nombre_empresa LIKE CONCAT('%', p_termino_busqueda, '%') OR
        p.nombre_contacto LIKE CONCAT('%', p_termino_busqueda, '%') OR
        p.tipo_servicio LIKE CONCAT('%', p_termino_busqueda, '%');
END //

-- Procedimiento para crear empleado
CREATE PROCEDURE CrearEmpleado(
    IN p_clave_sistema VARCHAR(20),
    IN p_nombre VARCHAR(100),
    IN p_apellido_paterno VARCHAR(100),
    IN p_apellido_materno VARCHAR(100),
    IN p_correo VARCHAR(100),
    IN p_telefono VARCHAR(15),
    IN p_direccion VARCHAR(255),
    IN p_cargo VARCHAR(100),
    IN p_sueldo_actual DECIMAL(10,2),
    IN p_fecha_contratacion DATE,
    IN p_imagen_empleado VARCHAR(255),
    OUT p_id_empleado_out INT
)
BEGIN
    DECLARE v_id_estado_activo INT DEFAULT 1;
    
    START TRANSACTION;
    
    INSERT INTO empleados (
        clave_sistema, nombre, apellido_paterno, apellido_materno, correo, telefono, 
        direccion, cargo, sueldo_actual, fecha_contratacion, imagen_empleado, id_estado
    ) VALUES (
        p_clave_sistema, p_nombre, p_apellido_paterno, p_apellido_materno, p_correo, p_telefono, 
        p_direccion, p_cargo, p_sueldo_actual, p_fecha_contratacion, p_imagen_empleado, v_id_estado_activo
    );
    
    SET p_id_empleado_out = LAST_INSERT_ID();
    
    COMMIT;
END //

-- Procedimiento para leer empleados
CREATE PROCEDURE LeerEmpleados()
BEGIN
    SELECT 
        e.id_empleado,
        e.id_usuario,
        e.clave_sistema,
        e.nombre,
        e.apellido_paterno,
        e.apellido_materno,
        e.correo,
        e.telefono,
        e.direccion,
        e.cargo,
        e.sueldo_actual,
        e.fecha_contratacion,
        e.imagen_empleado,
        e.id_estado,
        est.nombre_estado AS estado_empleado
    FROM empleados e
    LEFT JOIN estados est ON e.id_estado = est.id_estado
    WHERE e.id_estado = 1;
END //

-- Procedimiento para actualizar empleado
CREATE PROCEDURE ActualizarEmpleado(
    IN p_id_empleado INT,
    IN p_clave_sistema VARCHAR(100),
    IN p_nombre VARCHAR(100),
    IN p_apellido_paterno VARCHAR(100),
    IN p_apellido_materno VARCHAR(100),
    IN p_correo VARCHAR(100),
    IN p_telefono VARCHAR(15),
    IN p_direccion VARCHAR(255),
    IN p_cargo VARCHAR(100),
    IN p_sueldo_actual DECIMAL(10,2),
    IN p_imagen_empleado VARCHAR(255)
)
BEGIN
    DECLARE v_estado_actual INT;
    
    SELECT id_estado INTO v_estado_actual
    FROM empleados 
    WHERE id_empleado = p_id_empleado;
    
    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Empleado no encontrado';
    END IF;
    
    IF v_estado_actual != 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede actualizar un empleado inactivo';
    END IF;
    
    START TRANSACTION;
    
    UPDATE empleados SET 
        clave_sistema = p_clave_sistema,
        nombre = p_nombre,
        apellido_paterno = p_apellido_paterno,
        apellido_materno = p_apellido_materno,
        correo = p_correo,
        telefono = p_telefono,
        direccion = p_direccion,
        cargo = p_cargo,
        sueldo_actual = p_sueldo_actual,
        imagen_empleado = p_imagen_empleado
    WHERE id_empleado = p_id_empleado;
    
    COMMIT;
END //

-- Procedimiento para inactivar empleado
CREATE PROCEDURE InactivarEmpleado(IN p_id_empleado INT)
BEGIN
    DECLARE v_id_estado_inactivo INT DEFAULT 2;
    DECLARE v_estado_actual INT;
    
    SELECT id_estado INTO v_estado_actual
    FROM empleados 
    WHERE id_empleado = p_id_empleado;
    
    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Empleado no encontrado';
    END IF;
    
    IF v_estado_actual = 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El empleado ya está inactivo';
    END IF;
    
    START TRANSACTION;
    
    UPDATE empleados 
    SET id_estado = v_id_estado_inactivo
    WHERE id_empleado = p_id_empleado;
    
    COMMIT;
END //

-- Procedimiento para buscar cliente por RFC
CREATE PROCEDURE BuscarClientePorRFC(IN p_rfc VARCHAR(13))
BEGIN
    SELECT 
        c.id_cliente,
        c.nombre,
        c.apellido_paterno,
        c.apellido_materno,
        c.id_direccion,
        c.telefono_cliente,
        c.rfc,
        c.curp,
        c.tipo_cliente,
        c.correo_cliente,
        c.id_estado,
        c.fecha_registro,
        d.calle,
        d.numero,
        d.colonia,
        d.ciudad,
        d.estado_geografico,
        d.codigo_postal,
        d.referencias,
        e.nombre_estado AS estado_cliente
    FROM clientes c
    LEFT JOIN direcciones d ON c.id_direccion = d.id_direccion
    LEFT JOIN estados e ON c.id_estado = e.id_estado
    WHERE c.rfc = UPPER(p_rfc);
END //

-- Procedimiento para buscar cliente por nombre
CREATE PROCEDURE BuscarClientePorNombre(IN p_texto VARCHAR(100))
BEGIN
    SELECT 
        c.id_cliente,
        c.nombre,
        c.apellido_paterno,
        c.apellido_materno,
        c.id_direccion,
        c.telefono_cliente,
        c.rfc,
        c.curp,
        c.tipo_cliente,
        c.correo_cliente,
        c.id_estado,
        c.fecha_registro,
        d.calle,
        d.numero,
        d.colonia,
        d.ciudad,
        d.estado_geografico,
        d.codigo_postal,
        d.referencias,
        e.nombre_estado AS estado_cliente
    FROM clientes c
    LEFT JOIN direcciones d ON c.id_direccion = d.id_direccion
    LEFT JOIN estados e ON c.id_estado = e.id_estado
    WHERE CONCAT(c.nombre, ' ', c.apellido_paterno, ' ', IFNULL(c.apellido_materno, '')) 
          LIKE CONCAT('%', p_texto, '%');
END //

-- Procedimiento para buscar inmueble por cliente
CREATE PROCEDURE BuscarInmueblePorCliente(IN p_id_cliente INT)
BEGIN
    SELECT 
        i.id_inmueble,
        i.nombre_inmueble,
        i.id_direccion,
        i.monto_total,
        i.tipo_inmueble,
        i.tipo_operacion,
        i.precio_venta,
        i.precio_renta,
        i.id_estado,
        i.id_cliente,
        i.id_empleado,
        i.caracteristicas,
        i.fecha_registro,
        i.margen_utilidad,
        d.calle,
        d.numero,
        d.colonia,
        d.ciudad,
        d.estado_geografico,
        d.codigo_postal,
        d.referencias,
        e.nombre_estado AS estado_inmueble
    FROM inmuebles i
    LEFT JOIN direcciones d ON i.id_direccion = d.id_direccion
    LEFT JOIN estados e ON i.id_estado = e.id_estado
    WHERE i.id_cliente = p_id_cliente;
END //

-- Procedimiento para crear usuario y empleado
CREATE PROCEDURE CrearUsuarioEmpleado(
    IN p_nombre VARCHAR(100),
    IN p_apellido VARCHAR(100),
    IN p_nombre_usuario VARCHAR(100),
    IN p_contraseña VARCHAR(255),
    IN p_correo VARCHAR(100),
    IN p_imagen_perfil VARCHAR(255),
    IN p_clave_sistema VARCHAR(20),
    IN p_apellido_materno VARCHAR(100),
    IN p_telefono VARCHAR(15),
    IN p_direccion VARCHAR(255),
    IN p_cargo VARCHAR(100),
    IN p_sueldo_actual DECIMAL(10,2),
    IN p_fecha_contratacion DATE,
    IN p_correo_contacto VARCHAR(100),
    IN p_imagen_empleado VARCHAR(255),
    OUT p_id_usuario_out INT,
    OUT p_id_empleado_out INT
)
BEGIN
    DECLARE v_id_estado_activo INT DEFAULT 1;
    
    SET p_correo = CASE WHEN p_correo IS NULL OR p_correo = '' THEN p_correo_contacto ELSE p_correo END;
    
    IF LENGTH(p_contraseña) < 8 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La contraseña debe tener al menos 8 caracteres';
    END IF;

    IF EXISTS(SELECT 1 FROM usuarios WHERE nombre_usuario = p_nombre_usuario) THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre de usuario ya existe';
    END IF;
    
    START TRANSACTION;
    
    INSERT INTO usuarios (
        nombre, apellido, nombre_usuario, contraseña_usuario, correo_cliente, imagen_perfil, id_estado
    ) VALUES (
        p_nombre, p_apellido, p_nombre_usuario, EncriptarContraseña(p_contraseña), p_correo, p_imagen_perfil, v_id_estado_activo
    );
    
    SET p_id_usuario_out = LAST_INSERT_ID();
    
    INSERT INTO historial_usuarios (id_usuario, id_estado_anterior, id_estado_nuevo)
    VALUES (p_id_usuario_out, NULL, v_id_estado_activo);
    
    INSERT INTO empleados (
        id_usuario, clave_sistema, nombre, apellido_paterno, apellido_materno, 
        correo, telefono, direccion, cargo, sueldo_actual, fecha_contratacion, 
        imagen_empleado, id_estado
    ) VALUES (
        p_id_usuario_out, p_clave_sistema, p_nombre, p_apellido, p_apellido_materno,
        p_correo_contacto, p_telefono, p_direccion, p_cargo, p_sueldo_actual, 
        p_fecha_contratacion, p_imagen_empleado, v_id_estado_activo
    );
    
    SET p_id_empleado_out = LAST_INSERT_ID();
    
    COMMIT;
END //

-- Procedimiento para leer empleados con usuarios
CREATE PROCEDURE LeerEmpleadosConUsuarios()
BEGIN
    SELECT 
        e.id_empleado,
        e.id_usuario,
        e.clave_sistema,
        e.nombre,
        e.apellido_paterno,
        e.apellido_materno,
        e.correo,
        e.telefono,
        e.direccion,
        e.cargo,
        e.sueldo_actual,
        e.fecha_contratacion,
        e.imagen_empleado,
        e.id_estado,
        u.nombre_usuario,
        u.correo_cliente,
        u.imagen_perfil,
        u.id_estado AS usuario_estado,
        est.nombre_estado AS estado_empleado
    FROM empleados e
    LEFT JOIN usuarios u ON e.id_usuario = u.id_usuario
    LEFT JOIN estados est ON e.id_estado = est.id_estado
    WHERE e.id_estado = 1;
END //

-- Procedimiento para obtener empleado con usuario
CREATE PROCEDURE ObtenerEmpleadoUsuario(IN p_id_empleado INT)
BEGIN
    SELECT 
        e.id_empleado,
        e.id_usuario,
        e.clave_sistema,
        e.nombre,
        e.apellido_paterno,
        e.apellido_materno,
        e.correo,
        e.telefono,
        e.direccion,
        e.cargo,
        e.sueldo_actual,
        e.fecha_contratacion,
        e.imagen_empleado,
        e.id_estado,
        u.nombre_usuario,
        u.correo_cliente,
        u.imagen_perfil,
        u.id_estado AS usuario_estado,
        est.nombre_estado AS estado_empleado
    FROM empleados e
    LEFT JOIN usuarios u ON e.id_usuario = u.id_usuario
    LEFT JOIN estados est ON e.id_estado = est.id_estado
    WHERE e.id_empleado = p_id_empleado;
END //

-- Procedimiento para actualizar usuario y empleado
CREATE PROCEDURE ActualizarUsuarioEmpleado(
    IN p_id_usuario INT,
    IN p_id_empleado INT,
    IN p_nombre VARCHAR(100),
    IN p_apellido VARCHAR(100),
    IN p_nombre_usuario VARCHAR(100),
    IN p_contraseña VARCHAR(255),
    IN p_correo VARCHAR(100),
    IN p_imagen_perfil VARCHAR(255),
    IN p_clave_sistema VARCHAR(20),
    IN p_apellido_materno VARCHAR(100),
    IN p_telefono VARCHAR(15),
    IN p_direccion VARCHAR(255),
    IN p_cargo VARCHAR(100),
    IN p_sueldo_actual DECIMAL(10,2),
    IN p_imagen_empleado VARCHAR(255)
)
BEGIN
    DECLARE v_estado_actual INT;
    
    SELECT id_estado INTO v_estado_actual
    FROM empleados 
    WHERE id_empleado = p_id_empleado;
    
    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Empleado no encontrado';
    END IF;
    
    IF v_estado_actual != 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede actualizar un empleado inactivo';
    END IF;

    IF EXISTS (SELECT 1 FROM usuarios WHERE nombre_usuario = p_nombre_usuario AND id_usuario <> p_id_usuario) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nombre de usuario ya en uso';
    END IF;
    
    START TRANSACTION;
    
    UPDATE usuarios SET 
        nombre = p_nombre, 
        apellido = p_apellido, 
        nombre_usuario = p_nombre_usuario,
        correo_cliente = p_correo,
        imagen_perfil = p_imagen_perfil,
        contraseña_usuario = CASE 
            WHEN p_contraseña IS NOT NULL AND p_contraseña <> '' 
            THEN EncriptarContraseña(p_contraseña)
            ELSE contraseña_usuario
        END
    WHERE id_usuario = p_id_usuario;
    
    UPDATE empleados SET 
        clave_sistema = p_clave_sistema,
        nombre = p_nombre,
        apellido_paterno = p_apellido,
        apellido_materno = p_apellido_materno,
        correo = p_correo,
        telefono = p_telefono,
        direccion = p_direccion,
        cargo = p_cargo,
        sueldo_actual = p_sueldo_actual,
        imagen_empleado = p_imagen_empleado
    WHERE id_empleado = p_id_empleado;
    
    COMMIT;
END //

-- Procedimiento para inactivar usuario y empleado
CREATE PROCEDURE InactivarUsuarioEmpleado(IN p_id_usuario INT, IN p_id_empleado INT)
BEGIN
    DECLARE v_id_estado_inactivo INT DEFAULT 2;
    DECLARE v_estado_actual_usuario INT;
    DECLARE v_estado_actual_empleado INT;
    
    SELECT id_estado INTO v_estado_actual_usuario
    FROM usuarios 
    WHERE id_usuario = p_id_usuario;
    
    IF v_estado_actual_usuario IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no encontrado';
    END IF;
    
    IF v_estado_actual_usuario = 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario ya está inactivo';
    END IF;
    
    SELECT id_estado INTO v_estado_actual_empleado
    FROM empleados
    WHERE id_empleado = p_id_empleado;
    
    IF v_estado_actual_empleado IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Empleado no encontrado';
    END IF;
    
    START TRANSACTION;
    
    UPDATE usuarios 
    SET id_estado = v_id_estado_inactivo
    WHERE id_usuario = p_id_usuario;
    
    INSERT INTO historial_usuarios (id_usuario, id_estado_anterior, id_estado_nuevo)
    VALUES (p_id_usuario, v_estado_actual_usuario, v_id_estado_inactivo);
    
    UPDATE empleados 
    SET id_estado = v_id_estado_inactivo
    WHERE id_empleado = p_id_empleado;
    
    COMMIT;
END //

-- Procedimiento para reactivar usuario y empleado
CREATE PROCEDURE ReactivarUsuarioEmpleado(IN p_id_usuario INT, IN p_id_empleado INT)
BEGIN
    DECLARE v_id_estado_activo INT DEFAULT 1;
    DECLARE v_estado_actual_usuario INT;
    DECLARE v_estado_actual_empleado INT;
    
    SELECT id_estado INTO v_estado_actual_usuario
    FROM usuarios 
    WHERE id_usuario = p_id_usuario;
    
    IF v_estado_actual_usuario IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no encontrado';
    END IF;
    
    IF v_estado_actual_usuario = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario ya está activo';
    END IF;
    
    SELECT id_estado INTO v_estado_actual_empleado
    FROM empleados
    WHERE id_empleado = p_id_empleado;
    
    IF v_estado_actual_empleado IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Empleado no encontrado';
    END IF;
    
    START TRANSACTION;
    
    UPDATE usuarios 
    SET id_estado = v_id_estado_activo
    WHERE id_usuario = p_id_usuario;
    
    INSERT INTO historial_usuarios (id_usuario, id_estado_anterior, id_estado_nuevo)
    VALUES (p_id_usuario, v_estado_actual_usuario, v_id_estado_activo);
    
    UPDATE empleados 
    SET id_estado = v_id_estado_activo
    WHERE id_empleado = p_id_empleado;
    
    COMMIT;
END //

-- Procedimiento para crear venta
CREATE PROCEDURE CrearVenta(
    IN p_id_cliente INT,
    IN p_id_inmueble INT,
    IN p_fecha_venta DATE,
    IN p_ingreso DECIMAL(15,2),
    IN p_comision_proveedores DECIMAL(15,2),
    IN p_utilidad_neta DECIMAL(15,2),
    OUT p_id_venta_out INT
)
BEGIN
    DECLARE cliente_existe INT;
    DECLARE inmueble_existe INT;
    DECLARE estado_inmueble INT;
    DECLARE tipo_op VARCHAR(10);

    SELECT COUNT(*) INTO cliente_existe 
    FROM clientes 
    WHERE id_cliente = p_id_cliente;
    
    IF cliente_existe = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'El cliente especificado no existe';
    END IF;

    SELECT COUNT(*) INTO inmueble_existe 
    FROM inmuebles 
    WHERE id_inmueble = p_id_inmueble;
    
    IF inmueble_existe = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'El inmueble especificado no existe';
    END IF;
    
    -- Verificar que el inmueble esté disponible (id_estado = 3)
    SELECT id_estado INTO estado_inmueble
    FROM inmuebles
    WHERE id_inmueble = p_id_inmueble;
    
    IF estado_inmueble != 3 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'El inmueble no está disponible para la venta';
    END IF;

    START TRANSACTION;

    INSERT INTO ventas (
        id_cliente, id_inmueble, fecha_venta, ingreso, comision_proveedores, utilidad_neta, id_estado
    ) VALUES (
        p_id_cliente, p_id_inmueble, COALESCE(p_fecha_venta, CURDATE()), 
        p_ingreso, p_comision_proveedores, p_utilidad_neta, 7 -- 'venta_en_proceso'
    );

    SET p_id_venta_out = LAST_INSERT_ID();

    SELECT tipo_operacion INTO tipo_op 
    FROM inmuebles 
    WHERE id_inmueble = p_id_inmueble;

    IF tipo_op = 'venta' THEN
        UPDATE inmuebles 
        SET id_estado = 4 -- Vendido
        WHERE id_inmueble = p_id_inmueble;
    ELSE
        UPDATE inmuebles 
        SET id_estado = 5 -- Rentado
        WHERE id_inmueble = p_id_inmueble;
    END IF;

    COMMIT;
END //

-- Procedimiento para obtener todas las ventas
CREATE PROCEDURE ObtenerVentas()
BEGIN
    SELECT 
        v.id_venta,
        v.fecha_venta,
        c.nombre AS nombre_cliente,
        c.apellido_paterno AS apellido_cliente,
        i.nombre_inmueble,
        i.tipo_inmueble,
        i.tipo_operacion,
        v.ingreso,
        v.comision_proveedores,
        v.utilidad_bruta,
        v.utilidad_neta,
        e.nombre_estado AS estado_venta
    FROM ventas v
    JOIN clientes c ON v.id_cliente = c.id_cliente
    JOIN inmuebles i ON v.id_inmueble = i.id_inmueble
    JOIN estados e ON v.id_estado = e.id_estado
    ORDER BY v.fecha_venta DESC;
END //

-- Procedimiento para asignar un proveedor a un inmueble
CREATE PROCEDURE AsignarProveedorAInmueble(
    IN p_id_inmueble INT,
    IN p_id_proveedor INT,
    IN p_servicio_detalle VARCHAR(255),
    IN p_costo DECIMAL(12,2),
    IN p_fecha_asignacion DATE,
    IN p_fecha_servicio DATE,
    OUT p_id_servicio_out INT
)
BEGIN
    DECLARE v_id_estado_activo INT DEFAULT 1;
    
    IF NOT EXISTS(SELECT 1 FROM inmuebles WHERE id_inmueble = p_id_inmueble) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El inmueble especificado no existe';
    END IF;
    
    IF NOT EXISTS(SELECT 1 FROM proveedores WHERE id_proveedor = p_id_proveedor AND id_estado = 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proveedor especificado no existe o está inactivo';
    END IF;
    
    START TRANSACTION;
    
    INSERT INTO inmueble_proveedor_servicio (
        id_inmueble, id_proveedor, servicio_detalle, costo, 
        fecha_asignacion, fecha_servicio, id_estado
    ) VALUES (
        p_id_inmueble, p_id_proveedor, p_servicio_detalle, p_costo, 
        COALESCE(p_fecha_asignacion, CURDATE()), p_fecha_servicio, v_id_estado_activo
    );
    
    SET p_id_servicio_out = LAST_INSERT_ID();
    
    CALL ActualizarCostoServiciosInmueble(p_id_inmueble);
    
    COMMIT;
END //

-- Procedimiento para actualizar el costo total de servicios en la tabla de inmuebles
CREATE PROCEDURE ActualizarCostoServiciosInmueble(
    IN p_id_inmueble INT
)
BEGIN
    DECLARE v_costo_total DECIMAL(12,2);
    DECLARE v_costo_cliente DECIMAL(12,2);
    DECLARE v_comision_agencia DECIMAL(12,2);
    DECLARE v_comision_agente DECIMAL(12,2);
    DECLARE v_precio_venta_final DECIMAL(12,2);
    DECLARE v_margen_utilidad DECIMAL(5,2);
    
    SELECT IFNULL(SUM(costo), 0) INTO v_costo_total
    FROM inmueble_proveedor_servicio
    WHERE id_inmueble = p_id_inmueble AND id_estado = 1;
    
    SELECT IFNULL(costo_cliente, 0) INTO v_costo_cliente
    FROM inmuebles
    WHERE id_inmueble = p_id_inmueble;
    
    SET v_comision_agencia = v_costo_cliente * 0.30;
    SET v_comision_agente = v_costo_cliente * 0.03;
    SET v_precio_venta_final = v_costo_cliente + v_costo_total + v_comision_agencia + v_comision_agente;
    
    IF v_precio_venta_final > 0 THEN
        SET v_margen_utilidad = ((v_comision_agencia + v_comision_agente) / v_precio_venta_final) * 100;
    ELSE
        SET v_margen_utilidad = 0;
    END IF;
    
    UPDATE inmuebles SET
        costo_servicios = v_costo_total,
        comision_agencia = v_comision_agencia,
        comision_agente = v_comision_agente,
        precio_venta_final = v_precio_venta_final,
        margen_utilidad = v_margen_utilidad
    WHERE id_inmueble = p_id_inmueble;
END //

-- Procedimiento para eliminar un servicio de proveedor
CREATE PROCEDURE EliminarServicioProveedor(
    IN p_id INT
)
BEGIN
    DECLARE v_id_inmueble INT;
    
    IF NOT EXISTS(SELECT 1 FROM inmueble_proveedor_servicio WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El servicio especificado no existe';
    END IF;
    
    SELECT id_inmueble INTO v_id_inmueble FROM inmueble_proveedor_servicio WHERE id = p_id;
    
    START TRANSACTION;
    
    DELETE FROM inmueble_proveedor_servicio WHERE id = p_id;
    
    CALL ActualizarCostoServiciosInmueble(v_id_inmueble);
    
    COMMIT;
END //

-- Procedimiento para obtener servicios de proveedores por inmueble
CREATE PROCEDURE ObtenerServiciosProveedorPorInmueble(
    IN p_id_inmueble INT
)
BEGIN
    SELECT 
        ips.id,
        ips.id_inmueble,
        ips.id_proveedor,
        ips.servicio_detalle,
        ips.costo,
        ips.comision,
        ips.fecha_asignacion,
        ips.fecha_servicio,
        ips.id_estado,
        p.nombre AS nombre_proveedor,
        p.tipo_servicio,
        e.nombre_estado
    FROM inmueble_proveedor_servicio ips
    JOIN proveedores p ON ips.id_proveedor = p.id_proveedor
    JOIN estados e ON ips.id_estado = e.id_estado
    WHERE ips.id_inmueble = p_id_inmueble
    ORDER BY ips.fecha_asignacion DESC;
END //

-- Procedimiento para recalcular valores financieros en toda la base
CREATE PROCEDURE RecalcularFinanzasInmuebles()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE inmueble_id INT;
    DECLARE cur CURSOR FOR SELECT id_inmueble FROM inmuebles;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO inmueble_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        CALL ActualizarCostoServiciosInmueble(inmueble_id);
    END LOOP;
    
    CLOSE cur;
END //

-- Procedimiento para actualizar las utilidades de una venta
CREATE PROCEDURE ActualizarUtilidadVenta(
    IN p_id_venta INT,
    IN p_gastos_adicionales DECIMAL(15,2)
)
BEGIN
    DECLARE v_utilidad_bruta DECIMAL(15,2);
    DECLARE v_utilidad_neta DECIMAL(15,2);
    DECLARE v_venta_existe INT;
    DECLARE v_usuario_mod INT DEFAULT NULL;
    DECLARE v_valor_anterior DECIMAL(15,2);
    
    -- Comprobar que la venta existe
    SELECT COUNT(*), utilidad_bruta, utilidad_neta INTO v_venta_existe, v_utilidad_bruta, v_valor_anterior
    FROM ventas 
    WHERE id_venta = p_id_venta;
    
    IF v_venta_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta especificada no existe';
    END IF;
    
    -- Validar que los gastos no sean negativos
    IF p_gastos_adicionales < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los gastos adicionales no pueden ser negativos';
    END IF;
    
    -- Calcular la nueva utilidad neta
    SET v_utilidad_neta = v_utilidad_bruta - p_gastos_adicionales;
    
    START TRANSACTION;
    
    -- Actualizar la venta
    UPDATE ventas 
    SET utilidad_neta = v_utilidad_neta 
    WHERE id_venta = p_id_venta;
    
    -- Registrar en historial
    INSERT INTO historial_ventas (
        id_venta, 
        campo_modificado, 
        valor_anterior, 
        valor_nuevo,
        usuario_modificacion, 
        fecha_modificacion
    ) VALUES (
        p_id_venta,
        'utilidad_neta',
        v_valor_anterior,
        v_utilidad_neta,
        v_usuario_mod,
        CURRENT_TIMESTAMP
    );
    
    COMMIT;
END //

-- Procedimiento para obtener estadísticas de ventas con filtros de fecha
CREATE PROCEDURE ObtenerEstadisticasVentas(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    -- Si no se proporcionan fechas, usar valores por defecto
    SET p_fecha_inicio = COALESCE(p_fecha_inicio, '2000-01-01');
    SET p_fecha_fin = COALESCE(p_fecha_fin, CURRENT_DATE());
    
    SELECT 
        COUNT(*) AS total_ventas,
        SUM(v.ingreso) AS ingreso_total,
        SUM(v.utilidad_neta) AS utilidad_total,
        COALESCE(AVG(v.utilidad_neta / NULLIF(v.ingreso, 0)) * 100, 0) AS margen_promedio
    FROM ventas v
    JOIN inmuebles i ON v.id_inmueble = i.id_inmueble
    WHERE v.fecha_venta BETWEEN p_fecha_inicio AND p_fecha_fin
    AND v.id_estado IN (7, 8); -- Considerar ventas en proceso y completadas
END //

-- Procedimiento para análisis de rentabilidad por tipo de inmueble
CREATE PROCEDURE AnalisisRentabilidadPorTipo()
BEGIN
    SELECT 
        i.tipo_inmueble,
        COUNT(*) AS cantidad_ventas,
        COALESCE(AVG(v.utilidad_neta / NULLIF(v.ingreso, 0)) * 100, 0) AS margen_promedio,
        SUM(v.utilidad_neta) AS utilidad_total,
        AVG(v.ingreso) AS precio_promedio,
        MIN(v.ingreso) AS precio_minimo,
        MAX(v.ingreso) AS precio_maximo
    FROM ventas v
    JOIN inmuebles i ON v.id_inmueble = i.id_inmueble
    WHERE v.id_estado IN (7, 8) -- Considerar ventas en proceso y completadas
    GROUP BY i.tipo_inmueble
    ORDER BY utilidad_total DESC;
END //

CREATE PROCEDURE CambiarEstadoVenta(
    IN p_id_venta INT,
    IN p_nuevo_estado INT,
    IN p_usuario_modificacion INT
)
BEGIN
    DECLARE v_estado_actual INT;
    DECLARE v_id_inmueble INT;
    DECLARE v_error_message VARCHAR(255);

    -- Verificar que el nuevo estado sea válido (8: completada, 9: cancelada)
    IF p_nuevo_estado NOT IN (8, 9) THEN
        SET v_error_message = 'Estado nuevo inválido. Solo se permite 8 (completada) o 9 (cancelada)';
        INSERT INTO historial_ventas (
            id_venta, campo_modificado, valor_anterior, valor_nuevo, usuario_modificacion, fecha_modificacion
        ) VALUES (
            p_id_venta, 'id_estado', NULL, p_nuevo_estado, p_usuario_modificacion, CURRENT_TIMESTAMP
        );
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;

    -- Obtener el estado actual y el id_inmueble de la venta
    SELECT id_estado, id_inmueble INTO v_estado_actual, v_id_inmueble
    FROM ventas
    WHERE id_venta = p_id_venta;

    IF v_estado_actual IS NULL THEN
        SET v_error_message = 'La venta especificada no existe';
        INSERT INTO historial_ventas (
            id_venta, campo_modificado, valor_anterior, valor_nuevo, usuario_modificacion, fecha_modificacion
        ) VALUES (
            p_id_venta, 'id_estado', NULL, p_nuevo_estado, p_usuario_modificacion, CURRENT_TIMESTAMP
        );
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;

    -- Solo se puede cambiar desde "venta_en_proceso" (id_estado = 7)
    IF v_estado_actual != 7 THEN
        SET v_error_message = 'Solo se puede cambiar el estado de una venta en proceso';
        INSERT INTO historial_ventas (
            id_venta, campo_modificado, valor_anterior, valor_nuevo, usuario_modificacion, fecha_modificacion
        ) VALUES (
            p_id_venta, 'id_estado', v_estado_actual, p_nuevo_estado, p_usuario_modificacion, CURRENT_TIMESTAMP
        );
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;

    -- Si todas las validaciones pasan, proceder con el cambio
    START TRANSACTION;

    -- Actualizar el estado de la venta
    UPDATE ventas
    SET id_estado = p_nuevo_estado
    WHERE id_venta = p_id_venta;

    -- Si la venta se cancela (9), revertir el estado del inmueble a "disponible" (3)
    IF p_nuevo_estado = 9 THEN
        UPDATE inmuebles
        SET id_estado = 3
        WHERE id_inmueble = v_id_inmueble;
    END IF;

    -- Registrar el cambio exitoso en historial_ventas
    INSERT INTO historial_ventas (
        id_venta, campo_modificado, valor_anterior, valor_nuevo, usuario_modificacion, fecha_modificacion
    ) VALUES (
        p_id_venta, 'id_estado', v_estado_actual, p_nuevo_estado, p_usuario_modificacion, CURRENT_TIMESTAMP
    );

    COMMIT;
END //

DELIMITER ;