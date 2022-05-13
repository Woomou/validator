import numpy as np
import time
import threading
import keyboard
MAX_FLOW_LEN = 6000 - 1
#FLOW保存每0.01s=10ms发生的键盘变动值，共1min，长度为6_000
FLOW = np.zeros((MAX_FLOW_LEN,6),dtype=float)
#FLOW游标，当超过最大值时就重新回到原点覆盖
FLOW_CURSOR = int(0)
TEMP = np.zeros((6,1),dtype=float)
#读取任意两个时刻的差值数据，
WAVE = np.zeros((6,1),dtype=float)
MAX_WAVE_RECORD_LEN = 4000 - 1
#0.015s一次，记录1min内即可=60s=0.015*4000s
WAVE_RECORD = np.zeros((MAX_WAVE_RECORD_LEN,6),dtype=float)
WAVE_RECORD_CURSOR = int(0)

def _timer():
    global FLOW_CURSOR,MAX_FLOW_LEN,FLOW,TEMP
    start_time = time.time()
    while(True):
        if(time.time()-start_time > 0.01):
            FLOW_CURSOR += 1
            #游标达到最大值会返回开始点
            if(FLOW_CURSOR > MAX_FLOW_LEN):
                FLOW_CURSOR = 0
            FLOW[FLOW_CURSOR] = TEMP.reshape(1,6)
            start_time = time.time()
        else:
            time.sleep(0.01)

def _spliter():
    global FLOW_CURSOR,WAVE
    start_time = time.time()
    while(True):
        if(time.time()-start_time > 0.015 and FLOW_CURSOR>1):
            WAVE = FLOW[FLOW_CURSOR] - FLOW[FLOW_CURSOR-1]
            start_time = time.time()
        else:
            time.sleep(0.015)

def _refresh():
    global WAVE_RECORD_CURSOR,MAX_WAVE_RECORD_LEN,WAVE_RECORD,WAVE
    while(True):
    #每隔0.015s访问wave求新数值并输出
    #W键0上 S键1下 A键2左 D键3右 Q键4前 E键5后
        if(WAVE_RECORD_CURSOR >= MAX_WAVE_RECORD_LEN):
            WAVE_RECORD_CURSOR = 0
        WAVE_RECORD[WAVE_RECORD_CURSOR] = WAVE.reshape(1,6)
        time.sleep(0.015)

class wave_gen():
    """
    Startup the global real-time event data-stream.
    :type thread_timer: thread of "FLOW"
    :type thread_spliter: thread of "WAVE"
    :type thread_wave: thread of "WAVE_RECORD"
    """
    def __init__(self):
        global _timer,_spliter,_refresh
        #0.01s定时器，统计一段时间内发生的键盘数变动，每两段时间点之差值即为所求
        self.thread_timer = threading.Thread(target=_timer,kwargs={})
        self.thread_timer.start()
        #WAVE更新时间
        self.thread_spliter = threading.Thread(target=_spliter,kwargs={})
        self.thread_spliter.start()
        #WAVE_RECORD更新时间
        self.thread_wave = threading.Thread(target=_refresh,kwargs={})
        self.thread_wave.start()

w_down = keyboard.KeyboardEvent(event_type='down',scan_code=17,name="w_down")
setattr(w_down,'scanner_index',0)
s_down = keyboard.KeyboardEvent(event_type='down',scan_code=31,name="s_down")
setattr(s_down,'scanner_index',1)
a_down = keyboard.KeyboardEvent(event_type='down',scan_code=30,name="a_down")
setattr(a_down,'scanner_index',2)
d_down = keyboard.KeyboardEvent(event_type='down',scan_code=32,name="d_down")
setattr(d_down,'scanner_index',3)
q_down = keyboard.KeyboardEvent(event_type='down',scan_code=16,name="q_down")
setattr(q_down,'scanner_index',4)
e_down = keyboard.KeyboardEvent(event_type='down',scan_code=18,name="e_down")
setattr(e_down,'scanner_index',5)
events = [w_down,s_down,a_down,d_down,q_down,e_down]
def response(x):
    #W键17 S键31 A键30 D键32 Q键16 E键18
    for event in events:
        if(event.scan_code == x.scan_code):
            TEMP[event.scanner_index][0] += 1
            break
    return
keyboard.hook(response)#开启键盘响应循环
#绑定到一个指令流实时输出窗口
from PyQt5.QtGui import QTextCursor
def realtime_show(Browser):
    def _refresh(browser):
        global WAVE
        while(True):
            #每隔0.15s访问WAVE求新数值并输出
            #W键0 Y S键1 θ A键2 φ D键3 ψ Q键4 X E键5后 Z
            browser.insertPlainText('实时传感器数值：'+\
                        'Y:%.3f,θ:%.3f,φ:%.3f,ψ:%.3f,X:%.3f,Z:%.3f\n'%(\
                        WAVE[0],WAVE[1],\
                        WAVE[2],WAVE[3],\
                        WAVE[4],WAVE[5]))
            browser.moveCursor(QTextCursor.End)
            time.sleep(0.015)
    thread_textbrowser = threading.Thread(target=_refresh,kwargs={\
                                            "browser":Browser})
    thread_textbrowser.start()
    return

#将[-1,1]的数值映射到[-180,180]
angle_map = lambda x : 180 * x

def realtime_anime(Qwin,actor):
    def _run(Qwin,actor):
        global WAVE
        global angle_map
        while(True):
            label = WAVE/50
            actor.SetPosition(label[0],label[1],label[2])
            actor.RotateX(angle_map(label[3]))
            actor.RotateY(angle_map(label[4]))
            actor.RotateZ(angle_map(label[5]))
            Qwin.VisualRealtime.update()
            time.sleep(0.015)
    thread = threading.Thread(target=_run,kwargs={\
            "Qwin":Qwin,"actor":actor})
    thread.start()
    return
