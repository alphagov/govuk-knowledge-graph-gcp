"""
MongoDB Restore Service (mongo_restore.py)

This module provides helper methods to start a temporary MongoDB instance,
restore backup data, and clean up resources after processing.

Functions:
1. start() : Starts a local MongoDB instance for temporary data restoration.
2. restore() : Restores a MongoDB backup archive into the local instance.
3. stop() : Stops MongoDB and removes temporary files.
4. __enter__() / __exit__() : Supports using the service as a context manager
  to automatically manage startup and cleanup.

"""

import shutil
import subprocess
import time
from pathlib import Path
from pymongo import MongoClient
from services.exceptions import JobFailure
from utils.logging import get_logger

logger = get_logger(__name__)


class MongoRestoreService:

    # Parameterized variables with safe defaults to prevent run conflicts and aid testability
    def __init__(
        self, 
        port: int = 27017, 
        db_dir: str = "/tmp/mongodb", 
        log_path: str = "/tmp/mongod.log"
    ):
        self.port = port
        self.db_path = Path(db_dir)
        self.log_path = Path(log_path)
        self.process = None
        self.client = None
        self.log_file = None
    
    # =================================================================
    # 1. Starts a local MongoDB instance for temporary data restoration
    # =================================================================

    def start(self):
        # Ensure temporary database directory exists
        self.db_path.mkdir(parents=True, exist_ok=True)

        # Open log file for mongod stdout/stderr redirect
        self.log_file = open(self.log_path, "w", encoding="utf-8")

        logger.info("Starting local mongod on port %d...", self.port)
        self.process = subprocess.Popen(
            [
                "mongod",
                "--port", str(self.port),
                "--dbpath", str(self.db_path),
                "--bind_ip", "127.0.0.1",
                "--wiredTigerCacheSizeGB", "0.5"
            ],
            stdout=self.log_file,
            stderr=subprocess.STDOUT
        )

        # Connect client to the configured port
        self.client = MongoClient(
            f"mongodb://127.0.0.1:{self.port}",
            serverSelectionTimeoutMS=2000
        )

        # Wait up to 15 seconds for mongod to initialize and accept connections
        for _ in range(15):
            try:
                self.client.admin.command("ping")
                logger.info("Local mongod started successfully on port %d", self.port)
                return
            except Exception:
                time.sleep(1)

        raise JobFailure(f"Mongo failed to start on port {self.port} within 15 seconds")

    # =================================================================
    # 2. Restores a MongoDB backup archive into the local instance
    # =================================================================

    def restore(self, archive_file, collection_name):
        logger.info("Restoring namespace '*.%s' from archive: %s", collection_name, archive_file)

        cmd = [
            "mongorestore",
            "--gzip",
            f"--archive={archive_file}",
            "--nsInclude",
            f"*.{collection_name}",
            "--host",
            f"127.0.0.1:{self.port}"
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            logger.error("mongorestore execution failed. Output:\n%s", result.stderr)
            raise JobFailure(f"mongorestore failed with exit code {result.returncode}: {result.stderr}")

        logger.info("Successfully restored namespace '*.%s'", collection_name)

    # =================================================================
    # 3. Stops MongoDB and removes temporary files
    # =================================================================

    def stop(self):
        logger.info("Cleaning up MongoRestoreService...")

        # 1. Close PyMongo client connection pool
        if self.client:
            self.client.close()
            self.client = None

        # 2. Stop mongod process safely with timeout fallback
        if self.process:
            logger.info("Stopping mongod process...")
            self.process.terminate()
            try:
                self.process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                logger.warning("mongod did not shut down gracefully. Killing process.")
                self.process.kill()
                self.process.wait()
            self.process = None

        # 3. Close the log file descriptor
        if self.log_file:
            self.log_file.close()
            self.log_file = None

        # 4. Clean up temporary database files to prevent disk bloat
        if self.db_path.exists():
            try:
                shutil.rmtree(self.db_path)
                logger.info("Cleaned up temporary database directory: %s", self.db_path)
            except Exception as e:
                logger.warning("Failed to clean up temporary database directory %s: %s", self.db_path, e)

    # =======================================================================
    # 4. Context manager methods to automatically manage startup and cleanup
    # =======================================================================

    def __enter__(self):
        try:
            self.start()
            return self
        except Exception:
            # If start() fails, aggressively cleanup resources before letting exception bubble up
            self.stop()
            raise

    def __exit__(self, exc_type, exc, tb):
        self.stop()