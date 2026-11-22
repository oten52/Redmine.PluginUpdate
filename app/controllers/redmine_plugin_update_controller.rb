# frozen_string_literal: true

class RedminePluginUpdateController < ApplicationController
  before_action :require_admin

  def install
    url = params[:url]
    url = '' unless url.is_a?(String)
    finish(RedminePluginUpdate::Installer.install(url))
  end

  def pull
    finish(with_plugin {|plugin| RedminePluginUpdate::Updater.pull(plugin) })
  end

  def remove
    finish(with_plugin {|plugin| RedminePluginUpdate::Remover.remove(plugin) })
  end

  private

  def with_plugin
    plugin = find_plugin
    unless plugin
      RedminePluginUpdate::Log.error(action_name, 'plugin not found')
      return RedminePluginUpdate::Result.fail(I18n.t(:redmine_plugin_update_not_found))
    end

    yield plugin
  rescue StandardError => e
    RedminePluginUpdate::Log.exception(action_name, e)
    RedminePluginUpdate::Result.fail(I18n.t(:redmine_plugin_update_failed))
  end

  def find_plugin
    plugin_id = params[:plugin_id]
    return nil unless plugin_id.is_a?(String)
    return nil unless plugin_id =~ /\A[a-z0-9_]+\z/

    ::Redmine::Plugin.find(plugin_id)
  rescue StandardError => e
    RedminePluginUpdate::Log.exception('find', e)
    nil
  end

  def finish(result)
    unless result.respond_to?(:ok?)
      result = RedminePluginUpdate::Result.fail(I18n.t(:redmine_plugin_update_failed))
    end
    text = result.message.to_s.slice(0, 300)
    if result.ok?
      flash[:notice] = text
    else
      flash[:error] = text
    end
    redirect_to(plugins_location)
  rescue StandardError => e
    RedminePluginUpdate::Log.exception('redirect', e)
    render :plain => I18n.t(:redmine_plugin_update_failed), :status => 500
  end

  # A relative path stays on the host the browser used. An absolute URL built
  # from Setting.host_name can differ from the container's request host and
  # Rails then refuses the redirect.
  def plugins_location
    root = ::Redmine::Utils.relative_url_root.to_s
    root = '' if root.blank? || root == '/'
    "#{root.chomp('/')}/admin/plugins"
  rescue StandardError
    '/admin/plugins'
  end
end
