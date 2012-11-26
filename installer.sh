#!/usr/bin/env bash

########################################
# Facebook HipHop All-in-one Installer #
# Version: v1.0 Beta                   #
# Support Platforms                    #
# - Ubuntu 12.04 64bit                 #
# - Centos 6.3 64bit                   #
########################################
# Author: Everright.Chen               #
# URL:    www.everright.cn             #
# Email:  everright.chen@gmail.com     #
########################################
OS_ID=$(lsb_release -si)
OS_VER=$(lsb_release -sr)
OS_ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
OS_CURRENT="${OS_ID} ${OS_VER} ${OS_ARCH}"
OS_SUPPORT="Ubuntu 12.04 64:CentOS 6.3 64"

PROFILE='/etc/profile'

LIBEVENT_VERSION='1.4.14b-stable'
LIBEVENT_PATCH_VERSION='1.4.14'
LIBCURL_VERSION='master'
LIBCURL_PATCH_VERSION='7.22.1'
LIBMCRYPT_VERSION='2.5.8-9.el6.x86_64'
JEMALLOC_VERSION='3.2.0'
LIBUNWIND_VERSION='1.0.1'
LIBMEMCACHED_VERSION='0.49'
TBB_VERSION='40_20111130oss'

LIBDWARF_GIT='git://libdwarf.git.sourceforge.net/gitroot/libdwarf/libdwarf'
HIPHOP_PHP_GIT='git://github.com/facebook/hiphop-php.git'
HIPHOP_NAME='hiphop-php'
PREFIX_PATH='/opt/hiphop-allinone'
CURRENT_PATH="$(pwd)"

## OS Support
function p_os_support() {
    IFS=: OSS=($OS_SUPPORT);
    for OS in "${OSS[@]}"
    do
        echo -ne " - ${OS}\n"
    done
    echo ""
}

## Introduce
function p_introduce() {
    echo -ne "Welcome to use Facebook HipHop All-in-one Installer\n\n"
    echo -ne "########################################\n"
    echo -ne "# Facebook HipHop All-in-one Installer #\n"
    echo -ne "# Version: v1.0 Beta                   #\n"
    echo -ne "# Support Platforms                    #\n"
    echo -ne "# - Ubuntu 12.04 64bit                 #\n"
    echo -ne "# - CentOS 6.3 64bit                   #\n"
    echo -ne "########################################\n"
    echo -ne "# Author: Everright.Chen               #\n"
    echo -ne "# URL:    www.everright.cn             #\n"
    echo -ne "# Email:  everright.chen@gmail.com     #\n"
    echo -ne "########################################\n"
    echo -ne "\nSudo or run this script as root\n\n"
}

## Check platform support and install confirm
function os_support() {
    local support="no"

    IFS=: OSS=($OS_SUPPORT);
    for OS in "${OSS[@]}"
    do
        if [ "$OS" == "$OS_CURRENT" ]; then
            support="yes"
            break;
        fi
    done

    if [ "no" == "$support" ]; then
        echo -ne "Your current OS Platform is: [${OS_CURRENT}]\n\n"
        echo -ne "This script only supoort these platforms\n\n"
        p_os_support
        exit 1
    elif [ "yes" == "$support" ]; then
        echo -ne "Your current OS Platform is: [${OS_CURRENT}]\n\n"
        while (true); do
            echo -ne "Are you sure you want to start the installation? [y/n]:"
            read ANSWER
            if [ "y" == "$ANSWER" ]; then
                break;
            elif [ "n" == "$ANSWER" ]; then
                exit 1
            fi
        done
    else
        exit 1
    fi
}

## Install all package dependencies
function install_dependencies() {
    echo -n "Update & Install package dependencies."
    if [ "Ubuntu" == "$OS_ID" ]; then
        apt-get update -y
        apt-get install -y git-core cmake g++ libboost-dev libmysqlclient-dev libxml2-dev libmcrypt-dev libicu-dev openssl build-essential binutils-dev libcap-dev libgd2-xpm-dev zlib1g-dev libtbb-dev libonig-dev libpcre3-dev autoconf libtool libcurl4-openssl-dev libboost-system-dev libboost-program-options-dev libboost-filesystem-dev wget memcached libreadline-dev libncurses-dev libmemcached-dev libbz2-dev libc-client2007e-dev php5-mcrypt php5-imagick libgoogle-perftools-dev libcloog-ppl0 libelf-dev libdwarf-dev libunwind7-dev
    elif [ "CentOS" == "$OS_ID" ]; then
        yum update -y
        yum install -y git svn cpp make autoconf automake libtool patch memcached gcc-c++ cmake wget boost-devel mysql-devel pcre-devel gd-devel libxml2-devel expat-devel libicu-devel bzip2-devel oniguruma-devel openldap-devel readline-devel libc-client-devel libcap-devel binutils-devel pam-devel elfutils-libelf-devel
    fi
}

## Enter to install path
function setup_prefix() {
    if [ ! -d "$PREFIX_PATH" ]; then
        echo "Create prefix path ${PREFIX_PATH}"
        mkdir -p "$PREFIX_PATH"
    fi
    echo "Enter prefix path."
    cd "$PREFIX_PATH"
}

## Cleanup temp files
function clean_files() {
    echo "Cleaning temp files..."
    rm -rf libevent-${LIBEVENT_VERSION} curl-${LIBCURL_VERSION} jemalloc-${JEMALLOC_VERSION}
    if [ "CentOS" == "$OS_ID" ]; then
        rm -rf libunwind-${LIBUNWIND_VERSION} libmemcached-${LIBMEMCACHED_VERSION} tbb${TBB_VERSION} libdwarf usr
    fi
}

## Download files
function download_file() {
    local name=$1
    local url=$2
    if [ -n "$name" -a -n "$url" ]; then
        if [ ! -f "$name" ]; then
            echo "Downloading ${name}"
            wget -q "$url" -O "$name"
            if [ $? -eq 0 ]; then
                echo " > DONE"
            else
                echo " > Failed to download ${name}"
                exit 1
            fi
        fi
    fi
}

## Fetch libraries
function fetch_libraries() {
    echo "Downloading library dependencies."

    # libevent
    download_file "libevent-${LIBEVENT_VERSION}.tar.gz" "https://github.com/downloads/libevent/libevent/libevent-${LIBEVENT_VERSION}.tar.gz"
    # curl
    download_file "curl-${LIBCURL_VERSION}.tar.gz" "https://github.com/bagder/curl/archive/master.tar.gz"
    # jemalloc
    download_file "jemalloc-${JEMALLOC_VERSION}.tar.bz2" "http://www.canonware.com/download/jemalloc/jemalloc-${JEMALLOC_VERSION}.tar.bz2"

    if [ 'CentOS' == ${OS_ID} ]; then
        # libmcrypt
        download_file "libmcrypt-devel-${LIBMCRYPT_VERSION}.rpm" "ftp://rpmfind.net/linux/epel/beta/6/x86_64/libmcrypt-devel-${LIBMCRYPT_VERSION}.rpm"
        download_file "libmcrypt-${LIBMCRYPT_VERSION}.rpm" "ftp://rpmfind.net/linux/epel/beta/6/x86_64/libmcrypt-${LIBMCRYPT_VERSION}.rpm"
        # libunwind
        download_file "libunwind-${LIBUNWIND_VERSION}.tar.gz" "http://download.savannah.gnu.org/releases/libunwind/libunwind-${LIBUNWIND_VERSION}.tar.gz"
        # libmemcached
        download_file "libmemcached-${LIBMEMCACHED_VERSION}.tar.gz" "http://launchpad.net/libmemcached/1.0/0.49/+download/libmemcached-${LIBMEMCACHED_VERSION}.tar.gz"
        # tbb
        download_file "tbb${TBB_VERSION}.tgz" "http://threadingbuildingblocks.org/sites/default/files/software_releases/source/tbb${TBB_VERSION}_src.tgz"

    fi
}

## Git clone file
function git_clone() {
    local url=$1
    local name=$2

    if [ -n "$url" ]; then
        echo " > Git clone from ${url}"
        if [ -z "$name" ]; then
            name=$url
            git clone -q "$url"
        else
            git clone -q "$url" "$name"
        fi
        if [ $? -eq 0 ]; then
            echo " > DONE"
        else
            echo " > Failed to download ${name}"
            exit 1
        fi  
    fi
}

## Fetch hiphop
function fetch_hiphop() {
    if [ ! -d ${HIPHOP_NAME} ]; then
        echo "Downloading HipHop-PHP."
        git_clone "$HIPHOP_PHP_GIT" "$HIPHOP_NAME"
    else
        while (true); do
            echo -ne "Directory ${HIPHOP_NAME} exist, do you want to rebuild? [y/n]"
            read answer
            if [ "n" == "$answer" ]; then
                rm -rf ${HIPHOP_NAME}
                echo "Downloading HipHop-PHP."
                git_clone "$HIPHOP_PHP_GIT" "$HIPHOP_NAME"

                break;
            elif [ "y" == "$answer" ]; then
                if [ -f "${HIPHOP_NAME}/CMakeCache.txt" ]; then
                    echo "Clean Hiphop make cache."
                    rm -f CMakeCache.txt
                fi

                break;
            fi
        done
    fi
}

## Setup environmental variables
function setup_environment() {
    echo "Initial setup environment."
    cd ${HIPHOP_NAME}
    export CMAKE_PREFIX_PATH=`/bin/pwd`/..
    if [ "CentOS" == "$OS_ID" ]; then
        export CMAKE_PREFIX_PATH=`/bin/pwd`/../usr
    fi
    export HPHP_HOME=`/bin/pwd`
    export HPHP_LIB=`/bin/pwd`/bin
    export USE_HHVM=1
    cd ..
}

## libmcrypt
function install_lib_libmcrypt() {
    echo "Install libmcrypt."
    rpm -i libmcrypt-*.rpm
}

## libevent
function install_lib_libevent() {
    echo "Install libevent-${LIBEVENT_VERSION}."
    tar xvzf libevent-${LIBEVENT_VERSION}.tar.gz
    cd libevent-${LIBEVENT_VERSION}
    cat ../${HIPHOP_NAME}/src/third_party/libevent-${LIBEVENT_PATCH_VERSION}.fb-changes.diff | patch -p1
    ./autogen.sh
    ./configure --prefix=${CMAKE_PREFIX_PATH}
    make && make install

    if [ $? -eq 0 ]; then
        echo " > DONE"
    else
        echo " > Failed to install libevent-${LIBEVENT_VERSION}."
        exit 1
    fi

    cd ..
}

## libCurl
function install_lib_libcurl() {
    echo "Install curl-${LIBCURL_VERSION}."
    tar xvzf curl-${LIBCURL_VERSION}.tar.gz
    cd curl-${LIBCURL_VERSION}
    if [ -z ${LIBCURL_PATCH_VERSION} ]; then
        cat ../${HIPHOP_NAME}/src/third_party/libcurl.fb-changes.diff | patch -p1
    else
        cat ../${HIPHOP_NAME}/src/third_party/libcurl-${LIBCURL_PATCH_VERSION}.fb-changes.diff | patch -p1
    fi
    ./buildconf
    ./configure --prefix=${CMAKE_PREFIX_PATH}
    make && make install

    if [ $? -eq 0 ]; then
        echo " > DONE"
    else
        echo " > Failed to install curl-${LIBCURL_VERSION}."
        exit 1
    fi

    cd ..
}

## jemalloc
function install_lib_jemalloc() {
    echo "Install jemalloc-${JEMALLOC_VERSION}."
    tar xvjf jemalloc-${JEMALLOC_VERSION}.tar.bz2
    cd jemalloc-${JEMALLOC_VERSION}
    ./configure --prefix=${CMAKE_PREFIX_PATH}
    make && make install

    if [ $? -eq 0 ]; then
        echo " > DONE"
    else
        echo " > Failed to install jemalloc-${JEMALLOC_VERSION}."
        exit 1
    fi

    cd ..
}

## libunwind
function install_lib_libunwind() {
    echo "Install libunwind-${LIBUNWIND_VERSION}."
    tar xvzf libunwind-${LIBUNWIND_VERSION}.tar.gz
    cd libunwind-${LIBUNWIND_VERSION}
    autoreconf -i -f
    ./configure --prefix=$CMAKE_PREFIX_PATH
    make && make install

    if [ $? -eq 0 ]; then
        echo " > DONE"
    else
        echo " > Failed to install libunwind-${LIBUNWIND_VERSION}."
        exit 1
    fi

    cd ..
}

## libmemcached
function install_lib_libmemcached() {
    echo "Install libmemcached-${LIBMEMCACHED_VERSION}."
    tar xvzf libmemcached-${LIBMEMCACHED_VERSION}.tar.gz
    cd libmemcached-${LIBMEMCACHED_VERSION}
    ./configure --prefix=$CMAKE_PREFIX_PATH
    make && make install

    if [ $? -eq 0 ]; then
        echo " > DONE"
    else
        echo " > Failed to install libmemcached-${LIBMEMCACHED_VERSION}."
        exit 1
    fi

    cd ..
}

## tbb
function install_lib_tbb() {
    echo "Install tbb${TBB_VERSION}."
    tar xvzf tbb${TBB_VERSION}.tgz
    cd "tbb${TBB_VERSION}"
    make

    mkdir -p /usr/include/serial
    cp -a include/serial/* /usr/include/serial/

    mkdir -p /usr/include/tbb
    cp -a include/tbb/* /usr/include/tbb/

    cp build/linux_intel64_gcc_cc4.4.6_libc2.12_kernel2.6.32_release/libtbb.so.2 /usr/lib64/
    ln -fs /usr/lib64/libtbb.so.2 /usr/lib64/libtbb.so
    cd ..
}

## libdwarf
function install_lib_libdwarf() {
    git_clone "$LIBDWARF_GIT"
    echo "Install libdwarf."
    cd libdwarf/libdwarf
    ./configure
    make
    
    if [ ! -d "${CMAKE_PREFIX_PATH}/lib64" ]; then
        mkdir "${CMAKE_PREFIX_PATH}/lib64"
    fi
    cp libdwarf.a $CMAKE_PREFIX_PATH/lib64/
    cp libdwarf.h $CMAKE_PREFIX_PATH/include/
    cp dwarf.h $CMAKE_PREFIX_PATH/include/
    cd ../..
}

## Symbolically link to bins
function setup_bin() {
    ln -fs ${PREFIX_PATH}/${HIPHOP_NAME}/src/hphp/hphp /usr/bin/hphp
    ln -fs ${PREFIX_PATH}/${HIPHOP_NAME}/src/hhvm/hhvm /usr/bin/hhvm
}

## Set HPHP_HOME more permanently
function setup_hphp_home() {
    if grep -q 'HPHP_HOME=' ${PROFILE}; then
        sed '/HPHP_HOME=/d' ${PROFILE} > tmp_sed;cat tmp_sed > ${PROFILE};rm -f tmp_sed;
    fi
    echo "HPHP_HOME='${PREFIX_PATH}/${HIPHOP_NAME}'" >> ${PROFILE}
    source ${PROFILE}
}

## Install library dependencies
function install_libraries() {
    echo "Installing library dependencies."
    install_lib_libevent
    install_lib_libcurl
    install_lib_jemalloc
    if [ "CentOS" == "$OS_ID" ]; then
        install_lib_libmcrypt
        install_lib_libunwind
        install_lib_libmemcached
        install_lib_tbb
        install_lib_libdwarf
    fi
}

## Begin setup
function setup_begin() {
    p_introduce
    os_support
    install_dependencies
    setup_prefix
    clean_files
    fetch_libraries
    fetch_hiphop
    setup_environment
    install_libraries
}

## Build HipHop
function setup() {
    echo "Installing HipHop-PHP."
    cd ${HIPHOP_NAME}
    git submodule init
    git submodule update
    export HPHP_HOME=`pwd`
    export HPHP_LIB=`pwd`/bin
    cmake . && make

    if [ $? -ne 0 ]; then
        echo " > Failed to make ${HIPHOP_NAME}."
        exit 1
    fi
}

## Setting & clean
function setup_done() {
    setup_bin
    setup_hphp_home
    clean_files
    ## Return previous path
    cd ${CURRENT_PATH}
    ## Success
    echo "HipHop-PHP is now installed!"
    exit 0
}

## Run
setup_begin
setup
setup_done
