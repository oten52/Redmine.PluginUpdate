# Redmine Plugin Update
# Copyright (C) 2026 Niltek Arge
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version. See the LICENSE file for details.

require_relative 'lib/redmine_plugin_update'
require_relative 'lib/redmine_plugin_update/log'
require_relative 'lib/redmine_plugin_update/paths'
require_relative 'lib/redmine_plugin_update/git_cmd'
require_relative 'lib/redmine_plugin_update/restart'
require_relative 'lib/redmine_plugin_update/installer'
require_relative 'lib/redmine_plugin_update/updater'
require_relative 'lib/redmine_plugin_update/remover'
require_relative 'lib/redmine_plugin_update/hooks'

RedminePluginUpdate.cleanup_old_backups

Redmine::Plugin.register :redmine_plugin_update do
  name 'Plugin Güncelle'
  author 'Niltek Arge'
  author_url 'https://github.com/oten52'
  description 'Eklenti sayfasından git adresiyle eklenti ekler, günceller ve kaldırır.'
  version '0.1.1'
  url 'https://github.com/oten52/Redmine.PluginUpdate'
  requires_redmine version_or_higher: '4.2'

  # The git repository folder is Redmine.PluginUpdate. Point Redmine at this
  # directory so the plugin loads without renaming the clone.
  directory File.expand_path(__dir__)

  settings default: {
    'restart_command' => 'docker restart redmine-redmine-1'
  }, partial: 'settings/redmine_plugin_update'
end
