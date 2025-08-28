# Setting up Tailscale on OpenPLi (ARM Linux)

This page describes how to install and configure **Tailscale** on an OpenPLi set-top box using the ARM version of Linux.  
Because OpenPLi is a lightweight distribution, the usual package manager method may not work. Instead, you may need to use Tailscale’s static binaries and configure an init.d service for automatic startup.

---

## 1. Try the standard installation script

First, attempt to install Tailscale using the official script:

```sh
curl -fsSL https://tailscale.com/install.sh | sh
```

- If this works, skip ahead to [Step 4](#4-run-tailscale).  
- If it fails (common on OpenPLi), continue with the manual installation below.

---

## 2. Download the ARM static binaries

Go to [Tailscale Stable Releases](https://pkgs.tailscale.com/stable/#static) and download the ARM package.  
For example:

```sh
wget https://pkgs.tailscale.com/stable/tailscale_1.86.2_arm.tgz
```

---

## 3. Unpack and install the binaries

Extract the archive and copy the executables into `/usr/sbin`:

```sh
tar zxvf tailscale_1.86.2_arm.tgz
cp tailscale_1.86.2_arm/tailscal* /usr/sbin/
chmod +x /usr/sbin/tailscal*
```

This provides both `tailscale` (CLI) and `tailscaled` (daemon).

---

## 4. Create an init.d service for Tailscale

Since OpenPLi does not use `systemd`, we need to create an **init.d service** to start Tailscale at boot.

Create the service script:

```sh
cat << EOF >/etc/init.d/tailscaled
#!/bin/sh
DAEMON=/usr/sbin/tailscaled
PIDFILE=/var/run/tailscaled.pid
DAEMON_OPTS=""

case "$1" in
  start)
    echo "Starting tailscaled"
    start-stop-daemon --start --quiet --background --make-pidfile       --pidfile $PIDFILE --exec $DAEMON -- $DAEMON_OPTS
    ;;
  stop)
    echo "Stopping tailscaled"
    start-stop-daemon --stop --quiet --pidfile $PIDFILE
    ;;
  restart)
    $0 stop
    $0 start
    ;;
  status)
    if [ -f $PIDFILE ] && kill -0 "$(cat $PIDFILE)" 2>/dev/null; then
      echo "tailscaled is running"
    else
      echo "tailscaled is not running"
    fi
    ;;
  *)
    echo "Usage: /etc/init.d/tailscaled {start|stop|restart|status}"
    exit 1
    ;;
esac

exit 0
EOF
```

Make the script executable and add it to startup:

```sh
chmod +x /etc/init.d/tailscaled
update-rc.d tailscaled defaults
```

---

## 5. Test the service

Check the service status (should be stopped):

```sh
service tailscaled status
```

Start the daemon:

```sh
service tailscaled start
```

Verify it’s running:

```sh
service tailscaled status
```

You can also check that the PID file exists:

```sh
cat /var/run/tailscaled.pid
```

---

## 6. Run Tailscale

With the daemon running, bring Tailscale online:

```sh
tailscale up
```

You will receive an authentication URL, for example:

```
To authenticate, visit:

     https://login.tailscale.com/c/129a3b4e01e114a
```

Open this in your browser, log in, and the device will appear in your Tailscale network.

---

## 7. Notes

- The daemon will now automatically start on boot.  
- You can stop or restart it anytime using:  

```sh
service tailscaled stop
service tailscaled restart
```

- From here, Tailscale should work like on any other Linux machine.

---

✅ Success! At this point, your OpenPLi ARM device is part of your Tailscale network.
