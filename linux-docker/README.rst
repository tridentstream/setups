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

To get started, download and unzip the config file bundle

.. code-block:: bash

    curl -L -o bundle.zip https://github.com/tridentstream/setups/raw/master/linux-docker/bundle.zip && \
    unzip bundle.zip -d tridentstream && \
    rm bundle.zip && \
    cd tridentstream

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

Please note, if you do not use traefik as prescribed, then you will need to modify docker-compose.yml to fit your needs.

When Tridentstream is bootstrapped, it can be started by executing start.sh.

.. code-block:: bash

    ./start.sh

If you decided to include Deluge, it is now available at: https://your-domain.com/_deluge_web/
It is strongly recommended that you change the default password.


License
---------------------------------

MIT