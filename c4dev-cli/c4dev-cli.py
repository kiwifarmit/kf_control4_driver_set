from c4dev.commands import InstallCommand
from c4dev.commands import ValidateCommand
from c4dev.commands import CompileCommand
from c4dev.commands import BaseCommand
from c4dev.commands import UpdateCommand
from c4dev.commands import LicenseCommand
from c4dev.commands import LicensesCommand
from c4dev.commands import UnsquishCommand
from c4dev.commands import InfoCommand

import argparse
import os
import logging
import platform
import sys
import pathlib

logger = logging.getLogger(__name__)
VERSION='0.9.0'

if platform.system() == 'Windows':
    import winreg

def tools_main(args):
    command = args.subparser_name
    
    if 'release' in args:
        release = BaseCommand.DEV
        if (args.release == "beta"):
            release = BaseCommand.BETA
        elif (args.release == "production"):
            release = BaseCommand.PRODUCTION
        else:
            release = BaseCommand.DEV
        logger.debug(f"args.release = {args.release}")
        logger.debug(f"release = {release}")

    # PATH
    working_dir = os.getcwd()
    if 'path' in args:
        if (args.path):
            working_dir = args.path

    output_dir = working_dir
    if 'output_path' in args:
        if (args.output_path):
            output_dir = args.output_path

    if platform.system() == 'Windows':
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders") as key:
            result = winreg.QueryValueEx(key, "Personal")
            install_dir = os.path.join(result[0], "Control4\\Drivers")
    else:
        install_dir = os.path.expanduser('Documents/Control4/Drivers')

    if 'install_path' in args:
        if (args.install_path):
            install_dir = args.install_path

    if 'driver_editor' in args:
        drivereditor = args.driver_editor
    if 'version' in args:
        version = args.version
    if 'encrypt' in args:
        encrypt = args.encrypt
    if 'jit' in args:
        jit = args.jit

    if (command == "info"):
        InfoCommand(working_dir, output_dir).perform()
    if (command == "update" or command == "all"):
        UpdateCommand(working_dir, release, output_dir, version, encrypt, jit).perform()
    if (command == "compile" or command == "build" or command == "all"):
        CompileCommand(working_dir, drivereditor, output_dir).perform()
    if (command == "validate" or command == "build" or command == "all"):
        ValidateCommand(working_dir, drivereditor, output_dir).perform()
    if (command == "install" or command == "all"):
        InstallCommand(release, output_dir, install_dir).perform()

def  license_main(args):
    command = args.subparser_name
    if (command == "licenses"):
        input_file = args.infile
        output_file = args.outfile
        LicensesCommand(input_file=input_file, output_file=output_file, delimiter=args.delimiter, header_lenght=args.num_header_rows, only_codes=args.only_codes).perform()
    else:
        LicenseCommand(email=args.email, mac=args.mac, model=args.model).perform()

def unsqueeze_main(args):
    input_file = args.infile
    output_dir = args.outdir
    UnsquishCommand(input_file=input_file, output_dir=output_dir).perform()



def main():

    parser = argparse.ArgumentParser(
        description="Tool to help you to be effective in Control4 development!")

    subparsers = parser.add_subparsers(dest="subparser_name",help='')
    
    update_parser = subparsers.add_parser('update', help='update driver.xml changing version, encription and date')
    update_parser.add_argument("-p", "--path", help="""define the working directory. The default value is the current working directory""")
    update_parser.add_argument("-o", "--output-path", help="""OUTPUT_PATH is the folder where it will save c4z file. The default value is 'PATH/encrypted' if --release is production, 'PATH/no_crypt otherwise.""")
    update_parser.add_argument("-r", "--release", help="""use beta if you want generate a driver for testing purpose, use production for a final release""", choices=['beta', 'production'])
    update_parser.add_argument("-V", "--version", help="set the version to set in driver.xml.", type=int)
    update_parser.add_argument("-e", "--encrypt", help="enable the encryption in driver.xml. Default value is 'auto'", default='auto', choices=['auto', 'on', 'off'])
    update_parser.add_argument("-j", "--jit", help="enable the JIT support in driver.xml. Default value is 'auto'", default='auto', choices=['auto', 'on', 'off'])

    compile_parser = subparsers.add_parser('compile', help='create a c4z file')
    compile_parser.add_argument("-p", "--path", help="""define the working directory. The default value is the current working directory""")
    compile_parser.add_argument("-o", "--output-path", help="""OUTPUT_PATH is the folder where it will save c4z file. The default value is 'PATH/encrypted' if --release is production, 'PATH/no_crypt otherwise.""")
    compile_parser.add_argument("--driver-editor", help="""path to Driver Editor installation folder. The default value is C:\\Program Files (x86)\\Control4\\DriverEditor301\\""", default="C:\\Program Files (x86)\\Control4\\DriverEditor301\\")

    validate_parser = subparsers.add_parser('validate', help='validate a c4z file')
    validate_parser.add_argument("-p", "--path", help="""define the working directory. The default value is the current working directory""")
    validate_parser.add_argument("-o", "--output-path", help="""OUTPUT_PATH is the folder where it will save c4z file. The default value is 'PATH/encrypted' if --release is production, 'PATH/no_crypt otherwise.""")
    validate_parser.add_argument("--driver-editor", help="""path to Driver Editor installation folder. The default value is C:\\Program Files (x86)\\Control4\\DriverEditor301\\""", default="C:\\Program Files (x86)\\Control4\\DriverEditor301\\")

    install_parser = subparsers.add_parser('install', help='copy the c4z file in ComposerPro')
    install_parser.add_argument("-o", "--output-path", help="""OUTPUT_PATH is the folder where it will save c4z file. The default value is 'PATH/encrypted' if --release is production, 'PATH/no_crypt otherwise.""")
    install_parser.add_argument("-r", "--release", help="""use beta if you want generate a driver for testing purpose, use production for a final release""", choices=['beta', 'production'])
    install_parser.add_argument("-i", "--install-path", help="""INSTALL_PATH is the folder where it will install the c4z file. The default value is DOCUMENT_FOLDER/Control4/Drivers""")

    build_parser = subparsers.add_parser('build', help='(performs compile + validate')
    build_parser.add_argument("-p", "--path", help="""define the working directory. The default value is the current working directory""")
    build_parser.add_argument("-o", "--output-path", help="""OUTPUT_PATH is the folder where it will save c4z file. The default value is 'PATH/encrypted' if --release is production, 'PATH/no_crypt otherwise.""")
    build_parser.add_argument("--driver-editor", help="""path to Driver Editor installation folder. The default value is C:\\Program Files (x86)\\Control4\\DriverEditor301\\""", default="C:\\Program Files (x86)\\Control4\\DriverEditor301\\")

    all_parser = subparsers.add_parser('all', help='performs update + compile + validate + install')
    all_parser.add_argument("-p", "--path", help="""define the working directory. The default value is the current working directory""")
    all_parser.add_argument("-o", "--output-path", help="""OUTPUT_PATH is the folder where it will save c4z file. The default value is 'PATH/encrypted' if --release is production, 'PATH/no_crypt otherwise.""")
    all_parser.add_argument("-r", "--release", help="""use beta if you want generate a driver for testing purpose, use production for a final release""", choices=['beta', 'production'])
    all_parser.add_argument("-V", "--version", help="set the version to set in driver.xml.", type=int)
    all_parser.add_argument("-e", "--encrypt", help="enable the encryption in driver.xml. Default vaue is 'auto'", default='auto', choices=['auto', 'on', 'off'])
    all_parser.add_argument("-j", "--jit", help="enable the JIT support in driver.xml. Default value is 'auto'", default='auto', choices=['auto', 'on', 'off'])
    all_parser.add_argument("--driver-editor", help="""path to Driver Editor installation folder. The default value is C:\\Program Files (x86)\\Control4\\DriverEditor301\\""", default="C:\\Program Files (x86)\\Control4\\DriverEditor301\\")

    # Manage license generation command
    # create the parser for the "a" command
    license_parser = subparsers.add_parser('license', help='handle softkiwi liceses generation')
    license_parser.add_argument('email', help='customer email address')
    license_parser.add_argument('mac',   help='controller MAC address')
    license_parser.add_argument('model', help='driver model')
    
    licenses_parser = subparsers.add_parser('licenses', help='handle softkiwi liceses generation from CSV')
    licenses_parser.add_argument('infile', help="path to the CSV file to process", type=argparse.FileType('r'))
    licenses_parser.add_argument('outfile', help="path to the CSV file where to save the licenses", nargs='?', type=argparse.FileType('w'), default=sys.stdout)
    licenses_parser.add_argument("--delimiter", help="delimiter used in CSV file", default=',')
    licenses_parser.add_argument("--num-header-rows", help="Num of rows in file headers. It skips the header of the CSV file if greater than 0", type=int, default=0)
    licenses_parser.add_argument("--only-codes", help="If present do not copy input data in the output file, but output only license codes", action="store_true")

    info_parser = subparsers.add_parser('info', help='return infos from driver.xml and .c4zproj')
    info_parser.add_argument("-p", "--path", help="""define the working directory. The default value is the current working directory""")
    info_parser.add_argument("-o", "--output-path", help="""OUTPUT_PATH is the folder where it will save c4z file. The default value is 'PATH/encrypted' if --release is production, 'PATH/no_crypt otherwise.""")
        

    unsquish_parser = subparsers.add_parser('unsquish', help='Unsqueeze a squizeed Lua file')
    unsquish_parser.add_argument('infile', help="lua file to unsqueeze", type=argparse.FileType('r'))
    unsquish_parser.add_argument('outdir', help="output folder where to save the unsqueezed files")
    

    parser.add_argument("-v", "--verbose", help="set the level of logging messages",
                        default="error", choices=['info', 'debug', 'warning', 'error', 'critical'])
    
    args = parser.parse_args()
    
    # VERBOSE
    if (args.verbose == "debug"):
        logging.basicConfig(level=logging.DEBUG)
    elif (args.verbose == "warning"):
        logging.basicConfig(level=logging.WARNING)
    elif (args.verbose == "info"):
        logging.basicConfig(level=logging.INFO)
    elif (args.verbose == "critical"):
        logging.basicConfig(level=logging.CRITICAL)
    else:
        logging.basicConfig(level=logging.ERROR)

    logger = logging.getLogger(__name__)
    logger.debug(f"Args: {args}")
    

    if (args.subparser_name == None):
        print()
        print ("-----------------------------------------------------------")
        print (f" c4dev (v.{VERSION}) -- a tool for control4 driver developers")
        print ("-----------------------------------------------------------")
        print()
        print()
        parser.error("Please choose al least one command")
    else:    
        if (args.subparser_name == 'license' or args.subparser_name == 'licenses'):
            license_main(args)
        elif args.subparser_name == 'unsquish':
            unsqueeze_main(args)
        else:
            tools_main(args)


if __name__ == '__main__':
    main()



