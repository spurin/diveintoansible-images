#! /bin/bash

# (GPL3+) Alberto Salvia Novella (es20490446e)
passwordHash() {
   password=${1}
   salt=${2}
   encryption=${3}

   hashes=$(echo ${password} | openssl passwd -${encryption} -salt ${salt} -stdin)
   echo $(substring ${hashes} "$" "3")
}

passwordIsValid() {
   user=${1}
   password=${2}

   encryption=$(secret "encryption" ${user})
   salt=$(secret "salt" ${user})
   salted=$(secret "salted" ${user})
   hash=$(passwordHash ${password} ${salt} ${encryption})

   [ ${salted} = ${hash} ] && return 0 || return 1
}

secret() {
   secret=${1}
   user=${2}
   shadow=$(shadow ${user})

   if [ ${secret} = "encryption" ]; then
      position=1
   elif [ ${secret} = "salt" ]; then
      position=2
   elif [ ${secret} = "salted" ]; then
      position=3
   fi

   echo $(substring ${shadow} "$" ${position})
}

shadow() {
   user=${1}
   shadow=$(cat /etc/shadow | grep ${user})
   shadow=$(substring ${shadow} ":" "1")
   echo ${shadow}
}

substring() {
   string=${1}
   separator=${2}
   position=${3}

   substring=${string//"${separator}"/$'\2'}
   IFS=$'\2' read -a substring <<<"${substring}"
   echo ${substring[${position}]}
}

# Check ttyd is running
n=0
until systemctl status ttyd >/dev/null; do
   echo "failure: ttyd is not running - waiting for it to start"
   n=$((n + 1))
   if [ "$n" -ge 10 ]; then
      echo "exceeded retries, exiting"
      exit 1
   fi
   sleep 1
done
echo "ok: ttyd is running"

# Check sshd is running
n=0
until systemctl status sshd >/dev/null; do
   echo "failure: sshd is not running - waiting for it to start"
   n=$((n + 1))
   if [ "$n" -ge 10 ]; then
      echo "exceeded retries, exiting"
      exit 1
   fi
   sleep 1
done
echo "ok: sshd is running"

# Check startup service is running
n=0
until systemctl status startup >/dev/null; do
   echo "failure: startup is not running - waiting for it to start"
   n=$((n + 1))
   if [ "$n" -ge 10 ]; then
      echo "exceeded retries, exiting"
      exit 1
   fi
   sleep 1
done
echo "ok: startup is running"

# Check the permissions on /root
n=0
until stat -c '%a - %n' /root 2>/dev/null | grep '700 - /root' >/dev/null; do
   echo "failure: incorrect permissions found for /root, expecting permissions of 700 - attempting to resolve"
   n=$((n + 1))
   if [ "$n" -ge 10 ]; then
      echo "exceeded retries, exiting"
      exit 1
   fi
   systemctl restart startup
   sleep 1
done
echo "ok: correct permissions found for /root, expecting permissions of 700"

# Check the permissions on /home/ansible
n=0
until stat -c '%a - %n' /home/ansible 2>/dev/null | grep '755 - /home/ansible' >/dev/null; do
   echo "failure: incorrect permissions found for /home/ansible, expecting permissions of 755, attempting to resolve"
   systemctl restart startup
   n=$((n + 1))
   if [ "$n" -ge 10 ]; then
      echo "exceeded retries, exiting"
      exit 1
   fi
   sleep 1
done
echo "ok: correct permissions found for /home/ansible, expecting permissions of 755"

# Check the guest user ansible password
n=0
until passwordIsValid ansible $(cat /config/guest_passwd); do
   echo "failure: incorrect password set for ansible user, attempting to resolve"
   systemctl restart startup
   n=$((n + 1))
   if [ "$n" -ge 10 ]; then
      echo "exceeded retries, exiting"
      exit 1
   fi
   sleep 1
done
echo "ok: correct password set for ansible user"

# Check the root password
n=0
until passwordIsValid root $(cat /config/root_passwd); do
   echo "failure: incorrect password set for root user, attempting to resolve"
   systemctl restart startup
   n=$((n + 1))
   if [ "$n" -ge 10 ]; then
      echo "exceeded retries, exiting"
      exit 1
   fi
   sleep 1
done
echo "ok: correct password set for root user"

# Check the permissions on /dev/null
n=0
until stat -c '%a - %n' /dev/null 2>/dev/null | grep '666 - /dev/null' >/dev/null; do
   echo "failure: incorrect permissions found for /dev/null, expecting permissions of 666 - attempting to resolve"
   systemctl start systemd-udev-trigger.service
   n=$((n + 1))
   if [ "$n" -ge 10 ]; then
      echo "exceeded retries, exiting"
      exit 1
   fi
   sleep 1
done
echo "ok: correct permissions found for /dev/null, expecting permissions of 666"

exit 0
