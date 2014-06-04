require 'date'

module BacklogII
  module API
    class ArgumentError < StandardError ; end

    def get_project_id(project_key)
      issue = BacklogII::Object::IssueColumnNames.new
      project_info = self.call('backlog.getProject', project_key.to_s)
      project_info[issue.id].to_s
    end

    def find_latest_issue(project_id)
      issue = BacklogII::Object::IssueColumnNames.new
      find_issue = self.call('backlog.findIssue', {
          projectId: project_id,
          order:     1,
          limit:     1
      })
      find_issue[0][issue.key].to_s
    end

    def get_issue_type_names(project_id)
      issue = BacklogII::Object::IssueColumnNames.new
      issue_types = []
      h = self.call('backlog.getIssueTypes', project_id.to_i)
      h.each do |row|
        issue_types.push row[issue.name]
      end
      issue_types
    end

    def get_component_names(project_id)
      issue = BacklogII::Object::IssueColumnNames.new
      components = []
      h = self.call('backlog.getComponents', project_id.to_i)
      h.each do |row|
        components.push row[issue.name]
      end
      components
    end

    def get_version_names(project_id)
      issue = BacklogII::Object::IssueColumnNames.new
      versions = []
      h = self.call('backlog.getVersions', project_id.to_i)
      h.each do |row|
        versions.push row[issue.name]
      end
      versions
    end

    # Add issue attributes
    def add_issue_type(project_id, name, color='#666665')
      self.call('backlog.addIssueType', {
          project_id: project_id.to_i,
          name:       name.to_s,
          color:      color.to_s
      })
    end

    def add_component(project_id, name)
      self.call('backlog.addComponent', {
          project_id: project_id.to_i,
          name:       name.to_s
      })
    end

    def add_version(project_id, name)
      self.call('backlog.addVersion', {
          project_id: project_id.to_i,
          name:       name.to_s
      })
    end

    # Create issues
    def create_issues(project_id, hash)
      obj = BacklogII::Object::FileColumnNames.new
      h = { projectId:   project_id.to_i,
            summary:     hash[obj.summary].to_s,
            description: tr(hash[obj.description]).to_s,
            issueType:   hash[obj.issue_type].to_s,
            component:   hash[obj.components].to_s,
            version:     hash[obj.versions].to_s,
            milestone:   hash[obj.milestones].to_s,
            priority:    hash[obj.priority].to_s
      }
      due_date = hash[obj.due_date]
      if due_date.nil?
        self.call('backlog.createIssue', h)
      else
        h[:due_date] = sd(due_date.to_s)
        self.call('backlog.createIssue', h)
      end
    end

    # Update issue
    def update_issue(issue_key, hash)
      obj = BacklogII::Object::FileColumnNames.new
      self.call('backlog.updateIssue', {
          key:          issue_key.to_s,
          resolutionId: hash[obj.resolution_id].to_i,
          comment:      tr(hash["#{obj.comment}1"]).to_s
      })
    end

    # Add comment
    def add_comments(issue_key, comments_length, hash)
      obj = BacklogII::Object::FileColumnNames.new
      (2..comments_length.to_i).each {|num|
        comment = hash["#{obj.comment}#{num}"]
        unless comment.nil?
          self.call('backlog.addComment', {
              key:     issue_key.to_s,
              content: tr(comment).to_s
          })
        end
      }
    end

    # Switch issue status
    def switch_status(issue_key, hash)
      obj = BacklogII::Object::FileColumnNames.new
      if hash[obj.status_id].to_i != 1
        self.call('backlog.switchStatus', {
            key:          issue_key.to_s,
            statusId:     hash[obj.status_id].to_i
        })
      end
    end


    # new line code -> \n
    def tr(string)
      string.to_s.gsub(/(\\\\r\\\\n|\\\\n|\\\\r)/, "\n")
    end

    # String -> YYYYMMDD
    def sd(string)
      Date.parse(string).strftime('%Y%m%d')
    end

  end
end