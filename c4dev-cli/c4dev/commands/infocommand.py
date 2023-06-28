import datetime
import logging
import math
import os
import glob

import xml.etree.ElementTree as ET

from c4dev.commands.basecommand import BaseCommand
from c4dev.handlers.driverxmlhandler import DriverXmlHandler
from c4dev.handlers.c4zprojhandler import C4zProjHandler

logger = logging.getLogger(__name__)


class InfoCommand(BaseCommand):

    def __init__(self, working_dir, output_dir):
        self._output_dir = output_dir
        self._working_dir = working_dir
        self._xml_path = os.path.join(self._working_dir, "driver.xml")

    @property
    def working_dir(self):
        return self._working_dir

    @property
    def manifest_file_path(self):
        manifest_pattern = os.path.join(self._working_dir, "*.c4zproj")
        manifest_file = glob.glob(manifest_pattern)[0]
        logger.info(f"Manifest file {manifest_file}")

        return manifest_file
        
    def perform(self):
        print(f"\n** Collecting info from {self._xml_path}...")

        driver_xml = DriverXmlHandler()
        driver_xml.load(self._xml_path)


        print(f"Version: {driver_xml.version}")
        print(f"Encryption: {driver_xml.encryption}")

        proj_xml = C4zProjHandler()
        proj_xml.load(self.manifest_file_path)

        print(f"Name/Model: {proj_xml.name}")
  
