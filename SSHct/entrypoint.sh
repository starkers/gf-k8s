#!/bin/sh

echo $CTTIMEZONE > /etc/timezone
ln -sf /usr/share/zoneinfo/$CTTIMEZONE /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

sed -i -e "s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen
sed -i -e "s/# $CTLOCALE UTF-8/$CTLOCALE UTF-8/" /etc/locale.gen
dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=$CTLOCALE

echo "AllowUsers $CTUSER" >> /etc/ssh/sshd_config
useradd --uid $CTUSERID --user-group --shell /bin/bash $CTUSER
echo $CTUSER:"$CTUSERPWD" | chpasswd
passwd -u $CTUSER
usermod -a -G sudo $CTUSER

# Add pubkey
if [ "$PUBKEY" != "none" ]; then
  echo "$PUBKEY" >> /home/$CTUSER/.ssh/authorized_keys
  chmod 600 /home/$CTUSER/.ssh/authorized_keys
fi

# Install additional packages in background 
if [ -f /home/.packages ]; then
  tmux new-session -d -s aptget 'cat /home/.packages | xargs --max-args=1 apt-get install -y'
fi

# start ssh daemon
exec /usr/sbin/sshd -Def /etc/ssh/sshd_config
