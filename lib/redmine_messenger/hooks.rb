module RedmineMessenger
  class MessengerListener < Redmine::Hook::Listener
    def model_changeset_scan_commit_for_issue_ids_pre_issue_update(context = {})
      issue = context[:issue]
      journal = issue.current_journal
      changeset = context[:changeset]

      channels = Messenger.channels_for_project issue.project
      url = Messenger.url_for_project issue.project

#      return unless channels.present? && url && issue.changes.any? && Messenger.setting_for_project(issue.project, :post_updates)
      return unless url && issue.changes.any? && Messenger.setting_for_project(issue.project, :post_updates)
      return if issue.is_private? && !Messenger.setting_for_project(issue.project, :post_private_issues)

#      msg = "[#{Messenger.markup_format issue.project}]" \
#            " #{Messenger.markup_format journal.user.to_s} updated <#{Messenger.object_url issue}|#{Messenger.markup_format issue}>"

      msg = " #{Messenger.markup_format journal.user.to_s} updated <#{Messenger.object_url issue}|#{Messenger.markup_format issue}>"

      repository = changeset.repository

      if Setting.host_name.to_s =~ %r{/\A(https?://)?(.+?)(:(\d+))?(/.+)?\z/i}
        host = Regexp.last_match(2)
        port = Regexp.last_match(4)
        prefix = Regexp.last_match(5)
        revision_url = Rails.application.routes.url_for(
          controller: 'repositories',
          action: 'revision',
          id: repository.project,
          repository_id: repository.identifier_param,
          rev: changeset.revision,
          host: host,
          protocol: Setting.protocol,
          port: port,
          script_name: prefix
        )
      else
        revision_url = Rails.application.routes.url_for(
          controller: 'repositories',
          action: 'revision',
          id: repository.project,
          repository_id: repository.identifier_param,
          rev: changeset.revision,
          host: Setting.host_name,
          protocol: Setting.protocol
        )
      end

      attachment = {}
      attachment[:text] = ll(Setting.default_language,
                             :text_status_changed_by_changeset,
                             "<#{revision_url}|#{Messenger.markup_format changeset.comments}>")
      attachment[:fields] = journal.details.map { |d| Messenger.detail_to_field d }

      Messenger.speak msg, channels, url, attachment: attachment, project: repository.project
    end
  end
end
