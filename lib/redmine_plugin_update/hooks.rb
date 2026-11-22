# frozen_string_literal: true

module RedminePluginUpdate
  class Hooks < ::Redmine::Hook::ViewListener
    render_on :view_layouts_base_body_bottom, :partial => 'redmine_plugin_update/admin'
  end
end
