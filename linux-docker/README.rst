================================================
Docker installer
================================================

This guide explains how to get Tridentstream Media Server up and running
on a server where you have access to Docker.

.. contents::


Prerequisite
---------------------------------

Requirements

* A server with root access (Ubuntu or Debian for this guide).
* A domain already pointing to the server.

If you do not already have docker and docker-compose installed, do this:

.. code-block:: bash

    apt-get install \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common -y && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
    add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable" && \
    apt-get install docker-ce docker-ce-cli containerd.io -y && \
    curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose


Installation
---------------------------------

To get started, clone the setups repository

.. code-block:: bash

    git clone --depth 1 https://github.com/tridentstream/setups

Head into the linux-docker folder

.. code-block:: bash

    cd setups/linux-docker

OPTIONAL: If you do not have your own webserver to be infront of the Tridentstream instance, then traefik is recommended.
It's easy to get going and is already included.

.. code-block:: bash

    docker network create web && \
    cd traefik && \
    touch acme.json && \
    chmod 600 acme.json && \
    docker-compose up -d && \
    cd ..

Time to get Tridentstream bootstrapped.

.. code-block:: bash

    # If you do not need to use built-in deluge, skip -d
    ./bootstrap.sh -d -o your-domain.com

Follow the on-screen instructions and read the Setting Up section in the `main README <https://github.com/tridentstream/mediaserver>`_.

Please note, if you do not use traefik as prescribed, then you will need to modify docker-compose.yml to fit your needs.

Plugins
---------------------------------

To install plugins, put the plugin installation package into tridentstream/packages, edit .env and add its name to INSTALLED_APPS.

License
---------------------------------

MIT