# Scripts to Build Debian based hosts

```
sudo apt install git -y
cd ~
git clone https://github.com/peteha/labosinit.git
```

labinit.sh - Initial Host Setup Script

nfsinit.sh - mount NFS Share to lab server

## Initial Host Setup

labinit.sh

     -a : Add User requires Username and Password
     -u <username> : Username for admin user
     -p <password> : Password for admin user
     -h <hostname> : hostname for device
     -s <ssh key to add> : Requires username
     -t : Sets timezone to Australia/Brisbane
     -n : No Update
     -d : Install docker - requires Username
     -r : reboot host at the end of the process
     -k : Add K8S options for Raspberry PI
     -w : Disable wireless and bluetooth - Raspberry Pi

Typical initial:

```
./labinit.sh -u user1 -p pass1 -h hostname1 -t -d -r
```

Docker install performs simple shell script install.
Updates and upgrades OS as well.

## NFS Setup

nfsinit.sh

    -i <nas ip> : IP Address of NAS
    -h <hostname> # hostname used in shared drive

Implementation requires shared directory setup in NAS.
