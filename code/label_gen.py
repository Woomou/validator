import numpy as np

RandomSamplingDiff = np.zeros((100),dtype=float)
RandomSamplingDiff_cnt = 0

MaxDiff = np.zeros((100),dtype=float)
MaxDiff_cnt = 0

_getrandom = lambda : np.random.uniform(-1,1,(1,6))

#迭代器可迭代提供标签数值
class LabelEnumerator(object):

    """
    Implements a iterator for generating label via Distance Maximum Strategy
    :param range_min: the minimum value of the label's boundary
    :param range_max: the maximum value of the label's boundary
    :return: a iterator for generating label
    """
    def __init__(self,range_min,range_max):
        self.get_bound = lambda sbit : range_min if int(sbit) == 0 else range_max
        self._features_num = 6
    def __iter__(self):
        self._iterSteps = int(pow(2,6))
        self._iterIndex = 0
        self._iterBinEnc = lambda string : 6 - len(string)
        return self
    def __next__(self):
        if(self._iterIndex < self._iterSteps):
            #根据索引确定一个二值编码
            bin_enc = bin(self._iterIndex)[2:]
            bin_enc = self._iterBinEnc(bin_enc)*"0" + bin_enc
            self._iterIndex += 1
            return np.array([[self.get_bound(bin_enc[0]),self.get_bound(bin_enc[1]),\
                              self.get_bound(bin_enc[2]),self.get_bound(bin_enc[3]),\
                              self.get_bound(bin_enc[4]),self.get_bound(bin_enc[5])]])
        else:
            raise StopIteration

class LabelGen(object):

    """
    Implements Algorithm of Distance Maximum Generator of the paper.
    :return: (ndarray6X1)a label vector
    """
    def __init__(self):
        self._LabelSet_MaxLength,self._Features_num = 1000,6 #标签集大小和输出特征空间大小
        self.y_label = np.zeros((self._LabelSet_MaxLength,self._Features_num),dtype='float')
        self._threshold = 1.0 #随机采样阈值
        self._decimal = 2 #数值正则化的定点数
        self._random_number_min = -5
        self._random_number_max = 5
        #即时返回(min,max)内的正则化的标签向量
        self._random = lambda : np.round(np.random.uniform(self._random_number_min,\
                                                                 self._random_number_max,\
                                                                 (1,self._Features_num)),self._decimal)
        self.densed = False
        self.label_num = 0
        self.RSDiff = 1
        self.requst_idx = 0
    #给出第一批标签，设置y_label,label_num,dist_dict(记录距离平方值)
    def first_label(self):
        self.y_label[0] = self._random()
        self.label_num = 1
        #在距离字典设置第一个标签
        self.dist_dict = dict()
        #设置第二个标签
        self.dist_dict["1"] = dict()
        self.y_label[1] = self._random()
        self.label_num += 1
        self.dist_dict["2"] = dict()
        y_fir2sec_dist = np.sqrt(np.sum((self.y_label[0]-self.y_label[1])**2))
        self.dist_dict["2"]["1"] = y_fir2sec_dist
        return
    #功能：计算一个给出的标签label与y_label中各数据点的欧式距离
    #参数：label格式为(1x6)ndarray
    #返回：label与各数据点的距离
    def label_validate(self,label):
        label.resize(6)
        #N to N+1的距离
        y_n2nn_dist = (self.y_label[self.label_num-1]-label)**2
        sum_y_n2nn_dist = np.sqrt(np.sum(y_n2nn_dist))
        '''
        dist["1"~"label_num"]["1"~"label_num-1"]，第一个键为数据点，第二个键指示与哪个数据点的距离
        '''
        accumlator = int(0) + sum_y_n2nn_dist
        for i in range(self.label_num-1):#0~(N-1)个
            #P to N距离，P~(1,N-1)
            y_p2n_dist = (self.dist_dict[str(self.label_num)][str(i+1)])**2 + \
                         (sum_y_n2nn_dist)**2 - 2*np.dot( \
                         self.y_label[i] - self.y_label[self.label_num-1],\
                         label - self.y_label[self.label_num-1])
            accumlator += np.sqrt(y_p2n_dist)
        return accumlator
    #功能：计算一个给出的标签label与y_label中各数据点的距离，并记录到字典
    #参数：label格式为(1x6)ndarray
    #返回：无
    def label_record(self,label):
        #创建字典，保存N to N+1到字典
        y_n2nn_dist = (self.y_label[self.label_num-1]-label)**2
        sum_y_n2nn_dist = np.sqrt(np.sum(y_n2nn_dist))
        self.dist_dict[str(self.label_num+1)] = dict()
        self.dist_dict[str(self.label_num+1)][str(self.label_num)] = sum_y_n2nn_dist
        #保存P to N+1到字典
        for i in range(self.label_num-1):
            y_p2n_dist = (self.dist_dict[str(self.label_num)][str(i+1)])**2 + \
                         (sum_y_n2nn_dist)**2 - 2*np.dot( \
                         self.y_label[i] - self.y_label[self.label_num-1],\
                         label - self.y_label[self.label_num-1])
            self.dist_dict[str(self.label_num+1)][str(i+1)] = np.sqrt(y_p2n_dist)
        #更新label_num和y_label
        self.label_num += 1
        self.y_label[self.label_num - 1] = label
        return
    def label_gen(self):
        #当测试的label在validate中与随机采样差异不大时，可以认为<数据点密集>
        if(self.densed):
            label = self._random()
            label.resize(6)
            self.label_record(label) # 直接记录随机值
            return
        if(self.label_num == 0):
            self.first_label()
            return
        LabelEnum = LabelEnumerator(range_min=self._random_number_min*(1/np.ceil(self.label_num/5)),\
                                    range_max=self._random_number_max*(1/np.ceil(self.label_num/5)))
        Max_label,Max_dist = np.zeros((1,6)),0
        for label in LabelEnum:
            dist = self.label_validate(label)
            if(dist > Max_dist): #记录最大值情况
                Max_dist = dist
                Max_label = label
        global MaxDiff
        global MaxDiff_cnt
        MaxDiff[MaxDiff_cnt] = np.round(Max_dist,3)
        MaxDiff_cnt += 1
        #测试Max_label与随机采样的差距，这里采样5个并且平均一下
        avg_dist = sum([self.label_validate(self._random()) for x in range(5)])/5
        
        if(avg_dist + self._threshold > Max_dist):
            self.densed = True
        global RandomSamplingDiff
        global RandomSamplingDiff_cnt
        RandomSamplingDiff[RandomSamplingDiff_cnt] = np.round(Max_dist-avg_dist,3)
        RandomSamplingDiff_cnt += 1
        #将最大的Label进行储存
        self.label_record(Max_label)
        return
    def getLabel(self):
        if(self.requst_idx >= self.label_num):
            diff = self.requst_idx - self.label_num
            diff = 1 if diff == 0 else diff
            for _ in range(diff):
                self.label_gen()
        label = self.y_label[self.requst_idx]
        self.requst_idx += 1
        return label.reshape(6,1)
#数值正则化
def numericalregularization(label,decimal):
    return np.round(label,decimal)
#混洗方法，根据长度(范围)和混洗个数得到 混洗个数的索引
from random import randint
shuffle_idx = lambda len,i : [randint(0,len-1) for x in range(i)]
#分拆方法，要求partion是1,2,6之一，其余不写处理算法
def partionregularization(label,partion):
    label = label.reshape(6,1)
    if(partion==1):
        return [label]
    elif(partion==6):
        label_seq = [np.zeros((6,1),dtype=float) for i in range(6)]#生成6个零向量
        for i in range(6):
            label_seq[i] = label[i]
        return label_seq
    elif(partion==2):
        global shuffle_idx
        label1,label2 = np.zeros((6,1),dtype=float),np.zeros((6,1),dtype=float)
        s_idx = shuffle_idx(6,3)
        for i in range(6):
            if(i in s_idx):
                label1[i] = label[i]
            else:
                label2[i] = label[i]
        return [label1,label2]
    else:
        return []
#绑定“生成标签按钮”
_lg = LabelGen()
LABELGEN_QWIN = 0
LABELGEN_TEMP = 0
TASK_TABLE = [0 for i in range(5)]

def btn_gen_label_init(Qwin):
    global LABELGEN_QWIN
    LABELGEN_QWIN = Qwin
    def btn_gen_label():
        global _lg,LABELGEN_QWIN
        demical_reg = int(Qwin.spinBox.value())
        partion_reg = int(Qwin.spinBox_2.value())
        strategy = Qwin.comboBox.currentText()
        label = _lg.getLabel() if strategy == '距离最大化' else _getrandom()
        label = numericalregularization(label,demical_reg)
        label = partionregularization(label,partion_reg)
        for l in enumerate(label):
            Qwin.textBrowser_6.insertPlainText("目标标签:")
            _l = label[l].reshape(1,6)
            Qwin.textBrowser_6.insertPlainText(\
                'Y:%.3f,θ:%.3f,φ:%.3f,ψ:%.3f,X:%.3f,Z:%.3f\n'%(\
                _l[0][0],_l[0][1],_l[0][2],_l[0][3],_l[0][4],_l[0][5]))
        global LABELGEN_TEMP
        LABELGEN_TEMP = label
        return
    Qwin.pushButton.clicked.connect(btn_gen_label)
    return

CREATE_TASK_WIN = 0
TASK_CURSOR = 0
def bth_create_task_init(Qwin):
    global CREATE_TASK_WIN
    CREATE_TASK_WIN = Qwin
    def btn_create_task():
        global TASK_TABLE,TASK_CURSOR,CREATE_TASK_WIN
        task_name = int(CREATE_TASK_WIN.comboBox_2.currentText())
        TASK_CURSOR = task_name
        TASK_TABLE[task_name-1] = LABELGEN_TEMP
        Qwin.textBrowser_6.insertPlainText("已保存为任务%d号\n"%task_name)
        Qwin.label_4.setText("第%d个任务已创建，就绪"%task_name)
        return
    Qwin.pushButton_7.clicked.connect(btn_create_task)
    return

input_X = 0
cursor_X = 0
store_cursor_X = 0
#该方法开始任务，记录键盘事件流
def btn_start_task_init(Qwin):
    def btn_start_task():
        global cursor_X,store_cursor_X,TASK_CURSOR
        store_cursor_X = cursor_X
        Qwin.label_4.setText("第%d个任务开始"%TASK_CURSOR)
        return
    Qwin.pushButton_8.clicked.connect(btn_start_task)
    return

#该方法重置任务，重启键盘事件流的记录
def btn_reset_task_init(Qwin):
    def btn_reset_task():
        global cursor_X,store_cursor_X
        store_cursor_X = cursor_X
        Qwin.label_4.setText("第%d个任务重启"%TASK_CURSOR)
        return
    Qwin.pushButton_5.clicked.connect(btn_reset_task)
    return

class pair(object):
    """
    A pair of two elements
    :param x: the first element
    :param y: the second element
    :val x: the first element
    :val y: the second element
    """
    def __init__(self,x,y):
        self.x = x
        self.y = y

DATA_PAIRS = []
#该方法结束任务，得到待截取的数据对
def btn_end_task_init(Qwin):
    def btn_end_task():
        global input_X,cursor_X,store_cursor_X,TASK_CURSOR,TASK_TABLE,DATA_PAIRS
        range_x = cursor_X - store_cursor_X#得到可截取数据对的长度
        pairs = [pair(0,0) for i in range(range_x)]
        for i in range(range_x):
            #input_X为Nx6向量
            pairs[i].x = input_X[store_cursor_X+i]
        #这里假定TASK_TABLE[TASK_CURSOR]为6X1向量，暂时不考虑组合正则化
        if(isinstance(TASK_TABLE[TASK_CURSOR]) == np.ndarray):
            y_label_interval = TASK_TABLE[TASK_CURSOR]/range_x
        else:
            #切分y为小段
            y_label_interval = TASK_TABLE[TASK_CURSOR][0]/range_x
        for i in range(range_x):
            pairs[i].y = y_label_interval*(i+1)
        DATA_PAIRS = pairs
        Qwin.label_4.setText("第%d个任务结束"%TASK_CURSOR)
        return
    Qwin.pushButton_3.clicked.connect(btn_end_task)
    return

CUT_DATA_WIN = 0
CUT_DATA_TEMP = []
def btn_cut_data_init(Qwin):
    global CUT_DATA_WIN
    CUT_DATA_WIN = Qwin
    def btn_cut_data():
        global DATA_PAIRS,CUT_DATA_WIN
        M = CUT_DATA_WIN.textEdit.toPlainText()
        M = int(M)
        if(M > len(DATA_PAIRS)):
            Qwin.label_4.setText("超过数据长度")
            return
        sample_step = (int)(len(DATA_PAIRS) / M)
        DATA_X = [p.x for p in DATA_PAIRS]
        DATA_Y = [p.y for p in DATA_PAIRS]
        DATA_X = [sum(x)/sample_step for x in [DATA_X[i*sample_step:i*sample_step+(sample_step-1)] for i in range(M)]]
        DATA_Y = [sum(x)/sample_step for x in [DATA_Y[i*sample_step:i*sample_step+(sample_step-1)] for i in range(M)]]
        out_format = lambda x : 'Y:%.3f,θ:%.3f,φ:%.3f,ψ:%.3f,X:%.3f,Z:%.3f\n'%(x[0],x[1],x[2],x[3],x[4],x[5])
        for i in range(M):
            CUT_DATA_WIN.textBrowser_5.insertPlainText("第%d对："%i)
            CUT_DATA_WIN.textBrowser_5.insertPlainText(
                "Input:%s Output:%s\n"%(out_format(DATA_X[i]),out_format(DATA_Y[i]))
            )
        global CUT_DATA_TEMP
        CUT_DATA_TEMP = [DATA_X,DATA_Y]
        return
    Qwin.pushButton_4.clicked.connect(btn_cut_data)
    return

