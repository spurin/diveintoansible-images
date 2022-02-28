## Dive Into Ansible Images

[![Follow](https://shields.io/twitter/follow/jamesspurin?label=Follow)](https://twitter.com/jamesspurin)
[![GitHub Stars](https://shields.io/docker/pulls/spurin/diveintoansible)](https://hub.docker.com/r/spurin/diveintoansible)

✨ This repository provides the container sources for DiveInto.com's 'Dive Into Ansible' lab ✨

The related lab is available at - https://github.com/spurin/diveintoansible-lab

The video course relating to this lab is available on -

* [DiveInto](https://diveinto.com)
* [Udemy](https://www.udemy.com/course/diveintoansible/?referralCode=28BBB7A1DCCD01BBA51F)
* [O'Reilly](https://learning.oreilly.com/videos/dive-into-ansible/9781801076937)
* [PacktPub](https://www.packtpub.com/product/dive-into-ansible-from-beginner-to-expert-in-ansible-video/9781801076937)
  
### Build

See the respective branches for each of the container images

Included is the build.sh and build_rc.sh that I use to create the images  If you wish to build local images, from each respective branch run -

```build.sh -local```

Other options exist within these scripts for cross archicture building (for amd64 and arm64) as per how I release the image files

### See Also

These images are built upon two other images that are also shared on GitHub -

* Parent systemd images with sshd and ttyd - [spurin/container-systemd-sshd-ttyd](https://github.com/spurin/container-systemd-sshd-ttyd)
    * Parent systemd images - [spurin/container-systemd](https://github.com/spurin/container-systemd)


The hierarchy for the centos, ubuntu and ansible images is as follows -

* spurin/diveintoansible-images
    * spurin/container-systemd-sshd-ttyd
        * spurin/container-systemd

---

![DiveIntoAnsible Cover](DiveIntoAnsible_Cover.png?raw=true "Dive Into Ansible")
