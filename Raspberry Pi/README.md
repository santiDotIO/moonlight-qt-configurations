# moonlight-qt-configurations

Overview
OS - Raspi OS Lite
Hardware - Raspberry Pi 3 Model b+

Replace [REPLACE_USER] with whatver user was created

## the basic stuff

add repo, depending on platform

https://github.com/moonlight-stream/moonlight-docs/wiki/Installing-Moonlight-Qt-on-Raspberry-Pi-4

```
sudo apt update
sudo apt upgrade -y


curl -1sLf 'https://dl.cloudsmith.io/public/moonlight-game-streaming/moonlight-qt/setup.deb.sh' | distro=raspbian codename=$(lsb_release -cs) sudo -E bash
sudo apt install -y uhubctl pulseaudio moonlight-qt
```

## create service file under user

```
nano ~/.config/systemd/user/moonlight.service

# create moonlight init script
nano /usr/local/bin/moonlight-launch.sh
chmod + /usr/local/bin/moonlight-launch.sh

ln': ln -s /usr/local/bin/moonlight-launch.sh ~/moonlight-launch.sh

# Enable moonlight service
systemctl --user daemon-reexec
systemctl --user enable --now moonlight.service
```

## moonlight config file

```
ln -s ~/.config/Moonlight\ Game\ Streaming\ Project/Moonlight.conf ~/Moonlight.conf
```

## Create service to auto connecy dongle

Some dongles might not auto connect, after the Raspi has booted, connect the dongle and check which port it's running on

```
> lsusb

...
Bus 001 Device 013: ID 2dc8:3106 8BitDo 8BitDo Receiver
...

the devince number in this case is `13`

Now we cna run `lsusb -t` to check which port is device 13 connected to

```
> lsusb -t

/:  Bus 01.Port 1: Dev 1, Class=root_hub, Driver=dwc_otg/1p, 480M
    |__ Port 1: Dev 2, If 0, Class=Hub, Driver=hub/5p, 480M
        |__ Port 1: Dev 3, If 0, Class=Vendor Specific Class, Driver=smsc95xx, 480M
        |__ Port 2: Dev 13, If 0, Class=Vendor Specific Class, Driver=xpad, 12M
        |__ Port 3: Dev 10, If 0, Class=Human Interface Device, Driver=usbhid, 12M
        |__ Port 3: Dev 10, If 1, Class=Human Interface Device, Driver=usbhid, 12M
        |__ Port 3: Dev 10, If 2, Class=Human Interface Device, Driver=usbhid, 12M
```

We see Buss 1 port 2 is device 13. Using `uhubctl` we will power cycle that port so the Raspbery Pi can detect it



```
sudo nano /usr/local/bin/power-cycle-8bitdo.sh

# for easy acess link it to the home dir
sudo ln /usr/local/bin/power-cycle-8bitdo.sh ~/power-cycle-8bitdo.sh

sudo chmod +x /usr/local/bin/power-cycle-8bitdo.sh

# create the service file
sudo nano /etc/systemd/system/power-cycle-8bitdo.service

# enable service

```
sudo systemctl daemon-reexec
sudo systemctl enable --now power-cycle-8bitdo.service
```


## last reboot 

```
sudo reboot
```
