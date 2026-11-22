# Changelog

## 0.1.2

* When `docker` is not available inside the container, boot the new code with `rails runner` before restarting.
* Do not restart, and revert the file change, when that boot test fails.
* After a successful boot test, stop the process so the container restart policy can start Redmine again.

## 0.1.1

* Keep the plugins-page redirect on a relative path so an in-container request does not end as an internal error.
* If git is missing or the container user cannot write the plugin directory, report that instead of a generic failure.
* If the restart command is not available inside the container, keep the file change and ask for a restart on the server.

## 0.1.0

* Add, update, and remove plugins from the Administration plugins page.
* Add a plugin by its git URL. Update pulls the plugin's own checkout. Remove moves the folder aside.
* Restart Redmine with the command configured in the plugin settings.
* On failure, write the error to the log and roll the file change back.
