# System config changes

If there is any change to be made at the environment,
it should first be made at the ~/Projects/dotfiles directory.
This machine's is a CentOS Stream 10 and has a corresponding branch at the dotfiles project called centos

Branch centos_xps_9700 derives from centos and holds the configuration specific to the Dell XPS 17 9700 (`cat /sys/class/dmi/id/product_name` prints `XPS 17 9700`).
On that machine, make changes on centos_xps_9700; make a change that every CentOS machine needs on centos, then merge centos into centos_xps_9700.
