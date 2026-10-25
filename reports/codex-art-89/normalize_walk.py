"""Same ART-72 normaliser, eight output columns for the complete walk row."""
import os, sys
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
sys.path.insert(0, str(Path('tools/sprite_pipeline').resolve()))
import normalize
normalize.COLUMNS=8
raise SystemExit(normalize.main())
