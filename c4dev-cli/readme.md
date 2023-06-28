# User Manual: How to Use c4dev.exe

## Installation of c4dev.exe for Control4 Driver Development

The installation process is very simple: just add the folder
 
 `PATH_TO_CODE_FOLDER\dist` 
 
 to the Windows PATH. To learn how to do this, you can refer to this link: https://www.java.com/en/download/help/path.xml


## Quick Start

The tool is used from the command line and works in both Batch and PowerShell environments.

To see a quick summary of available commands and parameters, simply run the command with the `--help` parameter, like this: `c4dev.exe --help`

To use the command, navigate to the folder that contains the driver.xml file and the `.c4zproj` file.

From this folder, you can:

* automatically update the version and last modified date/time with the command `c4dev.exe update`
* compile the driver into a `.c4z` file using the command `c4dev.exe compile`. The package will be saved in the `.\no_crypt\` folder.
* validate the newly generated `.c4z` file with the simple command `c4dev.exe validate`
* install the file in Composer using the command `c4dev.exe install`

If you want to compile and validate in sequence (without updating driver.xml), use `c4dev.exe build`.

If you want to perform all operations with a single command, use `c4dev.exe all`: driver.xml will be updated, the driver will be compiled, validated, and installed.

When you are ready to send the driver to your beta testers, use `c4dev.exe all --release beta`: this command will save a compiled version of the driver in the `.\encrypted\` folder.

When you are ready to distribute the driver, use `c4dev.exe all --release production`: this command will save a compiled version of the driver in the `.\encrypted\` folder after setting the version number according to the rules for a release-ready driver (see the description of the `update` command below).

## c4dev.exe Command and Parameter Guide

### General Parameters

The `--verbose` (`-v`) parameter sets the logging level for program messages. The allowed values are: `info`, `debug`, `warning`, `error`, and `critical`. If not specified, the default level is `error`.


### `update` Command

The `update` command updates the driver.xml file, modifying the version and date. It also enables or disables driver encryption.

If no other parameters are provided, it performs the following actions:

* increments the version number by 1
* sets the current date and time as the last modification date and time of the driver
* disables encryption

The version number follows the following convention:

* It is a number with at least 4 digits.
* If it ends with a sequence of three zeros, it indicates a production driver or a beta version for public testing (i.e., a number rounded to the nearest thousand).
* If the last three digits are not zeros, they represent development versions (internal).

Example: version 001034 ends with '034', indicating a development version; version 023000 ends with '000', indicating a test version or a public release.


The `--release` (`-r`) parameter modifies how the version number is calculated and whether encryption is enabled or not:

* If `--release beta` is specified, the version number is rounded to the next thousand and encryption is disabled.

* If `--release production` is specified, the version number is rounded to the next thousand and encryption is enabled.

However, it is possible to set a specific version number using the `--version` (`-V`) parameter, followed by the desired version number. When this parameter is used, the `--release` parameter does not affect the version number.

The `--encrypt` (`-e`) parameter allows you to force the enabling or disabling of encryption regardless of the `--release` settings:

* If `--encrypt on` is specified, driver encryption is enabled.
* If `--encrypt off` is specified, driver encryption is disabled.
* If `--encrypt auto` is specified, the program decides based on the `--release` rules described above (this is the default value).

The `--jit` (`-j`) parameter allows you to force the enabling or disabling of JIT (Just-In-Time) support:

* If `--jit on` is specified, JIT support is enabled.
* If `--jit off` is specified, JIT support is disabled.
* If `--jit auto` is specified, the existing value remains unchanged.

The `--path` (`-p`) parameter defines the working directory. It should be set to the directory that contains the `driver.xml` file and the `.c4zproj` project file of the driver. The default value is the current directory.

The `--output-path` (`-o`) parameter specifies the folder where the generated `.c4z` files will be saved. If the parameter is not provided, the default value depends on whether `--release production` is specified or not. It will be `WORKING_DIRECTORY/no_crypt` if not specified, or `WORKING_DIRECTORY/encrypted` if `--release production` is present.


### `compile` Command

The `compile` command uses the Control4 _DriverPackager.exe_ program to compile and package the driver source code into a `.c4z` file.

Encryption preferences are retrieved from the `driver.xml` file and the `.c4zproj` file.

The generated `.c4z` package will have the name specified within the `.c4zproj` file.

The `--path` (`-p`) parameter defines the working directory. It should be set to the directory that contains the `driver.xml` file and the `.c4zproj` project file of the driver. The default value is the current directory.

The `--output-path` (`-o`) parameter indicates the folder where the generated `.c4z` files will be saved. If the parameter is not provided, the default value depends on whether `--release production` is specified or not. It will be `WORKING_DIRECTORY/no_crypt` if not specified, or `WORKING_DIRECTORY/encrypted` if `--release production` is present.

The `--driver-editor` parameter defines the path to the Control4 DriverEditor software executables. If not specified, the default value is C:\Program Files (x86)\Control4\DriverEditor301\.


### `validate` Command

The `validate` command uses the Control4 _DriverValidator.exe_ program to validate all `.c4z` files present in the output folder (see `--output-path` parameter description).

The `--path` (`-p`) parameter defines the working directory. It should be set to the directory that contains the `driver.xml` file and the `.c4zproj` project file of the driver. The default value is the current directory.

The `--output-path` (`-o`) parameter indicates the folder where the generated `.c4z` files will be saved. If the parameter is not provided, the default value depends on whether `--release production` is specified or not. It will be `WORKING_DIRECTORY/no_crypt` if not specified, or `WORKING_DIRECTORY/encrypted` if `--release production` is present.

The `--driver-editor` parameter defines the path to the Control4 DriverEditor software executables. If not specified, the default value is C:\Program Files (x86)\Control4\DriverEditor301\.


### `install` Command

The `install` command copies all `.c4z` files present in the output folder to the folder where Control4's Composer.exe stores the usable drivers.

The default path for this folder is `%DOCUMENTFOLDER%\Control4\Drivers`, but it can be manually redefined using the `--install-path` (`-i`) parameter followed by the desired path.

The `--output-path` (`-o`) parameter indicates the folder where the generated `.c4z` files will be saved. If the parameter is not provided, the default value depends on whether `--release production` is specified or not. It will be `WORKING_DIRECTORY/no_crypt` if not specified, or `WORKING_DIRECTORY/encrypted` if `--release production` is present.

### `build` Command

The `build` command is a shortcut that performs the `build` and `validate` commands sequentially.

### `all` Command

The `all` command is a shortcut that performs the following commands sequentially: `update`, `build`, `validate`, and `install`.

### `license` Command

The `license` command generates a soft.kiwi license. It expects the following parameters: `email` (customer's email), `mac` (MAC address of the controller where the license will be installed), and `model` (the string that identifies the driver to be licensed).

### `licenses` Command

The `licenses` command generates a list of licenses from a CSV file.

The command has two parameters: `infile` and `outfile`.
`infile` is the name of the input CSV file.
`outfile` is the name of the output file (optional). If not specified, the output will be printed to the screen.

The CSV file must have the following columns in order:
- `email`: customer's email
- `mac`: MAC address of the controller where the license will be installed
- `model`: the string that identifies the driver to be licensed

The `--num-header-rows` parameter allows skipping the first n rows of the header in the file, where n is the number specified after the parameter. The default value is 0 (no header in the file).

The `--delimiter` parameter indicates the delimiter character of the CSV file (default: comma).

The output of the command will be a CSV file containing the input data plus an additional column with the license code. If the `--only-codes` parameter is present, the output will only contain the license codes.


### `info` Command

The `info` command displays the main information of the driver.

The `--path` (`-p`) parameter defines the working directory. It should be set to the directory that contains the `driver.xml` file and the `.c4zproj` project file of the driver. The default value is the current directory.

The `--output-path` (`-o`) parameter indicates the folder where the generated `.c4z` files will be saved. If the parameter is not provided, the default value depends on whether `--release production` is specified or not. It will be `WORKING_DIRECTORY/no_crypt` if not specified, or `WORKING_DIRECTORY/encrypted` if `--release production` is present.


### `unsquish` Command

The `unsquish` command extracts the original files that make up a .lua.shquised file.

The command has two parameters: `infile` and `outpath`.
`infile` is the name of the .squised file to be processed.
`outpath` is the name of the folder where the extracted Lua files will be saved.


# Toolchain for c4dev.exe Developer: If you only need to use c4dev.exe, this part is not relevant to you.

1. Install Python 3.7 from the official website (64-bit version).
1b. Create a Virtual Environment to keep things clean and activate it.
```
py -3 -m venv env
.\env\Scripts\activate
```

2. Install the latest version of PyInstaller that supports Python 3.7 with the command:
```
pip install pyinstaller
```
(https://www.pyinstaller.org)

3. To compile everything:
```
pyinstaller.exe -F .\c4dev-cli.py
```

4. Add the `dist` folder to the PATH (instead of the `build` folder).

## Tools Used
1. pyenv-win to manage virtual environments -> https://github.com/pyenv-win/pyenv-win
2. Poetry to manage dependencies -> https://github.com/sdispater/poetry
3. Git (which also includes curl.exe used to install Poetry)

## Setting Up the Environment

1. Install an up-to-date version of Python on your system (any version 3.x.x will do).

2. From PowerShell:
```
pip install pyenv-win --target $HOME\.pyenv
```
From cmd.exe:
```
pip install pyenv-win --target %USERPROFILE%\.pyenv
```

3. Add the following folders to the system PATH. *These paths must come before any existing Python paths!!!*:
```
PATH_TO_YOUR_HOME\.pyenv\pyenv-win\bin
PATH_TO_YOUR_HOME\.pyenv\pyenv-win\shims
```

4. In the same shell, navigate to the source code folder:
```
cd PATH_TO_c4dev_CODE
```
This will automatically activate the correct virtual environment. Now we can add the necessary dependencies.

5. Check which Python version you need to install:
```
pyenv.bat local
```
Take note of the version number that appears, e.g., 3.6.8.

6. Install the required version:
```
pyenv.bat install VERSION_NUMBER
pyenv.bat rehash
```

7. Install Poetry:
```
curl https://raw.githubusercontent.com/sdispater/poetry/master/get-poetry.py -o get-poetry.py
python get-poetry.py --preview
poetry.bat
```

8. Install the dependencies with Poetry:
```
poetry.bat install
```

## Generating the Executable (exe)

Now we are ready to create the exe:
```
poetry run python setup.py build_exe
```
