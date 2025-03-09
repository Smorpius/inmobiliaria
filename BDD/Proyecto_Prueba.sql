-- Crear base de datos si no existe y seleccionarla
CREATE DATABASE IF NOT EXISTS Proyecto_Prueba CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE Proyecto_Prueba;

-- Eliminar primero los procedimientos almacenados y funciones existentes
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
DROP PROCEDURE IF EXISTS ActualizarProveedor;
DROP PROCEDURE IF EXISTS InactivarProveedor;
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

-- Primero eliminamos las tablas en orden correcto respetando dependencias
DROP TABLE IF EXISTS historial_usuarios;
DROP TABLE IF EXISTS inmuebles;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS empleados;
DROP TABLE IF EXISTS proveedores;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS direcciones;
DROP TABLE IF EXISTS estados;

-- Inicializar estados con ID fijo
CREATE TABLE IF NOT EXISTS estados (
    id_estado INT PRIMARY KEY,
    nombre_estado VARCHAR(20) NOT NULL UNIQUE
);

-- Insertar estados con ID específicos
INSERT INTO estados (id_estado, nombre_estado) 
VALUES 
    (1, 'activo'),
    (2, 'inactivo') 
AS new ON DUPLICATE KEY UPDATE nombre_estado = new.nombre_estado;

-- Crear tabla de direcciones normalizadas con código postal opcional
CREATE TABLE direcciones (
    id_direccion INT AUTO_INCREMENT PRIMARY KEY,
    calle VARCHAR(255) NOT NULL,
    numero VARCHAR(50),
    ciudad VARCHAR(100) NOT NULL,
    id_estado INT NOT NULL,
    codigo_postal VARCHAR(20) NULL,
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
);

-- Crear tabla de Usuarios con campo para imagen
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

-- Crear tabla de historial de usuarios para registrar cambios
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

-- Crear tabla de Clientes con las modificaciones solicitadas
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

-- Crear tabla de Proveedores con validación de correo
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
    UNIQUE INDEX idx_proveedores_correo (correo),
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
);

-- Crear tabla de Empleados con campo para imagen
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

-- Crear tabla de Inmuebles con valores por defecto
CREATE TABLE inmuebles (
    id_inmueble INT AUTO_INCREMENT PRIMARY KEY,
    nombre_inmueble VARCHAR(100) NOT NULL,
    id_direccion INT,
    monto_total DECIMAL(12,2) NOT NULL,
    id_estado INT DEFAULT 1,
    id_cliente INT,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_direccion) REFERENCES direcciones(id_direccion),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON DELETE SET NULL,
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
);

-- Definir los triggers
DELIMITER //

-- Trigger para validar correo de usuario
DROP TRIGGER IF EXISTS validar_correo_usuario //
CREATE TRIGGER validar_correo_usuario
BEFORE INSERT ON usuarios
FOR EACH ROW
BEGIN
    IF NEW.correo_cliente IS NOT NULL AND 
       NEW.correo_cliente <> '' AND
       NEW.correo_cliente NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Correo electrónico de usuario inválido';
    END IF;
END //

-- Trigger para validar teléfono de cliente
CREATE TRIGGER validar_telefono_cliente
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
    IF NEW.telefono_cliente IS NOT NULL AND 
       NEW.telefono_cliente NOT REGEXP '^[+]?[0-9]{10,15}$' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Número de teléfono inválido';
    END IF;
END //

-- Trigger para validar correo de cliente
CREATE TRIGGER validar_correo_cliente
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
    IF NEW.correo_cliente IS NOT NULL AND 
       NEW.correo_cliente NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Correo electrónico inválido';
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

-- Procedimiento para crear usuario con imagen
CREATE PROCEDURE CrearUsuario(
    IN p_nombre VARCHAR(100), 
    IN p_apellido VARCHAR(100), 
    IN p_nombre_usuario VARCHAR(100), 
    IN p_contraseña VARCHAR(255),
    IN p_correo_cliente VARCHAR(100),
    IN p_imagen_perfil VARCHAR(255)
)
BEGIN
    DECLARE usuario_existente INT;
    DECLARE v_id_usuario INT;
    DECLARE v_id_estado_activo INT DEFAULT 1;

    IF LENGTH(p_contraseña) < 8 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La contraseña debe tener al menos 8 caracteres';
    END IF;

    SELECT COUNT(*) INTO usuario_existente 
    FROM usuarios 
    WHERE nombre_usuario = p_nombre_usuario;

    IF usuario_existente > 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre de usuario ya existe';
    ELSE
        INSERT INTO usuarios (
            nombre, apellido, nombre_usuario, contraseña_usuario, correo_cliente, imagen_perfil, id_estado
        ) VALUES (
            p_nombre, p_apellido, p_nombre_usuario, EncriptarContraseña(p_contraseña), p_correo_cliente, p_imagen_perfil, v_id_estado_activo
        );

        SET v_id_usuario = LAST_INSERT_ID();

        INSERT INTO historial_usuarios (
            id_usuario, id_estado_anterior, id_estado_nuevo
        ) VALUES (
            v_id_usuario, NULL, v_id_estado_activo
        );
    END IF;
END //

-- Procedimiento para actualizar usuario con imagen
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
    DECLARE v_estado_nombre VARCHAR(20);
    
    SELECT usuarios.id_estado, estados.nombre_estado INTO estado_actual_id, v_estado_nombre
    FROM usuarios 
    JOIN estados ON usuarios.id_estado = estados.id_estado
    WHERE id_usuario = p_id_usuario;
    
    IF estado_actual_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no encontrado';
    END IF;
    
    IF v_estado_nombre = 'inactivo' THEN
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
END //

-- Procedimiento para inactivar usuario
CREATE PROCEDURE InactivarUsuario(IN p_id_usuario INT)
BEGIN
    DECLARE estado_actual_id INT;
    DECLARE v_id_estado_inactivo INT DEFAULT 2;
    DECLARE estado_actual_nombre VARCHAR(20);

    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id_usuario = p_id_usuario) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no encontrado';
    END IF;

    SELECT usuarios.id_estado, estados.nombre_estado INTO estado_actual_id, estado_actual_nombre
    FROM usuarios 
    JOIN estados ON usuarios.id_estado = estados.id_estado
    WHERE id_usuario = p_id_usuario;

    IF estado_actual_nombre = 'inactivo' THEN
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

-- Procedimientos CRUD para Clientes (modificados)
CREATE PROCEDURE CrearCliente(
    IN p_nombre VARCHAR(100),
    IN p_apellido_paterno VARCHAR(100),
    IN p_apellido_materno VARCHAR(100),
    IN p_direccion_calle VARCHAR(255),
    IN p_direccion_numero VARCHAR(50),
    IN p_direccion_ciudad VARCHAR(100),
    IN p_direccion_codigo_postal VARCHAR(20),
    IN p_telefono_cliente VARCHAR(20),
    IN p_rfc VARCHAR(13),
    IN p_curp VARCHAR(18),
    IN p_correo_cliente VARCHAR(100),
    IN p_tipo_cliente ENUM('comprador', 'arrendatario', 'ambos')
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
    
    INSERT INTO direcciones (
        calle, numero, ciudad, id_estado, codigo_postal
    ) VALUES (
        p_direccion_calle, p_direccion_numero, p_direccion_ciudad, v_id_estado_activo, p_direccion_codigo_postal
    );
    
    SET v_id_direccion = LAST_INSERT_ID();
    
    INSERT INTO clientes (
        nombre, apellido_paterno, apellido_materno, id_direccion, telefono_cliente, 
        rfc, curp, tipo_cliente, correo_cliente, id_estado
    ) VALUES (
        p_nombre, p_apellido_paterno, p_apellido_materno, v_id_direccion, p_telefono_cliente, 
        UPPER(p_rfc), UPPER(p_curp), COALESCE(p_tipo_cliente, 'comprador'), p_correo_cliente, v_id_estado_activo
    );
END //

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
        d.ciudad, 
        d.codigo_postal,
        e.nombre_estado AS estado_cliente
    FROM clientes c
    JOIN direcciones d ON c.id_direccion = d.id_direccion
    JOIN estados e ON c.id_estado = e.id_estado
    WHERE e.nombre_estado = 'activo';
END //

CREATE PROCEDURE ActualizarCliente(
    IN p_id_cliente INT,
    IN p_nombre VARCHAR(100),
    IN p_apellido_paterno VARCHAR(100),
    IN p_apellido_materno VARCHAR(100),
    IN p_telefono_cliente VARCHAR(20),
    IN p_rfc VARCHAR(13),
    IN p_curp VARCHAR(18),
    IN p_correo_cliente VARCHAR(100),
    IN p_direccion_calle VARCHAR(255),
    IN p_direccion_numero VARCHAR(50),
    IN p_direccion_ciudad VARCHAR(100),
    IN p_direccion_codigo_postal VARCHAR(20),
    IN p_tipo_cliente ENUM('comprador', 'arrendatario', 'ambos')
)
BEGIN
    DECLARE v_id_direccion INT;
    DECLARE v_estado_actual VARCHAR(20);
    
    SELECT c.id_direccion, e.nombre_estado INTO v_id_direccion, v_estado_actual
    FROM clientes c
    JOIN estados e ON c.id_estado = e.id_estado
    WHERE c.id_cliente = p_id_cliente;
    
    IF v_id_direccion IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente no encontrado';
    END IF;
    
    IF v_estado_actual != 'activo' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede actualizar un cliente inactivo';
    END IF;
    
    IF NOT (p_rfc REGEXP '^[A-Z&Ñ]{3,4}[0-9]{6}[A-Z0-9]{3}$') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de RFC inválido';
    END IF;
    
    IF NOT (p_curp REGEXP '^[A-Z][AEIOUX][A-Z]{2}[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[HM](AS|BC|BS|CC|CL|CM|CS|CH|DF|DG|GT|GR|HG|JC|MC|MN|MS|NT|NL|OC|PL|QT|QR|SP|SL|SR|TC|TS|TL|VZ|YN|ZS|NE)[B-DF-HJ-NP-TV-Z]{3}[0-9A-Z][0-9]$') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de CURP inválido';
    END IF;
    
    UPDATE direcciones SET
        calle = p_direccion_calle,
        numero = p_direccion_numero,
        ciudad = p_direccion_ciudad,
        codigo_postal = p_direccion_codigo_postal
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
END //

CREATE PROCEDURE InactivarCliente(IN p_id_cliente INT)
BEGIN
    DECLARE v_id_estado_inactivo INT;
    DECLARE v_estado_actual VARCHAR(20);
    
    SELECT id_estado INTO v_id_estado_inactivo
    FROM estados 
    WHERE nombre_estado = 'inactivo';
    
    SELECT e.nombre_estado INTO v_estado_actual
    FROM clientes c
    JOIN estados e ON c.id_estado = e.id_estado
    WHERE c.id_cliente = p_id_cliente;
    
    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente no encontrado';
    END IF;
    
    IF v_estado_actual = 'inactivo' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente ya está inactivo';
    END IF;
    
    UPDATE clientes 
    SET id_estado = v_id_estado_inactivo
    WHERE id_cliente = p_id_cliente;
END //

CREATE PROCEDURE ReactivarCliente(IN p_id_cliente INT)
BEGIN
    DECLARE v_id_estado_activo INT;
    DECLARE v_estado_actual VARCHAR(20);
    
    SELECT id_estado INTO v_id_estado_activo
    FROM estados 
    WHERE nombre_estado = 'activo';
    
    SELECT e.nombre_estado INTO v_estado_actual
    FROM clientes c
    JOIN estados e ON c.id_estado = e.id_estado
    WHERE c.id_cliente = p_id_cliente;
    
    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente no encontrado';
    END IF;
    
    IF v_estado_actual = 'activo' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente ya está activo';
    END IF;
    
    UPDATE clientes 
    SET id_estado = v_id_estado_activo
    WHERE id_cliente = p_id_cliente;
END //

-- Procedimiento para crear inmueble
CREATE PROCEDURE CrearInmueble(
    IN p_nombre_inmueble VARCHAR(100),
    IN p_direccion_calle VARCHAR(255),
    IN p_direccion_numero VARCHAR(50),
    IN p_direccion_ciudad VARCHAR(100),
    IN p_direccion_estado INT,
    IN p_direccion_codigo_postal VARCHAR(20),
    IN p_monto_total DECIMAL(10,2),
    IN p_estatus_inmueble VARCHAR(20),
    IN p_id_cliente INT
)
BEGIN
    DECLARE v_id_direccion INT;
    DECLARE v_id_estado INT DEFAULT 1;
    
    INSERT INTO direcciones (
        calle, numero, ciudad, id_estado, codigo_postal
    ) VALUES (
        p_direccion_calle, p_direccion_numero, p_direccion_ciudad, p_direccion_estado, p_direccion_codigo_postal
    );
    
    SET v_id_direccion = LAST_INSERT_ID();
    
    IF p_estatus_inmueble = 'vendido' THEN
        SET v_id_estado = 2;
    END IF;
    
    INSERT INTO inmuebles (
        nombre_inmueble, id_direccion, monto_total, id_estado, id_cliente
    ) VALUES (
        p_nombre_inmueble, v_id_direccion, p_monto_total, v_id_estado, p_id_cliente
    );
END //

-- Procedimiento para actualizar inmueble
CREATE PROCEDURE ActualizarInmueble(
    IN p_id_inmueble INT,
    IN p_nombre_inmueble VARCHAR(100),
    IN p_direccion_calle VARCHAR(255),
    IN p_direccion_numero VARCHAR(50),
    IN p_direccion_ciudad VARCHAR(100),
    IN p_id_estado INT,
    IN p_monto_total DECIMAL(10,2),
    IN p_id_cliente INT
)
BEGIN
    DECLARE v_id_direccion INT;
    DECLARE v_old_id_estado INT;

    SELECT id_direccion, id_estado INTO v_id_direccion, v_old_id_estado
    FROM inmuebles 
    WHERE id_inmueble = p_id_inmueble;

    IF v_id_direccion IS NULL THEN
        INSERT INTO direcciones (
            calle, numero, ciudad, id_estado, codigo_postal
        ) VALUES (
            p_direccion_calle, p_direccion_numero, p_direccion_ciudad, p_id_estado, '00000'
        );
        SET v_id_direccion = LAST_INSERT_ID();
    ELSE
        UPDATE direcciones SET
            calle = p_direccion_calle,
            numero = p_direccion_numero,
            ciudad = p_direccion_ciudad,
            id_estado = p_id_estado
        WHERE id_direccion = v_id_direccion;
    END IF;

    UPDATE inmuebles SET
        nombre_inmueble = p_nombre_inmueble,
        id_direccion = v_id_direccion,
        monto_total = p_monto_total,
        id_estado = p_id_estado,
        id_cliente = p_id_cliente
    WHERE id_inmueble = p_id_inmueble;
END //

-- Procedimientos CRUD para Proveedores
CREATE PROCEDURE CrearProveedor(
    IN p_nombre VARCHAR(100), 
    IN p_nombre_empresa VARCHAR(150), 
    IN p_nombre_contacto VARCHAR(100), 
    IN p_direccion VARCHAR(255), 
    IN p_telefono VARCHAR(15), 
    IN p_correo VARCHAR(100), 
    IN p_tipo_servicio VARCHAR(100)
)
BEGIN
    DECLARE v_id_estado_activo INT;
    
    SELECT id_estado INTO v_id_estado_activo 
    FROM estados 
    WHERE nombre_estado = 'activo';
    
    INSERT INTO proveedores (
        nombre, nombre_empresa, nombre_contacto, direccion, telefono, correo, tipo_servicio, id_estado
    ) VALUES (
        p_nombre, p_nombre_empresa, p_nombre_contacto, p_direccion, p_telefono, p_correo, p_tipo_servicio, v_id_estado_activo
    );
END //

CREATE PROCEDURE LeerProveedores()
BEGIN
    SELECT p.*, e.nombre_estado AS estado_proveedor
    FROM proveedores p
    JOIN estados e ON p.id_estado = e.id_estado
    WHERE e.nombre_estado = 'activo';
END //

CREATE PROCEDURE ActualizarProveedor(
    IN p_id_proveedor INT,
    IN p_nombre VARCHAR(100), 
    IN p_nombre_empresa VARCHAR(150), 
    IN p_nombre_contacto VARCHAR(100), 
    IN p_direccion VARCHAR(255), 
    IN p_telefono VARCHAR(15), 
    IN p_correo VARCHAR(100), 
    IN p_tipo_servicio VARCHAR(100)
)
BEGIN
    DECLARE v_id_estado_activo INT;

    SELECT id_estado INTO v_id_estado_activo 
    FROM estados WHERE nombre_estado = 'activo';

    IF v_id_estado_activo IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede actualizar un proveedor inactivo';
    END IF;

    UPDATE proveedores SET 
        nombre = p_nombre, 
        nombre_empresa = p_nombre_empresa, 
        nombre_contacto = p_nombre_contacto, 
        direccion = p_direccion, 
        telefono = p_telefono, 
        correo = p_correo, 
        tipo_servicio = p_tipo_servicio
    WHERE id_proveedor = p_id_proveedor;
END //

CREATE PROCEDURE InactivarProveedor(IN p_id_proveedor INT)
BEGIN
    DECLARE v_id_estado_inactivo INT;
    DECLARE v_estado_actual VARCHAR(20);
    
    SELECT id_estado INTO v_id_estado_inactivo
    FROM estados 
    WHERE nombre_estado = 'inactivo';
    
    SELECT e.nombre_estado INTO v_estado_actual
    FROM proveedores p
    JOIN estados e ON p.id_estado = e.id_estado
    WHERE p.id_proveedor = p_id_proveedor;
    
    IF v_estado_actual = 'inactivo' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proveedor ya está inactivo';
    END IF;
    
    UPDATE proveedores 
    SET id_estado = v_id_estado_inactivo
    WHERE id_proveedor = p_id_proveedor;
END //

-- CRUD para Empleados con imagen
CREATE PROCEDURE CrearEmpleado(
    IN p_clave_sistema VARCHAR(20),
    IN p_nombre VARCHAR(100),
    IN p_apellido_paterno VARCHAR(100),
    IN p_apellido_materno VARCHAR(100),
    IN p_correo VARCHAR(100),
    IN p_telefono VARCHAR(15),
    IN p_direccion VARCHAR(225),
    IN p_cargo VARCHAR(100),
    IN p_sueldo_actual DECIMAL(10,2),
    IN p_fecha_contratacion DATE,
    IN p_imagen_empleado VARCHAR(255)
)
BEGIN
    DECLARE v_id_estado_activo INT;
    
    SELECT id_estado INTO v_id_estado_activo 
    FROM estados 
    WHERE nombre_estado = 'activo';
    
    INSERT INTO empleados (
        clave_sistema, nombre, apellido_paterno, apellido_materno, correo, telefono, 
        direccion, cargo, sueldo_actual, fecha_contratacion, imagen_empleado, id_estado
    ) VALUES (
        p_clave_sistema, p_nombre, p_apellido_paterno, p_apellido_materno, p_correo, p_telefono, 
        p_direccion, p_cargo, p_sueldo_actual, p_fecha_contratacion, p_imagen_empleado, v_id_estado_activo
    );
END //

CREATE PROCEDURE LeerEmpleados()
BEGIN
    SELECT e.*, est.nombre_estado AS estado_empleado
    FROM empleados e
    JOIN estados est ON e.id_estado = est.id_estado
    WHERE est.nombre_estado = 'activo';
END //

CREATE PROCEDURE ActualizarEmpleado(
    IN p_id_empleado INT,
    IN p_clave_sistema VARCHAR(20),
    IN p_nombre VARCHAR(100),
    IN p_apellido_paterno VARCHAR(100),
    IN p_apellido_materno VARCHAR(100),
    IN p_correo VARCHAR(100),
    IN p_telefono VARCHAR(15),
    IN p_direccion VARCHAR(225),
    IN p_cargo VARCHAR(100),
    IN p_sueldo_actual DECIMAL(10,2),
    IN p_imagen_empleado VARCHAR(255)
)
BEGIN
    DECLARE v_estado_actual VARCHAR(20);
    
    SELECT e.nombre_estado INTO v_estado_actual
    FROM empleados emp
    JOIN estados e ON emp.id_estado = e.id_estado
    WHERE emp.id_empleado = p_id_empleado;
    
    IF v_estado_actual != 'activo' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede actualizar un empleado inactivo';
    END IF;
    
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
END //

CREATE PROCEDURE InactivarEmpleado(IN p_id_empleado INT)
BEGIN
    DECLARE v_id_estado_inactivo INT;
    DECLARE v_estado_actual VARCHAR(20);
    
    SELECT id_estado INTO v_id_estado_inactivo
    FROM estados 
    WHERE nombre_estado = 'inactivo';
    
    SELECT e.nombre_estado INTO v_estado_actual
    FROM empleados emp
    JOIN estados e ON emp.id_estado = e.id_estado
    WHERE emp.id_empleado = p_id_empleado;
    
    IF v_estado_actual = 'inactivo' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El empleado ya está inactivo';
    END IF;
    
    UPDATE empleados 
    SET id_estado = v_id_estado_inactivo
    WHERE id_empleado = p_id_empleado;
END //

-- Procedimientos de búsqueda
CREATE PROCEDURE BuscarClientePorRFC(IN p_rfc VARCHAR(13))
BEGIN
    SELECT 
        c.*, 
        d.calle, d.numero, d.ciudad, d.codigo_postal,
        e.nombre_estado AS estado_cliente
    FROM clientes c
    JOIN direcciones d ON c.id_direccion = d.id_direccion
    JOIN estados e ON c.id_estado = e.id_estado
    WHERE c.rfc = p_rfc;
END //

CREATE PROCEDURE BuscarClientePorNombre(IN p_texto VARCHAR(100))
BEGIN
    SELECT 
        c.*, 
        d.calle, d.numero, d.ciudad, d.codigo_postal,
        e.nombre_estado AS estado_cliente
    FROM clientes c
    JOIN direcciones d ON c.id_direccion = d.id_direccion
    JOIN estados e ON c.id_estado = e.id_estado
    WHERE CONCAT(c.nombre, ' ', c.apellido_paterno, ' ', IFNULL(c.apellido_materno, '')) 
          LIKE CONCAT('%', p_texto, '%');
END //

CREATE PROCEDURE BuscarInmueblePorCliente(IN p_id_cliente INT)
BEGIN
    SELECT 
        i.*, 
        d.calle, d.numero, d.ciudad, d.codigo_postal,
        e.nombre_estado AS estado_inmueble
    FROM inmuebles i
    JOIN direcciones d ON i.id_direccion = d.id_direccion
    JOIN estados e ON i.id_estado = e.id_estado
    WHERE i.id_cliente = p_id_cliente;
END //

-- Procedimiento para crear usuario y empleado con imágenes
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
    IN p_imagen_empleado VARCHAR(255)
)
BEGIN
    DECLARE v_id_usuario INT;
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
    
    SET v_id_usuario = LAST_INSERT_ID();
    
    INSERT INTO historial_usuarios (id_usuario, id_estado_anterior, id_estado_nuevo)
    VALUES (v_id_usuario, NULL, v_id_estado_activo);
    
    INSERT INTO empleados (
        id_usuario, clave_sistema, nombre, apellido_paterno, apellido_materno, 
        correo, telefono, direccion, cargo, sueldo_actual, fecha_contratacion, 
        imagen_empleado, id_estado
    ) VALUES (
        v_id_usuario, p_clave_sistema, p_nombre, p_apellido, p_apellido_materno,
        p_correo_contacto, p_telefono, p_direccion, p_cargo, p_sueldo_actual, 
        p_fecha_contratacion, p_imagen_empleado, v_id_estado_activo
    );
    
    COMMIT;
END //

-- Procedimiento para leer empleados con usuarios
CREATE PROCEDURE LeerEmpleadosConUsuarios()
BEGIN
    SELECT 
        e.*,
        u.id_usuario, u.nombre, u.apellido, u.nombre_usuario, u.correo_cliente, u.imagen_perfil,
        u.id_estado AS usuario_estado,
        est.nombre_estado AS estado_empleado
    FROM empleados e
    JOIN usuarios u ON e.id_usuario = u.id_usuario
    JOIN estados est ON e.id_estado = est.id_estado;
END //

-- Procedimiento para obtener empleado específico con usuario
CREATE PROCEDURE ObtenerEmpleadoUsuario(IN p_id_empleado INT)
BEGIN
    SELECT 
        e.*,
        u.id_usuario, u.nombre, u.apellido, u.nombre_usuario, u.correo_cliente, u.imagen_perfil,
        u.id_estado AS usuario_estado,
        est.nombre_estado AS estado_empleado
    FROM empleados e
    JOIN usuarios u ON e.id_usuario = u.id_usuario
    JOIN estados est ON e.id_estado = est.id_estado
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
    DECLARE v_estado_actual VARCHAR(20);
    
    SELECT e.nombre_estado INTO v_estado_actual
    FROM empleados emp
    JOIN estados e ON emp.id_estado = e.id_estado
    WHERE emp.id_empleado = p_id_empleado;
    
    IF v_estado_actual != 'activo' THEN
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
    DECLARE v_estado_nombre VARCHAR(20);
    
    SELECT usuarios.id_estado, estados.nombre_estado 
    INTO v_estado_actual_usuario, v_estado_nombre
    FROM usuarios 
    JOIN estados ON usuarios.id_estado = estados.id_estado
    WHERE id_usuario = p_id_usuario;
    
    IF v_estado_actual_usuario IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no encontrado';
    END IF;
    
    IF v_estado_nombre = 'inactivo' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario ya está inactivo';
    END IF;
    
    SELECT id_estado INTO v_estado_actual_empleado
    FROM empleados
    WHERE id_empleado = p_id_empleado;
    
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
    DECLARE v_estado_nombre VARCHAR(20);
    
    SELECT usuarios.id_estado, estados.nombre_estado 
    INTO v_estado_actual_usuario, v_estado_nombre
    FROM usuarios 
    JOIN estados ON usuarios.id_estado = estados.id_estado
    WHERE id_usuario = p_id_usuario;
    
    IF v_estado_actual_usuario IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no encontrado';
    END IF;
    
    IF v_estado_nombre = 'activo' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario ya está activo';
    END IF;
    
    SELECT id_estado INTO v_estado_actual_empleado
    FROM empleados
    WHERE id_empleado = p_id_empleado;
    
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

-- Índices adicionales
CREATE INDEX idx_usuarios_estado ON usuarios(id_estado);
CREATE INDEX idx_inmuebles_cliente ON inmuebles(id_cliente);
CREATE INDEX idx_inmuebles_estado ON inmuebles(id_estado);
CREATE INDEX idx_clientes_estado ON clientes(id_estado);
CREATE INDEX idx_proveedores_estado ON proveedores(id_estado);
CREATE INDEX idx_empleados_estado ON empleados(id_estado);