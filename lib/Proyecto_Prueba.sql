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

-- Procedimiento para agregar comprobante a un movimiento
CREATE PROCEDURE AgregarComprobanteMovimiento(
    IN p_id_movimiento INT,
    IN p_ruta_archivo VARCHAR(255),
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
    
    -- Verificar que el movimiento existe
    SELECT COUNT(*) INTO v_movimiento_existe 
    FROM movimientos_renta 
    WHERE id_movimiento = p_id_movimiento;
    
    IF v_movimiento_existe = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'El movimiento especificado no existe';
    END IF;
    
    START TRANSACTION;
    
    -- Si se marca como principal, actualizar los demás comprobantes
    IF p_es_principal = 1 THEN
        UPDATE comprobantes_movimientos
        SET es_principal = 0
        WHERE id_movimiento = p_id_movimiento;
    END IF;
    
    -- Insertar el nuevo comprobante con todos los campos
    INSERT INTO comprobantes_movimientos (
        id_movimiento, 
        ruta_archivo, 
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
        p_ruta_archivo, 
        COALESCE(p_tipo_archivo, 'imagen'), 
        COALESCE(p_descripcion, 'Comprobante'), 
        COALESCE(p_es_principal, 0),
        COALESCE(p_tipo_comprobante, 'otro'),
        p_numero_referencia,
        p_emisor,
        p_receptor,
        p_metodo_pago,
        COALESCE(p_fecha_emision, CURDATE()),
        p_notas_adicionales
    );
    
    SET p_id_comprobante_out = LAST_INSERT_ID();
    
    COMMIT;
END //

-- Procedimiento para obtener datos necesarios para generar un contrato de venta
CREATE PROCEDURE ObtenerDatosContratoVenta(
    IN p_id_venta INT
)
BEGIN
    -- Verificar que la venta existe
    DECLARE v_existe INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_existe FROM ventas WHERE id_venta = p_id_venta;
    
    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta especificada no existe';
    END IF;
    
    -- Obtener todos los datos necesarios para el contrato con un JOIN completo
    SELECT 
        v.id_venta,
        v.fecha_venta,
        v.ingreso AS monto_venta,
        v.utilidad_neta,
        c.id_cliente,
        c.nombre AS nombre_cliente,
        c.apellido_paterno,
        c.apellido_materno,
        c.telefono_cliente,
        c.correo_cliente,
        c.rfc AS rfc_cliente,
        cd.calle AS calle_cliente,
        cd.numero AS numero_cliente,
        cd.colonia AS colonia_cliente,
        cd.ciudad AS ciudad_cliente,
        cd.estado_geografico AS estado_cliente,
        cd.codigo_postal AS cp_cliente,
        i.id_inmueble,
        i.nombre_inmueble,
        i.tipo_inmueble,
        i.caracteristicas,
        di.calle AS calle_inmueble,
        di.numero AS numero_inmueble,
        di.colonia AS colonia_inmueble,
        di.ciudad AS ciudad_inmueble,
        di.estado_geografico AS estado_inmueble,
        di.codigo_postal AS cp_inmueble,
        di.referencias AS referencias_inmueble,
        e.nombre_estado AS estado_venta
    FROM 
        ventas v
        JOIN clientes c ON v.id_cliente = c.id_cliente
        JOIN inmuebles i ON v.id_inmueble = i.id_inmueble
        LEFT JOIN direcciones cd ON c.id_direccion = cd.id_direccion
        LEFT JOIN direcciones di ON i.id_direccion = di.id_direccion
        LEFT JOIN estados e ON v.id_estado = e.id_estado
    WHERE 
        v.id_venta = p_id_venta;
END //

DELIMITER ;