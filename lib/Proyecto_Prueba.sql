-- Configuración recomendada para servidor MySQL
SET GLOBAL max_allowed_packet = 16777216; -- 16MB
SET GLOBAL net_read_timeout = 180;
SET GLOBAL net_write_timeout = 180;
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
DROP PROCEDURE IF EXISTS InactivarInmueble;
DROP PROCEDURE IF EXISTS ReactivarInmueble;
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
DROP PROCEDURE IF EXISTS CambiarEstadoVenta;
DROP PROCEDURE IF EXISTS ObtenerInmuebles;
DROP PROCEDURE IF EXISTS VerificarExistenciaInmueble;
DROP PROCEDURE IF EXISTS BuscarInmuebles;
DROP PROCEDURE IF EXISTS ObtenerClientesInteresados;
DROP PROCEDURE IF EXISTS RegistrarClienteInteresado;
DROP PROCEDURE IF EXISTS ObtenerImagenesInmueble;
DROP PROCEDURE IF EXISTS ObtenerImagenPrincipal;
DROP PROCEDURE IF EXISTS AgregarImagenInmueble;
DROP PROCEDURE IF EXISTS MarcarImagenComoPrincipal;
DROP PROCEDURE IF EXISTS EliminarImagenInmueble;
DROP PROCEDURE IF EXISTS ActualizarDescripcionImagen;
DROP PROCEDURE IF EXISTS LimpiarImagenesHuerfanas;
DROP PROCEDURE IF EXISTS ObtenerClientesActivos;
DROP PROCEDURE IF EXISTS ObtenerClientesInactivos;
DROP PROCEDURE IF EXISTS ObtenerClientePorId;
DROP PROCEDURE IF EXISTS ObtenerInmueblesPorCliente;
DROP PROCEDURE IF EXISTS AsignarInmuebleACliente;
DROP PROCEDURE IF EXISTS DesasignarInmuebleDeCliente;
DROP PROCEDURE IF EXISTS ObtenerUsuarios;
DROP PROCEDURE IF EXISTS ObtenerUsuarioPorId;
DROP PROCEDURE IF EXISTS VerificarCredenciales;
DROP PROCEDURE IF EXISTS VerificarCredencialesAdmin;
DROP PROCEDURE IF EXISTS ObtenerAdministradores;
DROP PROCEDURE IF EXISTS CrearAdministrador;
DROP PROCEDURE IF EXISTS ActualizarContrasenaAdmin;
DROP PROCEDURE IF EXISTS ObtenerVentaPorId;
DROP PROCEDURE IF EXISTS ObtenerEstadisticasVentasPorFecha;
DROP PROCEDURE IF EXISTS ObtenerVentasMensuales;
DROP PROCEDURE IF EXISTS VerificarNombreUsuarioExiste;
DROP PROCEDURE IF EXISTS VerificarNombreUsuarioExisteExcluyendoId;
DROP PROCEDURE IF EXISTS GuardarImagenInmueble;
DROP PROCEDURE IF EXISTS VerificarUsuarioExiste;
DROP PROCEDURE IF EXISTS CrearUsuarioAdministrador;
DROP PROCEDURE IF EXISTS ObtenerVentaReporte;
DROP PROCEDURE IF EXISTS ObtenerEstadisticasVentasDetalladas;
DROP PROCEDURE IF EXISTS BuscarInmueblesAvanzado;
DROP PROCEDURE IF EXISTS VerificarConexion;
DROP PROCEDURE IF EXISTS ObtenerImagenInmuebleSegura;
DROP PROCEDURE IF EXISTS RegistrarMovimientoRenta;
DROP PROCEDURE IF EXISTS ObtenerMovimientosPorInmueble;
DROP PROCEDURE IF EXISTS AgregarComprobanteMovimiento;
DROP PROCEDURE IF EXISTS ObtenerComprobantesPorMovimiento;
DROP PROCEDURE IF EXISTS ObtenerResumenMovimientosRenta;
DROP PROCEDURE IF EXISTS EliminarMovimientoRenta;
DROP PROCEDURE IF EXISTS ObtenerDetalleRenta;
DROP PROCEDURE IF EXISTS RegistrarContratoRenta;
DROP PROCEDURE IF EXISTS ActualizarEstadoContratoRenta;
DROP PROCEDURE IF EXISTS  ObtenerContratos;
DROP PROCEDURE IF EXISTS  BuscarContratos;
DROP PROCEDURE IF EXISTS  ObtenerEstadisticasRentas;
DROP PROCEDURE IF EXISTS ActualizarComprobanteMovimiento;
DROP PROCEDURE IF EXISTS ObtenerComprobantesDetallados;
DROP PROCEDURE IF EXISTS BuscarComprobantes;
DROP PROCEDURE IF EXISTS BuscarComprobantesPorTipo;
DROP PROCEDURE IF EXISTS ObtenerContratoPorId;
DROP PROCEDURE IF EXISTS ObtenerResumenComprobantes;
DROP PROCEDURE IF EXISTS ReporteComprobantesMovimientosPorPeriodo;
DROP PROCEDURE IF EXISTS EliminarComprobanteMovimiento;
DROP PROCEDURE IF EXISTS ClonarComprobante;
DROP PROCEDURE IF EXISTS ValidarComprobanteFiscal;
DROP PROCEDURE IF EXISTS ObtenerComprobantesVencidos;
DROP PROCEDURE IF EXISTS ObtenerCumplimientoFiscal;
DROP PROCEDURE IF EXISTS ObtenerDatosContratoRenta;
DROP PROCEDURE IF EXISTS ObtenerDatosContratoVenta;
DROP PROCEDURE IF EXISTS RegistrarContratoGenerado;
DROP PROCEDURE IF EXISTS ActualizarComprobanteVenta;
DROP PROCEDURE IF EXISTS EliminarComprobanteVenta;
DROP PROCEDURE IF EXISTS ObtenerComprobantesPorVenta;
DROP PROCEDURE IF EXISTS ObtenerContratosGeneradosPorReferencia;
DROP PROCEDURE IF EXISTS EliminarContratoGenerado;
DROP PROCEDURE IF EXISTS ObtenerContratosPorInmueble;
DROP PROCEDURE IF EXISTS ObtenerMovimientosPorContrato;
DROP PROCEDURE IF EXISTS ObtenerComprobantesVenta;
DROP PROCEDURE IF EXISTS AgregarComprobanteVenta;
DROP FUNCTION IF EXISTS EncriptarContraseña;

-- Eliminar tablas que dependen de otras primero
DROP TABLE IF EXISTS comprobantes_movimientos;           -- Depende de movimientos_renta
DROP TABLE IF EXISTS movimientos_renta;                 -- Depende de inmuebles y clientes
DROP TABLE IF EXISTS contratos_renta;                   -- Depende de inmuebles y clientes
DROP TABLE IF EXISTS historial_usuarios;                -- Depende de usuarios
DROP TABLE IF EXISTS historial_proveedores;             -- Depende de proveedores y usuarios
DROP TABLE IF EXISTS historial_proveedores_detallado;   -- Depende de proveedores y usuarios
DROP TABLE IF EXISTS historial_ventas;                  -- Depende de ventas y usuarios
DROP TABLE IF EXISTS comisiones_pagadas;                -- Depende de ventas y empleados
DROP TABLE IF EXISTS inmuebles_imagenes;                -- Depende de inmuebles
DROP TABLE IF EXISTS inmuebles_clientes_interesados;    -- Depende de inmuebles y clientes
DROP TABLE IF EXISTS cliente_inmueble;                  -- Depende de inmuebles y clientes
DROP TABLE IF EXISTS comprobantes_ventas;
DROP TABLE IF EXISTS ventas;                            -- Depende de inmuebles y clientes
DROP TABLE IF EXISTS inmueble_proveedor_servicio;       -- Depende de inmuebles y proveedores



-- Ahora eliminar las tablas referenciadas
DROP TABLE IF EXISTS inmuebles;                         -- Referenciada por varias tablas
DROP TABLE IF EXISTS clientes;                          -- Referenciada por varias tablas
DROP TABLE IF EXISTS empleados;                         -- Referenciada por inmuebles y comisiones_pagadas
DROP TABLE IF EXISTS proveedores;                       -- Referenciada por historial_proveedores y inmueble_proveedor_servicio
DROP TABLE IF EXISTS contratos_generados;
DROP TABLE IF EXISTS usuarios;                          -- Referenciada por empleados y historial_usuarios
DROP TABLE IF EXISTS administrador;                     -- Sin dependencias directas
DROP TABLE IF EXISTS direcciones;                       -- Referenciada por clientes e inmuebles
DROP TABLE IF EXISTS estados;                           -- Referenciada por casi todas las tablas


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

-- Crear tabla de administrador
CREATE TABLE administrador (
    id_admin INT AUTO_INCREMENT PRIMARY KEY,
    NombreAdmin VARCHAR(100) NOT NULL,
    Contraseña VARCHAR(255) NOT NULL,
    id_estado INT DEFAULT 1,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
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
    comision_agencia DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Comisión para la agencia (30% del monto total)',
    comision_agente DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Comisión para el agente (3% del monto total)',
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

-- Tabla para registrar movimientos de renta
CREATE TABLE movimientos_renta (
    id_movimiento INT AUTO_INCREMENT PRIMARY KEY,
    id_inmueble INT NOT NULL,
    id_cliente INT NOT NULL,
    tipo_movimiento ENUM('ingreso','egreso') NOT NULL,
    concepto VARCHAR(100) NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    fecha_movimiento DATE NOT NULL,
    mes_correspondiente VARCHAR(7) NOT NULL,
    comentarios TEXT,
    id_estado INT NOT NULL DEFAULT 1,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_inmueble) REFERENCES inmuebles(id_inmueble) ON DELETE CASCADE,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado),
    INDEX idx_movimientos_mes (mes_correspondiente),
    INDEX idx_movimientos_inmueble (id_inmueble),
    INDEX idx_movimientos_cliente (id_cliente)
);

-- Tabla para los comprobantes de movimientos
CREATE TABLE comprobantes_movimientos (
    id_comprobante INT AUTO_INCREMENT PRIMARY KEY,
    id_movimiento INT NOT NULL,
    ruta_archivo VARCHAR(255) NOT NULL,
    tipo_archivo ENUM('imagen', 'pdf', 'documento') NOT NULL DEFAULT 'imagen',
    descripcion TEXT,
    es_principal TINYINT(1) NOT NULL DEFAULT 0,
    fecha_carga TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tipo_comprobante ENUM('factura', 'recibo', 'contrato', 'otro') NOT NULL,
    numero_referencia VARCHAR(50),
    emisor VARCHAR(100),
    receptor VARCHAR(100),
    metodo_pago ENUM('efectivo', 'transferencia', 'cheque', 'tarjeta', 'otro'),
    fecha_emision DATE,
    notas_adicionales TEXT,
    FOREIGN KEY (id_movimiento) REFERENCES movimientos_renta(id_movimiento) ON DELETE CASCADE,
    INDEX idx_comprobantes_movimiento (id_movimiento)
);

CREATE TABLE contratos_renta (
    id_contrato INT AUTO_INCREMENT PRIMARY KEY,
    id_inmueble INT NOT NULL,
    id_cliente INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    monto_mensual DECIMAL(12,2) NOT NULL,
    condiciones_adicionales TEXT,
    id_estado INT NOT NULL DEFAULT 1,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_inmueble) REFERENCES inmuebles(id_inmueble) ON DELETE CASCADE,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado),
    UNIQUE KEY (id_inmueble, id_estado, fecha_inicio),
    INDEX idx_contratos_inmueble (id_inmueble),
    INDEX idx_contratos_cliente (id_cliente)
);

CREATE TABLE comprobantes_ventas (
    id_comprobante INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    ruta_archivo VARCHAR(255) NOT NULL,
    tipo_archivo ENUM('imagen', 'pdf', 'documento') NOT NULL DEFAULT 'imagen',
    descripcion TEXT,
    es_principal TINYINT(1) NOT NULL DEFAULT 0,
    fecha_carga TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta) ON DELETE CASCADE,
    INDEX idx_comprobantes_venta (id_venta)
);

CREATE TABLE contratos_generados (
    id_contrato_generado INT AUTO_INCREMENT PRIMARY KEY,
    tipo_contrato ENUM('venta', 'renta') NOT NULL,
    id_referencia INT NOT NULL COMMENT 'ID de venta o contrato de renta',
    ruta_archivo VARCHAR(255) NOT NULL,
    fecha_generacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version INT NOT NULL DEFAULT 1,
    id_usuario INT,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    INDEX idx_contratos_tipo_ref (tipo_contrato, id_referencia)
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
CREATE INDEX idx_direcciones_ciudad ON direcciones(ciudad);
CREATE INDEX idx_inmuebles_tipo ON inmuebles(tipo_inmueble);
CREATE INDEX idx_clientes_rfc ON clientes(rfc);
CREATE INDEX idx_clientes_curp ON clientes(curp);
CREATE INDEX idx_proveedores_tipo_servicio ON proveedores(tipo_servicio);
CREATE INDEX idx_empleados_clave_sistema ON empleados(clave_sistema);
CREATE INDEX idx_inmuebles_operacion ON inmuebles(tipo_operacion);
CREATE INDEX idx_inmuebles_precio_venta ON inmuebles(precio_venta);
CREATE INDEX idx_inmuebles_precio_renta ON inmuebles(precio_renta);
CREATE INDEX idx_servicio_fecha_asignacion ON inmueble_proveedor_servicio(fecha_asignacion);
CREATE INDEX idx_servicio_fecha_servicio ON inmueble_proveedor_servicio(fecha_servicio);

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

CREATE TRIGGER validar_comprobante_update
BEFORE UPDATE ON comprobantes_movimientos
FOR EACH ROW
BEGIN
    -- Validar que si es una factura, tenga número de referencia
    IF NEW.tipo_comprobante = 'factura' AND (NEW.numero_referencia IS NULL OR NEW.numero_referencia = '') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Una factura debe tener un número de referencia';
    END IF;
    
    -- Validar que la fecha de emisión no sea futura
    IF NEW.fecha_emision > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de emisión no puede ser futura';
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
    
    -- Modificado: Calcular comisiones sobre monto total en lugar de costo cliente
    SET v_comision_agencia = p_monto_total * 0.30;
    SET v_comision_agente = p_monto_total * 0.03;
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
END//

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
    
    SELECT id_direccion INTO v_id_direccion
    FROM inmuebles 
    WHERE id_inmueble = p_id_inmueble;
    
    IF v_id_direccion IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inmueble no encontrado';
    END IF;

    -- Modificado: Calcular comisiones sobre monto total en lugar de costo cliente
    SET v_comision_agencia = p_monto_total * 0.30;
    SET v_comision_agente = p_monto_total * 0.03;
    SET v_precio_venta_final = IFNULL(p_costo_cliente, 0) + IFNULL(p_costo_servicios, 0) + v_comision_agencia + v_comision_agente;
    SET v_margen_utilidad = IF(v_precio_venta_final > 0, ((v_comision_agencia + v_comision_agente) / v_precio_venta_final) * 100, 0);

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
        id_estado = COALESCE(p_id_estado, id_estado),
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

-- Procedimiento para inactivar inmueble
CREATE PROCEDURE InactivarInmueble(IN p_id_inmueble INT)
BEGIN
    DECLARE v_id_estado_inactivo INT DEFAULT 2;
    DECLARE v_estado_actual INT;
    
    SELECT id_estado INTO v_estado_actual
    FROM inmuebles 
    WHERE id_inmueble = p_id_inmueble;
    
    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inmueble no encontrado';
    END IF;
    
    IF v_estado_actual = 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El inmueble ya está inactivo';
    END IF;
    
    START TRANSACTION;
    
    UPDATE inmuebles 
    SET id_estado = v_id_estado_inactivo
    WHERE id_inmueble = p_id_inmueble;
    
    COMMIT;
END //

-- Procedimiento para reactivar inmueble
CREATE PROCEDURE ReactivarInmueble(IN p_id_inmueble INT)
BEGIN
    DECLARE v_id_estado_disponible INT DEFAULT 3;
    DECLARE v_estado_actual INT;
    
    SELECT id_estado INTO v_estado_actual
    FROM inmuebles 
    WHERE id_inmueble = p_id_inmueble;
    
    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inmueble no encontrado';
    END IF;
    
    IF v_estado_actual = 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El inmueble ya está disponible';
    END IF;
    
    START TRANSACTION;
    
    UPDATE inmuebles 
    SET id_estado = v_id_estado_disponible
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
    OUT p_id_proveedor_out INT
)
BEGIN
    DECLARE v_id_estado_activo INT DEFAULT 1;
    
    IF EXISTS(SELECT 1 FROM proveedores WHERE correo = p_correo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El correo del proveedor ya existe';
    END IF;
    
    START TRANSACTION;
    
    INSERT INTO proveedores (
        nombre, nombre_empresa, nombre_contacto, direccion, telefono, correo, tipo_servicio, id_estado
    ) VALUES (
        p_nombre, p_nombre_empresa, p_nombre_contacto, p_direccion, p_telefono, p_correo, p_tipo_servicio, v_id_estado_activo
    );
    
    SET p_id_proveedor_out = LAST_INSERT_ID();
    
    INSERT INTO historial_proveedores (
        id_proveedor, id_estado_anterior, id_estado_nuevo
    ) VALUES (
        p_id_proveedor_out, NULL, v_id_estado_activo
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
        p.*,
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
    DECLARE v_correo_existente INT;
    
    SELECT id_estado INTO v_estado_actual
    FROM proveedores 
    WHERE id_proveedor = p_id_proveedor;
    
    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Proveedor no encontrado';
    END IF;
    
    IF v_estado_actual != 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede actualizar un proveedor inactivo';
    END IF;
    
    SELECT COUNT(*) INTO v_correo_existente
    FROM proveedores 
    WHERE correo = p_correo AND id_proveedor != p_id_proveedor;
    
    IF v_correo_existente > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El correo ya está en uso por otro proveedor';
    END IF;
    
    START TRANSACTION;
    
    UPDATE proveedores SET 
        nombre = p_nombre,
        nombre_empresa = p_nombre_empresa,
        nombre_contacto = p_nombre_contacto,
        direccion = p_direccion,
        telefono = p_telefono,
        correo = p_correo,
        tipo_servicio = p_tipo_servicio
    WHERE id_proveedor = p_id_proveedor;
    
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
    
    IF v_estado_actual = 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proveedor ya está inactivo';
    END IF;
    
    START TRANSACTION;
    
    UPDATE proveedores 
    SET id_estado = v_id_estado_inactivo,
        fecha_modificacion = NOW()
    WHERE id_proveedor = p_id_proveedor;
    
    INSERT INTO historial_proveedores (
        id_proveedor, id_estado_anterior, id_estado_nuevo, usuario_modificacion
    ) VALUES (
        p_id_proveedor, v_estado_actual, v_id_estado_inactivo, p_usuario_modificacion
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
        fecha_modificacion = NOW()
    WHERE id_proveedor = p_id_proveedor;
    
    INSERT INTO historial_proveedores (
        id_proveedor, id_estado_anterior, id_estado_nuevo, usuario_modificacion
    ) VALUES (
        p_id_proveedor, v_estado_actual, v_id_estado_activo, p_usuario_modificacion
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
        p.telefono LIKE CONCAT('%', p_termino_busqueda, '%') OR
        p.correo LIKE CONCAT('%', p_termino_busqueda, '%') OR
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
    DECLARE v_monto_total DECIMAL(12,2);
    DECLARE v_comision_agencia DECIMAL(12,2);
    DECLARE v_comision_agente DECIMAL(12,2);
    DECLARE v_precio_venta_final DECIMAL(12,2);
    DECLARE v_margen_utilidad DECIMAL(5,2);
    
    SELECT IFNULL(SUM(costo), 0) INTO v_costo_total
    FROM inmueble_proveedor_servicio
    WHERE id_inmueble = p_id_inmueble AND id_estado = 1;
    
    SELECT IFNULL(costo_cliente, 0), IFNULL(monto_total, 0) INTO v_costo_cliente, v_monto_total
    FROM inmuebles
    WHERE id_inmueble = p_id_inmueble;
    
    -- Modificado: Calcular comisiones sobre monto total en lugar de costo cliente
    SET v_comision_agencia = v_monto_total * 0.30;
    SET v_comision_agente = v_monto_total * 0.03;
    SET v_precio_venta_final = v_costo_cliente + v_costo_total + v_comision_agencia + v_comision_agente;
    
    IF v_precio_venta_final > 0 THEN
        SET v_margen_utilidad = ((v_comision_agencia + v_comision_agente) / v_precio_venta_final) * 100;
    ELSE
        SET v_margen_utilidad = 0;
    END IF;
    
    START TRANSACTION;
    
    UPDATE inmuebles SET
        costo_servicios = v_costo_total,
        comision_agencia = v_comision_agencia,
        comision_agente = v_comision_agente,
        precio_venta_final = v_precio_venta_final,
        margen_utilidad = v_margen_utilidad
    WHERE id_inmueble = p_id_inmueble;
    
    COMMIT;
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
    IN p_gastos_adicionales DECIMAL(15,2),
    IN p_usuario_modificacion INT
)
BEGIN
    DECLARE v_utilidad_bruta DECIMAL(15,2);
    DECLARE v_utilidad_neta DECIMAL(15,2);
    DECLARE v_valor_anterior DECIMAL(15,2);
    
    SELECT utilidad_bruta, utilidad_neta 
    INTO v_utilidad_bruta, v_valor_anterior
    FROM ventas 
    WHERE id_venta = p_id_venta;
    
    IF v_utilidad_bruta IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta especificada no existe';
    END IF;
    
    IF p_gastos_adicionales < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los gastos adicionales no pueden ser negativos';
    END IF;
    
    SET v_utilidad_neta = v_utilidad_bruta - p_gastos_adicionales;
    
    START TRANSACTION;
    
    UPDATE ventas 
    SET utilidad_neta = v_utilidad_neta 
    WHERE id_venta = p_id_venta;
    
    INSERT INTO historial_ventas (
        id_venta, campo_modificado, valor_anterior, valor_nuevo, 
        usuario_modificacion, fecha_modificacion
    ) VALUES (
        p_id_venta, 'utilidad_neta', v_valor_anterior, v_utilidad_neta,
        p_usuario_modificacion, CURRENT_TIMESTAMP
    );
    
    COMMIT;
END //

-- Procedimiento para obtener estadísticas de ventas con filtros de fecha
CREATE PROCEDURE ObtenerEstadisticasVentas(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
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
    AND v.id_estado IN (7, 8);
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
    WHERE v.id_estado IN (7, 8)
    GROUP BY i.tipo_inmueble
    ORDER BY utilidad_total DESC;
END //

-- Procedimiento para cambiar estado de venta
CREATE PROCEDURE CambiarEstadoVenta(
    IN p_id_venta INT,
    IN p_nuevo_estado INT,
    IN p_usuario_modificacion INT
)
BEGIN
    DECLARE v_estado_actual INT;
    DECLARE v_id_inmueble INT;
    
    SELECT id_estado, id_inmueble INTO v_estado_actual, v_id_inmueble
    FROM ventas
    WHERE id_venta = p_id_venta;
    
    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta especificada no existe';
    END IF;
    
    IF p_nuevo_estado NOT IN (8, 9) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado no válido. Solo se permite 8 (completada) o 9 (cancelada)';
    END IF;
    
    IF v_estado_actual != 7 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se puede cambiar el estado de una venta en proceso';
    END IF;
    
    START TRANSACTION;
    
    UPDATE ventas
    SET id_estado = p_nuevo_estado
    WHERE id_venta = p_id_venta;
    
    IF p_nuevo_estado = 9 THEN
        UPDATE inmuebles
        SET id_estado = 3
        WHERE id_inmueble = v_id_inmueble;
    END IF;
    
    INSERT INTO historial_ventas (
        id_venta, campo_modificado, valor_anterior, valor_nuevo, 
        usuario_modificacion, fecha_modificacion
    ) VALUES (
        p_id_venta, 'id_estado', v_estado_actual, p_nuevo_estado,
        p_usuario_modificacion, CURRENT_TIMESTAMP
    );
    
    COMMIT;
END //

-- Procedimiento para obtener inmuebles
CREATE PROCEDURE ObtenerInmuebles()
BEGIN
    SELECT 
        i.*,
        d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
        d.codigo_postal, d.referencias,
        e.nombre_estado AS estado_inmueble
    FROM inmuebles i
    LEFT JOIN direcciones d ON i.id_direccion = d.id_direccion
    LEFT JOIN estados e ON i.id_estado = e.id_estado
    ORDER BY i.fecha_registro DESC;
END //

-- Procedimiento para verificar existencia de inmueble
CREATE PROCEDURE VerificarExistenciaInmueble(
    IN p_id_inmueble INT,
    OUT p_existe INT
)
BEGIN
    SELECT COUNT(*) INTO p_existe
    FROM inmuebles 
    WHERE id_inmueble = p_id_inmueble;
END //

-- Procedimiento para buscar inmuebles
CREATE PROCEDURE BuscarInmuebles(
    IN p_tipo VARCHAR(20),
    IN p_operacion VARCHAR(20),
    IN p_precio_min DECIMAL(12,2),
    IN p_precio_max DECIMAL(12,2),
    IN p_ciudad VARCHAR(100),
    IN p_id_estado INT,
    IN p_margen_min DECIMAL(5,2)
)
BEGIN
    SELECT 
        i.*,
        d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
        d.codigo_postal, d.referencias,
        e.nombre_estado AS estado_inmueble
    FROM inmuebles i
    LEFT JOIN direcciones d ON i.id_direccion = d.id_direccion
    LEFT JOIN estados e ON i.id_estado = e.id_estado
    WHERE 1=1 
        AND (p_tipo IS NULL OR p_tipo = '' OR i.tipo_inmueble = p_tipo)
        AND (p_operacion IS NULL OR p_operacion = '' OR i.tipo_operacion = p_operacion)
        AND (p_precio_min IS NULL OR i.monto_total >= p_precio_min)
        AND (p_precio_max IS NULL OR i.monto_total <= p_precio_max)
        AND (p_ciudad IS NULL OR p_ciudad = '' OR d.ciudad LIKE CONCAT('%', p_ciudad, '%'))
        AND (p_id_estado IS NULL OR i.id_estado = p_id_estado)
        AND (p_margen_min IS NULL OR i.margen_utilidad >= p_margen_min)
    ORDER BY i.fecha_registro DESC;
END //

-- Procedimiento para obtener clientes interesados
CREATE PROCEDURE ObtenerClientesInteresados(
    IN p_id_inmueble INT
)
BEGIN
    SELECT 
        ci.id, ci.id_inmueble, ci.id_cliente, ci.fecha_interes, ci.comentarios,
        c.nombre, c.apellido_paterno, c.apellido_materno, c.telefono_cliente, c.correo_cliente
    FROM inmuebles_clientes_interesados ci
    JOIN clientes c ON ci.id_cliente = c.id_cliente
    WHERE ci.id_inmueble = p_id_inmueble
    ORDER BY ci.fecha_interes DESC;
END //

-- Procedimiento para registrar cliente interesado
CREATE PROCEDURE RegistrarClienteInteresado(
    IN p_id_inmueble INT,
    IN p_id_cliente INT,
    IN p_comentarios TEXT,
    OUT p_id_registro INT
)
BEGIN
    DECLARE v_inmueble_existe INT;
    DECLARE v_cliente_existe INT;
    
    SELECT COUNT(*) INTO v_inmueble_existe
    FROM inmuebles WHERE id_inmueble = p_id_inmueble;
    
    IF v_inmueble_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El inmueble especificado no existe';
    END IF;
    
    SELECT COUNT(*) INTO v_cliente_existe
    FROM clientes WHERE id_cliente = p_id_cliente;
    
    IF v_cliente_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente especificado no existe';
    END IF;
    
    START TRANSACTION;
    
    INSERT INTO inmuebles_clientes_interesados 
        (id_inmueble, id_cliente, comentarios, fecha_interes)
    VALUES 
        (p_id_inmueble, p_id_cliente, p_comentarios, NOW());
    
    SET p_id_registro = LAST_INSERT_ID();
    
    COMMIT;
END //

-- Procedimiento para obtener imágenes de inmueble
CREATE PROCEDURE ObtenerImagenesInmueble(
    IN p_id_inmueble INT
)
BEGIN
    SELECT 
        id_imagen, id_inmueble, ruta_imagen, descripcion, 
        es_principal, fecha_carga
    FROM inmuebles_imagenes
    WHERE id_inmueble = p_id_inmueble
    ORDER BY es_principal DESC, fecha_carga DESC;
END //

-- Procedimiento para obtener imagen principal
CREATE PROCEDURE ObtenerImagenPrincipal(
    IN p_id_inmueble INT
)
BEGIN
    SELECT 
        id_imagen, id_inmueble, ruta_imagen, descripcion, 
        es_principal, fecha_carga
    FROM inmuebles_imagenes
    WHERE id_inmueble = p_id_inmueble AND es_principal = 1
    LIMIT 1;
END //

-- Procedimiento para agregar imagen a inmueble
CREATE PROCEDURE AgregarImagenInmueble(
    IN p_id_inmueble INT,
    IN p_ruta_imagen VARCHAR(255),
    IN p_descripcion VARCHAR(100),
    IN p_es_principal BOOLEAN,
    OUT p_id_imagen_out INT
)
BEGIN
    DECLARE v_inmueble_existe INT;
    
    SELECT COUNT(*) INTO v_inmueble_existe
    FROM inmuebles WHERE id_inmueble = p_id_inmueble;
    
    IF v_inmueble_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El inmueble especificado no existe';
    END IF;
    
    START TRANSACTION;
    
    IF p_es_principal = 1 THEN
        UPDATE inmuebles_imagenes
        SET es_principal = 0
        WHERE id_inmueble = p_id_inmueble;
    END IF;
    
    INSERT INTO inmuebles_imagenes 
        (id_inmueble, ruta_imagen, descripcion, es_principal, fecha_carga)
    VALUES 
        (p_id_inmueble, p_ruta_imagen, p_descripcion, p_es_principal, NOW());
        
    SET p_id_imagen_out = LAST_INSERT_ID();
    
    COMMIT;
END //

-- Procedimiento para marcar imagen como principal
CREATE PROCEDURE MarcarImagenComoPrincipal(
    IN p_id_imagen INT,
    IN p_id_inmueble INT
)
BEGIN
    DECLARE v_imagen_valida INT;
    
    SELECT COUNT(*) INTO v_imagen_valida
    FROM inmuebles_imagenes 
    WHERE id_imagen = p_id_imagen AND id_inmueble = p_id_inmueble;
    
    IF v_imagen_valida = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La imagen no pertenece al inmueble especificado';
    END IF;
    
    START TRANSACTION;
    
    UPDATE inmuebles_imagenes
    SET es_principal = 0
    WHERE id_inmueble = p_id_inmueble;
    
    UPDATE inmuebles_imagenes
    SET es_principal = 1
    WHERE id_imagen = p_id_imagen;
    
    COMMIT;
END //

-- Procedimiento para eliminar imagen de inmueble
CREATE PROCEDURE EliminarImagenInmueble(
    IN p_id_imagen INT
)
BEGIN
    DECLARE v_es_principal BOOLEAN;
    DECLARE v_id_inmueble INT;
    
    SELECT es_principal, id_inmueble 
    INTO v_es_principal, v_id_inmueble
    FROM inmuebles_imagenes
    WHERE id_imagen = p_id_imagen;
    
    IF v_id_inmueble IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Imagen no encontrada';
    END IF;
    
    START TRANSACTION;
    
    DELETE FROM inmuebles_imagenes
    WHERE id_imagen = p_id_imagen;
    
    IF v_es_principal = 1 THEN
        UPDATE inmuebles_imagenes
        SET es_principal = 1
        WHERE id_inmueble = v_id_inmueble
        ORDER BY fecha_carga DESC
        LIMIT 1;
    END IF;
    
    COMMIT;
END //

-- Procedimiento para actualizar descripción de imagen
CREATE PROCEDURE ActualizarDescripcionImagen(
    IN p_id_imagen INT,
    IN p_nueva_descripcion VARCHAR(100)
)
BEGIN
    DECLARE v_imagen_existe INT;
    
    SELECT COUNT(*) INTO v_imagen_existe
    FROM inmuebles_imagenes WHERE id_imagen = p_id_imagen;
    
    IF v_imagen_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La imagen especificada no existe';
    END IF;
    
    UPDATE inmuebles_imagenes
    SET descripcion = p_nueva_descripcion
    WHERE id_imagen = p_id_imagen;
END //

-- Procedimiento para limpiar imágenes huérfanas
CREATE PROCEDURE LimpiarImagenesHuerfanas(
    OUT p_imagenes_eliminadas INT
)
BEGIN
    DECLARE v_contador INT DEFAULT 0;
    
    CREATE TEMPORARY TABLE tmp_imagenes_huerfanas (
        id_imagen INT,
        ruta_imagen VARCHAR(255)
    );
    
    INSERT INTO tmp_imagenes_huerfanas
    SELECT id_imagen, ruta_imagen
    FROM inmuebles_imagenes ii
    WHERE NOT EXISTS (
        SELECT 1 FROM inmuebles i 
        WHERE i.id_inmueble = ii.id_inmueble
    );
    
    SELECT COUNT(*) INTO v_contador FROM tmp_imagenes_huerfanas;
    
    DELETE FROM inmuebles_imagenes
    WHERE id_imagen IN (SELECT id_imagen FROM tmp_imagenes_huerfanas);
    
    DROP TEMPORARY TABLE IF EXISTS tmp_imagenes_huerfanas;
    
    SET p_imagenes_eliminadas = v_contador;
END //

-- Procedimiento para obtener clientes activos
CREATE PROCEDURE ObtenerClientesActivos()
BEGIN
    SELECT 
        c.*,
        d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
        d.codigo_postal, d.referencias,
        e.nombre_estado AS estado_cliente
    FROM clientes c
    LEFT JOIN direcciones d ON c.id_direccion = d.id_direccion
    LEFT JOIN estados e ON c.id_estado = e.id_estado
    WHERE c.id_estado = 1
    ORDER BY c.fecha_registro DESC;
END //

-- Procedimiento para obtener clientes inactivos
CREATE PROCEDURE ObtenerClientesInactivos()
BEGIN
    SELECT 
        c.*,
        d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
        d.codigo_postal, d.referencias,
        e.nombre_estado AS estado_cliente
    FROM clientes c
    LEFT JOIN direcciones d ON c.id_direccion = d.id_direccion
    LEFT JOIN estados e ON c.id_estado = e.id_estado
    WHERE c.id_estado != 1
    ORDER BY c.fecha_registro DESC;
END //

-- Procedimiento para obtener cliente por ID
CREATE PROCEDURE ObtenerClientePorId(IN p_id_cliente INT)
BEGIN
    SELECT 
        c.*,
        d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
        d.codigo_postal, d.referencias,
        e.nombre_estado AS estado_cliente
    FROM clientes c
    LEFT JOIN direcciones d ON c.id_direccion = d.id_direccion
    LEFT JOIN estados e ON c.id_estado = e.id_estado
    WHERE c.id_cliente = p_id_cliente;
END //

-- Procedimiento para obtener inmuebles por cliente
CREATE PROCEDURE ObtenerInmueblesPorCliente(IN p_id_cliente INT)
BEGIN
    SELECT 
        i.*,
        d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
        d.codigo_postal, d.referencias,
        e.nombre_estado AS estado_inmueble
    FROM inmuebles i
    LEFT JOIN direcciones d ON i.id_direccion = d.id_direccion
    LEFT JOIN estados e ON i.id_estado = e.id_estado
    WHERE i.id_cliente = p_id_cliente;
END //

-- Procedimiento para asignar inmueble a cliente
CREATE PROCEDURE AsignarInmuebleACliente(
    IN p_id_cliente INT,
    IN p_id_inmueble INT,
    IN p_fecha_adquisicion DATE,
    OUT p_resultado BOOLEAN
)
BEGIN
    DECLARE v_existe INT;
    
    SELECT COUNT(*) INTO v_existe
    FROM cliente_inmueble 
    WHERE id_inmueble = p_id_inmueble;
    
    IF v_existe > 0 THEN
        SET p_resultado = FALSE;
    ELSE
        START TRANSACTION;
        
        INSERT INTO cliente_inmueble (id_cliente, id_inmueble, fecha_adquisicion)
        VALUES (p_id_cliente, p_id_inmueble, p_fecha_adquisicion);
        SET p_resultado = TRUE;
        
        COMMIT;
    END IF;
END //

-- Procedimiento para desasignar inmueble de cliente
CREATE PROCEDURE DesasignarInmuebleDeCliente(
    IN p_id_inmueble INT,
    OUT p_resultado BOOLEAN
)
BEGIN
    START TRANSACTION;
    
    DELETE FROM cliente_inmueble 
    WHERE id_inmueble = p_id_inmueble;
    
    SET p_resultado = ROW_COUNT() > 0;
    
    COMMIT;
END //

-- Procedimiento para obtener todos los usuarios
CREATE PROCEDURE ObtenerUsuarios()
BEGIN
    SELECT * FROM usuarios;
END //

-- Procedimiento para obtener usuario por ID
CREATE PROCEDURE ObtenerUsuarioPorId(IN p_id_usuario INT)
BEGIN
    SELECT * FROM usuarios 
    WHERE id_usuario = p_id_usuario;
END //

-- Procedimiento para verificar credenciales
CREATE PROCEDURE VerificarCredenciales(
    IN p_nombre_usuario VARCHAR(100),
    IN p_contraseña VARCHAR(255),
    OUT p_existe BOOLEAN
)
BEGIN
    SELECT COUNT(*) > 0 INTO p_existe
    FROM usuarios 
    WHERE nombre_usuario = p_nombre_usuario 
    AND contraseña_usuario = EncriptarContraseña(p_contraseña);
END //

-- Procedimiento para verificar credenciales de administrador
CREATE PROCEDURE VerificarCredencialesAdmin(
    IN p_nombre_admin VARCHAR(100),
    IN p_contraseña VARCHAR(255),
    OUT p_existe BOOLEAN
)
BEGIN
    SELECT COUNT(*) > 0 INTO p_existe
    FROM administrador 
    WHERE NombreAdmin = p_nombre_admin 
    AND Contraseña = p_contraseña;
END //

-- Procedimiento para obtener administradores
CREATE PROCEDURE ObtenerAdministradores()
BEGIN
    SELECT * FROM administrador;
END //

-- Procedimiento para crear administrador
CREATE PROCEDURE CrearAdministrador(
    IN p_nombre_admin VARCHAR(100),
    IN p_contraseña VARCHAR(255),
    OUT p_id_admin_out INT
)
BEGIN
    START TRANSACTION;
    
    INSERT INTO administrador (NombreAdmin, Contraseña)
    VALUES (p_nombre_admin, p_contraseña);
    
    SET p_id_admin_out = LAST_INSERT_ID();
    
    COMMIT;
END //

-- Procedimiento para actualizar contraseña de administrador
CREATE PROCEDURE ActualizarContrasenaAdmin(
    IN p_nombre_admin VARCHAR(100),
    IN p_nueva_contraseña VARCHAR(255),
    OUT p_filas_afectadas INT
)
BEGIN
    START TRANSACTION;
    
    UPDATE administrador 
    SET Contraseña = p_nueva_contraseña 
    WHERE NombreAdmin = p_nombre_admin;
    
    SET p_filas_afectadas = ROW_COUNT();
    
    COMMIT;
END //

-- Procedimiento para obtener venta por ID
CREATE PROCEDURE ObtenerVentaPorId(IN p_id_venta INT)
BEGIN
    SELECT 
        v.id_venta,
        v.fecha_venta,
        v.id_cliente,
        v.id_inmueble,
        v.ingreso,
        v.comision_proveedores,
        v.utilidad_bruta,
        v.utilidad_neta,
        v.id_estado,
        c.nombre AS nombre_cliente,
        c.apellido_paterno AS apellido_cliente,
        i.nombre_inmueble,
        i.tipo_inmueble,
        i.tipo_operacion,
        e.nombre_estado AS estado_venta
    FROM ventas v
    JOIN clientes c ON v.id_cliente = c.id_cliente
    JOIN inmuebles i ON v.id_inmueble = i.id_inmueble
    JOIN estados e ON v.id_estado = e.id_estado
    WHERE v.id_venta = p_id_venta;
END //

-- Procedimiento para obtener estadísticas de ventas con filtro de fecha
CREATE PROCEDURE ObtenerEstadisticasVentasPorFecha(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    SELECT 
        COUNT(id_venta) AS total_ventas,
        SUM(ingreso) AS ingresos_totales,
        SUM(comision_proveedores) AS comisiones_totales,
        SUM(utilidad_bruta) AS utilidad_bruta_total,
        SUM(utilidad_neta) AS utilidad_neta_total,
        AVG(utilidad_neta) AS utilidad_promedio
    FROM ventas
    WHERE fecha_venta BETWEEN p_fecha_inicio AND p_fecha_fin
    AND id_estado = 8;
END //

-- Procedimiento para obtener ventas mensuales para gráficos
CREATE PROCEDURE ObtenerVentasMensuales(
    IN p_anio INT
)
BEGIN
    SELECT 
        MONTH(fecha_venta) AS mes,
        COUNT(id_venta) AS cantidad_ventas,
        SUM(ingreso) AS ingresos_totales,
        SUM(utilidad_neta) AS utilidad_neta
    FROM ventas
    WHERE YEAR(fecha_venta) = p_anio
    AND id_estado = 8
    GROUP BY MONTH(fecha_venta)
    ORDER BY MONTH(fecha_venta);
END //

-- Procedimiento para verificar si existe un nombre de usuario
CREATE PROCEDURE VerificarNombreUsuarioExiste(
    IN p_nombre_usuario VARCHAR(100),
    OUT p_existe BOOLEAN
)
BEGIN
    SELECT COUNT(*) > 0 INTO p_existe
    FROM usuarios
    WHERE nombre_usuario = p_nombre_usuario;
END //

-- Procedimiento para verificar si existe un nombre de usuario excluyendo un ID
CREATE PROCEDURE VerificarNombreUsuarioExisteExcluyendoId(
    IN p_nombre_usuario VARCHAR(100),
    IN p_id_excluir INT,
    OUT p_existe BOOLEAN
)
BEGIN
    SELECT COUNT(*) > 0 INTO p_existe
    FROM usuarios
    WHERE nombre_usuario = p_nombre_usuario AND id_usuario != p_id_excluir;
END //

-- Procedimiento para guardar una imagen de un inmueble
CREATE PROCEDURE GuardarImagenInmueble(
    IN p_id_inmueble INT,
    IN p_ruta_imagen VARCHAR(255),
    IN p_descripcion VARCHAR(100),
    IN p_es_principal BOOLEAN
)
BEGIN
    DECLARE v_inmueble_existe INT;
    
    SELECT COUNT(*) INTO v_inmueble_existe
    FROM inmuebles WHERE id_inmueble = p_id_inmueble;
    
    IF v_inmueble_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El inmueble especificado no existe';
    END IF;
    
    START TRANSACTION;
    
    IF p_es_principal = 1 THEN
        UPDATE inmuebles_imagenes
        SET es_principal = 0
        WHERE id_inmueble = p_id_inmueble;
    END IF;
    
    INSERT INTO inmuebles_imagenes 
        (id_inmueble, ruta_imagen, descripcion, es_principal, fecha_carga)
    VALUES 
        (p_id_inmueble, p_ruta_imagen, p_descripcion, p_es_principal, NOW());
    
    COMMIT;
END //

-- Procedimiento para verificar si un usuario existe
CREATE PROCEDURE VerificarUsuarioExiste(
    IN p_id_usuario INT,
    OUT p_existe BOOLEAN
)
BEGIN
    SELECT COUNT(*) > 0 INTO p_existe
    FROM usuarios
    WHERE id_usuario = p_id_usuario;
END //

-- Procedimiento para crear un usuario administrador
CREATE PROCEDURE CrearUsuarioAdministrador(
    IN p_nombre_admin VARCHAR(100),
    IN p_contraseña VARCHAR(255),
    OUT p_id_admin_out INT
)
BEGIN
    START TRANSACTION;
    
    INSERT INTO administrador (NombreAdmin, Contraseña)
    VALUES (p_nombre_admin, p_contraseña);
    
    SET p_id_admin_out = LAST_INSERT_ID();
    
    COMMIT;
END //

-- Procedimiento para obtener datos de una venta para un reporte
CREATE PROCEDURE ObtenerVentaReporte(
    IN p_id_venta INT
)
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
    WHERE v.id_venta = p_id_venta;
END //

-- Procedimiento para obtener estadísticas detalladas de ventas
CREATE PROCEDURE ObtenerEstadisticasVentasDetalladas(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    SET p_fecha_inicio = COALESCE(p_fecha_inicio, '2000-01-01');
    SET p_fecha_fin = COALESCE(p_fecha_fin, CURRENT_DATE());
    
    -- Estadísticas generales
    SELECT 
        COUNT(*) AS total_ventas,
        SUM(ingreso) AS ingreso_total,
        SUM(utilidad_neta) AS utilidad_total,
        AVG(utilidad_neta) AS utilidad_promedio,
        MIN(ingreso) AS venta_minima,
        MAX(ingreso) AS venta_maxima,
        COALESCE(AVG(utilidad_neta / NULLIF(ingreso, 0)) * 100, 0) AS porcentaje_utilidad_promedio
    FROM ventas
    WHERE fecha_venta BETWEEN p_fecha_inicio AND p_fecha_fin
    AND id_estado = 8;
    
    -- Estadísticas por tipo de inmueble
    SELECT 
        i.tipo_inmueble,
        COUNT(*) AS cantidad,
        SUM(v.ingreso) AS ingreso_total,
        SUM(v.utilidad_neta) AS utilidad_total,
        COALESCE(AVG(v.utilidad_neta / NULLIF(v.ingreso, 0)) * 100, 0) AS porcentaje_utilidad
    FROM ventas v
    JOIN inmuebles i ON v.id_inmueble = i.id_inmueble
    WHERE v.fecha_venta BETWEEN p_fecha_inicio AND p_fecha_fin
    AND v.id_estado = 8
    GROUP BY i.tipo_inmueble
    ORDER BY utilidad_total DESC;
    
    -- Ventas por mes
    SELECT 
        YEAR(fecha_venta) AS año,
        MONTH(fecha_venta) AS mes,
        COUNT(*) AS cantidad_ventas,
        SUM(ingreso) AS ingreso_total,
        SUM(utilidad_neta) AS utilidad_total
    FROM ventas
    WHERE fecha_venta BETWEEN p_fecha_inicio AND p_fecha_fin
    AND id_estado = 8
    GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
    ORDER BY YEAR(fecha_venta), MONTH(fecha_venta);
END //

-- Procedimiento para búsqueda avanzada de inmuebles
CREATE PROCEDURE BuscarInmueblesAvanzado(
    IN p_tipo VARCHAR(20),
    IN p_operacion VARCHAR(20),
    IN p_precio_min DECIMAL(12,2),
    IN p_precio_max DECIMAL(12,2),
    IN p_ciudad VARCHAR(100),
    IN p_estado_geo VARCHAR(100),
    IN p_margen_min DECIMAL(5,2)
)
BEGIN
    SELECT 
        i.*,
        d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
        d.codigo_postal, d.referencias,
        e.nombre_estado AS estado_inmueble
    FROM inmuebles i
    LEFT JOIN direcciones d ON i.id_direccion = d.id_direccion
    LEFT JOIN estados e ON i.id_estado = e.id_estado
    WHERE 1=1 
        AND (p_tipo IS NULL OR p_tipo = '' OR i.tipo_inmueble = p_tipo)
        AND (p_operacion IS NULL OR p_operacion = '' OR i.tipo_operacion = p_operacion)
        AND (p_precio_min IS NULL OR i.monto_total >= p_precio_min)
        AND (p_precio_max IS NULL OR i.monto_total <= p_precio_max)
        AND (p_ciudad IS NULL OR p_ciudad = '' OR d.ciudad LIKE CONCAT('%', p_ciudad, '%'))
        AND (p_estado_geo IS NULL OR p_estado_geo = '' OR d.estado_geografico LIKE CONCAT('%', p_estado_geo, '%'))
        AND (p_margen_min IS NULL OR i.margen_utilidad >= p_margen_min)
    ORDER BY i.fecha_registro DESC;
END //

-- Procedimiento para verificar conexion
CREATE PROCEDURE VerificarConexion()
BEGIN
    SELECT 1 as test;
END //

-- Procedimiento para registrar un nuevo movimiento
CREATE PROCEDURE RegistrarMovimientoRenta(
    IN p_id_inmueble INT,
    IN p_id_cliente INT,
    IN p_tipo_movimiento ENUM('ingreso', 'egreso'),
    IN p_concepto VARCHAR(100),
    IN p_monto DECIMAL(12,2),
    IN p_fecha_movimiento DATE,
    IN p_comentarios TEXT,
    OUT p_id_movimiento_out INT
)
BEGIN
    DECLARE v_mes_correspondiente VARCHAR(7);
    DECLARE v_estado_inmueble INT;
    
    -- Verificar que el inmueble exista y esté rentado
    SELECT id_estado INTO v_estado_inmueble
    FROM inmuebles 
    WHERE id_inmueble = p_id_inmueble;
    
    IF v_estado_inmueble IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El inmueble especificado no existe';
    END IF;
    
    IF v_estado_inmueble != 5 THEN -- 5 = rentado
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se pueden registrar movimientos para inmuebles rentados';
    END IF;
    
    -- Crear el formato YYYY-MM para mes correspondiente
    SET v_mes_correspondiente = DATE_FORMAT(p_fecha_movimiento, '%Y-%m');
    
    START TRANSACTION;
    
    INSERT INTO movimientos_renta (
        id_inmueble, id_cliente, tipo_movimiento, concepto, monto, 
        fecha_movimiento, mes_correspondiente, comentarios
    ) VALUES (
        p_id_inmueble, p_id_cliente, p_tipo_movimiento, p_concepto, p_monto,
        p_fecha_movimiento, v_mes_correspondiente, p_comentarios
    );
    
    SET p_id_movimiento_out = LAST_INSERT_ID();
    
    COMMIT;
END //

-- Procedimiento para obtener movimientos de un inmueble
CREATE PROCEDURE ObtenerMovimientosPorInmueble(
    IN p_id_inmueble INT
)
BEGIN
    SELECT 
        mr.*,
        c.nombre AS nombre_cliente,
        c.apellido_paterno AS apellido_cliente,
        i.nombre_inmueble,
        e.nombre_estado
    FROM movimientos_renta mr
    JOIN clientes c ON mr.id_cliente = c.id_cliente
    JOIN inmuebles i ON mr.id_inmueble = i.id_inmueble
    JOIN estados e ON mr.id_estado = e.id_estado
    WHERE mr.id_inmueble = p_id_inmueble
    ORDER BY mr.fecha_movimiento DESC;
END //

CREATE PROCEDURE ObtenerDatosContratoVenta(
    IN p_id_venta INT
)
BEGIN
    SELECT 
        v.id_venta, v.fecha_venta, v.ingreso, v.comision_proveedores,
        v.utilidad_bruta, v.utilidad_neta,
        c.id_cliente, c.nombre AS nombre_cliente, c.apellido_paterno,
        c.apellido_materno, c.rfc, c.curp, c.telefono_cliente, c.correo_cliente,
        i.id_inmueble, i.nombre_inmueble, i.tipo_inmueble, i.tipo_operacion,
        i.precio_venta, i.caracteristicas,
        d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
        d.codigo_postal, d.referencias
    FROM ventas v
    JOIN clientes c ON v.id_cliente = c.id_cliente
    JOIN inmuebles i ON v.id_inmueble = i.id_inmueble
    LEFT JOIN direcciones d ON i.id_direccion = d.id_direccion
    WHERE v.id_venta = p_id_venta;
END //

CREATE PROCEDURE ObtenerDatosContratoRenta(
    IN p_id_contrato INT
)
BEGIN
    SELECT 
        cr.id_contrato, cr.fecha_inicio, cr.fecha_fin, cr.monto_mensual,
        cr.condiciones_adicionales,
        c.id_cliente, c.nombre AS nombre_cliente, c.apellido_paterno,
        c.apellido_materno, c.rfc, c.curp, c.telefono_cliente, c.correo_cliente,
        i.id_inmueble, i.nombre_inmueble, i.tipo_inmueble, i.caracteristicas,
        d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
        d.codigo_postal, d.referencias
    FROM contratos_renta cr
    JOIN clientes c ON cr.id_cliente = c.id_cliente
    JOIN inmuebles i ON cr.id_inmueble = i.id_inmueble
    LEFT JOIN direcciones d ON i.id_direccion = d.id_direccion
    WHERE cr.id_contrato = p_id_contrato;
END //

CREATE PROCEDURE RegistrarContratoGenerado(
    IN p_tipo_contrato ENUM('venta', 'renta'),
    IN p_id_referencia INT,
    IN p_ruta_archivo VARCHAR(255),
    IN p_id_usuario INT,
    OUT p_id_contrato_generado_out INT
)
BEGIN
    DECLARE v_referencia_existe INT;
    DECLARE v_version INT;
    
    -- Verificar que la referencia exista
    IF p_tipo_contrato = 'venta' THEN
        SELECT COUNT(*) INTO v_referencia_existe
        FROM ventas 
        WHERE id_venta = p_id_referencia;
    ELSE
        SELECT COUNT(*) INTO v_referencia_existe
        FROM contratos_renta 
        WHERE id_contrato = p_id_referencia;
    END IF;
    
    IF v_referencia_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La referencia especificada no existe';
    END IF;
    
    -- Determinar la versión
    SELECT COALESCE(MAX(version), 0) + 1 INTO v_version
    FROM contratos_generados
    WHERE tipo_contrato = p_tipo_contrato AND id_referencia = p_id_referencia;
    
    START TRANSACTION;
    
    INSERT INTO contratos_generados (
        tipo_contrato, id_referencia, ruta_archivo, version, id_usuario
    ) VALUES (
        p_tipo_contrato, p_id_referencia, p_ruta_archivo, v_version, p_id_usuario
    );
    
    SET p_id_contrato_generado_out = LAST_INSERT_ID();
    
    COMMIT;
END //

-- Procedimiento para agregar comprobante a un movimiento
CREATE PROCEDURE AgregarComprobanteMovimiento(
    IN p_id_movimiento INT,
    IN p_ruta_archivo VARCHAR(255),  -- Cambiado de p_ruta_imagen a p_ruta_archivo
    IN p_tipo_archivo ENUM('imagen', 'pdf', 'documento'),
    IN p_descripcion TEXT,
    IN p_es_principal TINYINT(1),
    IN p_tipo_comprobante ENUM('factura', 'recibo', 'contrato', 'otro'),
    IN p_numero_referencia VARCHAR(50),
    IN p_emisor VARCHAR(100),
    IN p_receptor VARCHAR(100),
    IN p_metodo_pago ENUM('efectivo', 'transferencia', 'cheque', 'tarjeta', 'otro'),
    IN p_fecha_emision DATE,
    IN p_notas_adicionales TEXT,
    OUT p_id_comprobante_out INT
)
BEGIN
    DECLARE v_movimiento_existe INT;
    
    -- Verificar si el movimiento existe
    SELECT COUNT(*) INTO v_movimiento_existe
    FROM movimientos_renta
    WHERE id_movimiento = p_id_movimiento;
    
    IF v_movimiento_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El movimiento especificado no existe';
    END IF;
    
    START TRANSACTION;
    
    -- Insertar el nuevo comprobante con ruta_archivo (antes ruta_imagen)
    INSERT INTO comprobantes_movimientos (
        id_movimiento, 
        ruta_archivo,  -- Cambiado de ruta_imagen a ruta_archivo
        tipo_archivo, 
        descripcion, 
        es_principal, 
        tipo_comprobante,
        numero_referencia,
        emisor,
        receptor,
        metodo_pago,
        fecha_emision,
        notas_adicionales
    ) VALUES (
        p_id_movimiento, 
        p_ruta_archivo,  -- Cambiado de p_ruta_imagen a p_ruta_archivo
        p_tipo_archivo, 
        p_descripcion, 
        p_es_principal,
        p_tipo_comprobante,
        p_numero_referencia,
        p_emisor,
        p_receptor,
        p_metodo_pago,
        p_fecha_emision,
        p_notas_adicionales
    );
    
    SET p_id_comprobante_out = LAST_INSERT_ID();
    
    -- Si este es el comprobante principal, actualizar los demás a no principales
    IF p_es_principal = 1 THEN
        UPDATE comprobantes_movimientos
        SET es_principal = 0
        WHERE id_movimiento = p_id_movimiento AND id_comprobante != p_id_comprobante_out;
    END IF;
    
    COMMIT;
END //

-- Procedimiento para obtener comprobantes de un movimiento
CREATE PROCEDURE ObtenerComprobantesPorMovimiento(
    IN p_id_movimiento INT
)
BEGIN
    SELECT 
        id_comprobante,
        id_movimiento,
        ruta_imagen,
        descripcion,
        es_principal,
        tipo_comprobante,
        numero_referencia,
        emisor,
        receptor,
        metodo_pago,
        fecha_emision,
        notas_adicionales,
        fecha_carga
    FROM comprobantes_movimientos
    WHERE id_movimiento = p_id_movimiento
    ORDER BY es_principal DESC, fecha_carga DESC;
END //

CREATE PROCEDURE EliminarComprobanteMovimiento(
    IN p_id_comprobante INT,
    OUT p_afectados INT
)
BEGIN
    DECLARE v_comprobante_existe INT;
    DECLARE v_es_principal INT;
    DECLARE v_id_movimiento INT;
    
    -- Verificar que el comprobante exista y obtener datos relevantes
    SELECT COUNT(*), es_principal, id_movimiento 
    INTO v_comprobante_existe, v_es_principal, v_id_movimiento
    FROM comprobantes_movimientos 
    WHERE id_comprobante = p_id_comprobante;
    
    IF v_comprobante_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El comprobante especificado no existe';
    END IF;
    
    START TRANSACTION;
    
    -- Eliminar el comprobante
    DELETE FROM comprobantes_movimientos
    WHERE id_comprobante = p_id_comprobante;
    
    SET p_afectados = ROW_COUNT();
    
    -- Si era el comprobante principal, establecer otro como principal
    IF v_es_principal = 1 THEN
        -- Buscar el comprobante más reciente y establecerlo como principal
        UPDATE comprobantes_movimientos
        SET es_principal = 1
        WHERE id_movimiento = v_id_movimiento
        ORDER BY fecha_carga DESC
        LIMIT 1;
    END IF;
    
    COMMIT;
END //

-- Procedimiento para obtener resumen de movimientos por mes
CREATE PROCEDURE ObtenerResumenMovimientosRenta(
    IN p_id_inmueble INT,
    IN p_anio INT,
    IN p_mes INT
)
BEGIN
    DECLARE v_mes_correspondiente VARCHAR(7);
    
    -- Crear formato YYYY-MM para filtrar
    SET v_mes_correspondiente = CONCAT(
        LPAD(CAST(p_anio AS CHAR), 4, '0'), '-',
        LPAD(CAST(p_mes AS CHAR), 2, '0')
    );
    
    -- Ingresos totales
    SELECT SUM(monto) AS total_ingresos
    FROM movimientos_renta
    WHERE id_inmueble = p_id_inmueble 
      AND tipo_movimiento = 'ingreso'
      AND mes_correspondiente = v_mes_correspondiente;
      
    -- Egresos totales
    SELECT SUM(monto) AS total_egresos
    FROM movimientos_renta
    WHERE id_inmueble = p_id_inmueble 
      AND tipo_movimiento = 'egreso'
      AND mes_correspondiente = v_mes_correspondiente;
      
    -- Detalles de movimientos
    SELECT 
        mr.*,
        c.nombre AS nombre_cliente,
        c.apellido_paterno AS apellido_cliente
    FROM movimientos_renta mr
    JOIN clientes c ON mr.id_cliente = c.id_cliente
    WHERE mr.id_inmueble = p_id_inmueble
      AND mr.mes_correspondiente = v_mes_correspondiente
    ORDER BY mr.fecha_movimiento;
END //

CREATE PROCEDURE ActualizarComprobanteMovimiento(
    IN p_id_comprobante INT,
    IN p_descripcion TEXT,
    IN p_es_principal TINYINT(1),
    IN p_tipo_comprobante ENUM('factura', 'recibo', 'contrato', 'otro'),
    IN p_numero_referencia VARCHAR(50),
    IN p_emisor VARCHAR(100),
    IN p_receptor VARCHAR(100),
    IN p_metodo_pago ENUM('efectivo', 'transferencia', 'cheque', 'tarjeta', 'otro'),
    IN p_fecha_emision DATE,
    IN p_notas_adicionales TEXT
)
BEGIN
    DECLARE v_id_movimiento INT;
    DECLARE v_comprobante_existe INT;
    
    -- Verificar que el comprobante exista
    SELECT COUNT(*), id_movimiento INTO v_comprobante_existe, v_id_movimiento
    FROM comprobantes_movimientos 
    WHERE id_comprobante = p_id_comprobante
    GROUP BY id_movimiento;
    
    IF v_comprobante_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El comprobante especificado no existe';
    END IF;
    
    START TRANSACTION;
    
    -- Si se marca como principal, actualizar los demás comprobantes
    IF p_es_principal = 1 THEN
        UPDATE comprobantes_movimientos
        SET es_principal = 0
        WHERE id_movimiento = v_id_movimiento
        AND id_comprobante != p_id_comprobante;
    END IF;
    
    -- Actualizar el comprobante con todos los campos
    UPDATE comprobantes_movimientos
    SET 
        descripcion = p_descripcion,
        es_principal = p_es_principal,
        tipo_comprobante = p_tipo_comprobante,
        numero_referencia = p_numero_referencia,
        emisor = p_emisor,
        receptor = p_receptor,
        metodo_pago = p_metodo_pago,
        fecha_emision = p_fecha_emision,
        notas_adicionales = p_notas_adicionales
    WHERE id_comprobante = p_id_comprobante;
    
    COMMIT;
END //

CREATE PROCEDURE ObtenerComprobantesDetallados(
    IN p_id_movimiento INT,
    IN p_tipo_comprobante ENUM('factura', 'recibo', 'contrato', 'otro')
)
BEGIN
    SELECT 
        cm.id_comprobante,
        cm.id_movimiento,
        cm.ruta_imagen,
        cm.descripcion,
        cm.es_principal,
        cm.tipo_comprobante,
        cm.numero_referencia,
        cm.emisor,
        cm.receptor,
        cm.metodo_pago,
        cm.fecha_emision,
        cm.notas_adicionales,
        cm.fecha_carga,
        mr.concepto AS concepto_movimiento,
        mr.monto AS monto_movimiento,
        mr.fecha_movimiento,
        i.nombre_inmueble,
        c.nombre AS nombre_cliente,
        c.apellido_paterno AS apellido_cliente
    FROM comprobantes_movimientos cm
    JOIN movimientos_renta mr ON cm.id_movimiento = mr.id_movimiento
    JOIN inmuebles i ON mr.id_inmueble = i.id_inmueble
    JOIN clientes c ON mr.id_cliente = c.id_cliente
    WHERE cm.id_movimiento = p_id_movimiento
    AND (p_tipo_comprobante IS NULL OR cm.tipo_comprobante = p_tipo_comprobante)
    ORDER BY cm.es_principal DESC, cm.fecha_carga DESC;
END //

-- Procedimiento para actualizar un comprobante de venta
CREATE PROCEDURE ActualizarComprobanteVenta(
    IN p_id_comprobante INT,
    IN p_descripcion TEXT,
    IN p_es_principal TINYINT(1),
    IN p_tipo_archivo ENUM('imagen', 'pdf', 'documento')
)
BEGIN
    DECLARE v_id_venta INT;
    DECLARE v_comprobante_existe INT;
    
    -- Verificar que el comprobante exista y obtener el id_venta
    SELECT COUNT(*), id_venta INTO v_comprobante_existe, v_id_venta
    FROM comprobantes_ventas 
    WHERE id_comprobante = p_id_comprobante
    GROUP BY id_venta;
    
    IF v_comprobante_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El comprobante especificado no existe';
    END IF;
    
    START TRANSACTION;
    
    -- Si se marca como principal, actualizar los demás comprobantes de la venta
    IF p_es_principal = 1 THEN
        UPDATE comprobantes_ventas
        SET es_principal = 0
        WHERE id_venta = v_id_venta
        AND id_comprobante != p_id_comprobante;
    END IF;
    
    -- Actualizar el comprobante
    UPDATE comprobantes_ventas
    SET 
        descripcion = p_descripcion,
        es_principal = p_es_principal,
        tipo_archivo = COALESCE(p_tipo_archivo, tipo_archivo)
    WHERE id_comprobante = p_id_comprobante;
    
    COMMIT;
END //

-- Procedimiento para eliminar un comprobante de venta
CREATE PROCEDURE EliminarComprobanteVenta(
    IN p_id_comprobante INT,
    OUT p_afectados INT
)
BEGIN
    DECLARE v_comprobante_existe INT;
    DECLARE v_es_principal INT;
    DECLARE v_id_venta INT;
    
    -- Verificar que el comprobante exista y obtener datos relevantes
    SELECT COUNT(*), es_principal, id_venta 
    INTO v_comprobante_existe, v_es_principal, v_id_venta
    FROM comprobantes_ventas 
    WHERE id_comprobante = p_id_comprobante;
    
    IF v_comprobante_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El comprobante especificado no existe';
    END IF;
    
    START TRANSACTION;
    
    -- Eliminar el comprobante
    DELETE FROM comprobantes_ventas
    WHERE id_comprobante = p_id_comprobante;
    
    SET p_afectados = ROW_COUNT();
    
    -- Si era el comprobante principal, establecer otro como principal
    IF v_es_principal = 1 THEN
        UPDATE comprobantes_ventas
        SET es_principal = 1
        WHERE id_venta = v_id_venta
        ORDER BY fecha_carga DESC
        LIMIT 1;
    END IF;
    
    COMMIT;
END //

-- Procedimiento para obtener comprobantes por venta
CREATE PROCEDURE ObtenerComprobantesPorVenta(
    IN p_id_venta INT
)
BEGIN
    SELECT 
        id_comprobante,
        id_venta,
        ruta_archivo,
        tipo_archivo,
        descripcion,
        es_principal,
        fecha_carga
    FROM comprobantes_ventas
    WHERE id_venta = p_id_venta
    ORDER BY es_principal DESC, fecha_carga DESC;
END //

-- Procedimiento para obtener contratos generados por referencia
CREATE PROCEDURE ObtenerContratosGeneradosPorReferencia(
    IN p_tipo_contrato ENUM('venta', 'renta'),
    IN p_id_referencia INT
)
BEGIN
    SELECT 
        id_contrato_generado,
        tipo_contrato,
        id_referencia,
        ruta_archivo,
        fecha_generacion,
        version,
        id_usuario
    FROM contratos_generados
    WHERE tipo_contrato = p_tipo_contrato AND id_referencia = p_id_referencia
    ORDER BY version DESC;
END //

-- Procedimiento para eliminar un contrato generado
CREATE PROCEDURE EliminarContratoGenerado(
    IN p_id_contrato_generado INT,
    OUT p_afectados INT
)
BEGIN
    DECLARE v_contrato_existe INT;
    
    -- Verificar que el contrato generado exista
    SELECT COUNT(*) INTO v_contrato_existe
    FROM contratos_generados 
    WHERE id_contrato_generado = p_id_contrato_generado;
    
    IF v_contrato_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El contrato generado especificado no existe';
    END IF;
    
    START TRANSACTION;
    
    -- Eliminar el contrato generado
    DELETE FROM contratos_generados
    WHERE id_contrato_generado = p_id_contrato_generado;
    
    SET p_afectados = ROW_COUNT();
    
    COMMIT;
END //

-- Procedimiento para obtener contratos por inmueble
CREATE PROCEDURE ObtenerContratosPorInmueble(
    IN p_id_inmueble INT
)
BEGIN
    SELECT 
        cr.id_contrato,
        cr.fecha_inicio,
        cr.fecha_fin,
        cr.monto_mensual,
        cr.condiciones_adicionales,
        cr.id_estado,
        cr.fecha_registro,
        c.id_cliente,
        c.nombre AS nombre_cliente,
        c.apellido_paterno,
        c.apellido_materno,
        e.nombre_estado AS estado_contrato
    FROM contratos_renta cr
    JOIN clientes c ON cr.id_cliente = c.id_cliente
    JOIN estados e ON cr.id_estado = e.id_estado
    WHERE cr.id_inmueble = p_id_inmueble
    ORDER BY cr.fecha_inicio DESC;
END //

-- Procedimiento para obtener movimientos por contrato
CREATE PROCEDURE ObtenerMovimientosPorContrato(
    IN p_id_contrato INT
)
BEGIN
    DECLARE v_id_inmueble INT;
    DECLARE v_id_cliente INT;
    
    -- Obtener id_inmueble y id_cliente del contrato
    SELECT id_inmueble, id_cliente INTO v_id_inmueble, v_id_cliente
    FROM contratos_renta
    WHERE id_contrato = p_id_contrato;
    
    IF v_id_inmueble IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El contrato especificado no existe';
    END IF;
    
    -- Obtener movimientos asociados al inmueble y cliente del contrato
    SELECT 
        mr.id_movimiento,
        mr.tipo_movimiento,
        mr.concepto,
        mr.monto,
        mr.fecha_movimiento,
        mr.mes_correspondiente,
        mr.comentarios,
        mr.id_estado,
        mr.fecha_registro
    FROM movimientos_renta mr
    WHERE mr.id_inmueble = v_id_inmueble AND mr.id_cliente = v_id_cliente
    ORDER BY mr.fecha_movimiento DESC;
END //

CREATE PROCEDURE BuscarComprobantes(
    IN p_numero_referencia VARCHAR(50),
    IN p_tipo_comprobante ENUM('factura', 'recibo', 'contrato', 'otro'),
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    SELECT 
        cm.id_comprobante,
        cm.id_movimiento,
        cm.ruta_imagen,
        cm.descripcion,
        cm.es_principal,
        cm.tipo_comprobante,
        cm.numero_referencia,
        cm.emisor,
        cm.receptor,
        cm.metodo_pago,
        cm.fecha_emision,
        cm.notas_adicionales,
        cm.fecha_carga,
        mr.concepto AS concepto_movimiento,
        mr.monto AS monto_movimiento,
        mr.fecha_movimiento,
        i.nombre_inmueble,
        c.nombre AS nombre_cliente,
        c.apellido_paterno AS apellido_cliente
    FROM comprobantes_movimientos cm
    JOIN movimientos_renta mr ON cm.id_movimiento = mr.id_movimiento
    JOIN inmuebles i ON mr.id_inmueble = i.id_inmueble
    JOIN clientes c ON mr.id_cliente = c.id_cliente
    WHERE 1=1
    AND (p_numero_referencia IS NULL OR p_numero_referencia = '' OR cm.numero_referencia LIKE CONCAT('%', p_numero_referencia, '%'))
    AND (p_tipo_comprobante IS NULL OR cm.tipo_comprobante = p_tipo_comprobante)
    AND (p_fecha_inicio IS NULL OR cm.fecha_emision >= p_fecha_inicio)
    AND (p_fecha_fin IS NULL OR cm.fecha_emision <= p_fecha_fin)
    ORDER BY cm.fecha_carga DESC;
END //

-- Procedimiento para validar comprobantes fiscales
CREATE PROCEDURE ValidarComprobanteFiscal(
    IN p_id_comprobante INT,
    IN p_estado_validacion ENUM('pendiente', 'aprobado', 'rechazado'),
    IN p_comentario_validacion TEXT,
    IN p_usuario_validacion INT
)
BEGIN
    DECLARE v_comprobante_existe INT;
    DECLARE v_es_fiscal INT;
    
    -- Verificar que el comprobante exista
    SELECT COUNT(*) INTO v_comprobante_existe
    FROM comprobantes_movimientos 
    WHERE id_comprobante = p_id_comprobante;
    
    IF v_comprobante_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El comprobante especificado no existe';
    END IF;
    
    -- Verificar que sea un comprobante fiscal (factura o recibo)
    SELECT COUNT(*) INTO v_es_fiscal
    FROM comprobantes_movimientos 
    WHERE id_comprobante = p_id_comprobante
    AND tipo_comprobante IN ('factura', 'recibo');
    
    IF v_es_fiscal = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se pueden validar comprobantes de tipo factura o recibo';
    END IF;
    
    -- Actualizar el campo notas_adicionales para incluir la información de validación
    START TRANSACTION;
    
    UPDATE comprobantes_movimientos
    SET notas_adicionales = CONCAT(
        COALESCE(notas_adicionales, ''),
        '\n[VALIDACIÓN: ', p_estado_validacion, ' - ', 
        DATE_FORMAT(NOW(), '%d/%m/%Y %H:%i:%s'), ' - Usuario ID: ', p_usuario_validacion, 
        ']\n', p_comentario_validacion
    )
    WHERE id_comprobante = p_id_comprobante;
    
    COMMIT;
    
    SELECT 'Comprobante validado exitosamente' AS mensaje;
END //

CREATE PROCEDURE ObtenerComprobantesVenta(
    IN p_id_venta INT
)
BEGIN
    SELECT *
    FROM comprobantes_ventas
    WHERE id_venta = p_id_venta
    ORDER BY es_principal DESC, fecha_carga DESC;
END //

CREATE PROCEDURE AgregarComprobanteVenta(
    IN p_id_venta INT,
    IN p_ruta_archivo VARCHAR(255),
    IN p_tipo_archivo ENUM('imagen', 'pdf', 'documento'),
    IN p_descripcion TEXT,
    IN p_es_principal TINYINT(1),
    OUT p_id_comprobante_out INT
)
BEGIN
    DECLARE v_venta_existe INT;
    
    -- Verificar que la venta exista
    SELECT COUNT(*) INTO v_venta_existe
    FROM ventas 
    WHERE id_venta = p_id_venta;
    
    IF v_venta_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta especificada no existe';
    END IF;
    
    START TRANSACTION;
    
    -- Si es principal, actualizar los demás comprobantes
    IF p_es_principal = 1 THEN
        UPDATE comprobantes_ventas
        SET es_principal = 0
        WHERE id_venta = p_id_venta;
    END IF;
    
    INSERT INTO comprobantes_ventas (
        id_venta, ruta_archivo, tipo_archivo, descripcion, es_principal
    ) VALUES (
        p_id_venta, p_ruta_archivo, COALESCE(p_tipo_archivo, 'imagen'), p_descripcion, p_es_principal
    );
    
    SET p_id_comprobante_out = LAST_INSERT_ID();
    
    COMMIT;
END //

-- Procedimiento para buscar comprobantes por tipo
CREATE PROCEDURE BuscarComprobantesPorTipo(
    IN p_tipo_comprobante ENUM('factura', 'recibo', 'contrato', 'otro')
)
BEGIN
    SELECT 
        cm.id_comprobante,
        cm.id_movimiento,
        cm.ruta_imagen,
        cm.descripcion,
        cm.es_principal,
        cm.tipo_comprobante,
        cm.numero_referencia,
        cm.emisor,
        cm.receptor,
        cm.metodo_pago,
        cm.fecha_emision,
        cm.notas_adicionales,
        cm.fecha_carga,
        mr.concepto AS concepto_movimiento,
        mr.fecha_movimiento,
        mr.monto AS monto_movimiento,
        i.nombre_inmueble,
        c.nombre AS nombre_cliente,
        c.apellido_paterno AS apellido_cliente
    FROM comprobantes_movimientos cm
    JOIN movimientos_renta mr ON cm.id_movimiento = mr.id_movimiento
    JOIN inmuebles i ON mr.id_inmueble = i.id_inmueble
    JOIN clientes c ON mr.id_cliente = c.id_cliente
    WHERE cm.tipo_comprobante = p_tipo_comprobante
    ORDER BY cm.fecha_carga DESC;
END //

-- Procedimiento para obtener resumen de comprobantes fiscales
CREATE PROCEDURE ObtenerResumenComprobantes(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    -- Establecer fechas por defecto si son nulas
    SET p_fecha_inicio = COALESCE(p_fecha_inicio, DATE_SUB(CURDATE(), INTERVAL 1 YEAR));
    SET p_fecha_fin = COALESCE(p_fecha_fin, CURDATE());
    
    -- Resumen por tipo de comprobante
    SELECT 
        tipo_comprobante, 
        COUNT(*) as cantidad,
        COUNT(DISTINCT id_movimiento) as movimientos_asociados
    FROM comprobantes_movimientos
    WHERE (p_fecha_inicio IS NULL OR fecha_emision >= p_fecha_inicio)
    AND (p_fecha_fin IS NULL OR fecha_emision <= p_fecha_fin)
    GROUP BY tipo_comprobante;
    
    -- Resumen por mes
    SELECT 
        YEAR(fecha_emision) as anio,
        MONTH(fecha_emision) as mes,
        COUNT(*) as cantidad,
        COUNT(DISTINCT id_movimiento) as movimientos_asociados
    FROM comprobantes_movimientos
    WHERE (p_fecha_inicio IS NULL OR fecha_emision >= p_fecha_inicio)
    AND (p_fecha_fin IS NULL OR fecha_emision <= p_fecha_fin)
    GROUP BY YEAR(fecha_emision), MONTH(fecha_emision)
    ORDER BY YEAR(fecha_emision), MONTH(fecha_emision);
    
    -- Resumen por método de pago
    SELECT 
        metodo_pago, 
        COUNT(*) as cantidad
    FROM comprobantes_movimientos
    WHERE (p_fecha_inicio IS NULL OR fecha_emision >= p_fecha_inicio)
    AND (p_fecha_fin IS NULL OR fecha_emision <= p_fecha_fin)
    AND metodo_pago IS NOT NULL
    GROUP BY metodo_pago;
END //

CREATE PROCEDURE ReporteComprobantesMovimientosPorPeriodo(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_id_inmueble INT
)
BEGIN
    -- Establecer valores por defecto para las fechas si son NULL
    SET p_fecha_inicio = COALESCE(p_fecha_inicio, DATE_SUB(CURDATE(), INTERVAL 1 MONTH));
    SET p_fecha_fin = COALESCE(p_fecha_fin, CURDATE());
    
    -- Reporte detallado de comprobantes por fecha
    SELECT 
        cm.id_comprobante,
        cm.id_movimiento,
        cm.tipo_comprobante,
        cm.numero_referencia,
        cm.emisor,
        cm.receptor,
        cm.metodo_pago,
        cm.fecha_emision,
        cm.descripcion,
        mr.concepto,
        mr.monto,
        mr.tipo_movimiento,
        i.nombre_inmueble,
        c.nombre AS nombre_cliente,
        c.apellido_paterno AS apellido_cliente
    FROM comprobantes_movimientos cm
    JOIN movimientos_renta mr ON cm.id_movimiento = mr.id_movimiento
    JOIN inmuebles i ON mr.id_inmueble = i.id_inmueble
    JOIN clientes c ON mr.id_cliente = c.id_cliente
    WHERE cm.fecha_emision BETWEEN p_fecha_inicio AND p_fecha_fin
    AND (p_id_inmueble IS NULL OR mr.id_inmueble = p_id_inmueble)
    ORDER BY cm.fecha_emision DESC, i.nombre_inmueble;
    
    -- Resumen estadístico
    SELECT 
        COUNT(*) as total_comprobantes,
        COUNT(DISTINCT cm.id_movimiento) as total_movimientos,
        COUNT(DISTINCT mr.id_inmueble) as total_inmuebles,
        SUM(CASE WHEN cm.tipo_comprobante = 'factura' THEN 1 ELSE 0 END) as total_facturas,
        SUM(CASE WHEN cm.tipo_comprobante = 'recibo' THEN 1 ELSE 0 END) as total_recibos,
        SUM(CASE WHEN cm.tipo_comprobante = 'contrato' THEN 1 ELSE 0 END) as total_contratos,
        SUM(CASE WHEN cm.tipo_comprobante = 'otro' THEN 1 ELSE 0 END) as total_otros
    FROM comprobantes_movimientos cm
    JOIN movimientos_renta mr ON cm.id_movimiento = mr.id_movimiento
    WHERE cm.fecha_emision BETWEEN p_fecha_inicio AND p_fecha_fin
    AND (p_id_inmueble IS NULL OR mr.id_inmueble = p_id_inmueble);
END //

-- Procedimiento para eliminar un movimiento
CREATE PROCEDURE EliminarMovimientoRenta(
    IN p_id_movimiento INT
)
BEGIN
    DECLARE v_movimiento_existe INT;
    
    SELECT COUNT(*) INTO v_movimiento_existe
    FROM movimientos_renta 
    WHERE id_movimiento = p_id_movimiento;
    
    IF v_movimiento_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El movimiento especificado no existe';
    END IF;
    
    START TRANSACTION;
    
    -- Los comprobantes se eliminarán en cascada
    DELETE FROM movimientos_renta
    WHERE id_movimiento = p_id_movimiento;
    
    COMMIT;
END //

CREATE PROCEDURE ClonarComprobante(
    IN p_id_comprobante INT,
    IN p_id_movimiento_destino INT,
    OUT p_nuevo_id_comprobante INT
)
BEGIN
    DECLARE v_comprobante_existe INT;
    DECLARE v_movimiento_destino_existe INT;
    
    -- Verificar que el comprobante origen exista
    SELECT COUNT(*) INTO v_comprobante_existe
    FROM comprobantes_movimientos 
    WHERE id_comprobante = p_id_comprobante;
    
    IF v_comprobante_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El comprobante origen no existe';
    END IF;
    
    -- Verificar que el movimiento destino exista
    SELECT COUNT(*) INTO v_movimiento_destino_existe
    FROM movimientos_renta 
    WHERE id_movimiento = p_id_movimiento_destino;
    
    IF v_movimiento_destino_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El movimiento destino no existe';
    END IF;
    
    START TRANSACTION;
    
    -- Insertar una copia del comprobante con el nuevo id_movimiento
    INSERT INTO comprobantes_movimientos (
        id_movimiento,
        ruta_imagen,
        descripcion,
        es_principal,
        tipo_comprobante,
        numero_referencia,
        emisor,
        receptor,
        metodo_pago,
        fecha_emision,
        notas_adicionales
    )
    SELECT 
        p_id_movimiento_destino,
        ruta_imagen,
        CONCAT(descripcion, ' (Copia)'),
        0, -- No será principal por defecto
        tipo_comprobante,
        numero_referencia,
        emisor,
        receptor,
        metodo_pago,
        fecha_emision,
        CONCAT(notas_adicionales, ' - Clonado de comprobante #', p_id_comprobante)
    FROM comprobantes_movimientos
    WHERE id_comprobante = p_id_comprobante;
    
    SET p_nuevo_id_comprobante = LAST_INSERT_ID();
    
    COMMIT;
END //

CREATE PROCEDURE ObtenerCumplimientoFiscal(
    IN p_id_inmueble INT,
    IN p_anio INT,
    IN p_mes INT
)
BEGIN
    DECLARE v_mes_inicio DATE;
    DECLARE v_mes_fin DATE;
    
    -- Si no se especifica año o mes, usar el actual
    SET p_anio = COALESCE(p_anio, YEAR(CURDATE()));
    SET p_mes = COALESCE(p_mes, MONTH(CURDATE()));
    
    -- Calcular el inicio y fin del mes
    SET v_mes_inicio = CONCAT(p_anio, '-', LPAD(p_mes, 2, '0'), '-01');
    SET v_mes_fin = LAST_DAY(v_mes_inicio);
    
    -- Obtener todos los movimientos de renta del período
    SELECT 
        mr.id_movimiento,
        mr.concepto,
        mr.monto,
        mr.fecha_movimiento,
        mr.tipo_movimiento,
        i.nombre_inmueble,
        c.nombre AS nombre_cliente,
        c.apellido_paterno AS apellido_cliente,
        CASE 
            WHEN COUNT(cm.id_comprobante) = 0 THEN 'Sin comprobante'
            WHEN COUNT(CASE WHEN cm.tipo_comprobante = 'factura' THEN 1 ELSE NULL END) > 0 THEN 'Con factura'
            WHEN COUNT(CASE WHEN cm.tipo_comprobante = 'recibo' THEN 1 ELSE NULL END) > 0 THEN 'Con recibo'
            ELSE 'Otro comprobante'
        END AS estado_comprobante
    FROM movimientos_renta mr
    JOIN inmuebles i ON mr.id_inmueble = i.id_inmueble
    JOIN clientes c ON mr.id_cliente = c.id_cliente
    LEFT JOIN comprobantes_movimientos cm ON mr.id_movimiento = cm.id_movimiento
    WHERE mr.fecha_movimiento BETWEEN v_mes_inicio AND v_mes_fin
    AND (p_id_inmueble IS NULL OR mr.id_inmueble = p_id_inmueble)
    GROUP BY mr.id_movimiento
    ORDER BY mr.fecha_movimiento;
    
    -- Estadísticas de cumplimiento
    SELECT 
        COUNT(*) AS total_movimientos,
        SUM(CASE WHEN cm.id_comprobante IS NOT NULL THEN 1 ELSE 0 END) AS con_comprobante,
        SUM(CASE WHEN cm.id_comprobante IS NULL THEN 1 ELSE 0 END) AS sin_comprobante,
        SUM(CASE WHEN cm.tipo_comprobante = 'factura' THEN 1 ELSE 0 END) AS con_factura,
        SUM(CASE WHEN cm.tipo_comprobante = 'recibo' THEN 1 ELSE 0 END) AS con_recibo,
        SUM(CASE WHEN cm.tipo_comprobante NOT IN ('factura', 'recibo') AND cm.id_comprobante IS NOT NULL THEN 1 ELSE 0 END) AS otro_comprobante,
        ROUND((SUM(CASE WHEN cm.id_comprobante IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS porcentaje_cumplimiento,
        ROUND((SUM(CASE WHEN cm.tipo_comprobante = 'factura' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS porcentaje_facturas
    FROM movimientos_renta mr
    LEFT JOIN comprobantes_movimientos cm ON mr.id_movimiento = cm.id_movimiento
    WHERE mr.fecha_movimiento BETWEEN v_mes_inicio AND v_mes_fin
    AND (p_id_inmueble IS NULL OR mr.id_inmueble = p_id_inmueble);
END //

CREATE PROCEDURE ObtenerComprobantesVencidos(
    IN p_dias_antiguedad INT
)
BEGIN
    DECLARE v_fecha_limite DATE;
    
    -- Si no se especifica cantidad de días, usar 30 por defecto
    SET p_dias_antiguedad = COALESCE(p_dias_antiguedad, 30);
    
    -- Calcular la fecha límite
    SET v_fecha_limite = DATE_SUB(CURDATE(), INTERVAL p_dias_antiguedad DAY);
    
    SELECT 
        cm.id_comprobante,
        cm.id_movimiento,
        cm.ruta_imagen,
        cm.descripcion,
        cm.es_principal,
        cm.tipo_comprobante,
        cm.numero_referencia,
        cm.emisor,
        cm.receptor,
        cm.metodo_pago,
        cm.fecha_emision,
        cm.notas_adicionales,
        cm.fecha_carga,
        DATEDIFF(CURDATE(), cm.fecha_emision) AS dias_antiguedad,
        mr.concepto AS concepto_movimiento,
        mr.monto AS monto_movimiento,
        i.nombre_inmueble,
        c.nombre AS nombre_cliente,
        c.apellido_paterno AS apellido_cliente
    FROM comprobantes_movimientos cm
    JOIN movimientos_renta mr ON cm.id_movimiento = mr.id_movimiento
    JOIN inmuebles i ON mr.id_inmueble = i.id_inmueble
    JOIN clientes c ON mr.id_cliente = c.id_cliente
    WHERE cm.fecha_emision <= v_fecha_limite
    ORDER BY cm.fecha_emision;
END //

CREATE PROCEDURE ObtenerDetalleRenta(
    IN p_id_inmueble INT
)
BEGIN
    SELECT 
        cr.*,
        c.nombre AS nombre_cliente,
        c.apellido_paterno AS apellido_cliente,
        e.nombre_estado AS estado_renta
    FROM 
        contratos_renta cr
    JOIN 
        clientes c ON cr.id_cliente = c.id_cliente
    JOIN 
        estados e ON cr.id_estado = e.id_estado
    WHERE 
        cr.id_inmueble = p_id_inmueble 
        AND cr.id_estado = 1
    ORDER BY 
        cr.fecha_registro DESC
    LIMIT 1;
END //

CREATE PROCEDURE RegistrarContratoRenta(
    IN p_id_inmueble INT,
    IN p_id_cliente INT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_monto_mensual DECIMAL(12,2),
    IN p_condiciones_adicionales TEXT,
    OUT p_id_contrato_out INT
)
BEGIN
    -- Verificar si ya existe un contrato activo para este inmueble
    DECLARE v_contrato_activo INT;
    SELECT COUNT(*) INTO v_contrato_activo 
    FROM contratos_renta 
    WHERE id_inmueble = p_id_inmueble AND id_estado = 1;
    
    IF v_contrato_activo > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Ya existe un contrato activo para este inmueble';
    END IF;
    
    -- Insertar el contrato
    INSERT INTO contratos_renta(
        id_inmueble,
        id_cliente,
        fecha_inicio,
        fecha_fin,
        monto_mensual,
        condiciones_adicionales
    ) VALUES (
        p_id_inmueble,
        p_id_cliente,
        p_fecha_inicio,
        p_fecha_fin,
        p_monto_mensual,
        p_condiciones_adicionales
    );
    
    SET p_id_contrato_out = LAST_INSERT_ID();
    
    -- Actualizar el estado del inmueble a "Rentado" (5)
    UPDATE inmuebles SET id_estado = 5 WHERE id_inmueble = p_id_inmueble;
END //

CREATE PROCEDURE ActualizarEstadoContratoRenta(
    IN p_id_contrato INT,
    IN p_nuevo_estado INT
)
BEGIN
    DECLARE v_id_inmueble INT;
    
    -- Obtener el ID del inmueble asociado al contrato
    SELECT id_inmueble INTO v_id_inmueble 
    FROM contratos_renta 
    WHERE id_contrato = p_id_contrato;
    
    IF v_id_inmueble IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Contrato no encontrado';
    END IF;
    
    -- Actualizar el estado del contrato
    UPDATE contratos_renta 
    SET id_estado = p_nuevo_estado 
    WHERE id_contrato = p_id_contrato;
    
    -- Si se finaliza el contrato (estado 2 = inactivo), actualizar el estado del inmueble a Disponible (3)
    IF p_nuevo_estado = 2 THEN
        UPDATE inmuebles SET id_estado = 3 WHERE id_inmueble = v_id_inmueble;
    END IF;
END //

-- Procedimiento para obtener todos los contratos con datos relacionales
CREATE PROCEDURE ObtenerContratos()
BEGIN
  SELECT 
    cr.*,
    c.nombre AS nombre_cliente,
    c.apellido_paterno AS apellido_cliente,
    e.nombre_estado AS estado_renta,
    i.nombre_inmueble
  FROM contratos_renta cr
  JOIN clientes c ON cr.id_cliente = c.id_cliente
  JOIN estados e ON cr.id_estado = e.id_estado
  JOIN inmuebles i ON cr.id_inmueble = i.id_inmueble
  ORDER BY cr.fecha_registro DESC;
END //

-- Procedimiento para obtener un contrato por ID
CREATE PROCEDURE ObtenerContratoPorId(IN p_id_contrato INT)
BEGIN
  SELECT 
    cr.*,
    c.nombre AS nombre_cliente,
    c.apellido_paterno AS apellido_cliente,
    CONCAT(c.nombre, ' ', c.apellido_paterno, ' ', IFNULL(c.apellido_materno, '')) AS cliente_nombre_completo,
    i.nombre_inmueble,
    e.nombre_estado
  FROM contratos_renta cr
  JOIN clientes c ON cr.id_cliente = c.id_cliente
  JOIN inmuebles i ON cr.id_inmueble = i.id_inmueble
  JOIN estados e ON cr.id_estado = e.id_estado
  WHERE cr.id_contrato = p_id_contrato;
END //

-- Procedimiento para buscar contratos con filtros específicos
CREATE PROCEDURE BuscarContratos(
  IN p_id_cliente INT,
  IN p_id_inmueble INT,
  IN p_id_estado INT,
  IN p_fecha_inicio DATE,
  IN p_fecha_fin DATE
)
BEGIN
  SELECT 
    cr.*,
    c.nombre AS nombre_cliente,
    c.apellido_paterno AS apellido_cliente,
    e.nombre_estado AS estado_renta,
    i.nombre_inmueble
  FROM contratos_renta cr
  JOIN clientes c ON cr.id_cliente = c.id_cliente
  JOIN estados e ON cr.id_estado = e.id_estado
  JOIN inmuebles i ON cr.id_inmueble = i.id_inmueble
  WHERE 
    (p_id_cliente IS NULL OR cr.id_cliente = p_id_cliente) AND
    (p_id_inmueble IS NULL OR cr.id_inmueble = p_id_inmueble) AND
    (p_id_estado IS NULL OR cr.id_estado = p_id_estado) AND
    (p_fecha_inicio IS NULL OR cr.fecha_inicio >= p_fecha_inicio) AND
    (p_fecha_fin IS NULL OR cr.fecha_fin <= p_fecha_fin)
  ORDER BY cr.fecha_inicio DESC;
END //

-- Procedimiento para obtener estadísticas de rentas
CREATE PROCEDURE ObtenerEstadisticasRentas(
  IN p_fecha_inicio DATE,
  IN p_fecha_fin DATE
)
BEGIN
  -- Primera consulta: estadísticas de contratos
  SELECT 
    COUNT(*) as total_contratos,
    SUM(monto_mensual) as ingresos_mensuales,
    COUNT(IF(id_estado = 1, 1, NULL)) as contratos_activos
  FROM contratos_renta
  WHERE (fecha_inicio BETWEEN p_fecha_inicio AND p_fecha_fin) 
     OR (fecha_fin BETWEEN p_fecha_inicio AND p_fecha_fin)
     OR (fecha_inicio <= p_fecha_inicio AND fecha_fin >= p_fecha_fin);

  -- Segunda consulta: estadísticas de movimientos
  SELECT 
    COALESCE(SUM(IF(tipo_movimiento = 'ingreso', monto, 0)), 0) as total_ingresos,
    COALESCE(SUM(IF(tipo_movimiento = 'egreso', monto, 0)), 0) as total_egresos,
    COALESCE(SUM(IF(tipo_movimiento = 'ingreso', monto, 0)), 0) - 
    COALESCE(SUM(IF(tipo_movimiento = 'egreso', monto, 0)), 0) as balance
  FROM movimientos_renta
  WHERE fecha_movimiento BETWEEN p_fecha_inicio AND p_fecha_fin;
END //

-- Procedimiento para Obtener imagen de inmueble de manera segura
CREATE PROCEDURE ObtenerImagenInmuebleSegura(
    IN p_id_inmueble INT
)
BEGIN
    DECLARE imagen_count INT;
    
    -- Verificar si hay imágenes para este inmueble
    SELECT COUNT(*) INTO imagen_count
    FROM inmuebles_imagenes
    WHERE id_inmueble = p_id_inmueble;
    
    IF imagen_count = 0 THEN
        -- No hay imágenes, devolver conjunto vacío
        SELECT NULL as id_imagen, p_id_inmueble as id_inmueble, 
               NULL as ruta_imagen, NULL as descripcion, 
               0 as es_principal, NULL as fecha_carga;
    ELSE
        -- Primero intentar obtener la imagen principal
        SELECT * FROM inmuebles_imagenes
        WHERE id_inmueble = p_id_inmueble AND es_principal = 1
        LIMIT 1 INTO @imagen_principal;
        
        IF @imagen_principal IS NULL THEN
            -- Si no hay imagen principal, obtener la primera disponible
            SELECT * FROM inmuebles_imagenes
            WHERE id_inmueble = p_id_inmueble 
            ORDER BY fecha_carga DESC
            LIMIT 1;
        ELSE
            -- Devolver la imagen principal
            SELECT * FROM inmuebles_imagenes
            WHERE id_inmueble = p_id_inmueble AND es_principal = 1
            LIMIT 1;
        END IF;
    END IF;
END;
DELIMITER ;