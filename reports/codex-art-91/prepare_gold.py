"""ART-91 gold emblem variant: measured final pixels, stable emblem centre."""
import sys,importlib.util
from pathlib import Path
sys.dont_write_bytecode=True
s=importlib.util.spec_from_file_location('l91',Path(__file__).with_name('landmark_scan.py'));m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
def gold(im):
 c=m.component(im,'gold');b=c['bbox']
 return dict(size=c['height'],center=[(b[0]+b[2]-1)/2,(b[1]+b[3]-1)/2],bbox=b,method='gold 4-connected largest component height; landmark_scan threshold')
m.p.orb=gold
m.p.prepare(sys.argv[1])
