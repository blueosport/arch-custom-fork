#!/bin/bash

set -e -u

# 1. Locale and Timezone
sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# 2. User Configuration
usermod -s /usr/bin/bash root
cp -aT /etc/skel/ /root/
# Create liveuser with wheel group for sudo access
useradd -m -p "" -g users -G adm,audio,floppy,log,network,rfkill,scanner,storage,optical,power,wheel,input -s /bin/bash liveuser
chown -R liveuser:users /home/liveuser

# 3. SSH Configuration
sed -i 's/#\(PermitRootLogin \).\+/\1yes/' /etc/ssh/sshd_config

# 4. Pacman Configuration
sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist

# 5. XLibre Repository Setup (Automatic during ISO build)
# Add repository to pacman.conf
cat >> /etc/pacman.conf <<EOF

[xlibre]
Server = https://x11libre.net/repo/arch_based/x86_64/
EOF

# Import XLibre signing key
pacman-key --recv-keys 73580DE2EDDFA6D6
pacman-key --lsign-key 73580DE2EDDFA6D6

# 6. Systemd & Journal Configuration
sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf
sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' /etc/systemd/logind.conf

# 7. Enable Services
# Enable NetworkManager, Pacman-init, and LightDM
systemctl enable pacman-init.service choose-mirror.service NetworkManager.service lightdm.service

# Set default target to graphical
systemctl set-default graphical.target

# 8. Configure LightDM for i3 and Autologin
mkdir -p /etc/lightdm
cat > /etc/lightdm/lightdm.conf <<EOF
[LightDM]
run-directory=/run/lightdm

[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=i3
autologin-user=liveuser
autologin-user-timeout=0
EOF

# 9. Configure i3 for liveuser (Optional: Pre-generate a basic config to avoid first-run wizard)
# This ensures i3 doesn't ask to generate a config on first boot if you prefer a silent setup
# If you want the wizard to appear, you can remove the next 3 lines.
mkdir -p /home/liveuser/.config/i3
cat > /home/liveuser/.config/i3/config <<EOF
# i3 config file (v4)
# Please see https://i3wm.org/docs/userguide.html for a complete reference!

set \$mod Mod4

# Start a terminal
bindsym \$mod+Return exec i3-sensible-terminal

# Kill focused window
bindsym \$mod+Shift+q kill

# Reload configuration file
bindsym \$mod+Shift+c reload
# Restart i3 inplace (preserves your layout/session)
bindsym \$mod+Shift+r restart

# Change focused container to floating
bindsym \$mod+Shift+space floating toggle

# Select focus direction
bindsym \$mod+Left focus left
bindsym \$mod+Down focus down
bindsym \$mod+Up focus up
bindsym \$mod+Right focus right

# Move focused container
bindsym \$mod+Shift+Left move left
bindsym \$mod+Shift+Down move down
bindsym \$mod+Shift+Up move up
bindsym \$mod+Shift+Right move right

# Workspace names
bindsym \$mod+1 workspace 1
bindsym \$mod+2 workspace 2
bindsym \$mod+3 workspace 3
bindsym \$mod+4 workspace 4
bindsym \$mod+5 workspace 5
bindsym \$mod+6 workspace 6
bindsym \$mod+7 workspace 7
bindsym \$mod+8 workspace 8
bindsym \$mod+9 workspace 9
bindsym \$mod+0 workspace 10

# Move focused container to workspace
bindsym \$mod+Shift+1 move container to workspace 1
bindsym \$mod+Shift+2 move container to workspace 2
bindsym \$mod+Shift+3 move container to workspace 3
bindsym \$mod+Shift+4 move container to workspace 4
bindsym \$mod+Shift+5 move container to workspace 5
bindsym \$mod+Shift+6 move container to workspace 6
bindsym \$mod+Shift+7 move container to workspace 7
bindsym \$mod+Shift+8 move container to workspace 8
bindsym \$mod+Shift+9 move container to workspace 9
bindsym \$mod+Shift+0 move container to workspace 10

# Resize mode
mode "resize" {
    bindsym Left resize shrink width 10 px or 10 ppt
    bindsym Down resize grow height 10 px or 10 ppt
    bindsym Up resize shrink height 10 px or 10 ppt
    bindsym Right resize grow width 10 px or 10 ppt
    bindsym Return mode "default"
    bindsym Escape mode "default"
    bindsym \$mod+r mode "default"
}
bindsym \$mod+r mode "resize"

# Start i3bar to display a workspace bar
bar {
    status_command i3status
}
EOF

chown -R liveuser:users /home/liveuser/.config   
