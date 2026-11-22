# Changelog

## 0.1.0

* Add, update, and remove plugins from the Administration plugins page.
* Add a plugin by its git URL. Update pulls the plugin's own checkout. Remove moves the folder aside.
* Restart Redmine with the command configured in the plugin settings.
* On failure, write the error to the log and roll the file change back.
