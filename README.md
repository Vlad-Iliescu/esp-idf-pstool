ESP32 Windows 10 toolchain using developer mode bash
====================================================

This guide will walk you to the process of installing [ESP-IDF](https://github.com/espressif/esp-idf) toolchain 
using Developer mode Subsystem for Linux (Ubuntu 14) and some PowerShell scripts. 

!!Please note that this is still a beta and some problems may arise.!!

##Step 1: Install `bash` on windows
Some good guides for this can be found [here](http://www.windowscentral.com/how-install-bash-shell-command-line-windows-10)
and [here](http://www.windowscentral.com/how-install-bash-shell-command-line-windows-10). Just follow the steps there and 
you sould be ready to go.

## Step 2: Install ESP-IDF environment
Please refer to the original ESP-IDF [Linux documentation](https://esp-idf.readthedocs.io/en/latest/linux-setup.html) for more details

This guide assumes that you have your project directory is `D:/esp32/project`, your esp-idf will be installed in `D:/esp32/esp-idf`
and toolchain will be installed in `D:/esp32/xtensa-esp32-elf`
If you change this please adjust accordingly.

### 2.1 Run `bash` console
You can do this by running the `Bash on Ubuntu on Windows` application or by typing `bash` in a cmd window.
### 2.2 Install packages
`sudo apt-get install git wget make libncurses-dev flex bison gperf python python-serial`
### 2.3 Download binary toolchain
Again refer to the documentation for newer binaries.
 `https://dl.espressif.com/dl/xtensa-esp32-elf-linux64-1.22.0-61-gab8375a-5.2.0.tar.gz`
### 2.4 Extract
```
tar -xvf xtensa-esp32-elf-linux64-1.22.0-61-gab8375a-5.2.0.tar.gz
mv xtensa-esp32-elf /mnt/d/esp32/
```
### 2.5 Clone the esp-idf
```
git clone --recursive https://github.com/espressif/esp-idf.git
cd esp-idf
git submodule update --init
mv esp-idf/ /mnt/d/esp32/
```
### 2.6 Export paths
```
export IDF_PATH=/mnt/d/esp32/esp-idf
export PATH=/mnt/d/esp32/xtensa-esp32-elf/bin:$PATH
```
Also add this to `~/.profile` file.
`nano ~/.profile` paste at the end and save file.

## Step 3: Setup project
### 3.1 Clone template
```
cd /mnt/d/esp32
git clone https://github.com/espressif/esp-idf-template project
```
### 3.2 Clone tool
```
cd /mnt/d/esp32
git clone https://github.com/Vlad-Iliescu/esp-idf-pstool.git
cd esp-idf-pstool/
```
### 3.3 Add config
```
cp config.ini.dist config.ini
```
Now edit `config.ini` in accordance to your setup

## Step 4: Import and use the PowerShell functions
### 4.1 Install python 
I use python 3.6, but it should work with any python installation. After istalll make sure you add python to path.
### 4.2 Install pyserial
`pip install pyserial`
### 4.3 Start PowerShell
Either by running `Windows PowerShell` app or by typing powershell in a cmd window.
### 4.4 Navigate to project tool
`cd .\esp32\esp-idf-pstool`
### 4.5 Import
`. .\make.ps1`

### Step 5: Use `ESP32-Make`
Type `ESP32-Make` for a list of known commands

### [A bit of history on how I got to this solution](https://github.com/Vlad-Iliescu/esp-idf-pstool/wiki/history)
 
### TODOs:
1. `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force;`
