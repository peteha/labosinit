import http.client
import json

# Configuration
githuburl = "github.com"


def _getuserkeys(_username):
    _gitUserkey = "/" + _username + ".keys"
    conn = http.client.HTTPSConnection(githuburl)
    conn.request("GET", _gitUserkey)
    res = conn.getresponse()
    if res.status != 200:
        key = res.status
    else:
        data = res.read()
        key = data.decode("utf-8")
    conn.close()
    return key


if __name__ == '__main__':
    sshkey = _getuserkeys("peteha")
    if type(sshkey) != int:
        print(sshkey)