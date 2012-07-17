#!/bin/sh
#version=1.3

DIR=$2
#1 - local, 0 - remote
MODE=$1
local=false
remote=true
local_copy=root@10.55.164.158:/sapmnt/scratch/remus-xen

top_dir=$PWD
xen_src=$top_dir/$DIR
drbd_dir=drbd-8.3-remus
xen_tools_qemu=tools/qemu-xen-traditional-dir-remote
xen_kernel_dir=linux-2.6-xen
proxy=http://proxy.dub.sap.corp:8080
remus_web_path=http://remusha.wikidot.com/local--files/configuring-and-installing-remus
#primary remus server is set to 1; standby/backup server is set to 0.
primary=1
standby=0
local_kernel_config=config-2.6.32.x-xen0-$HOSTTYPE
web_kernel_config=$remus_web_path/$local_kernel_config_$HOSTTYPE
xen_kernel_version=2.6.32.x

enable_proxy()
{	
	#To be added later
	echo "Checking if proxy is enabled"
}

set_mode_dir()
{
if [ "$DIR" == "" ]; then
	echo "Please set a directory name for building package."
	read dir
	DIR=$dir
	if [ "$DIR" == "" ]; then
		DIR=xen-unstable-`date +%j%k%M`
		xen_src=$top_dir/$DIR
		echo "DIR variable is set to: $DIR"
	else
		echo "Pass"
	fi
else
	echo "DIR variable is set to: $DIR"
fi


if [ "$MODE" == "" ]; then
	echo "Please select local(1)/remote(0) mode for building package."
	read mode
	MODE=$mode
else
	echo "Continuing..."
fi

if [ "$MODE" == "1" ]; then
	echo "Change nothing; continue using local copy"
	echo "Mode variable is set to: local"
else
	remote=true
	local=false
	echo "Mode variable is set to: remote"
fi

echo "Mode variable is set to $MODE (local-1, remote-0) "
echo "Setting GIT to use HTTP protocol; otherwise breaks behind proxy"
export GIT_HTTP=y
}

install_base_packages()
{
	echo "Installing required packages"
	zypper install uuidd uuid-devel gcc readline readline-devel bz2 libbz2-devel sqlite3 libyajl libyajl-devel bison flex dev86 libglib2 libglib-dev xorg xorg-x11 openssl openssl-dev libopenssl-devel libncurses-dev libncurses libncurses5-dev  python-devel zlib binutils binutils-devel gettext pkg-config bridge-utils iproute udev libSDL acpica libSDL-devel pciutils-devel hg wget mercurial git-core mercurial screen tcpdump minicom ntp ntpdate tree debootstrap bcc bin86 gawk bridge-utils iproute libcurl3 libcurl4-openssl-dev bzip2 module-init-tools transfig tgif texinfo pciutils-dev build-essential make gcc libc6-dev zlib1g-dev python python-dev python-twisted libncurses5-dev patch libvncserver-dev libjpeg62-dev iasl libbz2-dev e2fslibs-dev uuid-dev libtext-template-perl autoconf debhelper debconf-utils docbook-xml docbook-xsl dpatch xsltproc rcconf bison flex gcc-multilib ocaml-findlib
}

install_ocaml()
{
	if [ "$HOSTTYPE" == "i386" ]; then
        	echo $HOSTTYPE
	        wget -ivh http://download.opensuse.org/repositories/devel:/languages:/ocaml/openSUSE_11.4/i586/ocaml-3.12.1-13.1.i586.rpm
		wget http://download.opensuse.org/distribution/11.1/repo/oss/suse/i586/zlib-1.2.3-104.137.i586.rpm
		wget http://download.opensuse.org/distribution/11.1/repo/oss/suse/i586/zlib-devel-1.2.3-104.137.i586.rpm
		rpm -ivh zlib-1.2.3-104.137.i586.rpm
		rpm -ivh zlib-devel-1.2.3-104.137.i586.rpm
		rpm -ivh ocaml-3.12.1-13.1.i586.rpm
	else
        	echo $HOSTTYPE
	        wget -ivh http://download.opensuse.org/repositories/devel:/languages:/ocaml/openSUSE_11.4/x86_64/ocaml-3.12.1-13.1.x86_64.rpm
		wget http://download.opensuse.org/distribution/11.1/repo/oss/suse/x86_64/zlib-1.2.3-104.231.x86_64.rpm
		wget http://download.opensuse.org/distribution/11.1/repo/oss/suse/x86_64/zlib-devel-1.2.3-104.231.x86_64.rpm
		rpm -ivh zlib-1.2.3-104.231.x86_64.rpm
		rpm -ivh zlib-devel-1.2.3-104.231.x86_64.rpm
		rpm -ivh ocaml-3.12.1-13.1.x86_64.rpm
	fi
}

install_ocaml_runtime()
{
	if [ "$HOSTTYPE" == "i386" ]; then
	        wget http://download.opensuse.org/repositories/devel:/languages:/ocaml/openSUSE_11.4/i586/ocaml-runtime-3.12.1-13.1.i586.rpm
		rpm -ivh ocaml-runtime-3.12.1-13.1.i586.rpm
	else
        	wget http://download.opensuse.org/repositories/devel:/languages:/ocaml/openSUSE_11.4/x86_64/ocaml-runtime-3.12.1-13.1.x86_64.rpm
		rpm -ivh ocaml-runtime-3.12.1-13.1.x86_64.rpm
	fi
}

install_ocaml_findlib()
{
	if [ "$HOSTTYPE" == "i386" ]; then
        wget http://download.opensuse.org/repositories/devel:/languages:/ocaml/openSUSE_11.4/i586/ocaml-findlib-1.2.7-3.1.i586.rpm
	rpm -ivh ocaml-findlib-1.2.7-3.1.i586.rpm
	wget http://download.opensuse.org/repositories/devel:/languages:/ocaml/openSUSE_11.4/i586/ocaml-findlib-devel-1.2.7-3.1.i586.rpm
	rpm -ivh ocaml-findlib-devel-1.2.7-3.1.i586.rpm
else
        echo $HOSTTYPE
        wget http://download.opensuse.org/repositories/devel:/languages:/ocaml/openSUSE_11.4/x86_64/ocaml-findlib-1.2.7-3.1.x86_64.rpm
        wget http://download.opensuse.org/repositories/devel:/languages:/ocaml/openSUSE_11.4/x86_64/ocaml-findlib-devel-1.2.7-3.1.x86_64.rpm
	rpm -ivh ocaml-findlib-1.2.7-3.1.x86_64.rpm
	rpm -ivh ocaml-findlib-devel-1.2.7-3.1.x86_64.rpm
fi
}

check_ocaml_rpms()
{	
	rpm -qa | grep ocaml-runtime
	if [ $? -eq 1 ]; then
		install_ocaml_runtime
	else
		echo "Ocaml-runtime is already installed"
	fi

	rpm -qa | grep ocaml-3
	if [ $? -eq 1 ]; then
                install_ocaml
        else
                echo "Ocaml-3 is already installed"
        fi
	
	rpm -qa | grep ocaml-findlib
	if [ $? -eq 1 ]; then
                install_ocaml_findlib
        else
                echo "Ocaml-findlib is already installed"
        fi
}


make_xen_unstable()
{
	echo "Downloading xen-unstable sources to dir: $DIR"
	#remote downloading of xen-unstable is allowed as .hg files are missing
	if [ "$remote" == "true" ]; then
		hg clone http://xenbits.xensource.com/xen-unstable.hg $DIR
		cd $DIR
		echo "Downloading Remus timeout and persistent_bitmap files"
		wget $remus_web_path/timeouts -O ./timeouts
		wget $remus_web_path/persistent_bitmap -O ./persistent_bitmap
	else
		mkdir -p $DIR
		#scp $local_copy/xen-unstable-4.2.tgz .
		cd $DIR
		echo $PWD
		tar -xzvf ../xen-unstable-4.2.tgz
		mv ../hgfiles/.*/* .
		mv ../hgfiles/.* .
		cp -a ../persistent_bitmap ./persistent_bitmap
		cp -a ../timeouts ./timeouts
	fi

	echo $PWD
	echo "Going into $DIR"
	#cd $DIR
	echo $PWD

	echo "Initialize and push persistent_bitmap"
	cp -a ../hgext.rc /etc/mercurial/hgrc.d/hgext.rc
	hg qinit
	hg qimport persistent_bitmap
	hg qpush

	echo "Initialize and push timeouts"
	hg qimport timeouts
	hg qpush

	echo "Clean the build before proceeding"
	make clean

	"Configuring"
	echo $PWD
	chmod a+x configure
	./configure --enable-githttp

	echo "Making xen core"
	echo $PWD
	make xen

	echo "Making xen-tools"
	make tools

	make install-xen
	make install-tools PYTHON_PREFIX_ARG=
}


install_drbd_hvm_fix()
{
	echo "Installing DBRD HVM Fix"
	cd $xen_tools_qemu
	if [ "$local" == "true" ]; then
		cp -a $top_dir/drbd-hvm-fix drbd-hvm-fix
	else
		wget $remus_web_path/drbd-hvm-fix
	fi
	patch -p1 <drbd-hvm-fix
	cd $xen_src
	make install-tools PYTHON_PREFIX_ARG=
}

make_linux_kernel()
{
	echo $PWD
	cd $top_dir
	if [ "$remote" == "true" ]; then 
		git clone http://git.kernel.org/pub/scm/linux/kernel/git/jeremy/xen.git $xen_kernel_dir
	else
		scp $local_copy/$xen_kernel_dir.tar.gz .
		mkdir -p $xen_kernel_dir
		cd $xen_kernel_dir && tar -xzvf ../$xen_kernel_dir.tar.gz
		cd ..
	fi	
	#Downloading the two configuration files is disabled. Configuration files are shipped with this script.
	# If downloading from the web, make sure that the changes are made as
	# mentioned in the wiki: http://wiki.xen.org/wiki/Remus
	if [ ! -e "$local_kernel_config" ]; then
		echo "Xen kernel configuration file doesn't exist, downloading..."
		wget $web_kernel_config
	else
		if [ -s "$local_kernel_config" ]; then
			echo "Configuration file is not empty"
		else
			wget $web_kernel_config
		fi
	fi
	
	cd $xen_kernel_dir
	git reset --hard 2b494f184d3337d10d59226e3632af56ea66629a
	
	#After downloading the configuration file if didn't exist before, 
	#then the local variable points correctly to it.
	cp -a ../$local_kernel_config .config
	make menuconfig ARCH=$HOSTTYPE
	make clean
	make
	make modules_install install
	mkinitrd -M System.map /boot/initrd.img-$xen_kernel_version $xen_kernel_version

}

#install DRBD after rebooting in Xen kernel
install_drbd()
{
	zypper install drbd yast2-drbd
}

install_sch_plugin()
{
	#install sch_plugin driver for xen 4.1/4.2 once booted into the new kernel
	wget http://pasik.reaktio.net/xen/remus/linux3x/Makefile
	wget http://pasik.reaktio.net/xen/remus/linux3x/sch_plug.c
	wget http://pasik.reaktio.net/xen/remus/linux3x/sch_plug.c.old
	make 
	make install
}
		 
_cmdline_menu()
{
#Option Menu
PS3='Please enter your choice: '
options=("Prepare" "Xen" "Kernel" "PostInstall" "World" "domU" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Prepare")
		echo "You have chosen to install prerequiste packages"
		check_ocaml_rpms
		install_base_packages
		;;
        "Xen")
		echo "You have chosen Xen install. Will download and build Xen unstable release."
		make_xen_unstable
		install_drbd_hvm_fix
		;;
        "Kernel")
		echo "You have chosen to build only the linux kernel; make sure you have already compiled xen sources."
		make_linux_kernel
		;;
        "PostInstall")
		echo "You have chosen to continue with post install steps."
		install_drbd
		install_sch_plugin
		;;
        "World")
		echo "you chose to install and build all packages (xen, kernel)"
		enable_proxy
		check_ocaml_rpms
		install_base_packages
		make_xen_unstable
		install_drbd_hvm_fix
		make_linux_kernel	
		;;
	"domU")
		echo "Not implemented yet."
		;;
	"Quit")
		break
		;;
        *) echo "Invalid option. Try another one.";continue;;
    esac
done
}

_show_menu()
{
input=/tmp/remus-menu-input
dialog --title "Remus Installation Application" \
           --menu "Please choose an option:" 15 55 5 \
                   1 "Install prerequisite pacakges" \
                   2 "Install and build Xen-Unstable" \
                   3 "Build Linux Kernel" \
                   4 "Execute all above steps" \
                   5 "Install DRBD and SCH plugin" \
                   6 "Build domU xen image" \
                   7 "Exit" 2> $input

retv=$?
choice=$(cat $input)
[ $retv -eq 1 -o $retv -eq 255 ] && exit

trap "rm -f $input" 0 1 2 5 15
clear

case $choice in
    1) 
	echo "You have chosen to install prerequiste packages"
	check_ocaml_rpms
	install_base_packages
        ;;
    2) 
	echo "You have chosen Xen install. Will download and build Xen unstable release."
	make_xen_unstable
	install_drbd_hvm_fix
	;;
    3) 
	echo "You have chosen to build only the linux kernel; make sure you have already compiled xen sources."
	make_linux_kernel
	;;
    4) 
	echo "You have chosen to install and build all packages (xen, kernel)"
	enable_proxy
	check_ocaml_rpms
	install_base_packages
	make_xen_unstable
	install_drbd_hvm_fix
	make_linux_kernel	
	;;
    5) 
	echo "You have chosen to continue with post install steps"
	install_drbd
	install_sch_plugin
	;;
    6)  echo "Not implemented yet."
	;;
    7)  
	exit
	;;

    *) echo "Invalid option. Try another one.";continue;;
   esac
}

_menu_option()
{
#Choose Menu Style (cmdline or dialog)
PS3='Please enter your choice: '
options=("DialogBox" "CommandLine")
select opt in "${options[@]}"
do
    case $opt in
	"DialogBox")
		echo "You have chosen to use the Dialog Box menu; if your machine does not support this, use Command Line menu."
		_show_menu
		break
		;;
	"CommandLine")
		echo "You have chosen to use the Command Line menu."
		_cmdline_menu
		break
		;;
        *) echo "Invalid option. Try another one.";continue;;
    esac
done
}

_main()
{

	#This step is run always to make sure core parameters are set.
	set_mode_dir
	_menu_option

}

_main

