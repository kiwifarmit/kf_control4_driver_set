import csv
import hashlib
import logging

from c4dev.commands.basecommand import BaseCommand
from c4dev.commands.licensecommand import LicenseCommand

logger = logging.getLogger(__name__)

class LicensesCommand(BaseCommand):
  

  def __init__(self, input_file, output_file, delimiter=',', header_lenght=0, only_codes=False):
    self.__input_file = None
    self.__output_file = None
    self.__delimiter = delimiter
    self.__header_lenght = header_lenght
    self.__only_codes=only_codes
    
    # Uso i setter che gestistono la doppia natura tra stringa e puntatore file
    self.input_file = input_file
    self.output_file = output_file

    
  def __del__(self):
    if (self.__input_file):
      self.__input_file.close()
    if (self.__output_file):
      self.__output_file.close()

  @property
  def delimiter(self):
    return self.__delimiter

  @property
  def header_lenght(self):
    return self.__header_lenght

  @property
  def only_codes(self):
    return self.__only_codes

  @property
  def input_file(self):
    return self.__input_file

  @input_file.setter
  def input_file(self, value):
    if (type(value) == str):
      self.__input_file=open(value,"r")
    else:
      self.__input_file=value

  @property
  def output_file(self):
    return self.__output_file

  @output_file.setter
  def output_file(self, value):
    if (type(value) == str):
      self.__output_file=open(value,"r")
    else:
      self.__output_file=value


  def perform(self):
    csv_reader = csv.reader(self.input_file, delimiter=self.delimiter)
    csv_writer = csv.writer(self.output_file, delimiter=self.delimiter, lineterminator='\n', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    row_counter = 0
    for row in csv_reader:
      if self.header_lenght == 0 or row_counter >= self.header_lenght:
        license = LicenseCommand(email=row[0], mac=row[1], model=row[2]).code

        if (self.only_codes):
          return_list = []
        else:
          return_list = [x for x in row]
        return_list.append(license)
        csv_writer.writerow(return_list)
      row_counter += 1
    
