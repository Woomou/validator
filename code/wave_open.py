#统一处理所有波形窗口
from array import array
import pyqtgraph as pg
import numpy as np
class wave_open(object):
    def __init__(self,Qwin):
        WIN_WIDTH = 100#显示10s内的数据
        WIN_HEIGHT = 1#Y数据的范围最大值的绝对值
        wave_win = [Qwin.RealtimeInputData,\
            Qwin.TaskData,\
            Qwin.LossWaveGraph,\
            Qwin.PrecisionWaveGraph]
        for p in wave_win:
            p.showGrid(x=True, y=True)
            if(p == Qwin.RealtimeInputData):
                p.setRange(xRange=[0,WIN_WIDTH], yRange=[-WIN_HEIGHT, WIN_HEIGHT], padding=0)
                p.setLabel(axis='left', text='输入特征')
            elif(p == Qwin.TaskData):
                p.setRange(xRange=[0,WIN_WIDTH], yRange=[-WIN_HEIGHT, WIN_HEIGHT], padding=0)
                p.setLabel(axis='left', text='目标特征')
            elif(p == Qwin.LossWaveGraph):
                p.setRange(xRange=[0,WIN_WIDTH], yRange=[0, WIN_HEIGHT], padding=0)
                p.setLabel(axis='left', text='平均LOSS')
                p.setTitle("神经网络损失")
                p.setLabel(axis='bottom', text='时间')
            elif(p == Qwin.PrecisionWaveGraph):
                p.setRange(xRange=[0,WIN_WIDTH], yRange=[0, WIN_HEIGHT], padding=0)
                p.setLabel(axis='left', text='预测精度')
                p.setTitle("神经网络预测精度")
                p.setLabel(axis='bottom', text='时间')
        #每项具体指向参考wave_win的索引
        wave_plot = [p.plot() for p in wave_win]
        wave_plot_idx = [0 for i in range(len(wave_win))]
        wave_data = [array('f') for i in range(len(wave_win))]
        self.wave_win = wave_win
        self.wave_plot = wave_plot
        self.wave_plot_idx = wave_plot_idx
        self.wave_data = wave_data
        self.WIN_WIDTH = WIN_WIDTH
        self.WIN_HEIGHT = WIN_HEIGHT
        def plotData1(self,which):
            #生成示例数据
            #temp = self.wave_data[which][self.wave_plot_idx[which]]
            temp = np.cos(np.pi/50*self.wave_plot_idx[which])
            if(len(self.wave_data[which]) < self.WIN_WIDTH):
                self.wave_data[which].append(temp)
            else:
                self.wave_data[which][:-1] = self.wave_data[which][1:]
                self.wave_data[which][-1] = temp
            self.wave_plot[which].setData(self.wave_data[which])
            self.wave_plot_idx[which] += 1
            return
        def plotData2(self,which):
            #生成示例数据
            #temp = self.wave_data[which][self.wave_plot_idx[which]]
            temp = np.cos(np.pi/50*self.wave_plot_idx[which])
            if(len(self.wave_data[which]) < self.WIN_WIDTH):
                self.wave_data[which].append(temp)
            else:
                self.wave_data[which][:-1] = self.wave_data[which][1:]
                self.wave_data[which][-1] = temp
            self.wave_plot[which].setData(self.wave_data[which])
            self.wave_plot_idx[which] += 1
            return
        def plotData3(self,which):
            #生成示例数据
            #temp = self.wave_data[which][self.wave_plot_idx[which]]
            temp = np.cos(np.pi/50*self.wave_plot_idx[which])
            if(len(self.wave_data[which]) < self.WIN_WIDTH):
                self.wave_data[which].append(temp)
            else:
                self.wave_data[which][:-1] = self.wave_data[which][1:]
                self.wave_data[which][-1] = temp
            self.wave_plot[which].setData(self.wave_data[which])
            self.wave_plot_idx[which] += 1
            return
        def plotData4(self,which):
            #生成示例数据
            #temp = self.wave_data[which][self.wave_plot_idx[which]]
            temp = np.cos(np.pi/50*self.wave_plot_idx[which])
            if(len(self.wave_data[which]) < self.WIN_WIDTH):
                self.wave_data[which].append(temp)
            else:
                self.wave_data[which][:-1] = self.wave_data[which][1:]
                self.wave_data[which][-1] = temp
            self.wave_plot[which].setData(self.wave_data[which])
            self.wave_plot_idx[which] += 1
            return
        wave_timer = [pg.QtCore.QTimer() for i in range(len(wave_win))]
        for i in range(len(wave_timer)):
            if(i==0):
                wave_timer[0].timeout.connect(lambda:plotData1(self,0))
            elif(i==1):
                wave_timer[1].timeout.connect(lambda:plotData2(self,1))
            elif(i==2):
                wave_timer[2].timeout.connect(lambda:plotData3(self,2))
            elif(i==3):
                wave_timer[3].timeout.connect(lambda:plotData4(self,3))
            wave_timer[i].start(100)#多少ms更新一次，设定为100ms=0.1s更新一次
        self.wave_timer = wave_timer
    
