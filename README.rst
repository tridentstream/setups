================================================
Tridentstream Media Server Installation Methods
================================================

Install everywhere...

.. contents::


Overview
---------------------------------

This is a collection of installers for Tridentstream Media Server to hopefully get it
running on whatever platform you want it on.

Installer linux-docker
````````````````````````````````

Tridentstream deployed with Docker, includes an optional Deluge.

Pros:

* Easy to setup
* Includes everything (SSL, Docker)
* Listens on standard port

Cons:

* Requires root
* Can be harder to customize

`Click here to open guide <https://github.com/tridentstream/setups/tree/master/linux-docker>`__


Installer linux-user
````````````````````````````````

Tridentstream deployed as a normal user on a shared server.

Pros:

* Can be deployed on shared servers

Cons:

* Does not include Deluge
* Have to configure SSL manually
* Listens on a weird port

`Click here to open guide <https://github.com/tridentstream/setups/tree/master/linux-user>`__

License
---------------------------------

MIT