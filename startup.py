from PyQt5 import QtCore, QtGui, QtWidgets
from PyQt5.QtWidgets import QApplication, QMainWindow
from MainWindow import Ui_MainWindow
import pyqtgraph as pg
import vtk
from vtk.qt.QVTKRenderWindowInteractor import QVTKRenderWindowInteractor
import keyboard
import numpy as np
import time
import threading
import pyqtgraph as pg
import sys
import os
code_path = "./code/"
os.chdir(code_path)
with open(code_path+'ui_layout.py', encoding='utf-8') as code:
    exec_code = code.read()
    exec(exec_code)
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
from wave_gen_bykeyboard import * # Noncompliant
#初始化实时键盘数据流
wave_gen = wave_gen()
#已导入WAVE_RECORD和WAVE_RECORD_CURSOR
realtime_show(win.textBrowser_2)#对文字窗口实时输出
realtime_anime(win,win.actors[1])#对图形窗口实时输出
from animation import *  # Noncompliant
anime = animation(win)#用于目标窗口的播放
from label_gen import * # Noncompliant
input_X = WAVE_RECORD
cursor_X = WAVE_RECORD_CURSOR
btn_gen_label_init(win)
bth_create_task_init(win)
sys.exit(app.exec_())