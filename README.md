# rx-gcc-docker
Docker with GCC toolchain for Renesas RX microcontrollers

I use this Docker for playing with YRDKRX62N development board.

Before building image download **JLink_Linux_V760a_x86_64.tgz** from [Segger](https://www.segger.com/downloads/jlink/)
and put it to **segger** folder.

Then build the image:

        sudo docker build --tag rx_img .
