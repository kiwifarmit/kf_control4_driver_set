import datetime
import logging
import math
import os

import xml.etree.ElementTree as ET

from c4dev.commands.basecommand import BaseCommand
from c4dev.handlers.driverxmlhandler import DriverXmlHandler

logger = logging.getLogger(__name__)


class UpdateCommand(BaseCommand):

    def __init__(self, working_dir, mode, output_dir, version, encrypt, jit):
        self._output_dir = output_dir
        self._working_dir = working_dir
        self._xml_path = os.path.join(self._working_dir, "driver.xml")
        self._output_xml_path = os.path.join(self._output_dir, "driver.xml")
        self._mode = mode
        self._version = version
        self._encrypt = encrypt
        self._jit = jit

    def perform(self):
        print(f"\n** Updating {self._xml_path}...")

        driver_xml = DriverXmlHandler()
        driver_xml.load(self._xml_path)

        today = datetime.datetime.today()
        logger.info(f"Setting new modified date...")
        logger.debug(f"Current modified date {driver_xml.modified_at_as_string}")
        logger.debug(f"New modified date {today}")
        driver_xml.modified_at = today
        print(f"Set modified date to {driver_xml.modified_at_as_string}")

        # VERSION
        logger.info(f"Updating version...")
        logger.debug(f"Current version is {driver_xml.version}")

        if self._version == None:
          new_version = driver_xml.version
          logger.debug(f"Release mode {self._mode}")
          if (self._mode == BaseCommand.BETA or self._mode == BaseCommand.PRODUCTION):
            new_version = math.ceil((new_version + 1) / 1000) * 1000
          else:
            new_version += 1
          logger.debug(f"New version will be {new_version}")
          driver_xml.version = new_version
        else:
          driver_xml.version = self._version

        print(f"Set version to {driver_xml.version}")

        # ENCRYPTION
        # <script encryption="2" file="driver.lua" />
        logger.info(f"Updating encryption...")
        logger.debug(f"Current encryption is {driver_xml.encryption}")

        if self._encrypt == 'on':
          driver_xml.encryption = 2
        elif self._encrypt == 'off':
          driver_xml.encryption = 0
        else:
          new_encryption = driver_xml.encryption
          logger.debug(f"Encryption {self._mode}")
          if (self._mode == BaseCommand.PRODUCTION):
            new_encryption = 2
          else:
            new_encryption = 0
          logger.debug(f"New encryption will be {new_encryption}")
          driver_xml.encryption = new_encryption
          
        print(f"Set encryption to {driver_xml.encryption}")

        # JIT support
        # <script jit="1" encryption="2" file="driver.lua" />
        logger.info(f"Updating JIT support...")
        logger.debug(f"Current JIT is {driver_xml.jit}")

        if self._jit == 'on':
          driver_xml.jit = 1
        elif self._jit == 'off':
          driver_xml.jit = 0
        else:
          new_jit = driver_xml.jit
          logger.debug(f"New JIT support will be {new_jit}")
          driver_xml.jit = new_jit
          
        print(f"Set JIT support to {driver_xml.jit}")

        driver_xml.save(self._output_xml_path)
