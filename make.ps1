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

function Normalize-Path($path) {
    return $path -replace '\\+', '/'
}

function _To-Linux-Path($path) {
    $matches = @{}
    if ($path -match '^([A-z])\:(.*)$') {
        return "/mnt/$($matches[1].ToLower())$(Normalize-Path $matches[2])"
    }
    $error = New-Object System.FormatException "Wrong Windows path format: $($path)"
    Throw $error
}

function _To-Windows-Path($path) {
    $matches = @{}
    if ($path -match '^/mnt/([A-z])(.*)$') {
        return "$($matches[1]):$($matches[2])"
    }
    $error = New-Object System.FormatException "Wrong Linux path format (must start with /mnt/): $($path)"
    Throw $error
}

function _Read-Config {
    $config = Parse-IniFile ".\config.ini"
    $config["project_path"] = Normalize-Path $config["project_path"]
    $config["idf_path"] = Normalize-Path $config["idf_path"]
    $config["idf_path_linux"] = _To-Linux-Path $config["idf_path"]
    $config["project_path_linux"] = _To-Linux-Path $config["project_path"]
    $config["script_path"] = _To-Linux-Path $PSScriptRoot
    $config["output_file"] = "$($config["script_path"])/output.log"

    $sdk = Parse-IniFile "$($config["project_path"])/sdkconfig"
    $config["port"] = $sdk["CONFIG_ESPTOOLPY_PORT"] -replace '"', ''
    $config["monitor_baud"] = $sdk["CONFIG_MONITOR_BAUD"]

    return $config
}

function _Get-Last-Output {
    Get-content -tail 1 (_To-Windows-Path $config["output_file"])
}

$config = _Read-Config

function _Make-Flash-Command {
    $cmd = _Get-Last-Output
    if (!$cmd.StartsWith("python")) {
        $error = New-Object System.ApplicationException "Flasher command not found. Did the make command run successfull?"
        Throw $error
    }
    $cmd = $cmd -replace $config["idf_path_linux"], $config["idf_path"]
    $cmd = $cmd -replace $config["project_path_linux"], $config["project_path"]

    return $cmd
}

function _ESP32-Make-Command($command) {
    if ($command -eq "all") {
        $command = "all -j$($config["threads"])"
    }
    $cmd = "bash -l -c `"cd $($config["project_path_linux"]) && make $($command) | tee $($config["output_file"])`""
    Invoke-Expression $cmd
 }

function _ESP32-Flash-Command {
    _ESP32-Make-Command "all"
    $cmd = _Make-Flash-Command

    Invoke-Expression $cmd    
}

function _ESP32-Monitor-Command {
    cmd.exe /c "python -m serial.tools.miniterm --rts 0 --dtr 0 --raw $($config["port"]) $($config["monitor_baud"])"
}

function ESP32-Make() {
    if (!$args.Count) {
        $args = @("help")
    }
    $cmd = "Start-Sleep -m 10"

    foreach($arg in $args) {
        if ($arg -eq "flash") {
            $cmd = "$($cmd); _ESP32-Flash-Command"
        } elseif ($arg -eq "monitor") {
            $cmd = "$($cmd); _ESP32-Monitor-Command"
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
            $cmd = "$($cmd); _ESP32-Make-Command $($arg)"
        }
    }

    Invoke-Expression $cmd
}
