# maestro-bamboo-plugin
Maestro plugin providing a "task" to control bamboo. This
plugin is a Ruby-based deployable that gets delivered as a Zip file.

<http://bamboo.com/>

Manifest:

* src/bamboo_worker.rb
* manifest.json
* README.md (this file)

## The Task
This Bamboo plugin requires a few inputs:



* **host** (hostname of the bamboo server)
* **port** (port bamboo is bound to)
* **use_ssl** (https or http?)
* **username** (user for logging into bamboo)
* **password** (password for bamboo)
* **web_path** (context path of bamboo app)
* **project** (name of bamboo project)
* **plan** (name of bamboo plan to execute)

## License
Apache 2.0 License: <http://www.apache.org/licenses/LICENSE-2.0.html>
