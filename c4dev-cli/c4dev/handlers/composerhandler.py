import logging
import glob
import os
import subprocess

logger = logging.getLogger(__name__)


class ComposerHandler:

    def __init__(self, working_dir, output_dir,  driver_editor_path):
        self._working_dir = working_dir
        self._output_dir = output_dir
        self._driver_editor_path = driver_editor_path

    @property
    def working_dir(self):
        return self._working_dir

    @property
    def output_dir(self):
        return self._output_dir

    @property
    def driver_packager_path(self):
        return os.path.join(self._driver_editor_path, "DriverPackager.exe")

    @property
    def driver_validator_path(self):
        return os.path.join(self._driver_editor_path, "DriverValidator.exe")

    @property
    def manifest_file(self):
        manifest_pattern = os.path.join(self._working_dir, "*.c4zproj")
        logger.info(f"Manifest pattern {manifest_pattern}")
        manifest_file = os.path.basename(glob.glob(manifest_pattern)[0])
        logger.info(f"Manifest file {manifest_file}")

        return manifest_file

    @property
    def c4z_file_pattern(self):
        return os.path.join(self._output_dir, '*.c4z')

    def compile(self):
        subprocess_params = [self.driver_packager_path, '-v',
                             self.working_dir, self.output_dir, self.manifest_file]
        logger.debug(f"External call: {' '.join(subprocess_params)}")
        subprocess.call(subprocess_params)

    def validate(self):

        for c4z_file in glob.glob(self.c4z_file_pattern):
            subprocess_params = [self.driver_validator_path,
                                '-v', '2', '-l', '4', '-d', c4z_file]
            logger.debug(f"External call: {' '.join(subprocess_params)}")
            subprocess.call(subprocess_params)
