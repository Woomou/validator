class instructional(object):
    def __init__(self,browser):
        self.browser = browser
        #样式变量
        #self.font = QFont("Microsoft YaHei",20,2)
        #self.cursor = QTextCursor()
        #输出内容变量
        self.direction_text = ["左","右","上","下","前","后"]
        self.speed_text = ["速度渐慢","速度稳定","速度渐快"]
    def setText(self,direct,speed,dist):
        self.direct_index = direct
        self.speed_index = speed
        self.dist = dist
    def showText(self):
        self.browser.insertPlainText("向<")
        self.browser.insertPlainText(self.direction_text[self.direct_index])
        self.browser.insertPlainText(">方向，")
        self.browser.insertPlainText(self.speed_text[self.speed_index])
        self.browser.insertPlainText("地移动")
        self.browser.insertPlainText(str(self.dist))
        self.browser.insertPlainText("个拳头的距离。\n")
        return