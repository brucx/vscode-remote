#!/bin/bash

set -e

read -p "Enter desired app name or press return to have a name generated:" appname

if [ -z "$appname" ]; then
    appname="app-$(date +%s)"
fi

read -p "Enter desired organization name or press return to use your personal org:" orgname

if [ -z "$orgname" ]; then
    orgname="personal"
fi

read -p "Enter disk size in GB or press return for default 10GB:" disksizenum

if [ -z "$disksizenum" ]; then
    disksize=""
else
    disksize="--size ${disksizenum}"
fi

# read -p "Use Docker on remote machine (y/n):" usedockerresponse

# case $usedockerresponse in 
# [Yy])
#     usedocker="--build-arg USE_DOCKER=y"
# ;;
# *)
#     usedocker=""
# ;;
# esac

echo

read -p "Any extra packages:" extrapackages


AUTHORIZED_KEYS=""

for i in ~/.ssh/*.pub; do
    AUTHORIZED_KEYS="$AUTHORIZED_KEYS$(cat $i)"$'\n'
done

echo "
app = '$appname'

[[services]]
internal_port = 22
protocol = 'tcp'
auto_stop_machines = 'stop'
auto_start_machines = true
min_machines_running = 0

[[services.ports]]
port = 10022

[[mounts]]
source = 'data'
destination = '/data'

[env]
HOME_SSH_AUTHORIZED_KEYS = '''
$AUTHORIZED_KEYS
'''

[[vm]]
  memory = '16gb'
  cpu_kind = 'shared'
  cpus = 8

">fly.toml

fly apps create $appname --org $orgname

fly volumes create data $disksize -y

fly deploy --build-arg USER=$(whoami) --build-arg EXTRA_PKGS="$extrapackages" --remote-only --depot=false

echo
echo
echo "To use in VS Code, tell the remote-ssh package to connect to $(whoami)@$(fly ips list -j | jq -r '.[] | select(.Type=="v4") | .Address'):10022"

