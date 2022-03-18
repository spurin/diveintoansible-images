#!/usr/bin/env python

import unittest
import os
import socket
import git
import time
from parameterized import parameterized
from shutil import copyfile

# Hosts Definition
ansible_host = "ubuntu-c"
ubuntu_hosts = ["ubuntu1", "ubuntu2", "ubuntu3"]
centos_hosts = ["centos1", "centos2", "centos3"]
portal = "portal"
allhosts = [ansible_host, portal] + ubuntu_hosts + centos_hosts

# Variables
ignore = ["hosts.yaml", "ec2_playbook.yaml"]
pairs = []


def initial_setup():
    # Grace period for containers to start all services before testing
    time.sleep(60)

    # Clone Repo
    os.system("rm -rf /home/ansible/diveintoansible")
    git.Repo.clone_from(
        "https://github.com/spurin/diveintoansible.git", "/tmp/diveintoansible"
    )

    # Clone to /tmp then move
    # https://superuser.com/questions/991832/git-clone-error-chmod-on-ntfs-mount-failed-operation-not-permitted
    os.system("mv /tmp/diveintoansible /home/ansible/diveintoansible 2>/dev/null")

    # Extract course updates / fixes for tests
    os.system("tar xPf /tests/required_updates.tar")

    # Remove playbooks that are meant to fail
    os.remove(
        "/home/ansible/diveintoansible/Ansible Playbooks, Introduction/Ansible Playbooks, Variables/10/variables_playbook.yaml"
    )
    os.remove(
        "/home/ansible/diveintoansible/Ansible Playbooks, Introduction/Ansible Playbooks, Variables/13/variables_playbook.yaml"
    )
    os.remove(
        "/home/ansible/diveintoansible/Structuring Ansible Playbooks/Using Roles/06/nginx_webapp_playbook.yaml"
    )

    # Revisit these as seperate tests
    ## require extra_vars_key passed
    os.remove(
        "/home/ansible/diveintoansible/Ansible Playbooks, Introduction/Ansible Playbooks, Variables/16/variables_playbook.yaml"
    )
    os.remove(
        "/home/ansible/diveintoansible/Ansible Playbooks, Introduction/Ansible Playbooks, Variables/17/variables_playbook.yaml"
    )

    # Requires plugins to be in place
    os.remove(
        "/home/ansible/diveintoansible/Creating Modules and Plugins/Creating Plugins/01/sorted_items_playbook.yaml"
    )
    os.remove(
        "/home/ansible/diveintoansible/Creating Modules and Plugins/Creating Plugins/02/reverse_upper_filter_playbook.yaml"
    )

    # Populate files in /etc/ansible/facts.d
    os.system('mkdir -p /etc/ansible/facts.d')
    os.system("cp /home/ansible/diveintoansible/Ansible\ Playbooks\,\ Introduction/Ansible\ Playbooks\,\ Facts/03/templates/* /etc/ansible/facts.d")

    # Run /utils/startup.sh (configure ssh keys)
    os.system("/utils/startup.sh >/dev/null 2>&1")

    # Open up 22 and 2222 on centos1
    os.system("ssh -o StrictHostKeyChecking=no centos1 'echo Port 22 >> /etc/ssh/sshd_config' >/dev/null 2>&1")
    os.system("ssh -o StrictHostKeyChecking=no centos1 'echo Port 2222 >> /etc/ssh/sshd_config' >/dev/null 2>&1")
    os.system("ssh -o StrictHostKeyChecking=no centos1 systemctl restart sshd")

# Run initial_setup as priority
initial_setup()

# Capture Playbooks
def get_playbooks():
    # Set the directory you want to start from
    rootDir = "."
    for dirName, subdirList, fileList in os.walk("/home/ansible/diveintoansible"):
        for fname in fileList:
            # A playbook will be in a directory with hosts, hosts.yaml or hosts.json
            if (
                os.path.isfile(dirName + "/hosts")
                or os.path.isfile(dirName + "/hosts.yaml")
                or os.path.isfile(dirName + "/hosts.json")
            ):
                # Ignore filename items in the ignore list
                if fname not in ignore:
                    # Ignore directories with the name template
                    if "template" not in dirName:
                        # Ignore files with _fail_ in the name
                        if "_fail_" not in fname:
                            # Check it ends with .yaml or .yml
                            if ".yaml" in fname or ".yml" in fname:
                                # Check if the file has 'hosts:' within it (indicating it's a playbook)
                                with open(f"{dirName}/{fname}") as myfile:
                                    if "hosts:" in myfile.read():
                                        # Check that the file has doesn't have 'vars_prompt:' within it (requires interactive mode)
                                        with open(f"{dirName}/{fname}") as myfile:
                                            if "vars_prompt:" not in myfile.read():
                                                pairs.append([dirName, fname])

    return pairs


# Check if port is open
def isOpen(ip, port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.connect((ip, int(port)))
        s.shutdown(2)
        return True
    except:
        return False


class DiveIntoAnsible_lab(unittest.TestCase):
    @parameterized.expand(allhosts)
    def test_01_check_ping_connectivity(self, host):
        self.assertEqual(os.system(f"ping -c 1 {host} > /dev/null 2>&1"), 0)

    @parameterized.expand(ubuntu_hosts + centos_hosts)
    def test_02_check_ssh_is_running(self, host):
        self.assertTrue(isOpen(host, 22))

    @parameterized.expand(ubuntu_hosts + centos_hosts)
    def test_03_check_ttyd_is_running(self, host):
        self.assertTrue(isOpen(host, 7681))

    def test_04_check_volume_mounts_working(self):
        self.assertTrue(os.path.exists("/etc/.env"))

    def test_05_check_env_has_content(self):
        self.assertNotEqual(open("/etc/.env", "r").read().find("ANSIBLE_HOME="), -1)

    def test_06_check_portal_running(self):
        self.assertTrue(isOpen("portal", 80))

    def test_07_check_docker_in_docker_running(self):
        self.assertTrue(isOpen("docker", 2375))

    @parameterized.expand(get_playbooks())
    def test_08_run_playbook(self, directory, playbook):
        os.chdir(directory)
        self.assertEqual(
            os.system(
                f"timeout 600 ansible-playbook --vault-password-file /tests/vaultpass {playbook} > /dev/null 2>&1"
            ),
            0,
        )
