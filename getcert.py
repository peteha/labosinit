import certbot.main
import os

emailadd = "admin@pggb.net"
fullhostname = "pi3.pggb.net"
cfcredir = "/root/cfcred/cf-api-token.ini"

if os.path.exists(_cfcredir, _addr, _fhn):
    certbot.main.main([
        "--non-interactive",
        "--agree-tos",
        "--email", "_emailadd",
        "--domains", _fullhostname,
        "--authenticator", "dns-cloudflare",
        "--dns-cloudflare-credentials", _cfcredir,
        "certonly",
        "--preferred-challenges", "dns-01"
    ])
else: