import certbot.main
import os



emailadd = "admin@pggb.net"
fullhostname = "pi3.pggb.net"
_cfcredir = "/root/cfcred/cf-api-token.ini"

if os.path.exists(_cfcredir):
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
