# `alpine-uboot`

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)  [![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/) [![Check the NOTICE](https://img.shields.io/badge/Check%20the-NOTICE-420C3B.svg)](./NOTICE)

Otherwise known as generic ARM

I spent a day trying to set up an ARM machine like an amd64 machine. I am not a smart man.

This doesn't and won't work.

## Dependencies

* `qemu`: In order for this to run, `qemu` must have ARM support.

    ```
    $ qemu-system-arm
    zsh: command not found: qemu-system-arm
    ```
    You may be able to get away with vanilla repos.
    ```
    sudo apt-get install -y qemu qemu-system-arm
    ```
    Compare the last of provided machines with the machines `u-boot` supports for a good measure.
    ```
    qemu-system-arm -machine help
    ```

    If you're a glutton for punishment like me, you [can build from source](https://wiki.qemu.org/Documentation).

    We'll also need `qemu-arm-static` which can be installed or built.
