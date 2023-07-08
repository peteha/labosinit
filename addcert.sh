#!/bin/bash
echo "## Getting SSH Keys ##"
curl -s "https://github.com/$user.keys" > "$user.keys"
gitpk_dl=$(cat "$user.keys")
if [ $? -eq 0 ] ; then
  if grep -Fxq "$gitpk_dl" "/home/$user/.ssh/authorized_keys"; then
    echo "## Already in authorized_keys ##"
  else
    mkdir -p "/home/$user/.ssh"
    cat "$user.keys" >> "/home/$user/.ssh/authorized_keys"
    echo "The SSH key was added successfully."
  fi
else
  echo "Failed to retrieve the SSH key. Please check your GitHub username."
fi
