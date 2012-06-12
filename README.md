# maestro-bamboo-plugin
Maestro plugin providing a "task" to control Bamboo. This
plugin is a Ruby-based deployable that gets delivered as a ZIP file.

<http://www.atlassian.com/bamboo/>

Manifest:

* src/bamboo_worker.rb
* manifest.json
* README.md (this file)

## The Task
This Bamboo plugin requires a few inputs:



* **host** (hostname of the Bamboo server)
* **port** (port Bamboo is bound to)
* **use_ssl** (https or http?)
* **username** (user for logging into Bamboo)
* **password** (password for Bamboo)
* **web_path** (context path of Bamboo app)
* **project** (name of Bamboo project)
* **plan** (name of Bamboo plan to execute)

## License
Apache 2.0 License: <http://www.apache.org/licenses/LICENSE-2.0.html>
