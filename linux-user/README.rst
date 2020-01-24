================================================
Linux user account installer
================================================

Install Tridentstream Media Server as a normal user on a (potentially shared)
server running linux.

Prerequisite
---------------------------------

Build tools must be installed, if you know someone with root, they can follow this guide to
install the required build tools: https://github.com/pyenv/pyenv/wiki/common-build-problems

Installation
---------------------------------

curl https://github.com/tridentstream/setups/raw/master/linux-user/bootstrap.sh | bash

Plugins
---------------------------------

To install plugins, put the plugin installation package into tridentstream/packages, edit .environ and add its name to INSTALLED_APPS.

Configuration
---------------------------------

Configurable options can be found in the .environ file and at the top of start.sh.

Settings are reloaded by running ./restart.sh.

If you want to enable SSL or change port, modify start.sh.

License
---------------------------------

MIT