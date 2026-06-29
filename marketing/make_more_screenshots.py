import os, random, math
from collections import deque
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT="/home/user/colouring-app-for-kids/ColoringFun/ColoringFun/Assets.xcassets"
OUTDIR="/home/user/colouring-app-for-kids/marketing"
FONT="/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
W,H=1290,2796
TOP,BOT=(255,247,219),(216,240,255)
INK=(60,52,96); PURP=(120,90,200)
PAL=[(255,138,128),(255,193,77),(129,212,250),(149,117,205),(244,143,177),
     (165,214,167),(255,171,145),(179,229,252),(206,147,216),(255,205,210),
     (178,235,242),(255,224,130),(197,225,165),(248,187,208),(128,222,234)]
TINTS=[(255,219,199),(204,230,255),(255,217,235),(255,222,168),(205,234,205),
       (228,216,250),(214,222,255),(255,214,204),(214,238,228),(245,221,238)]
def font(s): return ImageFont.truetype(FONT,s)
def asset(n):
    p=os.path.join(ROOT,f"{n}.imageset",f"{n}.png"); return p if os.path.exists(p) else None
def flat(path,maxw):
    im=Image.open(path).convert("RGBA"); s=maxw/im.width
    im=im.resize((maxw,max(1,int(im.height*s))))
    w=Image.new("RGBA",im.size,(255,255,255,255)); w.alpha_composite(im); return w.convert("RGB")
def colorize(path,maxw=420,seed=7):
    im=flat(path,maxw); Wd,Hd=im.size; data=list(im.getdata()); n=Wd*Hd
    wall=[(0.299*r+0.587*g+0.114*b)<140 for (r,g,b) in data]
    bg=[False]*n; dq=deque()
    for x in range(Wd):
        for yy in (0,Hd-1):
            i=yy*Wd+x
            if not wall[i] and not bg[i]: bg[i]=True; dq.append(i)
    for y in range(Hd):
        for xx in (0,Wd-1):
            i=y*Wd+xx
            if not wall[i] and not bg[i]: bg[i]=True; dq.append(i)
    while dq:
        i=dq.popleft(); x=i%Wd; y=i//Wd
        for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if 0<=nx<Wd and 0<=ny<Hd:
                j=ny*Wd+nx
                if not wall[j] and not bg[j]: bg[j]=True; dq.append(j)
    rng=random.Random(seed); out=[None]*n; vis=[False]*n
    for st in range(n):
        if wall[st] or bg[st] or vis[st]: continue
        col=PAL[rng.randrange(len(PAL))]; dq=deque([st]); vis[st]=True; reg=[st]
        while dq:
            i=dq.popleft(); x=i%Wd; y=i//Wd
            for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if 0<=nx<Wd and 0<=ny<Hd:
                    j=ny*Wd+nx
                    if not wall[j] and not bg[j] and not vis[j]: vis[j]=True; dq.append(j); reg.append(j)
        for i in reg: out[i]=col
    res=[(45,42,55) if wall[i] else ((255,255,255) if bg[i] else out[i]) for i in range(n)]
    img=Image.new("RGB",(Wd,Hd)); img.putdata(res); return img
def grad():
    g=Image.new("RGB",(W,H)); d=ImageDraw.Draw(g)
    for y in range(H):
        t=y/(H-1); d.line([(0,y),(W,y)],fill=tuple(int(TOP[i]*(1-t)+BOT[i]*t) for i in range(3)))
    return g.convert("RGBA")
def rmask(sz,r):
    m=Image.new("L",sz,0); ImageDraw.Draw(m).rounded_rectangle([0,0,sz[0],sz[1]],r,fill=255); return m
def fit(dr,txt,maxw,start):
    s=start
    while s>38:
        if dr.textbbox((0,0),txt,font=font(s))[2]<=maxw: return font(s)
        s-=4
    return font(38)
def center(dr,y,txt,f,fill):
    w=dr.textbbox((0,0),txt,font=f)[2]; dr.text(((W-w)//2,y),txt,font=f,fill=fill)
def pill(dr,y,txt,f,fill,bgc=(255,255,255,235)):
    w=dr.textbbox((0,0),txt,font=f)[2]; x=(W-w)//2-36
    dr.rounded_rectangle([x,y,x+w+72,y+f.size+38],46,fill=bgc); dr.text(((W-w)//2,y+18),txt,font=f,fill=fill)
def card(bg,x,y,cw,ch,tint,pimg,label=""):
    sh=Image.new("RGBA",(W,H),(0,0,0,0)); ImageDraw.Draw(sh).rounded_rectangle([x,y+12,x+cw,y+ch+12],46,fill=(60,40,90,55))
    bg.alpha_composite(sh.filter(ImageFilter.GaussianBlur(8)))
    ci=Image.new("RGBA",(cw,ch),(0,0,0,0)); cd=ImageDraw.Draw(ci); cd.rounded_rectangle([0,0,cw,ch],46,fill=tint+(255,))
    pad=22; s=min((cw-2*pad)/pimg.width,(ch-2*pad)/pimg.height); nw,nh=int(pimg.width*s),int(pimg.height*s)
    im=pimg.resize((nw,nh)).convert("RGBA"); im.putalpha(rmask((nw,nh),26)); ci.alpha_composite(im,((cw-nw)//2,(ch-nh)//2))
    cd.rounded_rectangle([4,4,cw-4,ch-4],44,outline=(255,255,255,255),width=9); bg.alpha_composite(ci,(x,y))
    if label:
        dr=ImageDraw.Draw(bg); lf=font(44); lw=dr.textbbox((0,0),label,font=lf)[2]; dr.text((x+(cw-lw)//2,y+ch+8),label,font=lf,fill=INK)

# ===== A: Before -> After =====
bg=grad(); dr=ImageDraw.Draw(bg)
center(dr,140,"Watch it come to life!",fit(dr,"Watch it come to life!",W-110,96),INK)
pill(dr,290,"Just tap to fill with color",font(50),PURP)
cw=560; y0=470
card(bg,55,y0,cw,cw,(236,236,245),flat(asset("unicorn_rainbow"),520),"Outline")
card(bg,W-55-cw,y0,cw,cw,(255,217,235),colorize(asset("unicorn_rainbow"),520,11),"Colored!")
ax=W//2; ay=y0+cw//2
dr.polygon([(ax-46,ay-34),(ax+10,ay-34),(ax+10,ay-60),(ax+62,ay),(ax+10,ay+60),(ax+10,ay+34),(ax-46,ay+34)],fill=PURP)
var=[a for a in ["princess_golden","fairy_butterfly","car_race","lion","trex","bird_peacock"] if asset(a)][:6]
sw=385; gp=46; mx=(W-3*sw-2*gp)//2; sy=1200
for idx,a in enumerate(var):
    r,c=divmod(idx,3); card(bg,mx+c*(sw+gp),sy+r*(sw+62),sw,sw,TINTS[idx%len(TINTS)],colorize(asset(a),350,idx*9+2))
pill(dr,sy+2*sw+62+34,"Animals - Fairies - Unicorns & more",font(44),INK)
bg.convert("RGB").save(os.path.join(OUTDIR,"store_screenshot_4_beforeafter.png")); print("A")

# ===== B: 100+ collage =====
bg=grad(); dr=ImageDraw.Draw(bg)
center(dr,140,"100+ Pictures to Color!",fit(dr,"100+ Pictures to Color!",W-100,96),INK)
pill(dr,290,"New favorites for every little artist",font(48),PURP)
items=["princess_golden","fairy_butterfly","unicorn_galaxy","lion","trex","bird_peacock",
       "car_police","princess_snow","unicorn_crystal","elephant","bird_flamingo","fairy_garden"]
items=[a for a in items if asset(a)][:12]
cols=3; mx=50; gp=34; cw=(W-2*mx-gp*(cols-1))//cols; ch=cw; sy=430
for idx,a in enumerate(items):
    r,c=divmod(idx,cols); x=mx+c*(cw+gp); y=sy+r*(ch+gp)
    card(bg,x,y,cw,ch,TINTS[idx%len(TINTS)],colorize(asset(a),360,idx*7+1))
pill(dr,sy+4*(ch+gp)+10,"Glitter - Sparkle - Stickers - Save & Share",font(42),INK)
bg.convert("RGB").save(os.path.join(OUTDIR,"store_screenshot_5_collage.png")); print("B")

# ===== C: Features =====
bg=grad(); dr=ImageDraw.Draw(bg)
center(dr,140,"Everything Kids Love",fit(dr,"Everything Kids Love",W-100,96),INK)
hero=colorize(asset("princess_golden"),640,seed=3)
hw=800; hh=int(hero.height*hw/hero.width); x=(W-hw)//2; y=360
sh=Image.new("RGBA",(W,H),(0,0,0,0)); ImageDraw.Draw(sh).rounded_rectangle([x,y+14,x+hw,y+hh+14],50,fill=(60,40,90,60))
bg.alpha_composite(sh.filter(ImageFilter.GaussianBlur(12)))
ci=Image.new("RGBA",(hw,hh),(0,0,0,0)); cd=ImageDraw.Draw(ci); cd.rounded_rectangle([0,0,hw,hh],50,fill=(255,236,210,255))
him=hero.resize((hw-40,hh-40)).convert("RGBA"); him.putalpha(rmask((hw-40,hh-40),34)); ci.alpha_composite(him,(20,20))
cd.rounded_rectangle([4,4,hw-4,hh-4],48,outline=(255,255,255,255),width=10); bg.alpha_composite(ci,(x,y))
feats=[("Draw your own pictures",(149,117,205)),("Glitter & Sparkle colors",(244,143,177)),
       ("Fun stickers to add",(255,171,77)),("Save & share your art",(129,200,170)),
       ("No ads - safe for kids",(120,180,240))]
fy=max(y+hh+60, 1460); ff=font(52)
for txt,dot in feats:
    pw=1050; px=(W-pw)//2
    dr.rounded_rectangle([px,fy,px+pw,fy+120],58,fill=(255,255,255,240))
    dr.ellipse([px+38,fy+40,px+82,fy+84],fill=dot)
    dr.text((px+116,fy+30),txt,font=ff,fill=INK)
    fy+=152
bg.convert("RGB").save(os.path.join(OUTDIR,"store_screenshot_6_features.png")); print("C")
