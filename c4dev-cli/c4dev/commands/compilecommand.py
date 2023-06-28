import datetime
import logging
import math
import os


import xml.etree.ElementTree as ET

from c4dev.commands.basecommand import BaseCommand
from c4dev.handlers.driverxmlhandler import DriverXmlHandler
from c4dev.handlers.composerhandler import ComposerHandler

logger = logging.getLogger(__name__)


class CompileCommand(BaseCommand):

    def __init__(self, working_dir, driver_editor_path, output_dir):

        self._working_dir = working_dir
        self._output_dir = output_dir
        logger.info(f"Working dir is {self._output_dir}")

        self._driver_editor_path = driver_editor_path
        logger.info(f"Driver Editor path is in {self._driver_editor_path}")

        self._xml_path = os.path.join(self._working_dir, "driver.xml")
        driver_xml = DriverXmlHandler()
        driver_xml.load(self._xml_path)

        # if (self._mode == BaseCommand.PRODUCTION):
        if (driver_xml.encryption == 2):
            self._output_dir = os.path.join(self._output_dir, "encrypted")
        else:
            self._output_dir = os.path.join(self._output_dir, "no_crypt")
        logger.info(f"Output to {self._output_dir}")

    def perform(self):

        composer = ComposerHandler(
            self._working_dir, self._output_dir,  self._driver_editor_path)
        composer.compile()
