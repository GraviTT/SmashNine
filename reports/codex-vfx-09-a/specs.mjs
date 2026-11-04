// CODEX-VFX-09 A. All distances are world pixels; angles are baked, never painter rotation.
export const specs = [
  {name:'luna_step',char:'luna',kind:'step',frames:7,fps:20,w:90,h:42,anchor:[72,28],note:'발이 닿자마자 짧게 터지는 별과 뒤로 흩어지는 별가루.',attach:'노말 Luna 걷기 F4/F8, 앞발 +17/+18px. 한 걸음 4/11.31초에 전 프레임을 맞춘다.',row:'walk'},
  {name:'luna_jump',char:'luna',kind:'jump',frames:9,fps:30,w:156,h:66,anchor:[78,28],note:'도약 순간 발 양옆의 분홍 예각 섬광과 금색 별.',attach:'노말 Luna 지상 점프 시작, 발 위치에 한 번. 오른쪽 기준, 좌우 반전만.',row:'jump'},
  {name:'luna_air_jump',char:'luna',kind:'air',frames:10,fps:30,w:174,h:90,anchor:[87,24],note:'공중 도약 아래로 갈라지는 다섯 별. 바닥 고리 없이 짧게 소멸.',attach:'노말 Luna 공중 점프 시작, 발 위치에 한 번. 오른쪽 기준, 좌우 반전만.',row:'jump'},
  {name:'brave_rush_1',kind:'jab',frames:7,fps:30,aim:-1,reach:131,row:0,pose:1,bodyFps:12.8,active:.075,note:'잽 끝에서 터지는 작고 날카로운 분홍 별과 짧은 가시.'},
  {name:'brave_rush_2',kind:'kick',frames:8,fps:30,aim:-3,reach:147,row:0,pose:3,bodyFps:12.8,active:.085,note:'보디 킥의 두 갈래 금빛 섬광과 별 파편.'},
  {name:'brave_rush_3',kind:'spin',frames:10,fps:30,aim:-22,reach:157,row:0,pose:5,bodyFps:12.8,active:.12,note:'회전 킥의 벌어진 별 세 개와 위로 솟는 예각 선.'},
  {name:'brave_up',kind:'upper',frames:10,fps:30,aim:-83,reach:156,row:1,pose:2,bodyFps:20.4,active:.12,note:'머리에서 떨어진 어퍼컷 끝에 세로 금빛 별 폭발.'},
  {name:'brave_low',kind:'low',frames:8,fps:30,aim:-3,reach:157,row:2,pose:2,bodyFps:18,active:.1,note:'발 높이의 낮고 납작한 별 파편과 짧은 분홍 접촉선.'},
  {name:'brave_side_air',kind:'flying',frames:8,fps:30,aim:-5,reach:170,row:3,pose:2,bodyFps:19.2,active:.095,note:'비행 발차기 끝의 전방 예각 섬광과 떨어지는 별.'},
  {name:'brave_down_air',kind:'dive',frames:11,fps:30,aim:81,reach:206,row:4,pose:2,bodyFps:18,active:.13,note:'급강하 킥 끝에서 아래로 찢어지는 금빛 별 조각. 바닥 반동 없음.'},
  {name:'brave_hit_after',kind:'hit',frames:9,fps:30,w:166,h:72,anchor:[83,28],note:'보통 적중 몸 양옆의 짧은 별 파열. 몸 가운데는 비움.',attach:'Brave 근접 적중 때 맞은 몸 중심, 기존 hit spark 자리에서 한 번. 넉백 400 미만.'},
  {name:'brave_hit_after_big',kind:'hit_big',frames:11,fps:30,w:244,h:96,anchor:[122,30],note:'강한 적중에 더 크고 넓게 터지는 금빛 별 여섯 개.',attach:'Brave 근접 적중 때 맞은 몸 중심에 한 번. 넉백 400 이상: 회전 킥 520/어퍼컷 430/급강하 킥 475.'},
].map(s=>({char:'luna_brave',w:310,h:450,anchor:[95,185],...s,attach:s.attach||`luna_brave_slash 시작과 같은 순간/몸 중심(발보다 32px 위). ${s.aim}도, 사거리 ${s.reach}px를 그림에 반영. 좌우 반전만, 회전 금지. 중력은 화면 아래.`,loop:false}));
