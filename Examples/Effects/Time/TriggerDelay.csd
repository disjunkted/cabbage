
/* Attribution-NonCommercial-ShareAlike 4.0 International
Attribution - You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
NonCommercial - You may not use the material for commercial purposes.
ShareAlike - If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode */

; TriggerDelay.csd
; Written by Iain McCurdy, 2012.

; This example works best with sharp percussive sounds

; A trigger impulse is generated each time the rms of the input signal crosses the defined 'Threshold' value.
; Each time a new trigger is generated a new random delay time (between user definable limits)
; - and a new random feedback value (again between user definable limits) are generated.

; It is possible to generate feedback values of 1 and greater (which can lead to a continuous build-up of sound)
;  this is included intentionally and the increasing sound will be clipped and can be filtered by reducing the 'Damping' control to produce increasing distortion of the sound within the delay buffer as it repeats 

; Increasing the 'Portamento' control damps the otherwise abrupt changes in delay time.

; 'Width' allows the user to vary the delay from a simple monophonic delay to a ping-pong style delay

<Cabbage>
form caption("Trigger Delay") size(540,240), pluginId("TDel")
image                  bounds(0, 0,540,240), colour(150,150,205), shape("rounded"), outlineColour("white"), outlineThickness(4) 

rslider  bounds(  5, 11, 70, 70),  text("Threshold"), textColour("black"),  channel("threshold"), range(0, 1.00, 0.1, 0.5),      colour( 40, 40, 95),trackerColour("white")

label    bounds(210,102,80,15), text("TRIGGER"), fontColour("black"), colour(150,150,205)
checkbox bounds(230,120,40,40), channel("TriggerIndicator"), shape("ellipse")                                          
                                                                                    
line     bounds( 83, 10, 95, 3), colour("Grey")
label    bounds(100,  6, 60, 10), text("DELAY TIME"), fontColour("black"), colour(150,150,205)

rslider bounds( 72, 18, 63, 63),  text("Min."),        textColour("black"),  channel("dly1"),     range(0.0001, 2, 0.001,0.5), colour( 40, 40, 95),trackerColour("white")
rslider bounds(130, 18, 63, 63), text("Max."),         textColour("black"),  channel("dly2"),     range(0.0001, 2, 0.1, 0.5),  colour( 40, 40, 95),trackerColour("white")

line     bounds(202, 10,  95,  3), colour("Grey")
label    bounds(222,  6,  55, 10), text("FEEDBACK"), fontColour("black"), colour(150,150,205)

rslider bounds(190, 18, 63, 63), text("Min."),      textColour("black"),  channel("fback1"),     range(0, 1.200, 0.5),        colour( 40, 40, 95),trackerColour("white")
rslider bounds(248, 18, 63, 63), text("Max."),      textColour("black"),  channel("fback2"),     range(0, 1.200, 0.9),        colour( 40, 40, 95),trackerColour("white")

rslider bounds(  5, 81, 70, 70), text("Portamento"), textColour("black"),  channel("porttime"),     range(0,  5.00, 0,0.5),         colour( 40, 40, 95),trackerColour("white")
rslider bounds( 65, 81, 70, 70), text("Cutoff"),     textColour("black"),  channel("cf"),     range(50,10000, 5000,0.5), colour( 40, 40, 95),trackerColour("white")
rslider bounds(125, 81, 70, 70), text("Bandwidth"),  textColour("black"),  channel("bw"),     range(600,22050, 4000,0.5), colour( 40, 40, 95),trackerColour("white")

rslider bounds(  5,151, 70, 70), text("Width"),        textColour("black"),  channel("width"),     range(0,  1.00, 1),         colour( 40, 40, 95),trackerColour("white")
rslider bounds( 65,151, 70, 70), text("Mix"),         textColour("black"),  channel("mix"),     range(0, 1.00, 0.5),        colour( 40, 40, 95),trackerColour("white")
rslider bounds(125,151, 70, 70), text("Level"),        textColour("black"),  channel("level"),     range(0, 1.00, 1),          colour( 40, 40, 95),trackerColour("white")


xypad bounds(315, 5, 210, 230), channel("cf", "bw"), rangeX(50, 10000, 5000), rangeY(600, 22050, 4000), text("CF/BW")
}                 
</Cabbage>

<CsoundSynthesizer>                       

<CsOptions>
-d -n
</CsOptions>

<CsInstruments>

; sr set by host
ksmps         =     32    ;NUMBER OF AUDIO SAMPLES IN EACH CONTROL CYCLE
nchnls         =     2    ;NUMBER OF CHANNELS (2=STEREO)
0dbfs        =    1

;Author: Iain McCurdy (2012)

instr    1
    kthreshold    chnget    "threshold"                ;read in widgets
    kdly1        chnget    "dly1"                ;read in widgets
    kdly2        chnget    "dly2"                ;read in widgets
    kfback1        chnget    "fback1"                ;read in widgets
    kfback2        chnget    "fback2"                ;read in widgets
    kwidth        chnget    "width"                ;
    kmix        chnget    "mix"                ;
    klevel        chnget    "level"                ;
    kporttime    chnget    "porttime"                ;
    kcf        chnget    "cf"
    kbw        chnget    "bw"
    ainL,ainR    ins                ;read stereo inputs

    krms    rms    (ainL+ainR)*0.5
    
    ktrig    trigger    krms, kthreshold, 0
    
    kdly    trandom    ktrig, 0, 1
    kdly    expcurve    kdly,8
    kMinDly    min    kdly1,kdly2
    kdly    =    (kdly * abs(kdly2 - kdly1) ) + kMinDly
    
    
    kramp    linseg    0,0.001,1
    
    kcf    portk    kcf, kramp * 0.05
    kbw    portk    kbw, kramp * 0.05
    
    kdly    portk    kdly, kporttime*kramp
    atime    interp    kdly

    kfback    trandom    ktrig, kfback1, kfback2
    schedkwhen ktrig, 0, 0, 2, 0, 0.2
    
    ;offset delay (no feedback)
    abuf    delayr    5
    afirst    deltap3    atime
    afirst    butbp    afirst,kcf,kbw
        delayw    ainL

    ;left channel delay (note that 'atime' is doubled) 
    abuf    delayr    10            ;
    atapL    deltap3    atime*2
    atapL    clip    atapL,0,0.9
    atapL    butbp    atapL,kcf,kbw
        delayw    afirst+(atapL*kfback)

     ;right channel delay (note that 'atime' is doubled) 
     abuf    delayr    10
     atapR    deltap3    atime*2
     atapR    clip    atapR,0,0.9
     atapR    butbp    atapR,kcf,kbw
        delayw    ainR+(atapR*kfback)
    
     ;create width control. note that if width is zero the result is the same as 'simple' mode
     atapL    =    afirst+atapL+(atapR*(1-kwidth))
     atapR    =    atapR+(atapL*(1-kwidth))
    
    amixL        ntrpol        ainL, atapL, kmix    ;CREATE A DRY/WET MIX BETWEEN THE DRY AND THE EFFECT SIGNAL
    amixR        ntrpol        ainR, atapR, kmix    ;CREATE A DRY/WET MIX BETWEEN THE DRY AND THE EFFECT SIGNAL
            outs        amixL * klevel, amixR * klevel
endin

instr 2
chnset 1-release:k(), "TriggerIndicator"
endin


</CsInstruments>

<CsScore>
i 1 0 [3600*24*7]
</CsScore>

</CsoundSynthesizer>
