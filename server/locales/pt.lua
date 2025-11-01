-- Portuguese Locale for LB-GPhone
-- Server-side translations

Locales['pt'] = {
    -- General
    ['phone_number_not_found'] = 'Número de telefone não encontrado',
    ['player_not_found'] = 'Jogador não encontrado',
    ['invalid_request'] = 'Solicitação inválida',
    ['operation_failed'] = 'Operação falhou',
    ['permission_denied'] = 'Permissão negada',
    ['not_authorized'] = 'Você não está autorizado a realizar esta ação',
    
    -- Currency
    ['currency_invalid_amount'] = 'Quantia inválida',
    ['currency_negative_amount'] = 'A quantia não pode ser negativa',
    ['currency_limit_exceeded'] = 'A quantia excede o limite máximo de %s',
    ['currency_invalid_format'] = 'Por favor, insira uma quantia válida',
    ['currency_below_minimum'] = 'A quantia deve ser maior que zero',
    ['currency_insufficient_funds'] = 'Fundos insuficientes para esta transação',
    ['currency_transaction_failed'] = 'Transação falhou. Por favor, tente novamente',
    ['currency_parse_error'] = 'Não foi possível analisar a quantia',
    ['currency_validation_failed'] = 'Validação de moeda falhou',
    ['currency_too_many_decimals'] = 'Muitas casas decimais',
    
    -- Marketplace
    ['marketplace_fetch_failed'] = 'Falha ao buscar anúncios do mercado',
    ['marketplace_missing_fields'] = 'Campos obrigatórios ausentes',
    ['marketplace_invalid_price'] = 'Preço inválido',
    ['marketplace_listing_limit'] = 'Você atingiu o número máximo de anúncios ativos',
    ['marketplace_listing_created'] = 'Anúncio criado com sucesso',
    ['marketplace_create_failed'] = 'Falha ao criar anúncio',
    ['marketplace_listing_not_found'] = 'Anúncio não encontrado',
    ['marketplace_not_owner'] = 'Você não é o proprietário deste anúncio',
    ['marketplace_listing_updated'] = 'Anúncio atualizado com sucesso',
    ['marketplace_update_failed'] = 'Falha ao atualizar anúncio',
    ['marketplace_listing_deleted'] = 'Anúncio excluído com sucesso',
    ['marketplace_delete_failed'] = 'Falha ao excluir anúncio',
    ['marketplace_listing_sold'] = 'Anúncio marcado como vendido',
    ['marketplace_sold_failed'] = 'Falha ao marcar anúncio como vendido',
    ['marketplace_stats_failed'] = 'Falha ao buscar estatísticas do mercado',
    
    -- Business Pages
    ['pages_fetch_failed'] = 'Falha ao buscar páginas de negócios',
    ['pages_missing_fields'] = 'Campos obrigatórios ausentes',
    ['pages_page_limit'] = 'Você atingiu o número máximo de páginas',
    ['pages_page_created'] = 'Página de negócio criada com sucesso',
    ['pages_create_failed'] = 'Falha ao criar página de negócio',
    ['pages_page_not_found'] = 'Página de negócio não encontrada',
    ['pages_not_owner'] = 'Você não é o proprietário desta página',
    ['pages_page_updated'] = 'Página de negócio atualizada com sucesso',
    ['pages_update_failed'] = 'Falha ao atualizar página de negócio',
    ['pages_page_deleted'] = 'Página de negócio excluída com sucesso',
    ['pages_delete_failed'] = 'Falha ao excluir página de negócio',
    ['pages_followed'] = 'Página seguida com sucesso',
    ['pages_follow_failed'] = 'Falha ao seguir página',
    ['pages_unfollowed'] = 'Página deixada de seguir com sucesso',
    ['pages_unfollow_failed'] = 'Falha ao deixar de seguir página',
    ['pages_announcement_sent'] = 'Anúncio enviado aos seguidores',
    ['pages_announcement_failed'] = 'Falha ao enviar anúncio',
    ['pages_stats_failed'] = 'Falha ao buscar estatísticas da página',
    
    -- Settings
    ['settings_language_changed'] = 'Idioma alterado com sucesso',
    ['settings_update_failed'] = 'Falha ao atualizar configurações',
    ['settings_invalid_locale'] = 'Seleção de idioma inválida',
    
    -- Notifications
    ['notification_new_message'] = 'Nova mensagem de %s',
    ['notification_missed_call'] = 'Chamada perdida de %s',
    ['notification_new_listing'] = 'Novo anúncio em %s',
    ['notification_page_followed'] = '%s seguiu sua página',
    ['notification_new_review'] = 'Nova avaliação em sua página',
    
    -- Errors
    ['error_database'] = 'Erro de banco de dados ocorreu',
    ['error_network'] = 'Erro de rede ocorreu',
    ['error_timeout'] = 'Tempo de solicitação esgotado',
    ['error_unknown'] = 'Ocorreu um erro desconhecido',
    
    -- Success messages
    ['success_operation'] = 'Operação concluída com sucesso',
    ['success_saved'] = 'Salvo com sucesso',
    ['success_deleted'] = 'Excluído com sucesso',
    ['success_updated'] = 'Atualizado com sucesso',
    
    -- Contact Sharing
    ['contact_sharing_nearby_section_title'] = 'Próximos',
    ['contact_sharing_share_contact'] = 'Compartilhar Contato',
    ['contact_sharing_add_contact'] = 'Adicionar Contato',
    ['contact_sharing_sharing_contact'] = 'Compartilhando Contato',
    ['contact_sharing_stop_sharing'] = 'Parar',
    ['contact_sharing_contact_request'] = 'Solicitação de Contato',
    ['contact_sharing_wants_to_share'] = '%s quer compartilhar contatos',
    ['contact_sharing_accept'] = 'Aceitar',
    ['contact_sharing_decline'] = 'Recusar',
    ['contact_sharing_contact_added'] = 'Contato adicionado com sucesso',
    ['contact_sharing_contact_shared'] = 'Contato compartilhado com %s',
    ['contact_sharing_request_declined'] = '%s recusou sua solicitação de contato',
    ['contact_sharing_request_sent'] = 'Solicitação de contato enviada para %s',
    ['contact_sharing_too_far_away'] = 'Jogador está muito longe',
    ['contact_sharing_contact_exists'] = 'Contato já existe',
    ['contact_sharing_nearby_count'] = '%d próximos',
    ['contact_sharing_time_remaining'] = '%ds restantes',
    ['contact_sharing_visible_to_nearby'] = 'Seu contato está visível para jogadores próximos',
    ['contact_sharing_request_expired'] = 'Solicitação de compartilhamento expirou',
    ['contact_sharing_request_not_found'] = 'Solicitação de compartilhamento não encontrada',
    ['contact_sharing_player_too_far'] = 'Jogador está muito longe',
    ['contact_sharing_cannot_share_self'] = 'Não é possível compartilhar contato consigo mesmo',
    ['contact_sharing_broadcast_not_active'] = 'Transmissão de contato não está ativa',
    ['contact_sharing_phone_not_open'] = 'O telefone deve estar aberto para compartilhar contatos',
    ['contact_sharing_rate_limit'] = 'Muitas solicitações de compartilhamento. Por favor, aguarde um momento',
    ['contact_sharing_share_my_contact'] = 'Compartilhar Meu Contato',
    ['contact_sharing_away'] = 'de distância',
}
