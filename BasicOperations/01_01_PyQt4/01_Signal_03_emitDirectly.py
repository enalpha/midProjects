from PyQt4 import QtGui, QtCore

class MyButton(QtGui.QPushButton):
    def __init__(self, *args, **kwargs):
        QtGui.QPushButton.__init__(self, *args, **kwargs)
        self.connect(self, QtCore.SIGNAL("clicked()"), self.emitClicked)
    def emitClicked(self):
        self.emit(QtCore.SIGNAL("myclicked()"))
app = QtGui.QApplication([])
w = QtGui.QWidget()
def showMsg():
    QtGui.QMessageBox.information(w, u"信息", u"ok")
btn = MyButton(u"点我", w)
w.connect(btn, QtCore.SIGNAL("myclicked()"), showMsg)
w.show()
app.exec_()