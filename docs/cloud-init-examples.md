# Cloud-init examples

## ConfigDrive2 example from Proxmox VE 9.1 with Windows VM

Should be `configdrive2` format when cloudinit is added to the VM when it already has `ostype` set to any Windows version, as mentioned [here](https://pve.proxmox.com/wiki/Cloud-Init_Support#_cloud_init_on_windows).

Settings in Proxmox UI:
* User: `MyOrgAdmin`
* Password: `plain_test_password`
* DNS domain: `-`
* DNS servers: `-`
* SSH public key: `ssh-rsa ...`
* Upgrade packages: `Yes`
* IP Config (net0): `-` (shown as "Static" with empty values)

### File openstack\latest\meta.json

```json
{
    "public_keys": {
        "key-0": "ssh-rsa ..."
    },
    "admin_pass": "plain_test_password",
    "uuid": "uuid_like_string",
    "network_config": {
        "content_path": "/content/0000"
    }
}
```

### File: openstack\latest\user_data

```
#cloud-config
hostname: xxx
manage_etc_hosts: true
fqdn: xxx
user: MyOrgAdmin
password: plain_test_password
ssh_authorized_keys:
  - ssh-rsa ...
chpasswd:
  expire: False
users:
  - default
package_upgrade: true
```
