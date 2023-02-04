#!/bin/bash
inst_pkgs="certbot python3 python3-certbot-dns-cloudflare nfs-common python3-pip nano"
bootfile=/boot/cmdline.txt
k8_params=" group_enable=cpuset cgroup_enable=memory cgroup_memory=1"
