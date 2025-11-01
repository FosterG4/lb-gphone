-- Japanese Locale for LB-GPhone
-- Server-side translations

Locales['ja'] = {
    -- General
    ['phone_number_not_found'] = '電話番号が見つかりません',
    ['player_not_found'] = 'プレイヤーが見つかりません',
    ['invalid_request'] = '無効なリクエスト',
    ['operation_failed'] = '操作に失敗しました',
    ['permission_denied'] = '権限がありません',
    ['not_authorized'] = 'この操作を実行する権限がありません',
    
    -- Currency
    ['currency_invalid_amount'] = '無効な金額',
    ['currency_negative_amount'] = '金額は負の値にできません',
    ['currency_limit_exceeded'] = '金額が上限の%sを超えています',
    ['currency_invalid_format'] = '有効な金額を入力してください',
    ['currency_below_minimum'] = '金額はゼロより大きくなければなりません',
    ['currency_insufficient_funds'] = 'この取引には残高が不足しています',
    ['currency_transaction_failed'] = '取引に失敗しました。もう一度お試しください',
    ['currency_parse_error'] = '通貨金額を解析できません',
    ['currency_validation_failed'] = '通貨検証に失敗しました',
    ['currency_too_many_decimals'] = '小数点以下の桁数が多すぎます',
    
    -- Marketplace
    ['marketplace_fetch_failed'] = 'マーケットプレイスの取得に失敗しました',
    ['marketplace_missing_fields'] = '必須項目が不足しています',
    ['marketplace_invalid_price'] = '無効な価格',
    ['marketplace_listing_limit'] = 'アクティブな出品数が上限に達しました',
    ['marketplace_listing_created'] = '出品が作成されました',
    ['marketplace_create_failed'] = '出品の作成に失敗しました',
    ['marketplace_listing_not_found'] = '出品が見つかりません',
    ['marketplace_not_owner'] = 'この出品の所有者ではありません',
    ['marketplace_listing_updated'] = '出品が更新されました',
    ['marketplace_update_failed'] = '出品の更新に失敗しました',
    ['marketplace_listing_deleted'] = '出品が削除されました',
    ['marketplace_delete_failed'] = '出品の削除に失敗しました',
    ['marketplace_listing_sold'] = '出品が売却済みとしてマークされました',
    ['marketplace_sold_failed'] = '売却済みマークに失敗しました',
    ['marketplace_stats_failed'] = '統計の取得に失敗しました',
    
    -- Business Pages
    ['pages_fetch_failed'] = 'ビジネスページの取得に失敗しました',
    ['pages_missing_fields'] = '必須項目が不足しています',
    ['pages_page_limit'] = 'ページ数が上限に達しました',
    ['pages_page_created'] = 'ビジネスページが作成されました',
    ['pages_create_failed'] = 'ビジネスページの作成に失敗しました',
    ['pages_page_not_found'] = 'ビジネスページが見つかりません',
    ['pages_not_owner'] = 'このページの所有者ではありません',
    ['pages_page_updated'] = 'ビジネスページが更新されました',
    ['pages_update_failed'] = 'ビジネスページの更新に失敗しました',
    ['pages_page_deleted'] = 'ビジネスページが削除されました',
    ['pages_delete_failed'] = 'ビジネスページの削除に失敗しました',
    ['pages_followed'] = 'ページをフォローしました',
    ['pages_follow_failed'] = 'ページのフォローに失敗しました',
    ['pages_unfollowed'] = 'ページのフォローを解除しました',
    ['pages_unfollow_failed'] = 'フォロー解除に失敗しました',
    ['pages_announcement_sent'] = 'フォロワーにお知らせを送信しました',
    ['pages_announcement_failed'] = 'お知らせの送信に失敗しました',
    ['pages_stats_failed'] = 'ページ統計の取得に失敗しました',
    
    -- Settings
    ['settings_language_changed'] = '言語が変更されました',
    ['settings_update_failed'] = '設定の更新に失敗しました',
    ['settings_invalid_locale'] = '無効な言語選択',
    
    -- Notifications
    ['notification_new_message'] = '%sから新しいメッセージ',
    ['notification_missed_call'] = '%sからの不在着信',
    ['notification_new_listing'] = '%sに新しい出品',
    ['notification_page_followed'] = '%sがあなたのページをフォローしました',
    ['notification_new_review'] = 'あなたのページに新しいレビュー',
    
    -- Errors
    ['error_database'] = 'データベースエラーが発生しました',
    ['error_network'] = 'ネットワークエラーが発生しました',
    ['error_timeout'] = 'リクエストがタイムアウトしました',
    ['error_unknown'] = '不明なエラーが発生しました',
    
    -- Success messages
    ['success_operation'] = '操作が正常に完了しました',
    ['success_saved'] = '正常に保存されました',
    ['success_deleted'] = '正常に削除されました',
    ['success_updated'] = '正常に更新されました',
    
    -- Contact Sharing
    ['contact_sharing_nearby_section_title'] = '近くのユーザー',
    ['contact_sharing_share_contact'] = '連絡先を共有',
    ['contact_sharing_add_contact'] = '連絡先を追加',
    ['contact_sharing_sharing_contact'] = '連絡先を共有中',
    ['contact_sharing_stop_sharing'] = '停止',
    ['contact_sharing_contact_request'] = '連絡先リクエスト',
    ['contact_sharing_wants_to_share'] = '%sが連絡先を共有したいです',
    ['contact_sharing_accept'] = '承認',
    ['contact_sharing_decline'] = '拒否',
    ['contact_sharing_contact_added'] = '連絡先が追加されました',
    ['contact_sharing_contact_shared'] = '%sと連絡先を共有しました',
    ['contact_sharing_request_declined'] = '%sがあなたの連絡先リクエストを拒否しました',
    ['contact_sharing_request_sent'] = '%sに連絡先リクエストを送信しました',
    ['contact_sharing_too_far_away'] = 'プレイヤーが遠すぎます',
    ['contact_sharing_contact_exists'] = '連絡先は既に存在します',
    ['contact_sharing_nearby_count'] = '%d人が近くにいます',
    ['contact_sharing_time_remaining'] = '残り%d秒',
    ['contact_sharing_visible_to_nearby'] = 'あなたの連絡先は近くのプレイヤーに表示されています',
    ['contact_sharing_request_expired'] = '共有リクエストの有効期限が切れました',
    ['contact_sharing_request_not_found'] = '共有リクエストが見つかりません',
    ['contact_sharing_player_too_far'] = 'プレイヤーが遠すぎます',
    ['contact_sharing_cannot_share_self'] = '自分自身と連絡先を共有できません',
    ['contact_sharing_broadcast_not_active'] = '連絡先のブロードキャストがアクティブではありません',
    ['contact_sharing_phone_not_open'] = '連絡先を共有するには電話を開く必要があります',
    ['contact_sharing_rate_limit'] = '共有リクエストが多すぎます。しばらくお待ちください',
    ['contact_sharing_share_my_contact'] = '自分の連絡先を共有',
    ['contact_sharing_away'] = '離れています',
}
