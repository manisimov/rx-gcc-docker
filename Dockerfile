FROM ubuntu:focal

ARG DEBIAN_FRONTEND=noninteractive

##################################################################
# 1 - SOURCES
##################################################################


# [1] Install packages

RUN apt-get update

RUN  apt-get install dialog apt-utils -y --no-install-recommends

RUN  apt-get install build-essential -y --no-install-recommends; \
     apt-get update;                                             \
     apt-get upgrade;                                            \
     apt-get install \
             flex    \
             bison   \
             texinfo \
             libncurses5-dev \
             autoconf \
             wget \
             unzip \
             cmake \
             automake \
             git \
             ca-certificates \
             libreadline-dev \
             python-dev     \
             -y --no-install-recommends;


# [2] Download sources

RUN  mkdir home/RX-Toolchain; \
     mkdir home/sources;      \
     mkdir home/build;        \
     mkdir home/prefix;

WORKDIR home/sources

RUN wget -O gdb.zip      https://llvm-gcc-renesas.com/downloads/d.php?f=rx/gdb/8.3.0.202104-gnurx/gdb_rx_7.8.2_2021q4.zip
RUN wget -O binutils.zip https://llvm-gcc-renesas.com/downloads/d.php?f=rx/binutils/8.3.0.202104-gnurx/binutils_rx_2.36.1_2021q4.zip
RUN wget -O newlib.zip   https://llvm-gcc-renesas.com/downloads/d.php?f=rx/newlib/8.3.0.202104-gnurx/newlib_rx_3.1.0_2021q4.zip
RUN wget -O gcc.zip      https://llvm-gcc-renesas.com/downloads/d.php?f=rx/gcc/8.3.0.202104-gnurx/gcc_rx_8.3.0_2021q4.zip

RUN unzip gdb.zip
RUN unzip binutils.zip
RUN unzip newlib.zip
RUN unzip gcc.zip


WORKDIR /home/sources/cgdb
RUN git clone https://github.com/cgdb/cgdb.git
RUN cd cgdb && git checkout v0.7.1



#############################################################
# 2 - BUILD
#############################################################

WORKDIR /home/build


########
# CGDB
########

WORKDIR /home/sources/cgdb/cgdb
RUN ./autogen.sh
RUN mkdir /home/build/cgdb
WORKDIR /home/build/cgdb
RUN /home/sources/cgdb/cgdb/configure --prefix=/home/prefix/cgdb
RUN make -j6
RUN make install

ENV PATH=${PATH}:/home/prefix/cgdb/bin
WORKDIR /home/build


#############
# binutils
#############

RUN mkdir binutils
WORKDIR /home/build/binutils
RUN chmod +x /home/sources/binutils-2.36.1/configure
RUN chmod +x /home/sources/binutils-2.36.1/mkinstalldirs
RUN /home/sources/binutils-2.36.1/configure --target=rx-elf --prefix=/home/prefix --disable-werror
RUN touch $(find /home/sources/binutils-2.36.1 -name aclocal.m4)
RUN touch $(find /home/sources/binutils-2.36.1 -name Makefile.in)
RUN touch /home/sources/binutils-2.36.1/configure
RUN make -j6
RUN make install

ENV PATH=${PATH}:/home/prefix/bin


################
# GCC
################

WORKDIR /home/build

RUN cd /home/sources/gcc-8.3.0 && \
    chmod +x ./contrib/download_prerequisites && \
    ./contrib/download_prerequisites

RUN mkdir gcc
WORKDIR /home/build/gcc
RUN chmod +x /home/sources/gcc-8.3.0/configure
RUN chmod +x /home/sources/gcc-8.3.0/move-if-change
RUN /home/sources/gcc-8.3.0/configure --target=rx-elf --prefix=/home/prefix --enable-languages=c,c++ --disable-shared --with-newlib --enable-lto --enable-gold --disable-libstdcxx-pch --with-pkgversion=GCC_Build_1.02
RUN make all-gcc -j6
RUN make install-gcc


#############
# Newlib Nano
#############

WORKDIR /home/build
RUN mkdir newlib_nano
WORKDIR /home/build/newlib_nano
RUN chmod +x /home/sources/newlib/configure
RUN /home/sources/newlib/configure --target=rx-elf --prefix=/home/prefix_nano  \
                                   CFLAGS_FOR_TARGET=-Os                       \
                                   -enable-newlib-reent-small                  \
                                   -disable-newlib-fvwrite-in-streamio         \
                                   -disable-newlib-fseek-optimization          \
                                   -disable-newlib-wide-orient                 \
                                   -enable-newlib-nano-malloc                  \
                                   -disable-newlib-unbuf-stream-opt            \
                                   -enable-newlib-nano-formatted-io            \
                                   -disable-nls
RUN make -j6
RUN make install


#############
# Newlib
#############

WORKDIR /home/build
RUN mkdir newlib
WORKDIR /home/build/newlib
RUN chmod +x /home/sources/newlib/configure
RUN /home/sources/newlib/configure --target=rx-elf --prefix=/home/prefix
RUN make -j6
RUN make install


##################
# Copy nano libs
##################

COPY nano_copy.sh /home
RUN chmod +x /home/nano_copy.sh && /home/nano_copy.sh


############
# GDB
############

WORKDIR /home/build
RUN mkdir gdb
WORKDIR /home/build/gdb
RUN chmod a+x -R /home/sources/gdb/configure
RUN chmod a+x -R /home/sources/gdb/mkinstalldirs
RUN chmod a+x -R /home/sources/gdb/gdb/observer.sh
WORKDIR /home/build/gdb/gdb
RUN wget -O gdb_patch1.patch https://llvm-gcc-renesas.com/wiki/patches/c_exp_128bit_.patch
RUN wget -O gdb_patch2.patch https://llvm-gcc-renesas.com/wiki/patches/c_exp_128bit_.patch
RUN patch -R gdb_patch1.patch
RUN patch gdb_patch2.patch
WORKDIR /home/build/gdb
RUN /home/sources/gdb/configure --target=rx-elf --prefix=/home/prefix --with-python=/usr/bin/python
RUN make -j6
RUN make install


###############
# GCC final
###############

WORKDIR /home/build/gcc
RUN chmod +x /home/sources/gcc-8.3.0/libgcc/mkheader.sh
RUN make -j6
RUN make install

# TODO : make gcc final for nano.
#        add cpp library to nano_copy.sh
#        move "Copy nano libs" step after that


######################################################################################
# 3 - JLINK
######################################################################################

RUN mkdir /home/JLINK
WORKDIR /home/JLINK
COPY segger /home/JLINK
RUN tar xvf JLink_Linux_V760a_x86_64.tgz
ENV PATH=${PATH}:/home/JLINK/JLink_Linux_V760a_x86_64



WORKDIR /
