import datetime
import logging
import platform

import xml.etree.ElementTree as ET

logger = logging.getLogger(__name__)


class DriverXmlHandler:

    def __init__(self):
        self._tree = None
        self._root = None
        self._datetime_format = '%m/%d/%Y %I:%M %p'


    def load(self, file_path):
        self._tree = ET.parse(file_path)
        self._root = self._tree.getroot()

    def save(self, file_path):
        self._tree.write(file_path)

    @property
    def modified_at(self):
        modified_at_tag = self._root.find('modified')
        modified_at_datetime = datetime.datetime.strptime(
            modified_at_tag.text, self._datetime_format)
        return modified_at_datetime
    
    @property
    def modified_at_as_string(self):
        modified_at_tag = self._root.find('modified')
        return modified_at_tag.text

    @modified_at.setter
    def modified_at(self, value):
        modified_at_tag = self._root.find('modified')
        new_modified_at = self.format_date(value)
        modified_at_tag.text = new_modified_at

    @property
    def version(self):
        version_tag = self._root.find('version')
        version_int = int(version_tag.text)
        return version_int

    @version.setter
    def version(self, value):
        version_tag = self._root.find('version')
        version_tag.text = f"{value:06}"

    @property
    def encryption(self):
      config_tag = self._root.find('config')
      script_tag = config_tag.find('script')
      return int(script_tag.get('encryption'))

    @encryption.setter
    def encryption(self, value):
      config_tag = self._root.find('config')
      script_tag = config_tag.find('script')
      script_tag.set('encryption', str(value))

    @property
    def jit(self):
        config_tag = self._root.find('config')
        script_tag = config_tag.find('script')
        if script_tag.get('jit'):
            return int(script_tag.get('jit'))
        else:
            return 0

    @jit.setter
    def jit(self, value):
        config_tag = self._root.find('config')
        script_tag = config_tag.find('script')
        script_tag.set('jit', str(value))


    ######## UTILS

    def format_date(self, date_time):
        #if platform.system() == 'Windows':
        #  self._datetime_format = '%#m/%#d/%Y %#I:%M %p'
        #else:
        #  self._datetime_format = '%m/%d/%Y %I:%M %p'

        return f"{date_time.month}/{date_time.day}/{date_time.year} {date_time.strftime('%I:%M %p')}"