import subprocess
import pwd
import os
import json
import getpass

def is_installed(package):
    cmd = "dpkg-query -W -f='${Status}' " + package
    status = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if status.returncode == 0:
        return True
    else:
        return False

def install(packages):
    subprocess.run(["apt-get", "install", "-y"] + packages, check=True)


def service_control(service_name, action):
    os.system(f"systemctl {action} {service_name}")


def add_user(username, password):
    try:
        pwd.getpwnam(username)
        print(f"{username} already exists.")
    except KeyError:
        os.system(f"useradd -m -p $(openssl passwd -1 {password}) {username}")


def add_ssh_key(username, ssh_key):
    home_dir = os.path.expanduser(f"~{username}")
    ssh_dir = os.path.join(home_dir, ".ssh")
    authorized_keys = os.path.join(ssh_dir, "authorized_keys")

    # Create .ssh directory if it does not exist
    os.makedirs(ssh_dir, exist_ok=True)

    # Append the ssh key to the authorized_keys file
    with open(authorized_keys, "a") as f:
        f.write(ssh_key)


def append_text_to_file_end(file_path, text):
    with open(file_path, "ab") as f:
        f.write(text.encode())


def check_text_in_file(file_path, text_to_find):
    with open(file_path, 'r') as f:
        for line in f:
            if text_to_find in line:
                return True
    return False


def append_text_to_file(file_path, text):
    with open(file_path, 'a') as f:
        f.write(text + "\n")


def gather_variables(_input):
    _varlist = dict()
    for key, keydet in _input.items():
        _varlist[key] = input(f"{keydet[0]} [{keydet[1]}]: ") or keydet[1]
    return _varlist

def pretty_print_json(json_obj):
    print(json.dumps(json_obj, indent=4))


def read_json_file(file_path):
    with open(file_path) as json_file:
        json_data = json.load(json_file)
    return json_data


def _initialise():
    json_obj = read_json_file(file_path)
    user_input = gather_variables(json_obj)
    return user_input


def add_user():
    username = input("Enter username: ")
    password = getpass.getpass("Enter password: ")
    userres = subprocess.run(["useradd", "-m", "-p", password, username], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if userres.returncode == 0:
        print("User added successfully")
    else:
        if userres.returncode == 9:
            print("User", username, "already exists.")
            q = input("Do you wish to change the password (y/n): ") or "n"
            if q.upper() == "Y":
                pwdres = subprocess.run(["passwd", username, password], stdin=subprocess.PIPE,
                                        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                if pwdres.returncode == 0:
                    print("Password changed successfully")
                else:
                    print("Error changing password:", pwdres.stderr.decode().strip())
        else:
            print("Error adding user:", userres.stderr.decode().strip())
    return username

file_path = './buildDef.json'


add_user()


##package = "salt-master"
##if is_installed(package):
##    print(package + " is installed.")
##else:
##    print(package + " is not installed.")
##    packages = list()
##    packages.append(package)
##    install(packages)


#username = "newuser"
#password = "password"
#add_user(username, password)
#
#username = "newuser"
#os.system(f"usermod -aG sudo {username}")
#
#service_name = "service_name"
#action = "stop"
#service_control(service_name, action)
#
#action = "start"
#service_control(service_name, action)
#