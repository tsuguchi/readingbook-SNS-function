module Api
  module V1
    # GET  /api/v1/notifications                自分宛の通知一覧（新着順）
    #      ?unread_only=true                    未読のみフィルタ
    # POST /api/v1/notifications/:id/read       個別既読化
    # POST /api/v1/notifications/read_all       一括既読化
    # GET  /api/v1/notifications/unread_count   未読件数（ベルバッジ用）
    class NotificationsController < BaseController
      def index
        scope = current_user.received_notifications.order(created_at: :desc)
        scope = scope.unread if ActiveModel::Type::Boolean.new.cast(params[:unread_only])

        notifications = scope.includes(:actor, :target)
                             .limit(limit)
                             .offset(offset)

        render json: NotificationSerializer.new(notifications, params: { current_user: current_user })
                                           .serializable_hash, status: :ok
      end

      def read
        notification = current_user.received_notifications.find(params[:id])
        notification.read!
        head :no_content
      end

      def read_all
        current_user.received_notifications.unread.update_all(read_at: Time.current)
        head :no_content
      end

      def unread_count
        count = current_user.received_notifications.unread.count
        render json: { data: { unread_count: count } }, status: :ok
      end

      private

      def limit
        [ params.fetch(:limit, 20).to_i, 100 ].min
      end

      def offset
        [ params.fetch(:offset, 0).to_i, 0 ].max
      end
    end
  end
end
