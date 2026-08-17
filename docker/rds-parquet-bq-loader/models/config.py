"""
Configuration Loader (config.py)

Purpose:
This module loads the pipeline configuration from a JSON file specified
by the `CONFIG_PATH` environment variable. If no path is provided, it
defaults to the development configuration file.

Execution Flow:
1. Read the configuration file path from the `CONFIG_PATH` environment variable.
2. Use the default development configuration if no path is specified.
3. Open and parse the JSON configuration file.
4. Return the configuration as a dictionary.
5. Log and raise a `RuntimeError` if the file is missing, contains invalid JSON,
   or cannot be loaded.
"""

import os
import json
import logging

logger = logging.getLogger(__name__)

# Read the path from the environment, defaulting to development for safety
CONFIG_FILE = os.getenv("CONFIG_PATH", "config/development/config.json")

    
def load_config():
    logger.info("Loading configuration from: %s", CONFIG_FILE)
    try:
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)

    except FileNotFoundError:
        logger.exception("Config file not found: %s", CONFIG_FILE)
        raise RuntimeError(f"Config file not found: {CONFIG_FILE}")

    except json.JSONDecodeError:
        logger.exception("Invalid JSON in config file: %s", CONFIG_FILE)
        raise RuntimeError(f"Invalid JSON in config file: {CONFIG_FILE}")

    except Exception:
        logger.exception("Failed loading config file: %s", CONFIG_FILE)
        raise RuntimeError(f"Failed loading config: {CONFIG_FILE}")
