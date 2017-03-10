# Change Log

[0.9.1](#) (2017-03-07)
* Get `drive_letter` from project path
* Parse `ESP32-Make all` output and use that for the `ESP32-Make flash` by replacing the paths
* Removed `port`, `flash_baud` and `monitor_baud`. These are now taken from the `sdkconfig` config file
* Added `coredump` parse functionality. To use this create a file called `core.dat` in your project root and copy the ESP32 coredup string. After run `ESP32-Make coredump`.
* Parse the `sdkconfig` config file for data

[0.9.0](#) (2017-03-05) 
* Initial release
