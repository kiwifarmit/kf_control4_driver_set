import logging
import re
import os
import pathlib


from c4dev.commands.basecommand import BaseCommand

logger = logging.getLogger(__name__)

class UnsquishCommand(BaseCommand):
  

  def __init__(self, input_file, output_dir):
    self.__input_file = None
    self.__output_dir = None
    
    # Uso i setter che gestistono la doppia natura tra stringa e puntatore file
    self.input_file = input_file
    self.output_dir = output_dir
    
    
  def __del__(self):
    if (self.__input_file):
      self.__input_file.close()

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
  def output_dir(self):
    return self.__output_dir

  @output_dir.setter
  def output_dir(self, value):
    self.__output_dir=pathlib.Path(value)

  def perform(self):
    squished_lua = ""
    squished_lua=self.input_file.read()

    regex = r"package\.preload\['([^']+)'\] = \(function \(\.\.\.\)([\s\S]+?)end\)"

    matches = re.finditer(regex, squished_lua)

    for matchNum, match in enumerate(matches, start=1):
        pack_id, file_content = match.groups()
        logger.info(f"Saving {pack_id} ({len(file_content)} chars)...")

        self.save_lua_file(pack_id, file_content, self.output_dir)

    # save the last file: driver.lua
    r = re.compile(regex)
    driver_file_content = r.sub('', squished_lua)

    logger.info(f"Saving driver.lua ({len(driver_file_content)} chars)...")
    self.save_lua_file("driver", driver_file_content, self.output_dir)

    
  def save_lua_file(self, pack_id, content, out_folder):
    identifiers = pack_id.split('.')
    file_name = f"{identifiers[-1]}.lua"
    folders = identifiers[:-1]

    logger.debug(f"{pack_id}: {file_name} => {folders}")
    
    new_folder = out_folder.joinpath(*folders)
    logger.info(f"New folder {new_folder}")
    if (not os.path.isdir(new_folder)):
        os.makedirs(new_folder, exist_ok=True)

    new_file = pathlib.Path(new_folder) / file_name
    with open(new_file,"w") as f:
        f.write(content)
