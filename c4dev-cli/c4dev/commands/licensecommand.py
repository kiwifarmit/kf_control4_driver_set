import hashlib
import logging

from c4dev.commands.basecommand import BaseCommand

logger = logging.getLogger(__name__)

class LicenseCommand(BaseCommand):
  

  def __init__(self, email, mac, model):
    self.__email=email
    self.__mac=mac
    self.__model=model
    self.__salt = "ZIB(3UU(jE2&4Bn-043899!-LkLhD#@@" 

  @property
  def salt(self):
    return self.__salt

  @property
  def email(self):
    return self.__email

  @email.setter
  def email(self, value):
    self.__email = value

  @property
  def mac(self):
    return self.__mac

  @mac.setter
  def mac(self, value):
    self.__mac = value.upper()

  @property
  def model(self):
    return self.__model

  @model.setter
  def model(self, value):
    self.__model = value

  @property
  def code(self):
    mac = self.mac
    salt1 = self.salt
    email = self.email
    model = self.model
    if (mac and salt1 and email and model):
        toBehashed = f"{salt1}{mac}{email}{model}"
        hashed = hashlib.sha1()
        hashed.update(toBehashed.encode('utf-8'))
        return hashed.hexdigest()
    else:
        return None


  def perform(self):
    logger.info("LicenseCommand.perform()")
    mac = self.mac
    email = self.email
    model = self.model
    code = self.code

    logger.debug(f"LicenseCommand.perform().mac: {mac}")
    logger.debug(f"LicenseCommand.perform().email: {email}")
    logger.debug(f"LicenseCommand.perform().model: {model}")
    if (code):
        print(code)
    else:
        logger.error("Unable to process license: missing mandatory params")
