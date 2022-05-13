from PyQt5.QtWidgets import QApplication, QMainWindow
import sys
import os
code_path = "./code/"
os.chdir(code_path)
from ui_layout import Ui_MainWindow
app = QApplication(sys.argv) 
win = Ui_MainWindow()
qwin = QMainWindow()
win.setupUi(qwin)
qwin.show()
win.Scene_Initialize()
win.rend_target.Initialize()
win.rend_target.Start()
win.rend_realtime.Initialize()
win.rend_realtime.Start()
#导入波形图开启类
import wave_open
#初始化波形
wave_open = wave_open.wave_open(win)
#导入实时键盘数据生成
import wave_gen_bykeyboard # Noncompliant
from wave_gen_bykeyboard import * # Noncompliant
#初始化实时键盘数据流
wave_gen = wave_gen()
#已导入WAVE_RECORD和WAVE_RECORD_CURSOR
wave_gen_bykeyboard.realtime_show(win.textBrowser_2)#对文字窗口实时输出
wave_gen_bykeyboard.realtime_anime(win,win.actors[1])#对图形窗口实时输出
import animation # Noncompliant
anime = animation.animation(win)#用于目标窗口的播放
import label_gen # Noncompliant
from label_gen import * # Noncompliant
input_X = wave_gen_bykeyboard.WAVE_RECORD
cursor_X = wave_gen_bykeyboard.WAVE_RECORD_CURSOR
label_gen.btn_gen_label_init(win)
label_gen.bth_create_task_init(win)
sys.exit(app.exec_())