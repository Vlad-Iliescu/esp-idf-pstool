function Parse-IniFile ($file) {
    # Thanks to http://stackoverflow.com/a/422529/1306490
    $ini = @{}

    # Create a default section if none exist in the file. Like a java prop file.
    $section = "DEFAULT"
    $ini[$section] = @{}

    switch -regex -file $file {
        "^\[(.+)\]$" {
            $section = $matches[1].Trim()
            $ini[$section] = @{}
        }
        "^\s*([^#].+?)\s*=\s*(.*)" {
            $name,$value = $matches[1..2]
            # skip comments that start with semicolon:
            if (!($name.StartsWith(";"))) {
                $ini[$section][$name] = $value.Trim()
            }
        }
    }
    $ini["DEFAULT"]
}

$config = Parse-IniFile(".\config.ini");
$config["drive_letter"] = $config["project_path"].Substring(0,1).ToLower()

function ESP32-Make-Command($command) {
    if ($command -eq "all") {
        $command = "all -j$($config["threads"])"
    }
    bash -l -c "cd /mnt/$($config["drive_letter"])$($config["project_path"]) && make $($command)"
 }

function ESP32-Flash-Command {
    ESP32-Make-Command "all"
    $cmd =  "python $($config["idf_path"])/components/esptool_py/esptool/esptool.py " +
        "--chip esp32 --port $($config["port"]) --baud $($config["flash_baud"]) --before esp32r0 " + 
        "--after hard_reset write_flash -u --flash_mode dio --flash_freq 40m --flash_size detect " + 
        "0x1000 $($config["drive_letter"]):$($config["project_path"])/build/bootloader/bootloader.bin " + 
        "0x10000 $($config["drive_letter"]):$($config["project_path"])/build/p1p.bin " + 
        "0x8000 $($config["drive_letter"]):$($config["project_path"])/build/partitions_singleapp.bin"

    Invoke-Expression $cmd
}

function ESP32-Monitor-Command {
    cmd.exe /c "python -m serial.tools.miniterm --rts 0 --dtr 0 --raw $($config["port"]) $($config["monitor_baud"])"
}

function ESP32-Make() {
    if (!$args.Count) {
        $args = @("help")
    }
    $cmd = "Start-Sleep -m 10"

    foreach($arg in $args) {
        if ($arg -eq "flash") {
            $cmd = "$($cmd); ESP32-Flash-Command"
        } elseif ($arg -eq "monitor") {
            $cmd = "$($cmd); ESP32-Monitor-Command"
        } elseif ($arg -eq "help") {
            write-host ""
            write-host "Welcome to Espressif IDF build system porting to PowerShell. Some useful make targets:" -foreground "green"
            write-host "" -foreground "green"
	        write-host "make menuconfig" -NoNewline -foreground "yellow"; write-host " - Configure IDF project" -foreground "green"
	        write-host "make defconfig" -NoNewline -foreground "yellow"; write-host " - Set defaults for all new configuration options" -foreground "green"
	        write-host ""
	        write-host "make all" -NoNewline -foreground "yellow"; write-host " - Build app, bootloader, partition table" -foreground "green"
	        write-host "make flash" -NoNewline -foreground "yellow"; write-host " - Flash app, bootloader, partition table to a chip" -foreground "green"
	        write-host "make clean" -NoNewline -foreground "yellow"; write-host " - Remove all build output" -foreground "green"
	        write-host "make size" -NoNewline -foreground "yellow"; write-host " - Display the memory footprint of the app" -foreground "green"
	        write-host "make erase_flash" -NoNewline -foreground "yellow"; write-host " - Erase entire flash contents" -foreground "green"
	        write-host "make monitor" -NoNewline -foreground "yellow"; write-host " - Display serial output on terminal console" -foreground "green"
	        write-host ""
	        write-host "make app" -NoNewline -foreground "yellow"; write-host " - Build just the app" -foreground "green"
	        write-host "make app-flash" -NoNewline -foreground "yellow"; write-host " - Flash just the app" -foreground "green"
	        write-host "make app-clean" -NoNewline -foreground "yellow"; write-host " - Clean just the app" -foreground "green"
	        write-host ""
	        write-host "See also 'make bootloader', 'make bootloader-flash', 'make bootloader-clean', " -foreground "green"
	        write-host "'make partition_table', etc, etc." -foreground "green"
	        write-host ""
        } else {
            $cmd = "$($cmd); ESP32-Make-Command $($arg)"
        }
    }

    Invoke-Expression $cmd
}
