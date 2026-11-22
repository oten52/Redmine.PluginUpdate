# Redmine Plugin Update

Adds, updates, and removes Redmine plugins from the Administration plugins page.

[Türkçe](README.tr.md)

## What's new

* 0.1.0: First release. See [CHANGELOG](CHANGELOG.md).

## Features

* On Administration → Plugins, paste a git URL to clone a plugin.
* Each plugin that is a git checkout has an Update button. It runs `git pull --ff-only` in that plugin's directory.
* Each plugin has a Remove button. The folder is moved aside, then Redmine restarts.
* After a successful add, update, or removal, the restart command in the plugin settings runs. The default is `docker restart redmine-redmine-1`.
* If cloning, pulling, or the restart command fails, the file change is reverted and the error is written to `log/redmine_plugin_update.log` and the Redmine log.
* A plugin with local git changes is not updated.
* A repository without `init.rb`, or a plugin that is already installed, is deleted again.

## Required Redmine version

* 4.2.x ~ 6.x

No database migrations and no gems. Git must be installed for the user that runs Redmine, and that user must be able to write the `plugins` directory.

## Install

1. From the Redmine `plugins` directory:

```bash
git clone https://github.com/oten52/Redmine.PluginUpdate.git
```

The directory name can stay `Redmine.PluginUpdate`.

2. Restart Redmine.

3. Open Administration → Plugins → Plugin Güncelle → Configure if the restart command should be different. Inside Docker, `docker restart` works only when the Docker client can reach the Docker socket. If the command fails, the plugin change is reverted.

## Uninstall

1. Remove the plugin from Administration → Plugins, or delete the `Redmine.PluginUpdate` folder.
2. Restart Redmine.

## Author

Niltek Arge — https://github.com/oten52

## License

GNU General Public License v3.0 or later. See [LICENSE](LICENSE).

If you modify and distribute this plugin, keep the copyright notices, state your changes and
distribute your version under the same license.
