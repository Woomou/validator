from time import time
from numpy import double
import torch
import torch.nn as nn
from torch.autograd import Variable
import torch.optim as optim
import threading
import random
import gc

class Net(nn.Module):

    """
    Override and Allow User to define A customized network architecture
    :param hidden_size: the input width and output width of hidden layer
    :param hidden_num: the number of hidden layers
    :return Net: a hidden-layer-customized network
    """
    def __init__(self,hidden_size,hidden_num):
        super().__init__()
        self.input_layer = nn.Linear(6,hidden_size)
        self.output_layer = nn.Linear(hidden_size,6)
        self.hidden_layer = [nn.Linear(hidden_size,hidden_size) for i\
                            in range(hidden_num)]
    def forward(self,x):
        x = self.input_layer(x)
        for i in range(len(self.hidden_layer)):
            x = self.hidden_layer[i](x)
        x = self.output_layer(x)
        return x
#格式为训练组索引：训练组数据Tensor，训练组目标Tensor
TRAIN_FLOW = list()

#该函数完成预测精度的时序图展示，可以实时地调用该函数以实现精度图的流动
#该函数从过去已有的训练数据随机采样一个Tensor，参数num为随机采样的个数
def flow_randomsampler(num):
    global TRAIN_FLOW
    sampler_list = [random.choice(TRAIN_FLOW) for i in range(num)]
    return sampler_list
TEST_BATCH_SIZE = 10
#该函数计算神经网络实时测试的精确度
def nn_test(model):
    global flow_randomsampler,TEST_BATCH_SIZE
    #得到一个长度为10的[tensor,tensor]的列表
    batch = flow_randomsampler(TEST_BATCH_SIZE)
    eval_acc = 0
    for unit in batch:
        #获取数据并保存到CUDA
        data,label = Variable(unit[0]).cuda(),Variable(unit[1]).cuda()
        #计算模型的输出
        output = model(data)
        #计算模型的误差(百分比误差)
        acc = ((output - label)/label).abs().mean()
        #转化为双精度的预测精度（1-误差）
        eval_acc += (1 - double(acc))
    #返回精确度
    return eval_acc/TEST_BATCH_SIZE

ACC_FLOW = []

def test_flow(model,sleep_interval=0.5):
    global ACC_FLOW
    while(True):
        time.sleep(sleep_interval)
        acc = nn_test(model)
        ACC_FLOW.append(acc)



#该函数完成单次训练
#batches为一个二维张量，为(5,6)的张量
#batches = [(tensor,tensor),(tensor,tensor),...]
def nn_train(model,optimizer,criterion,batches):
    model.train(True)
    optimizer.zero_grad()#训练器梯度归零
    data, target = Variable(batches).cuda(), Variable(batches).cuda()
    output = model(data)#根据数据计算输出
    loss = criterion(output,target)
    torch.cuda.empty_cache()
    loss.backward()
    optimizer.step()
    gc.collect()
    return double(loss.data)

LOSS_FLOW = []

#训练批大小为每次取样的数据对个数
TRAIN_BATCH_SIZE = 5
#模型开始训练流的函数
def start_flow(model,optim_type='SGD',learning_rate=0.005):
    global TRAIN_FLOW
    #设置游标
    flow_cursor = int(0)
    if(optim_type == 'SGD'):
        optimizer = optim.SGD(model.parameters(),lr=learning_rate)
    elif(optim_type == 'Adam') :
        optimizer = optim.Adam(model.parameters(),lr=learning_rate)
    else:
        optimizer = optim.SGD(model.parameters(),lr=learning_rate)
    #设置损失函数
    global LOSS_FLOW
    loss_fn = nn.MSELoss()
    global TRAIN_BATCH_SIZE
    batch = torch.zeros(TRAIN_BATCH_SIZE,6)
    while(True):
        for i in range(TRAIN_BATCH_SIZE):
            batch[i] = TRAIN_FLOW[flow_cursor]
            flow_cursor += 1
        #已得到batch，进行训练
        loss = nn_train(model,optimizer,loss_fn,batch)
        #输出到LOSS_FLOW窗口
        LOSS_FLOW.append(loss)

def start_train():
    model = Net(6,TRAIN_BATCH_SIZE)#1个输入，1个输出，中间5个层
    #批训练
    thread_train = threading.Thread(target=start_flow,kwargs={
        'model':model,'optim_type':'Adam','learning_rate':0.005})
    thread_train.start()
    #随机采样估计
    thread_test = threading.Thread(target=test_flow,kwargs={})
    thread_test.start()
    return


