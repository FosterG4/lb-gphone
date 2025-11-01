-- German Locale for LB-GPhone
-- Server-side translations

Locales['de'] = {
    -- General
    ['phone_number_not_found'] = 'Telefonnummer nicht gefunden',
    ['player_not_found'] = 'Spieler nicht gefunden',
    ['invalid_request'] = 'Ungültige Anfrage',
    ['operation_failed'] = 'Operation fehlgeschlagen',
    ['permission_denied'] = 'Berechtigung verweigert',
    ['not_authorized'] = 'Sie sind nicht berechtigt, diese Aktion auszuführen',
    
    -- Currency
    ['currency_invalid_amount'] = 'Ungültiger Betrag',
    ['currency_negative_amount'] = 'Betrag kann nicht negativ sein',
    ['currency_limit_exceeded'] = 'Betrag überschreitet das Maximum von %s',
    ['currency_invalid_format'] = 'Bitte geben Sie einen gültigen Betrag ein',
    ['currency_below_minimum'] = 'Betrag muss größer als Null sein',
    ['currency_insufficient_funds'] = 'Unzureichende Mittel für diese Transaktion',
    ['currency_transaction_failed'] = 'Transaktion fehlgeschlagen. Bitte versuchen Sie es erneut',
    ['currency_parse_error'] = 'Währungsbetrag kann nicht analysiert werden',
    ['currency_validation_failed'] = 'Währungsvalidierung fehlgeschlagen',
    ['currency_too_many_decimals'] = 'Zu viele Dezimalstellen',
    
    -- Marketplace
    ['marketplace_fetch_failed'] = 'Fehler beim Abrufen der Marktplatz-Angebote',
    ['marketplace_missing_fields'] = 'Erforderliche Felder fehlen',
    ['marketplace_invalid_price'] = 'Ungültiger Preis',
    ['marketplace_listing_limit'] = 'Sie haben die maximale Anzahl aktiver Angebote erreicht',
    ['marketplace_listing_created'] = 'Angebot erfolgreich erstellt',
    ['marketplace_create_failed'] = 'Fehler beim Erstellen des Angebots',
    ['marketplace_listing_not_found'] = 'Angebot nicht gefunden',
    ['marketplace_not_owner'] = 'Sie sind nicht der Besitzer dieses Angebots',
    ['marketplace_listing_updated'] = 'Angebot erfolgreich aktualisiert',
    ['marketplace_update_failed'] = 'Fehler beim Aktualisieren des Angebots',
    ['marketplace_listing_deleted'] = 'Angebot erfolgreich gelöscht',
    ['marketplace_delete_failed'] = 'Fehler beim Löschen des Angebots',
    ['marketplace_listing_sold'] = 'Angebot als verkauft markiert',
    ['marketplace_sold_failed'] = 'Fehler beim Markieren des Angebots als verkauft',
    ['marketplace_stats_failed'] = 'Fehler beim Abrufen der Marktplatz-Statistiken',
    
    -- Business Pages
    ['pages_fetch_failed'] = 'Fehler beim Abrufen der Unternehmensseiten',
    ['pages_missing_fields'] = 'Erforderliche Felder fehlen',
    ['pages_page_limit'] = 'Sie haben die maximale Anzahl von Seiten erreicht',
    ['pages_page_created'] = 'Unternehmensseite erfolgreich erstellt',
    ['pages_create_failed'] = 'Fehler beim Erstellen der Unternehmensseite',
    ['pages_page_not_found'] = 'Unternehmensseite nicht gefunden',
    ['pages_not_owner'] = 'Sie sind nicht der Besitzer dieser Seite',
    ['pages_page_updated'] = 'Unternehmensseite erfolgreich aktualisiert',
    ['pages_update_failed'] = 'Fehler beim Aktualisieren der Unternehmensseite',
    ['pages_page_deleted'] = 'Unternehmensseite erfolgreich gelöscht',
    ['pages_delete_failed'] = 'Fehler beim Löschen der Unternehmensseite',
    ['pages_followed'] = 'Seite erfolgreich gefolgt',
    ['pages_follow_failed'] = 'Fehler beim Folgen der Seite',
    ['pages_unfollowed'] = 'Seite erfolgreich entfolgt',
    ['pages_unfollow_failed'] = 'Fehler beim Entfolgen der Seite',
    ['pages_announcement_sent'] = 'Ankündigung an Follower gesendet',
    ['pages_announcement_failed'] = 'Fehler beim Senden der Ankündigung',
    ['pages_stats_failed'] = 'Fehler beim Abrufen der Seitenstatistiken',
    
    -- Settings
    ['settings_language_changed'] = 'Sprache erfolgreich geändert',
    ['settings_update_failed'] = 'Fehler beim Aktualisieren der Einstellungen',
    ['settings_invalid_locale'] = 'Ungültige Sprachauswahl',
    
    -- Notifications
    ['notification_new_message'] = 'Neue Nachricht von %s',
    ['notification_missed_call'] = 'Verpasster Anruf von %s',
    ['notification_new_listing'] = 'Neues Angebot in %s',
    ['notification_page_followed'] = '%s folgt Ihrer Seite',
    ['notification_new_review'] = 'Neue Bewertung auf Ihrer Seite',
    
    -- Errors
    ['error_database'] = 'Datenbankfehler aufgetreten',
    ['error_network'] = 'Netzwerkfehler aufgetreten',
    ['error_timeout'] = 'Zeitüberschreitung der Anfrage',
    ['error_unknown'] = 'Ein unbekannter Fehler ist aufgetreten',
    
    -- Success messages
    ['success_operation'] = 'Operation erfolgreich abgeschlossen',
    ['success_saved'] = 'Erfolgreich gespeichert',
    ['success_deleted'] = 'Erfolgreich gelöscht',
    ['success_updated'] = 'Erfolgreich aktualisiert',
    
    -- Contact Sharing
    ['contact_sharing_nearby_section_title'] = 'In der Nähe',
    ['contact_sharing_share_contact'] = 'Kontakt teilen',
    ['contact_sharing_add_contact'] = 'Kontakt hinzufügen',
    ['contact_sharing_sharing_contact'] = 'Kontakt wird geteilt',
    ['contact_sharing_stop_sharing'] = 'Stoppen',
    ['contact_sharing_contact_request'] = 'Kontaktanfrage',
    ['contact_sharing_wants_to_share'] = '%s möchte Kontakte teilen',
    ['contact_sharing_accept'] = 'Akzeptieren',
    ['contact_sharing_decline'] = 'Ablehnen',
    ['contact_sharing_contact_added'] = 'Kontakt erfolgreich hinzugefügt',
    ['contact_sharing_contact_shared'] = 'Kontakt mit %s geteilt',
    ['contact_sharing_request_declined'] = '%s hat Ihre Kontaktanfrage abgelehnt',
    ['contact_sharing_request_sent'] = 'Kontaktanfrage an %s gesendet',
    ['contact_sharing_too_far_away'] = 'Spieler ist zu weit entfernt',
    ['contact_sharing_contact_exists'] = 'Kontakt existiert bereits',
    ['contact_sharing_nearby_count'] = '%d in der Nähe',
    ['contact_sharing_time_remaining'] = '%ds verbleibend',
    ['contact_sharing_visible_to_nearby'] = 'Ihr Kontakt ist für Spieler in der Nähe sichtbar',
    ['contact_sharing_request_expired'] = 'Teilungsanfrage ist abgelaufen',
    ['contact_sharing_request_not_found'] = 'Teilungsanfrage nicht gefunden',
    ['contact_sharing_player_too_far'] = 'Spieler ist zu weit entfernt',
    ['contact_sharing_cannot_share_self'] = 'Sie können keinen Kontakt mit sich selbst teilen',
    ['contact_sharing_broadcast_not_active'] = 'Kontakt-Broadcast ist nicht aktiv',
    ['contact_sharing_phone_not_open'] = 'Telefon muss geöffnet sein, um Kontakte zu teilen',
    ['contact_sharing_rate_limit'] = 'Zu viele Teilungsanfragen. Bitte warten Sie einen Moment',
    ['contact_sharing_share_my_contact'] = 'Meinen Kontakt teilen',
    ['contact_sharing_away'] = 'entfernt',
}
