# Shebang the following lines to get self-wrapped script
#/usr/bin/env nix-shell
# nix-shell -i python -p python3Packages.ovh

# Environment variables
# see https://github.com/ovh/python-ovh#environment-vars-and-predefined-configuration-files

# IP: /path/to/ip executable
# IFNAME: interface name
# OVH_ENDPOINT
# OVH_APPLICATION_KEY
# OVH_APPLICATION_SECRET
# OVH_CONSUMER_KEY

import json
import os
import subprocess
import sys

import ovh

def getIp():
    ip = os.environ['IP']
    res = subprocess.run([ip, "--json", "address"], capture_output=True, text=True)
    data = json.loads(res.stdout)

    ifname = os.environ['IFNAME']
    addresses = [
        interface['addr_info']
        for interface in data
        if interface['ifname'] == ifname
    ][0]

    ipv6 = max([
            address
            for address in addresses
            if address['scope'] == "global"
            and address['family'] == "inet6"
            and not ('deprecated' in address and address['deprecated'])
        ],
        key=lambda a: a['preferred_life_time']
    )['local']

    return ipv6

def updateIp(newIp, domainName):
    client = ovh.Client()

    recordId = client.get(f"/domain/zone/{domainName}/record?fieldType=AAAA")
    if not len(recordId):
        print(f"error no AAAA {domainName}. record", file=sys.stderr)
        sys.exit(1)
    recordId = recordId[0]

    recordData = client.get(f"/domain/zone/{domainName}/record/{recordId}")
    oldIp = recordData['target']

    if oldIp != newIp:
        client.put(f"/domain/zone/{domainName}/record/{recordId}", target=newIp)
        client.post(f"/domain/zone/{domainName}/refresh")
        print(f"{domainName}: update from {oldIp} to {newIp}")
    # else:
    #     print(f"{domainName}: unchanged {oldIp}")

newIp = getIp()
updateIp(newIp, "ppom.me")
updateIp(newIp, "fesse.cloud")
