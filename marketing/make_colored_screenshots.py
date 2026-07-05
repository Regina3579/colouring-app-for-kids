import math
import os, random
from collections import deque
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = "/home/user/colouring-app-for-kids/ColoringFun/ColoringFun/Assets.xcassets"
OUTDIR = "/home/user/colouring-app-for-kids/marketing"
FONT = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
W, H = 1290, 2796
TOP, BOT = (255, 247, 219), (216, 240, 255)
INK = (60, 52, 96)

PAL = [(255,138,128),(255,193,77),(129,212,250),(149,117,205),(244,143,177),
       (165,214,167),(255,171,145),(179,229,252),(206,147,216),(255,205,210),
       (178,235,242),(255,224,130),(197,225,165),(248,187,208),(128,222,234)]

def font(sz): return ImageFont.truetype(FONT, sz)
def asset(n):
    p = os.path.join(ROOT, f"{n}.imageset", f"{n}.png")
    return p if os.path.exists(p) else None

def colorize(path, maxw=520, seed=7):
    im = Image.open(path).convert("RGB")
    sc = maxw / im.width
    im = im.resize((maxw, max(1, int(im.height*sc))))
    Wd, Hd = im.size
    data = list(im.getdata()); n = Wd*Hd
    wall = [(0.299*r+0.587*g+0.114*b) < 140 for (r,g,b) in data]
    bg = [False]*n; dq = deque()
    for x in range(Wd):
        for yy in (0, Hd-1):
            i = yy*Wd+x
            if not wall[i] and not bg[i]: bg[i]=True; dq.append(i)
    for y in range(Hd):
        for xx in (0, Wd-1):
            i = y*Wd+xx
            if not wall[i] and not bg[i]: bg[i]=True; dq.append(i)
    while dq:
        i = dq.popleft(); x=i%Wd; y=i//Wd
        for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if 0<=nx<Wd and 0<=ny<Hd:
                j=ny*Wd+nx
                if not wall[j] and not bg[j]: bg[j]=True; dq.append(j)
    rng = random.Random(seed)
    out = [None]*n; visited=[False]*n
    for start in range(n):
        if wall[start] or bg[start] or visited[start]: continue
        col = PAL[rng.randrange(len(PAL))]
        dq=deque([start]); visited[start]=True; region=[start]
        while dq:
            i=dq.popleft(); x=i%Wd; y=i//Wd
            for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if 0<=nx<Wd and 0<=ny<Hd:
                    j=ny*Wd+nx
                    if not wall[j] and not bg[j] and not visited[j]:
                        visited[j]=True; dq.append(j); region.append(j)
        for i in region: out[i]=col
    res = [(45,42,55) if wall[i] else ((255,255,255) if bg[i] else out[i]) for i in range(n)]
    img = Image.new("RGB",(Wd,Hd)); img.putdata(res)
    return img

def sparkle_overlay(img, seed=1):
    img=img.convert("RGB"); Wd,Hd=img.size; px=img.load()
    pts=[]
    for y in range(0,Hd,3):
        for x in range(0,Wd,3):
            r,g,b=px[x,y]
            if not (r>238 and g>238 and b>238): pts.append((x,y))
    if not pts: return img
    rng=random.Random(seed*7+1)
    ov=Image.new("RGBA",(Wd,Hd),(0,0,0,0)); d=ImageDraw.Draw(ov)
    scol=[(255,255,255),(255,245,170),(255,210,240),(200,235,255)]
    n=min(int(Wd*Hd/1700)+14, 240)
    def star(cx,cy,r,col):
        p=[]
        for k in range(8):
            rr=r if k%2==0 else r*0.4; a=math.pi/4*k-math.pi/2
            p.append((cx+rr*math.cos(a),cy+rr*math.sin(a)))
        d.polygon(p,fill=col)
    for _ in range(n):
        cx,cy=rng.choice(pts); r=rng.uniform(3,9)
        if rng.random()<0.55: star(cx,cy,r,rng.choice(scol))
        else: d.ellipse([cx-2,cy-2,cx+2,cy+2],fill=(255,255,255,235))
    img=img.convert("RGBA"); img.alpha_composite(ov); return img.convert("RGB")
def glit(path,maxw=420,seed=7):
    return sparkle_overlay(colorize(path,maxw,seed),seed)

def gradient_bg():
    bg = Image.new("RGB",(W,H)); d=ImageDraw.Draw(bg)
    for y in range(H):
        t=y/(H-1); d.line([(0,y),(W,y)], fill=tuple(int(TOP[i]*(1-t)+BOT[i]*t) for i in range(3)))
    return bg.convert("RGBA")

def rmask(size,r):
    m=Image.new("L",size,0); ImageDraw.Draw(m).rounded_rectangle([0,0,size[0],size[1]],r,fill=255); return m

def center(dr,y,txt,f,fill):
    w=dr.textbbox((0,0),txt,font=f)[2]; dr.text(((W-w)//2,y),txt,font=f,fill=fill)

def pill(dr,y,txt,f,fill,bgc=(255,255,255,235)):
    w=dr.textbbox((0,0),txt,font=f)[2]; x=(W-w)//2-36
    dr.rounded_rectangle([x,y,x+w+72,y+f.size+40],46,fill=bgc)
    dr.text(((W-w)//2,y+20),txt,font=f,fill=fill)

def card(bg, x,y,cw,ch,tint,pimg,label):
    sh=Image.new("RGBA",(W,H),(0,0,0,0))
    ImageDraw.Draw(sh).rounded_rectangle([x,y+12,x+cw,y+ch+12],46,fill=(60,40,90,55))
    bg.alpha_composite(sh.filter(ImageFilter.GaussianBlur(8)))
    cardimg=Image.new("RGBA",(cw,ch),(0,0,0,0)); cd=ImageDraw.Draw(cardimg)
    cd.rounded_rectangle([0,0,cw,ch],46,fill=tint+(255,))
    pad=26; iw=cw-2*pad; ih=ch-2*pad
    s=min(iw/pimg.width, ih/pimg.height); nw,nh=int(pimg.width*s),int(pimg.height*s)
    im=pimg.resize((nw,nh)).convert("RGBA"); im.putalpha(rmask((nw,nh),28))
    cardimg.alpha_composite(im,((cw-nw)//2,(ch-nh)//2))
    cd.rounded_rectangle([4,4,cw-4,ch-4],44,outline=(255,255,255,255),width=10)
    bg.alpha_composite(cardimg,(x,y))
    dr=ImageDraw.Draw(bg); lf=font(46); lw=dr.textbbox((0,0),label,font=lf)[2]
    dr.text((x+(cw-lw)//2,y+ch+10),label,font=lf,fill=INK)

# ---------- Screenshot 2: colored grid ----------
picks2=[("princess_royal","Princess",(255,219,199)),("fairy_rainbow","Fairy",(204,230,255)),
        ("unicorn_rainbow","Unicorn",(255,217,235)),("lion","Animals",(255,222,168)),
        ("trex","Dinosaurs",(205,234,205)),("car_race","Cars",(255,214,204))]
picks2=[p for p in picks2 if asset(p[0])]
bg=gradient_bg(); dr=ImageDraw.Draw(bg)
center(dr,150,"Bring them to life!",font(104),INK)
pill(dr,300,"Tap to fill with bright colors",font(52),(120,90,200))
margin,gap=70,46; cw=(W-2*margin-gap)//2; ch=cw; sy=470; rg=58
for idx,(a,lbl,tint) in enumerate(picks2):
    r,c=divmod(idx,2); x=margin+c*(cw+gap); y=sy+r*(ch+70+rg)
    card(bg,x,y,cw,ch,tint,glit(asset(a),520,idx*5+3),lbl)
pill(dr,2540,"Glitter & sparkle colors  -  Stickers  -  Draw your own",font(44),INK)
bg.convert("RGB").save(os.path.join(OUTDIR,"store_screenshot_2_colored.png"))
print("saved 2")

# ---------- Screenshot 3: glitter hero ----------
import math
bg=gradient_bg(); dr=ImageDraw.Draw(bg)
center(dr,150,"Glitter & Sparkle Magic",font(96),INK)
pill(dr,290,"Dazzling colors that really twinkle",font(50),(120,90,200))
hero=colorize(asset("unicorn_rainbow"),maxw=760,seed=11)
hw=1050; hh=int(hero.height*hw/hero.width)
x=(W-hw)//2; y=470
sh=Image.new("RGBA",(W,H),(0,0,0,0))
ImageDraw.Draw(sh).rounded_rectangle([x,y+16,x+hw,y+hh+16],60,fill=(60,40,90,60))
bg.alpha_composite(sh.filter(ImageFilter.GaussianBlur(12)))
ci=Image.new("RGBA",(hw,hh),(0,0,0,0)); cd=ImageDraw.Draw(ci)
cd.rounded_rectangle([0,0,hw,hh],60,fill=(255,224,240,255))
him=hero.resize((hw-52,hh-52)).convert("RGBA"); him.putalpha(rmask((hw-52,hh-52),40))
ci.alpha_composite(him,(26,26))
rng=random.Random(5); scol=[(255,255,255),(255,240,150),(255,200,235),(190,230,255)]
def star(draw,cx,cy,r,col):
    pts=[]
    for k in range(8):
        rr=r if k%2==0 else r*0.4; ang=math.pi/4*k-math.pi/2
        pts.append((cx+rr*math.cos(ang),cy+rr*math.sin(ang)))
    draw.polygon(pts,fill=col)
for _ in range(85):
    sx=rng.randint(20,hw-20); syy=rng.randint(20,hh-20); r=rng.randint(4,17)
    star(cd,sx,syy,r,rng.choice(scol))
cd.rounded_rectangle([5,5,hw-5,hh-5],56,outline=(255,255,255,255),width=12)
bg.alpha_composite(ci,(x,y))
strip=[("princess_golden",(255,236,200)),("fairy_butterfly",(228,216,250)),("unicorn_galaxy",(214,222,255))]
strip=[t for t in strip if asset(t[0])]
sw=400; sgap=48; total=len(strip)*sw+(len(strip)-1)*sgap; sx0=(W-total)//2; sy=y+hh+72
for i,(a,tint) in enumerate(strip):
    card(bg,sx0+i*(sw+sgap),sy,sw,sw,tint,glit(asset(a),440,i+30),"")
pill(dr,sy+sw+58,"Mermaid - Rainbow - Aurora - Gold & more",font(44),INK)
bg.convert("RGB").save(os.path.join(OUTDIR,"store_screenshot_3_glitter.png"))
print("saved 3")
