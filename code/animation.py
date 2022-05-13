import time
import threading
CONTINUM = 1
RESOLUTION = 200

#该类播放固定一个任务的动画
class animation(object):
    """
    Implement the animation effect.
    :param Qwin: The Qwindow object of broadcasting animation.
    :param actor: The VTK actor object of QWindow.
    :param label: The target state space label.
    :type Qwin: QWindow
    :type actor: vtkActor
    :type label: ndarray 6X1
    """
    def __init__(self,Qwin):
        self.Qwin = Qwin
        self.broadcast = False#停止播放信号
    #持续时间（秒数）
    def setContinum(self,continum):
        self.continum = continum
        return
    #res为一秒的分割数，表示分辨率
    def setResolution(self,resolution):
        self.resolution = resolution
        return
    def getStep(self):
        return self.continum * self.resolution
    def setLabel(self,label):
        self.label = label
    def getLabel(self):
        return self.label
    def runAnimation(self):
        step = self.getStep()
        label = self.getLabel()
        actor = self.Qwin.actors[0]
        def _run(Qwin,actor,label,step):
            #label为目标状态空间的标签值，SetPosition需要有基坐标的运算
            #根据i返回该维度下切分步数下的幅度
            lstep = lambda i : label[i]/step
            while(True):
                i = 1
                while(i<=step):
                    actor.SetPosition(lstep(0)*i,\
                                                lstep(1)*i,\
                                                lstep(2)*i)
                    actor.RotateX(lstep(3))
                    actor.RotateY(lstep(4))
                    actor.RotateZ(lstep(5))
                    Qwin.VisualTarget.update()
                    i += 1
                    time.sleep(1/RESOLUTION)
                time.sleep(0.25)
                actor.SetPosition(0,0,0)
                actor.RotateX(-label[3])
                actor.RotateY(-label[4])
                actor.RotateZ(-label[5])
                time.sleep(0.25)
        thread = threading.Thread(target=_run,kwargs={\
                "Qwin":self.Qwin,"actor":actor,\
                "label":label,"step":step})
        thread.start()
        self.thread = thread
        return
    def endAnimation(self):
        self.thread.join()
        return
