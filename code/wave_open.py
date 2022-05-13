#统一处理所有波形窗口
from array import array
import pyqtgraph as pg
import numpy as np
import pyqtgraph as pg

class wave_startup():
    """
    Implements the specified waveform 's initialization work.
    :param plot: The waveform to be initialized.
    :type plot: pyqtgraph.PlotWidget
    :param Qwin: The window that contains the waveform.
    :type Qwin: QMainWindow
    :param width: The width of the waveform.
    :type width: int
    :param height: The height of the waveform.
    :type height: int
    """
    def __init__(self,plot,Qwin,width,height) -> None:
        self.WIN_WIDTH = 100#显示10s内的数据
        self.WIN_HEIGHT = 1#Y数据的范围最大值的绝对值
        plot.showGrid(x=True, y=True)
        self.plot = plot
        self.Qwin = Qwin
        self.plot_idx = 0
        self.data = array('d')
    def draw_wave(self) -> None:
        p = self.plot
        WIN_WIDTH = self.WIN_WIDTH
        WIN_HEIGHT = self.WIN_HEIGHT
        Qwin = self.Qwin
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
        return
    def plotData(self):
        temp = np.cos(np.pi/50*self.plot_idx)
        if(len(self.data) < self.WIN_WIDTH):
            self.data.append(temp)
        else:
            self.data[:-1] = self.data[1:]
            self.data[-1] = temp
        self.plot.setData(self.data)
        self.plot_idx += 1
        return
    def start_timer(self):
        timer = pg.QtCore.QTimer()
        wave_timer = timer.timeout.connect(self.plotData())
        wave_timer.start(100)
        self.wave_timer = wave_timer
        return


class wave_open(object):
    """
    Initialize the data-stream and ploting of wave graph.
    :param Qwin: The top parent Qwindow of wave graph.
    """
    def __init__(self,Qwin) -> None:
        _WIN_WIDTH = 100#显示10s内的数据
        _WIN_HEIGHT = 1#Y数据的范围最大值的绝对值
        wave_win = [Qwin.RealtimeInputData,\
            Qwin.TaskData,\
            Qwin.LossWaveGraph,\
            Qwin.PrecisionWaveGraph]
        startup = [wave_startup(wave_obj,Qwin,_WIN_WIDTH,_WIN_HEIGHT) for wave_obj in wave_win]
        self.wave_list = startup
        for wave_obj in startup:
            wave_obj.draw_wave()
            wave_obj.start_timer()
    
