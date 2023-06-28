import datetime
import glob
import logging
import math
import os
import shutil

import xml.etree.ElementTree as ET

from c4dev.commands.basecommand import BaseCommand

logger = logging.getLogger(__name__)


class InstallCommand(BaseCommand):

    def __init__(self, mode, output_dir, install_dir):
        self._mode = mode

        self._output_dir = output_dir
        if (self._mode == BaseCommand.PRODUCTION):
            self._output_dir = os.path.join(self._output_dir, "encrypted")
        else:
            self._output_dir = os.path.join(self._output_dir, "no_crypt")
        logger.info(f"Output to {self._output_dir}")

        self._install_dir = install_dir
        logger.info(f"Install dir is {self._install_dir}")

    @property
    def c4z_file_pattern(self):
        c4z_path = os.path.join(self._output_dir, '*.c4z')
        logger.debug(f"c4z path {c4z_path}")
        return c4z_path

    def perform(self):
        print(
            f"\n** Installing {self.c4z_file_pattern} in {self._install_dir}")

        for file_name in glob.glob(self.c4z_file_pattern):
            dest_file = os.path.join(self._install_dir, os.path.basename(file_name))
            print(f"Copying file {file_name} in {dest_file}")
            shutil.copyfile(file_name, dest_file)
