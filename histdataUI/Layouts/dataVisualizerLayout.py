# -*- coding: utf-8 -*-
'''mid
此文件为数据管理程序主界面
用于对历史数据进行检查核对

功能：
    1.展示本地数据KLine图形
    2.下载远程数据到本地
窗口布局：
    1.数据展示主窗口
        左侧为本地数据列表
        右侧为KLine
        左下侧为本地数据操作命令按钮
    2.数据下载管理子窗口
        左侧为代码表
        右侧为待下载代码
程序结构：
    为了能够方便的被各种窗体调用嵌入，各个窗体都定义为layout
'''
from matplotlib.backends.backend_qt4agg import FigureCanvasQTAgg as FigureCanvas
from PyQt4 import QtGui,QtCore
from datetime import datetime
import os,sys
import numpy as np
import pandas as pd
import datetime as dt
import matplotlib.dates as mpd
import matplotlib.pyplot as plt

if sys.version > '3':
    PY3 = True
else:
    PY3 = False    
dataRoot = os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir,os.pardir,'histdata'))        
sys.path.append(dataRoot)        
import dataCenter as dataCenter    
import feedsForCandle as feedsForCandle
from data.mongodb.DataSourceMongodb import Mongodb

windowsRoot = os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
sys.path.append(windowsRoot)
from Widgets.pgCandleWidgetCross import pgCandleWidgetCross
from Views.HistoryCandleView import HistoryCandleView
from Views.HistoryTableView import HistoryTableView
class dataVisualizerLayout(QtGui.QHBoxLayout):
    def __init__(self,parent=None):
        self.parent = parent
        super(dataVisualizerLayout,self).__init__()        
        #mid data
        self.dataCenter = dataCenter.dataCenter()           
        #mid 1) local data selector
        layoutLocalDataSource = self.initLayoutLocalDataSource()
        
        layoutLocalDataVisualizer = self.initLayoutLocalDataVisualizer()

        # bottom--------------------------------------------------------------------
        self.addLayout(layoutLocalDataSource)
        self.addLayout(layoutLocalDataVisualizer)
        self.setStretch(0, 1)
        self.setStretch(1, 4)        
    def initLayoutSymbolsSelector(self):
        layoutSymbolsSelector = QtGui.QHBoxLayout(self.parent)

        label7=QtGui.QLabel(self.tr("locally available symbols:"))
        labelSourceType = QtGui.QLabel('source Type:')
        labelStorageType = QtGui.QLabel(self.tr("storage type:"))
        labelPeriodType = QtGui.QLabel(self.tr("period type:"))
        
        datasourceComboBox = QtGui.QComboBox()
        self.localDatasourceComboBox = datasourceComboBox
        datasourceComboBox.insertItem(0,'tushare')
        datasourceComboBox.insertItem(1,'sina')
        datasourceComboBox.insertItem(2,'yahoo')
        
        storageComboBox = QtGui.QComboBox()
        self.localSymbolsStorageComboBox = storageComboBox
        storageComboBox.insertItem(0,self.tr("mongodb"))
        storageComboBox.insertItem(1,self.tr("csv")) 
        storageComboBox.insertItem(2,self.tr("all")) 
        
        periodComboBox=QtGui.QComboBox()
        self.localSymbolsPeriodComboBox = periodComboBox
        periodComboBox.insertItem(0,self.tr("D"))
        periodComboBox.insertItem(1,self.tr("min"))  
        periodComboBox.insertItem(2,self.tr("all"))  
        
        datasourceComboBox.activated[str].connect(self.onLocalSymbolSelectorActivate)        
        storageComboBox.activated[str].connect(self.onLocalSymbolSelectorActivate)        
        periodComboBox.activated[str].connect(self.onLocalSymbolSelectorActivate)        
        
        
        
        
        layoutSymbolsSelector.addWidget(label7)
        
        layoutSymbolsSelector.addWidget(labelSourceType)
        layoutSymbolsSelector.addWidget(datasourceComboBox)
        
        layoutSymbolsSelector.addWidget(labelStorageType)
        layoutSymbolsSelector.addWidget(storageComboBox)      
        
        layoutSymbolsSelector.addWidget(labelPeriodType)
        layoutSymbolsSelector.addWidget(periodComboBox)        
        
        return layoutSymbolsSelector
    def onLocalSymbolSelectorActivate(self,text):
        self.updateLocalAvailableSymbolsTable()    
    def updateLocalAvailableSymbolsTable(self):
        """mid
        dfLocalSymbols.index = 'code'
        dfLocalSymbols.columns = ['code','name','c_name',...]
        """
        datasource = self.localDatasourceComboBox.currentText()
        storageType = self.localSymbolsStorageComboBox.currentText()
        period = self.localSymbolsPeriodComboBox.currentText()        
        
        dfLocalSymbols = self.dataCenter.getLocalAvailableDataSymbols(dataType = datasource,storageType = storageType,periodType = period)

        
        self.tableLocalAvailableSymbols.setSelectionBehavior(QtGui.QAbstractItemView.SelectRows)  
        self.tableLocalAvailableSymbols.setEditTriggers(QtGui.QTableWidget.NoEditTriggers)  
        self.tableLocalAvailableSymbols.setSelectionBehavior(QtGui.QTableWidget.SelectRows)  
        self.tableLocalAvailableSymbols.setSelectionMode(QtGui.QTableWidget.SingleSelection)  
        self.tableLocalAvailableSymbols.setAlternatingRowColors(True)         
        
        
        self.tableLocalAvailableSymbols.clear()
        header = ["code","counts","date from","date to"]
        self.tableLocalAvailableSymbols.setColumnCount(len(header))
        
        if(dfLocalSymbols is None):
            self.tableLocalAvailableSymbols.setRowCount(0)
            return        
        
        self.tableLocalAvailableSymbols.setRowCount(len(dfLocalSymbols))
        self.tableLocalAvailableSymbols.setHorizontalHeaderLabels(header)     #mid should be after .setColumnCount()
        
        
        if(True):
            for row in range(len(dfLocalSymbols.index)):
                for column in range(len(dfLocalSymbols.columns)):
                    self.tableLocalAvailableSymbols.setItem(row,column,QtGui.QTableWidgetItem(str(dfLocalSymbols.iget_value(row, column))))        
        else: #mid the above codes have better performance than the below.
            for row in np.arange(0,len(dfLocalSymbols)):
                code = dfLocalSymbols.index[row]
                
                #symbol = QtGui.QLabel(self.tr(code))
                symbol = str(code)
                codeName = dfLocalSymbols.loc[code,'name']
                codeClass = dfLocalSymbols.loc[code,'c_name']
                                   
                #self.tableLocalSymbols.setCellWidget(row,0,symbol)
                self.tableLocalAvailableSymbols.setItem(row,0,QtGui.QTableWidgetItem(symbol))
                self.tableLocalAvailableSymbols.setItem(row,1,QtGui.QTableWidgetItem(codeName))
                self.tableLocalAvailableSymbols.setItem(row,2,QtGui.QTableWidgetItem(codeClass))    
    

    #----------------------------------------------------------------------    
    def initLayoutLocalDataSource(self):      
        bottomLeft01 = QtGui.QVBoxLayout(self.parent)  
        # 05)symbols selector
        layoutSymbolsSelector = self.initLayoutSymbolsSelector()
        
        self.tableLocalAvailableSymbols = QtGui.QTableWidget()

        # 06)bottomLeft03
        bottomLeft03 = QtGui.QHBoxLayout(self.parent)
    
        DeleteOneFromDBButton=QtGui.QPushButton(self.tr("DeleteOneFromDB"))
        DeleteAllFromDBButton=QtGui.QPushButton(self.tr("DeleteAllFromDB"))      
        ShowInTableButton=QtGui.QPushButton(self.tr("ShowInTable"))
        ShowInGraphButton=QtGui.QPushButton(self.tr("ShowInGraph"))           
    
        bottomLeft03.addWidget(DeleteOneFromDBButton)
        bottomLeft03.addWidget(DeleteAllFromDBButton)
        bottomLeft03.addWidget(ShowInTableButton)
        bottomLeft03.addWidget(ShowInGraphButton)
        self.connect(ShowInTableButton,QtCore.SIGNAL("clicked()"),self.slotShowInTable)
        self.connect(ShowInGraphButton,QtCore.SIGNAL("clicked()"),self.slotShowInCandleGraph) 
                
        bottomLeft01.addLayout(layoutSymbolsSelector)
        bottomLeft01.addWidget(self.tableLocalAvailableSymbols)
        bottomLeft01.addLayout(bottomLeft03)
        return bottomLeft01
    def initLayoutLocalDataVisualizer(self):
        bottomLeft02 = QtGui.QVBoxLayout(self.parent)  
    
        # 05)bottomLeft02---------------------
        label7=QtGui.QLabel(self.tr("Current symbol graphview:"))
        
        dataForCandle = self.dataCenter.retriveCandleData(datasource = 'tushare',storageType = 'mongodb',symbol = '600028')     
        candle = pgCandleWidgetCross(dataForCandle=dataForCandle)          
        
        
        
        bottomLeft02.addWidget(label7)
        bottomLeft02.addWidget(candle)  
        
        return bottomLeft02    

    def slotShowInTable(self):
        """
        show currrent selected symbol in table
        """
        def getRawDataFromMongodb():
            # 1)connect to Mongodb 
            connect = Mongodb('192.168.0.212', 27017)
            connect.use('Tushare')    #database
            
            # 2)retrive data from specified collection
            symbol = '600028'
            strStart = '2015-01-01'
            dateEnd = dt.datetime.now()
            strEnd = dateEnd.strftime('%Y-%m-%d')  
            frequency = 'D'
            connect.setCollection(frequency)    #table
            return connect.retrive(symbol,strStart,strEnd,frequency)        
            
        data = getRawDataFromMongodb()
        self.tableHistory=HistoryTableView(rawData=data)
        self.tableHistory.setWindowTitle("history")
        self.tableHistory.show()        
    def slotShowInCandleGraph(self):
        rowSelected = self.tableLocalAvailableSymbols.currentRow()
        if((rowSelected<0) and (self.tableLocalAvailableSymbols.rowCount()>0)):
            rowSelected = 0
            
        if(rowSelected>=0):   #a row selected or table is not empty.
            datasource = self.localDatasourceComboBox.currentText()
            storageType = self.localSymbolsStorageComboBox.currentText()
            symbolToDownload = self.tableLocalAvailableSymbols.item(rowSelected,0).text()
            period = self.localSymbolsPeriodComboBox.currentText()
            #history = self.dataCenter.retriveHistData(symbolToDownload)
            
            dataForCandle = self.dataCenter.retriveCandleData(datasource = datasource,storageType = storageType,symbol = symbolToDownload)     
            self.__showCandle__(dataForCandle)
            #self.myWindowfff = MyDialog(dataForCandle=dataForCandle)  
            #self.myWindowfff.show()                        
        else:   #none selected and empty table
            symbol = 'none to download.'
            QtGui.QMessageBox.information(self,"Information",self.tr(symbol)) 
    def __showCandle__(self,dataForCandle):
        dialog = QtGui.QDialog()
        self.pgCandleView = dialog
        layout = QtGui.QHBoxLayout()
        layoutLeft = QtGui.QVBoxLayout()
        layout.addLayout(layoutLeft)
        dialog.setLayout(layout)        
        dialog.setWindowTitle(('ComboView'))
        # 2) creates widgets 
        editor = QtGui.QTextEdit()
        editor.setText("<span style='font-size: 15pt' style='color: red'>x = %0.1f,y = %0.1f</span>"% (2.0,2.0))
    
        candle = pgCandleWidgetCross(dataForCandle=dataForCandle)  
        #candle = pgCrossAddition()
        # 3)arrange widgets
        #layout.addWidget(editor)
        layout.addWidget(candle)
        dialog.showMaximized()         

if __name__ == '__main__':
    #----------------------------------------------------------------------
    class MainWindow(QtGui.QMainWindow):
        def __init__(self):
            super(MainWindow, self).__init__()
            cw = QtGui.QWidget()
            self.setCentralWidget(cw) 
            cw.setLayout(dataVisualizerLayout(self))    
    app = QtGui.QApplication(sys.argv)
    mainWin = MainWindow()
    mainWin.showMaximized()
    sys.exit(app.exec_())