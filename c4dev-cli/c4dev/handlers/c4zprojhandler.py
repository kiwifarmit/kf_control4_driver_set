import datetime
import logging
import platform

import xml.etree.ElementTree as ET

logger = logging.getLogger(__name__)


class C4zProjHandler:

    def __init__(self):
        self._tree = None
        self._root = None
        

    def load(self, file_path):
        self._tree = ET.parse(file_path)
        self._root = self._tree.getroot()

    def save(self, file_path):
        self._tree.write(file_path)

    @property
    def name(self):
      driver_tag = self._root #.find('driver')
      name = driver_tag.get('name')
      return name

    @name.setter
    def name(self, value):
      driver_tag = self._root.find('driver')
      driver_tag.set('name', str(value))
