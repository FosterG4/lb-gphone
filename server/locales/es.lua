-- Spanish Locale for LB-GPhone
-- Server-side translations

Locales['es'] = {
    -- General
    ['phone_number_not_found'] = 'Número de teléfono no encontrado',
    ['player_not_found'] = 'Jugador no encontrado',
    ['invalid_request'] = 'Solicitud inválida',
    ['operation_failed'] = 'Operación fallida',
    ['permission_denied'] = 'Permiso denegado',
    ['not_authorized'] = 'No estás autorizado para realizar esta acción',
    
    -- Currency
    ['currency_invalid_amount'] = 'Cantidad inválida',
    ['currency_negative_amount'] = 'La cantidad no puede ser negativa',
    ['currency_limit_exceeded'] = 'La cantidad excede el límite máximo de %s',
    ['currency_invalid_format'] = 'Por favor ingresa una cantidad válida',
    ['currency_below_minimum'] = 'La cantidad debe ser mayor que cero',
    ['currency_insufficient_funds'] = 'Fondos insuficientes para esta transacción',
    ['currency_transaction_failed'] = 'Transacción fallida. Por favor intenta de nuevo',
    ['currency_parse_error'] = 'No se puede analizar la cantidad de moneda',
    ['currency_validation_failed'] = 'Validación de moneda fallida',
    ['currency_too_many_decimals'] = 'Demasiados decimales',
    
    -- Marketplace
    ['marketplace_fetch_failed'] = 'Error al obtener listados del mercado',
    ['marketplace_missing_fields'] = 'Faltan campos requeridos',
    ['marketplace_invalid_price'] = 'Precio inválido',
    ['marketplace_listing_limit'] = 'Has alcanzado el número máximo de listados activos',
    ['marketplace_listing_created'] = 'Listado creado exitosamente',
    ['marketplace_create_failed'] = 'Error al crear listado',
    ['marketplace_listing_not_found'] = 'Listado no encontrado',
    ['marketplace_not_owner'] = 'No eres dueño de este listado',
    ['marketplace_listing_updated'] = 'Listado actualizado exitosamente',
    ['marketplace_update_failed'] = 'Error al actualizar listado',
    ['marketplace_listing_deleted'] = 'Listado eliminado exitosamente',
    ['marketplace_delete_failed'] = 'Error al eliminar listado',
    ['marketplace_listing_sold'] = 'Listado marcado como vendido',
    ['marketplace_sold_failed'] = 'Error al marcar listado como vendido',
    ['marketplace_stats_failed'] = 'Error al obtener estadísticas del mercado',
    
    -- Business Pages
    ['pages_fetch_failed'] = 'Error al obtener páginas de negocios',
    ['pages_missing_fields'] = 'Faltan campos requeridos',
    ['pages_page_limit'] = 'Has alcanzado el número máximo de páginas',
    ['pages_page_created'] = 'Página de negocio creada exitosamente',
    ['pages_create_failed'] = 'Error al crear página de negocio',
    ['pages_page_not_found'] = 'Página de negocio no encontrada',
    ['pages_not_owner'] = 'No eres dueño de esta página',
    ['pages_page_updated'] = 'Página de negocio actualizada exitosamente',
    ['pages_update_failed'] = 'Error al actualizar página de negocio',
    ['pages_page_deleted'] = 'Página de negocio eliminada exitosamente',
    ['pages_delete_failed'] = 'Error al eliminar página de negocio',
    ['pages_followed'] = 'Página seguida exitosamente',
    ['pages_follow_failed'] = 'Error al seguir página',
    ['pages_unfollowed'] = 'Página dejada de seguir exitosamente',
    ['pages_unfollow_failed'] = 'Error al dejar de seguir página',
    ['pages_announcement_sent'] = 'Anuncio enviado a seguidores',
    ['pages_announcement_failed'] = 'Error al enviar anuncio',
    ['pages_stats_failed'] = 'Error al obtener estadísticas de página',
    
    -- Settings
    ['settings_language_changed'] = 'Idioma cambiado exitosamente',
    ['settings_update_failed'] = 'Error al actualizar configuración',
    ['settings_invalid_locale'] = 'Selección de idioma inválida',
    
    -- Notifications
    ['notification_new_message'] = 'Nuevo mensaje de %s',
    ['notification_missed_call'] = 'Llamada perdida de %s',
    ['notification_new_listing'] = 'Nuevo listado en %s',
    ['notification_page_followed'] = '%s siguió tu página',
    ['notification_new_review'] = 'Nueva reseña en tu página',
    
    -- Errors
    ['error_database'] = 'Ocurrió un error de base de datos',
    ['error_network'] = 'Ocurrió un error de red',
    ['error_timeout'] = 'Tiempo de espera agotado',
    ['error_unknown'] = 'Ocurrió un error desconocido',
    
    -- Success messages
    ['success_operation'] = 'Operación completada exitosamente',
    ['success_saved'] = 'Guardado exitosamente',
    ['success_deleted'] = 'Eliminado exitosamente',
    ['success_updated'] = 'Actualizado exitosamente',
    
    -- Contact Sharing
    ['contact_sharing_nearby_section_title'] = 'Cerca',
    ['contact_sharing_share_contact'] = 'Compartir Contacto',
    ['contact_sharing_add_contact'] = 'Agregar Contacto',
    ['contact_sharing_sharing_contact'] = 'Compartiendo Contacto',
    ['contact_sharing_stop_sharing'] = 'Detener',
    ['contact_sharing_contact_request'] = 'Solicitud de Contacto',
    ['contact_sharing_wants_to_share'] = '%s quiere compartir contactos',
    ['contact_sharing_accept'] = 'Aceptar',
    ['contact_sharing_decline'] = 'Rechazar',
    ['contact_sharing_contact_added'] = 'Contacto agregado exitosamente',
    ['contact_sharing_contact_shared'] = 'Contacto compartido con %s',
    ['contact_sharing_request_declined'] = '%s rechazó tu solicitud de contacto',
    ['contact_sharing_request_sent'] = 'Solicitud de contacto enviada a %s',
    ['contact_sharing_too_far_away'] = 'El jugador está muy lejos',
    ['contact_sharing_contact_exists'] = 'El contacto ya existe',
    ['contact_sharing_nearby_count'] = '%d cerca',
    ['contact_sharing_time_remaining'] = '%ds restantes',
    ['contact_sharing_visible_to_nearby'] = 'Tu contacto es visible para jugadores cercanos',
    ['contact_sharing_request_expired'] = 'La solicitud de compartir ha expirado',
    ['contact_sharing_request_not_found'] = 'Solicitud de compartir no encontrada',
    ['contact_sharing_player_too_far'] = 'El jugador está muy lejos',
    ['contact_sharing_cannot_share_self'] = 'No puedes compartir contacto contigo mismo',
    ['contact_sharing_broadcast_not_active'] = 'La transmisión de contacto no está activa',
    ['contact_sharing_phone_not_open'] = 'El teléfono debe estar abierto para compartir contactos',
    ['contact_sharing_rate_limit'] = 'Demasiadas solicitudes de compartir. Por favor espera un momento',
    ['contact_sharing_share_my_contact'] = 'Compartir Mi Contacto',
    ['contact_sharing_away'] = 'de distancia',
}
