import runpy
from config import ROOT
runpy.run_path(str(ROOT/"handoff.py"),run_name="__main__")
