"""
Logging Utility (logging.py)

This module provides a centralized logging configuration for the application.

Functions:
- get_logger() : Returns a configured logger instance for use across pipeline
  modules.

The logging configuration is initialized once when this module is imported.
Logs are written to standard output (stdout) with timestamp, log level, and
module name details.

"""

import logging
import sys

# 1. Configure the root logger EXACTLY ONCE at the module level when this file is imported.
# We also use StreamHandler(sys.stdout) to ensure standard application logs go to stdout,
# keeping stderr clean for actual application failures/stack traces.
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)

# =========================================================
# 1. Get Logger Instance
# =========================================================

def get_logger(name: str = __name__) -> logging.Logger:
    """
    Returns a configured logger instance with the specified module name context.
    """
    return logging.getLogger(name)