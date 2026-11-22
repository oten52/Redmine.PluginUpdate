# frozen_string_literal: true

class RedminePluginUpdateController < ApplicationController
  before_action :require_admin

  def install
    url = params[:url]
    url = '' unless url.is_a?(String)
    finish(RedminePluginUpdate::Installer.install(url))
  end

  def pull
    plugin = find_plugin
    unless plugin
      RedminePluginUpdate::Log.error('pull', 'plugin not found')
      return finish(RedminePluginUpdate::Result.fail(I18n.t(:redmine_plugin_update_not_found)))
    end
    finish(RedminePluginUpdate::Updater.pull(plugin))
  end

  def remove
    plugin = find_plugin
    unless plugin
      RedminePluginUpdate::Log.error('remove', 'plugin not found')
      return finish(RedminePluginUpdate::Result.fail(I18n.t(:redmine_plugin_update_not_found)))
    end
    finish(RedminePluginUpdate::Remover.remove(plugin))
  end

  private

  def find_plugin
    plugin_id = params[:plugin_id]
    return nil unless plugin_id.is_a?(String)
    return nil unless plugin_id =~ /\A[a-z0-9_]+\z/

    ::Redmine::Plugin.find(plugin_id)
  rescue ::Redmine::PluginNotFound
    nil
  end

  def finish(result)
    if result.ok?
      flash[:notice] = result.message
    else
      flash[:error] = result.message
    end
    redirect_to(:controller => 'admin', :action => 'plugins')
  end
end
