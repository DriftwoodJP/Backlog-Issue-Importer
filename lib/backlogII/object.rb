module BacklogII
  module Object
    class IssueColumnNames
      attr_reader :id, :key, :name
      def initialize
        @id            = 'id'
        @key           = 'key'
        @name          = 'name'
      end
    end

    class FileColumnNames
      attr_reader :project_id, :key, :issue_type, :components,
                  :versions, :summary, :description, :status_id,
                  :priority, :milestones, :resolution_id,
                  :assigner_id, :due_date, :comment
      def initialize
        @project_id    = 'プロジェクトID'
        @key           = 'キー'
        @issue_type    = '種別'
        @components    = 'カテゴリー名'
        @versions      = 'バージョン'
        @summary       = '件名'
        @description   = '詳細'
        @status_id     = '状態ID'
        @priority      = '優先度'
        @milestones    = 'マイルストーン'
        @resolution_id = '完了理由ID'
        @assigner_id   = '担当者ID'
        @due_date      = '期限日'
        @comment       = 'コメント'
      end
    end
  end
end