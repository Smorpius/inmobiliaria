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
DROP FUNCTION IF EXISTS EncriptarContraseña;

-- Eliminar tablas respetando dependencias
DROP TABLE IF EXISTS historial_usuarios;
DROP TABLE IF EXISTS historial_proveedores;
DROP TABLE IF EXISTS historial_proveedores_detallado;
DROP TABLE IF EXISTS inmuebles_imagenes;
DROP TABLE IF EXISTS inmuebles_clientes_interesados;
DROP TABLE IF EXISTS cliente_inmueble;
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

-- Insertar estados predefinidos
INSERT INTO estados (id_estado, nombre_estado) 
VALUES 
    (1, 'activo'),
    (2, 'inactivo'),
    (3, 'disponible'),
    (4, 'vendido'),
    (5, 'rentado'),
    (6, 'en_negociacion')
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

-- Crear tabla de inmuebles
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
    OUT p_id_inmueble_out INT
)
BEGIN
    DECLARE v_id_direccion INT;
    DECLARE v_id_estado INT DEFAULT 3;
    
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
        precio_venta, precio_renta, id_estado, id_cliente, id_empleado, caracteristicas
    ) VALUES (
        p_nombre_inmueble, v_id_direccion, p_monto_total, COALESCE(p_tipo_inmueble, 'casa'), 
        COALESCE(p_tipo_operacion, 'venta'), p_precio_venta, p_precio_renta, v_id_estado, 
        p_id_cliente, p_id_empleado, p_caracteristicas
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
    IN p_caracteristicas TEXT
)
BEGIN
    DECLARE v_id_direccion INT;

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
        caracteristicas = p_caracteristicas
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
    
    -- Validaciones previas
    IF p_correo NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Correo electrónico del proveedor inválido';
    END IF;
    
    IF p_telefono NOT REGEXP '^[+]?[0-9]{10,15}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Número de teléfono del proveedor inválido';
    END IF;

    START TRANSACTION;
    
    -- Inserción en la tabla proveedores
    INSERT INTO proveedores (
        nombre, nombre_empresa, nombre_contacto, direccion, telefono, correo, tipo_servicio, id_estado
    ) VALUES (
        p_nombre, p_nombre_empresa, p_nombre_contacto, p_direccion, p_telefono, p_correo, p_tipo_servicio, v_id_estado_activo
    );
    
    -- Asignar el ID generado a la variable de salida
    SET p_id_proveedor_out = LAST_INSERT_ID();
    
    -- Registrar en el historial
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

-- Procedimiento para actualizar proveedor (VERSIÓN CORREGIDA)
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

    -- Verificar que el proveedor exista y obtener valores actuales
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
    
    -- Validar el correo electrónico
    IF p_correo NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Correo electrónico del proveedor inválido';
    END IF;
    
    -- Validar el teléfono
    IF p_telefono NOT REGEXP '^[+]?[0-9]{10,15}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Número de teléfono del proveedor inválido';
    END IF;

    -- Verificar si el correo ya está en uso por otro proveedor
    IF EXISTS (
        SELECT 1 
        FROM proveedores 
        WHERE correo = p_correo 
        AND id_proveedor != p_id_proveedor
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El correo ya está en uso por otro proveedor';
    END IF;

    START TRANSACTION;
    
    -- Actualizar los datos del proveedor
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

    -- Registrar cambios en el historial detallado
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
    
    -- Verificar si el proveedor existe y obtener su estado actual
    SELECT id_estado INTO v_estado_actual
    FROM proveedores 
    WHERE id_proveedor = p_id_proveedor;
    
    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Proveedor no encontrado';
    END IF;
    
    -- Verificar si ya está inactivo
    IF v_estado_actual = v_id_estado_inactivo THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proveedor ya está inactivo';
    END IF;
    
    START TRANSACTION;
    
    -- Actualizar el estado del proveedor a inactivo
    UPDATE proveedores 
    SET id_estado = v_id_estado_inactivo,
        fecha_modificacion = CURRENT_TIMESTAMP
    WHERE id_proveedor = p_id_proveedor;
    
    -- Registrar el cambio en el historial
    INSERT INTO historial_proveedores (
        id_proveedor, id_estado_anterior, id_estado_nuevo, usuario_modificacion
    ) VALUES (
        p_id_proveedor, v_estado_actual, v_id_estado_inactivo, p_usuario_modificacion
    );
    
    -- Registrar el cambio detallado
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

DELIMITER ;

-- Índices para mejorar el rendimiento
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