# Scripts to Build Ubuntu Hosts

labinit.sh - Initial Host Setup Script

nfsinit.sh - mount NFS Share to lab server

## Initial Host Setup

labinit.sh

	 -a : Add User requires Username and Password
	 -u <username> : Username for admin user
	 -p <password> : Password for admin user
	 -h <hostname> : hostname for device
	 -t : Sets timezone to Australia/Brisbane
	 -m : Install NetData monitoring
	 -d : Install docker - requires Username
	 -r : reboot host at the end of the process

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
