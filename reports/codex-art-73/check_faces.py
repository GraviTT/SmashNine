"""Read-only current composite summary; the initial draft checker was superseded."""
from pathlib import Path
import json
from composite_faces import on_bg, dialogue_preview
ROOT=Path(__file__).resolve().parents[2]
REPORT=Path(__file__).resolve().parent
FORMS=[('frey','frey'),('luna','luna'),('luna','luna_brave'),('yuki','yuki'),('nova','nova_male'),('nova','nova_female'),('rio','rio_male'),('rio','rio_female')]
EXPRESSIONS=['happy','angry','hurt']
def run():
    records=json.loads((REPORT/'composite-measurements.json').read_text(encoding='utf-8'))
    print(json.dumps(records,ensure_ascii=False,indent=2))
if __name__=='__main__':run()
