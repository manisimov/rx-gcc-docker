# rx-gcc-docker
Docker with GCC toolchain for Renesas RX microcontrollers

I use this Docker for playing with [YRDKRX62N](https://www.renesas.com/us/en/products/microcontrollers-microprocessors/rx-32-bit-performance-efficiency-mcus/yrdkrx62n-yrdkrx62n-demonstration-kit-rx62n) development board.

Before building image download **JLink_Linux_V760a_x86_64.tgz** from [Segger](https://www.segger.com/downloads/jlink/)
and put it to **segger** folder.

Then build the image:

        sudo docker build --tag rx_img .
        
As an example of the container usage see my YRDKRX62N [template project](https://github.com/manisimov/rx-template)

# Windows

On windows you would probably need to change **nano_copy.sh** line endings to Unix format.

For example in Notepad++:

* Open nano_copy.sh
* Edit -> EOL Conversion -> Unix
* Save the file
