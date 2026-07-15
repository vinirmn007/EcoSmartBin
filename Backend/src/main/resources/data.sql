-- =============================================
-- Datos iniciales: Tipos de Reciclaje
-- =============================================
INSERT INTO tipos_reciclaje (id, nombre, puntos_por_unidad, descripcion, icono)
VALUES
    (1, 'Plástico', 10, 'Botellas, envases y bolsas plásticas reciclables', '♻️'),
    (2, 'Papel', 5, 'Papel, cartón, periódicos y revistas', '📄'),
    (3, 'Vidrio', 15, 'Botellas y frascos de vidrio', '🫙'),
    (4, 'Orgánico', 3, 'Residuos orgánicos compostables (cáscaras, restos de comida)', '🌱'),
    (5, 'Metal', 20, 'Latas de aluminio, chatarra metálica', '🥫'),
    (6, 'Electrónico', 30, 'Equipos electrónicos, baterías, cables', '🔌'),
    (7, 'Cartón', 8, 'Cajas de cartón, empaques y envases de cartón', '📦'),
    (8, 'Basura General', 1, 'Residuos no reciclables o mixtos', '🗑️')
ON CONFLICT (id) DO NOTHING;

-- =============================================
-- Datos iniciales: Recompensas de ejemplo
-- =============================================
INSERT INTO recompensas (id, nombre, descripcion, costo_puntos, stock, imagen_url, activa)
VALUES
    (1, 'Botella Ecológica', 'Botella reutilizable de acero inoxidable 500ml con logo EcoSmartBin', 150, 50, NULL, true),
    (2, 'Bolsa de Tela', 'Bolsa ecológica de tela reutilizable para compras', 80, 100, NULL, true),
    (3, 'Cuaderno Reciclado', 'Cuaderno A5 fabricado con papel 100% reciclado', 60, 75, NULL, true),
    (4, 'Crédito Cafetería', 'Vale de $2.00 para la cafetería universitaria', 100, 200, NULL, true),
    (5, 'Plantita Suculenta', 'Pequeña planta suculenta en maceta biodegradable', 120, 30, NULL, true)
ON CONFLICT (id) DO NOTHING;

-- Ajustar secuencias después de la inserción manual de IDs
SELECT setval('tipos_reciclaje_id_seq', (SELECT COALESCE(MAX(id), 0) FROM tipos_reciclaje));
SELECT setval('recompensas_id_seq', (SELECT COALESCE(MAX(id), 0) FROM recompensas));
