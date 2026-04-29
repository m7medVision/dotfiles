"""Entry point when running as `python3 /path/to/praytime` or `python3 -m praytime`."""
import sys
from pathlib import Path

_pkg_dir = Path(__file__).parent
_scripts_dir = _pkg_dir.parent

if str(_scripts_dir) not in sys.path:
    sys.path.insert(0, str(_scripts_dir))

if __package__ is None:
    __package__ = "praytime"

from praytime.cli import main

main()
