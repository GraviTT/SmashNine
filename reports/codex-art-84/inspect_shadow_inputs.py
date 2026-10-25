from build_hurt import *

if __name__=='__main__':
    b=Image.new('RGB',(1000,660),'#151621')
    for i,(stem,cfg) in enumerate(old.FORMS.items()):
        x=(i%4)*250; y=(i//4)*330; crop=cfg['crop']
        text(b,(x+8,y+5),stem,17)
        im=Image.open(RAW/f'{stem}-shadow-v1.png').convert('RGBA')
        tile=old.on_bg(im).crop(crop).resize(((crop[2]-crop[0])*4,(crop[3]-crop[1])*4),Image.Resampling.NEAREST)
        b.paste(tile,(x+4,y+40))
        text(b,(x+4,y+300),str(crop),14)
    save(b,RAW/'shadow-input-crops.png')
