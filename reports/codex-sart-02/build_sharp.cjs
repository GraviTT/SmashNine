// Prepared fallback. Run only after the user accepts substituting the processing engine.
const fs = require('node:fs/promises');
const path = require('node:path');
const crypto = require('node:crypto');
const {createRequire} = require('node:module');
const runtimeRequire = createRequire('C:/Users/TH/AppData/Local/OpenAI/Codex/runtimes/cua_node/78fb63cda1a9e2b2/bin/node.exe');
const sharp = runtimeRequire('sharp');
const report = __dirname;
const root = path.resolve(report, '../..');
const cand = path.join(root,'art/bakeoff/story');
const fontfile = 'C:/Windows/Fonts/malgun.ttf';
const circled = ['','①','②','③','④','⑤','⑥','⑦','⑧','⑨'];
const order = [2,1,8,3,9,7,4,5,6];
const read = async p => JSON.parse((await fs.readFile(p,'utf8')).replace(/^\uFEFF/,''));
const hash = b => crypto.createHash('sha256').update(b).digest('hex');
const writeJSON = (p,v,flag='w') => fs.writeFile(p,JSON.stringify(v,null,2)+'\n',{flag});
const exists = async p => {try{await fs.access(p);return true;}catch{return false;}};
const escapeText = s => String(s).replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]));

async function metrics(buffer) {
  const {data,info}=await sharp(buffer).removeAlpha().toColourspace('srgb').raw().toBuffer({resolveWithObject:true});
  let sum=0,ss=0,sat=0,edgeSum=0,edgeN=0;
  const n=info.width*info.height;
  for(let i=0;i<n;i++){
    const r=data[i*3]/255,g=data[i*3+1]/255,b=data[i*3+2]/255;
    const y=.2126*r+.7152*g+.0722*b,mx=Math.max(r,g,b),mn=Math.min(r,g,b);
    sum+=y;ss+=y*y;sat+=mx?(mx-mn)/mx:0;
    const x=i%info.width,row=Math.floor(i/info.width);
    if(x<8||x>=info.width-8||row<8||row>=info.height-8){edgeSum+=y;edgeN++;}
  }
  const round=x=>Number(x.toFixed(6));
  return {brightness_mean_y709:round(sum/n),saturation_mean_hsv:round(sat/n),
    contrast_std_y709:round(Math.sqrt(ss/n-(sum/n)**2)),outer_8px_mean_y709:round(edgeSum/edgeN)};
}

async function label(text,size=22,colour='#e9ecff') {
  return sharp({text:{text:`<span foreground="${colour}">${escapeText(text)}</span>`,
    font:`Malgun Gothic ${size}`,fontfile,dpi:72,rgba:true}}).png().toBuffer();
}

async function boardFile(width,height,layers,name){
  const data=await sharp({create:{width,height,channels:3,background:'#101727'}})
    .composite(layers).jpeg({quality:90,chromaSubsampling:'4:4:4'}).toBuffer();
  if(data.length>2000000)throw Error('Board exceeds 2 MB '+name);
  await fs.writeFile(path.join(report,name),data);
  return {file:name,bytes:data.length,width,height,quality:90};
}

function spread(rows){
  const keys=['brightness_mean_y709','saturation_mean_hsv','contrast_std_y709'];
  return Object.fromEntries(keys.map(k=>{const a=rows.map(r=>r[k]),mean=a.reduce((x,y)=>x+y,0)/a.length;
    return [k,{min:Math.min(...a),max:Math.max(...a),range:Math.max(...a)-Math.min(...a),mean,
      std_population:Math.sqrt(a.reduce((v,x)=>v+(x-mean)**2,0)/a.length)}];}));
}

async function run(){
  const approval=await read(path.join(report,'processing-authorization.json'));
  if(approval.approved!==true)throw Error('Processing substitution has not been approved');
  const {jobs}=await read(path.join(report,'all-generations.json'));
  const selection=await read(path.join(report,'selection.json'));
  await fs.mkdir(cand,{recursive:true});
  const rows=[];
  for(const j of jobs){
    const input=path.join(root,'art/raw/story',j.id+'_raw.png');
    const output=path.join(cand,j.id+'.png'),metaPath=path.join(cand,j.id+'.json');
    const raw=await fs.readFile(input),source=await fs.readFile(j.source);
    if(!raw.equals(source))throw Error('Raw source mismatch '+j.id);
    if(await exists(metaPath)){
      const m=await read(metaPath),b=await fs.readFile(output);
      if(hash(b)!==m.candidate_sha256||hash(raw)!==m.raw_sha256)throw Error('Existing artifact hash mismatch');
      rows.push({id:j.id,stage:j.stage,version:j.version,recommended:selection[j.stage]===j.version,size:[640,360],...m.metrics});
      continue;
    }
    if(await exists(output))throw Error('Will not overwrite '+output);
    const m=await sharp(raw).metadata();
    const k=Math.min(Math.floor(m.width/16),Math.floor(m.height/9));
    const box=j.crop_box||[Math.floor((m.width-16*k)/2),Math.floor((m.height-9*k)/2),Math.floor((m.width-16*k)/2)+16*k,Math.floor((m.height-9*k)/2)+9*k];
    const left=box[0],top=box[1],width=box[2]-box[0],height=box[3]-box[1];
    if(width*9!==height*16)throw Error('Crop is not exact 16:9');
    if(width<640||height<360||m.hasAlpha)throw Error('Unexpected dimensions or alpha '+j.id);
    const final=await sharp(raw).extract({left,top,width,height})
      .resize(640,360,{kernel:'lanczos3',withoutEnlargement:true,fastShrinkOnLoad:false})
      .removeAlpha().toColourspace('srgb').png({compressionLevel:9}).toBuffer();
    const fm=await sharp(final).metadata();
    if(fm.width!==640||fm.height!==360||fm.channels!==3||fm.hasAlpha)throw Error('Candidate contract failed');
    const measured=await metrics(final);
    await fs.writeFile(output,final,{flag:'wx'});
    const metadata={note:j.note,stage:j.stage,title:j.title,version:j.version,status:'candidate',
      size:[640,360],mode:'RGB',opaque:true,processing:{engine:`sharp ${sharp.versions.sharp} / libvips ${sharp.versions.vips}`,
        requested_engine:'Python + Pillow; execution blocked by sandbox access denial',
        substitution_authorization:approval,source_returned_by_image_gen:j.source,
        raw_copy:`art/raw/story/${j.id}_raw.png`,raw_byte_identical:true,raw_size:[m.width,m.height],
        crop_box_ltrb_exclusive:[left,top,left+width,top+height],crop_size:[width,height],
        crop_method:j.crop_box?'review-directed exact 16:9 crop':'largest centred exact 16:9 integer crop',resize_to:[640,360],resize_filter:'Lanczos3',
        scale_x:640/width,scale_y:360/height,upscale:false,colour_or_content_edit:false},
      raw_sha256:hash(raw),candidate_sha256:hash(final),metrics:measured,prompt:j.prompt,references_in_order:j.refs};
    await writeJSON(metaPath,metadata,'wx');
    rows.push({id:j.id,stage:j.stage,version:j.version,recommended:selection[j.stage]===j.version,size:[640,360],...measured});
  }
  const sheets=[];
  for(let s=1;s<=9;s++){
    const group=jobs.filter(j=>j.stage===s).sort((a,b)=>a.version-b.version);
    const layers=[{input:await label(`${circled[s]} ${group[0].title} · 640×360 / 480×270`,24),left:24,top:14}];
    for(let n=0;n<group.length;n++){
      const j=group[n],x=24+n*664,b=await fs.readFile(path.join(cand,j.id+'.png'));
      layers.push({input:await label(`v${j.version}`+(selection[s]===j.version?' · 추천':''),22,selection[s]===j.version?'#f3cd7c':'#b7c4dc'),left:x,top:58});
      layers.push({input:b,left:x,top:91});
      layers.push({input:await sharp(b).resize(480,270,{kernel:'lanczos3'}).png().toBuffer(),left:x+80,top:493});
    }
    sheets.push(await boardFile(24+group.length*664,810,layers,`stage-${String(s).padStart(2,'0')}-comparison.jpg`));
  }
  const layers=[{input:await label('SART-02 · 추천 세트 · 후보 / 게임 미적용',26),left:24,top:14}];
  const labels=[];
  for(let n=0;n<order.length;n++){
    const s=order[n],j=jobs.find(j=>j.stage===s&&j.version===selection[s]);
    const x=24+(n%3)*496,y=64+Math.floor(n/3)*320;
    const b=await fs.readFile(path.join(cand,j.id+'.png'));
    layers.push({input:await sharp(b).resize(480,270,{kernel:'lanczos3'}).png().toBuffer(),left:x,top:y});
    const title=`${circled[s]} ${j.title}`;
    layers.push({input:await label(title,23),left:x,top:y+278});
    layers.push({input:await label(`v${j.version}`,18,'#f3cd7c'),left:x+420,top:y+282});
    labels.push(title);
  }
  sheets.push(await boardFile(1512,1038,layers,'set-board.jpg'));
  await writeJSON(path.join(report,'measurements.json'),{definitions:{
    brightness_mean_y709:'mean((0.2126 R + 0.7152 G + 0.0722 B)/255), sRGB code values, not linear luminance',
    saturation_mean_hsv:'mean((max(R,G,B)-min(R,G,B))/max(R,G,B)); black=0',
    contrast_std_y709:'population standard deviation of per-pixel Y709'},variants:rows,
    all:spread(rows),recommended:spread(rows.filter(r=>r.recommended))});
  await writeJSON(path.join(report,'board-validation.json'),{fontfile,font_family:'Malgun Gothic',
    rendering_engine:'sharp/libvips/Pango (authorized substitution for Pillow)',labels,order,sheets});
  return {candidates:rows.length,sheets:sheets.length,recommended:spread(rows.filter(r=>r.recommended))};
}
module.exports={run,metrics};
