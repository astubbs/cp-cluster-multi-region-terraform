# Running
- The `build.sh` will run terraform, and copy the ati generated inventory to an ansible directory.
- Requires Terraform.py project installed: https://github.com/mantl/terraform.py
 - This is used for reading the Terraform cache and building an Ansible inventory from it.

# Notes
- Can be used to setup full clusters in as many regions as you like
- All instance counts and types are configurable
- If you pass in varip as your latptop ip, will setup access access in the security groups for that IP
- Secrity hasn't been assessed yet and there are probably still gaps
- There is no security for broker port access between regions
