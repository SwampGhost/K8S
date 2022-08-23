#!/bin/sh

talosctl patch --mode=no-reboot machineconfig -n 10.2.0.231 --patch '[{"op": "add", "path": "/machine/sysctls", "value": {"vm.nr_hugepages": "1024"}}, {"op": "add", "path": "/machine/kubelet/extraArgs", "value": {"node-labels": "openebs.io/engine=mayastor"}}]
talosctl patch --mode=no-reboot machineconfig -n 10.2.0.232 --patch '[{"op": "add", "path": "/machine/sysctls", "value": {"vm.nr_hugepages": "1024"}}, {"op": "add", "path": "/machine/kubelet/extraArgs", "value": {"node-labels": "openebs.io/engine=mayastor"}}]
talosctl patch --mode=no-reboot machineconfig -n 10.2.0.233 --patch '[{"op": "add", "path": "/machine/sysctls", "value": {"vm.nr_hugepages": "1024"}}, {"op": "add", "path": "/machine/kubelet/extraArgs", "value": {"node-labels": "openebs.io/engine=mayastor"}}]

talosctl -n 10.2.0.231 service kubelet restart
talosctl -n 10.2.0.232 service kubelet restart
talosctl -n 10.2.0.233 service kubelet restart
