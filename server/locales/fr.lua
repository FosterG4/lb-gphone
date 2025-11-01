-- French Locale for LB-GPhone
-- Server-side translations

Locales['fr'] = {
    -- General
    ['phone_number_not_found'] = 'Numéro de téléphone introuvable',
    ['player_not_found'] = 'Joueur introuvable',
    ['invalid_request'] = 'Demande invalide',
    ['operation_failed'] = 'Opération échouée',
    ['permission_denied'] = 'Permission refusée',
    ['not_authorized'] = 'Vous n\'êtes pas autorisé à effectuer cette action',
    
    -- Currency
    ['currency_invalid_amount'] = 'Montant invalide',
    ['currency_negative_amount'] = 'Le montant ne peut pas être négatif',
    ['currency_limit_exceeded'] = 'Le montant dépasse la limite maximale de %s',
    ['currency_invalid_format'] = 'Veuillez entrer un montant valide',
    ['currency_below_minimum'] = 'Le montant doit être supérieur à zéro',
    ['currency_insufficient_funds'] = 'Fonds insuffisants pour cette transaction',
    ['currency_transaction_failed'] = 'Transaction échouée. Veuillez réessayer',
    ['currency_parse_error'] = 'Impossible d\'analyser le montant',
    ['currency_validation_failed'] = 'Validation de la devise échouée',
    ['currency_too_many_decimals'] = 'Trop de décimales',
    
    -- Marketplace
    ['marketplace_fetch_failed'] = 'Échec de la récupération des annonces',
    ['marketplace_missing_fields'] = 'Champs requis manquants',
    ['marketplace_invalid_price'] = 'Prix invalide',
    ['marketplace_listing_limit'] = 'Vous avez atteint le nombre maximum d\'annonces actives',
    ['marketplace_listing_created'] = 'Annonce créée avec succès',
    ['marketplace_create_failed'] = 'Échec de la création de l\'annonce',
    ['marketplace_listing_not_found'] = 'Annonce introuvable',
    ['marketplace_not_owner'] = 'Vous n\'êtes pas propriétaire de cette annonce',
    ['marketplace_listing_updated'] = 'Annonce mise à jour avec succès',
    ['marketplace_update_failed'] = 'Échec de la mise à jour de l\'annonce',
    ['marketplace_listing_deleted'] = 'Annonce supprimée avec succès',
    ['marketplace_delete_failed'] = 'Échec de la suppression de l\'annonce',
    ['marketplace_listing_sold'] = 'Annonce marquée comme vendue',
    ['marketplace_sold_failed'] = 'Échec du marquage de l\'annonce comme vendue',
    ['marketplace_stats_failed'] = 'Échec de la récupération des statistiques',
    
    -- Business Pages
    ['pages_fetch_failed'] = 'Échec de la récupération des pages d\'entreprise',
    ['pages_missing_fields'] = 'Champs requis manquants',
    ['pages_page_limit'] = 'Vous avez atteint le nombre maximum de pages',
    ['pages_page_created'] = 'Page d\'entreprise créée avec succès',
    ['pages_create_failed'] = 'Échec de la création de la page d\'entreprise',
    ['pages_page_not_found'] = 'Page d\'entreprise introuvable',
    ['pages_not_owner'] = 'Vous n\'êtes pas propriétaire de cette page',
    ['pages_page_updated'] = 'Page d\'entreprise mise à jour avec succès',
    ['pages_update_failed'] = 'Échec de la mise à jour de la page d\'entreprise',
    ['pages_page_deleted'] = 'Page d\'entreprise supprimée avec succès',
    ['pages_delete_failed'] = 'Échec de la suppression de la page d\'entreprise',
    ['pages_followed'] = 'Page suivie avec succès',
    ['pages_follow_failed'] = 'Échec du suivi de la page',
    ['pages_unfollowed'] = 'Page désabonnée avec succès',
    ['pages_unfollow_failed'] = 'Échec du désabonnement de la page',
    ['pages_announcement_sent'] = 'Annonce envoyée aux abonnés',
    ['pages_announcement_failed'] = 'Échec de l\'envoi de l\'annonce',
    ['pages_stats_failed'] = 'Échec de la récupération des statistiques de la page',
    
    -- Settings
    ['settings_language_changed'] = 'Langue changée avec succès',
    ['settings_update_failed'] = 'Échec de la mise à jour des paramètres',
    ['settings_invalid_locale'] = 'Sélection de langue invalide',
    
    -- Notifications
    ['notification_new_message'] = 'Nouveau message de %s',
    ['notification_missed_call'] = 'Appel manqué de %s',
    ['notification_new_listing'] = 'Nouvelle annonce dans %s',
    ['notification_page_followed'] = '%s a suivi votre page',
    ['notification_new_review'] = 'Nouvel avis sur votre page',
    
    -- Errors
    ['error_database'] = 'Erreur de base de données',
    ['error_network'] = 'Erreur réseau',
    ['error_timeout'] = 'Délai d\'attente dépassé',
    ['error_unknown'] = 'Une erreur inconnue s\'est produite',
    
    -- Success messages
    ['success_operation'] = 'Opération terminée avec succès',
    ['success_saved'] = 'Enregistré avec succès',
    ['success_deleted'] = 'Supprimé avec succès',
    ['success_updated'] = 'Mis à jour avec succès',
    
    -- Contact Sharing
    ['contact_sharing_nearby_section_title'] = 'À proximité',
    ['contact_sharing_share_contact'] = 'Partager le contact',
    ['contact_sharing_add_contact'] = 'Ajouter le contact',
    ['contact_sharing_sharing_contact'] = 'Partage du contact',
    ['contact_sharing_stop_sharing'] = 'Arrêter',
    ['contact_sharing_contact_request'] = 'Demande de contact',
    ['contact_sharing_wants_to_share'] = '%s souhaite partager des contacts',
    ['contact_sharing_accept'] = 'Accepter',
    ['contact_sharing_decline'] = 'Refuser',
    ['contact_sharing_contact_added'] = 'Contact ajouté avec succès',
    ['contact_sharing_contact_shared'] = 'Contact partagé avec %s',
    ['contact_sharing_request_declined'] = '%s a refusé votre demande de contact',
    ['contact_sharing_request_sent'] = 'Demande de contact envoyée à %s',
    ['contact_sharing_too_far_away'] = 'Le joueur est trop éloigné',
    ['contact_sharing_contact_exists'] = 'Le contact existe déjà',
    ['contact_sharing_nearby_count'] = '%d à proximité',
    ['contact_sharing_time_remaining'] = '%ds restantes',
    ['contact_sharing_visible_to_nearby'] = 'Votre contact est visible par les joueurs à proximité',
    ['contact_sharing_request_expired'] = 'La demande de partage a expiré',
    ['contact_sharing_request_not_found'] = 'Demande de partage introuvable',
    ['contact_sharing_player_too_far'] = 'Le joueur est trop éloigné',
    ['contact_sharing_cannot_share_self'] = 'Vous ne pouvez pas partager un contact avec vous-même',
    ['contact_sharing_broadcast_not_active'] = 'La diffusion de contact n\'est pas active',
    ['contact_sharing_phone_not_open'] = 'Le téléphone doit être ouvert pour partager des contacts',
    ['contact_sharing_rate_limit'] = 'Trop de demandes de partage. Veuillez patienter un moment',
    ['contact_sharing_share_my_contact'] = 'Partager mon contact',
    ['contact_sharing_away'] = 'de distance',
}
