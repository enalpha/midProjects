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
from data.mongodb.DataSourceMongodb import Mongodb

windowsRoot = os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
sys.path.append(windowsRoot)
from Widgets.pgCandleWidgetCross import pgCandleWidgetCross
from Views.HistoryCandleView import HistoryCandleView
from Views.HistoryTableView import HistoryTableView
class dataVisualizerLayout(QtGui.QVBoxLayout):
    def __init__(self,parent=None):
        '''mid
        1)创建combobox组，并初始化值
        2)依据combobox组的值初始化table
        3)依据combobox，table初始化candleview
        '''
        self.parent = None
        super(dataVisualizerLayout,self).__init__()        
        #mid data
        self.dataCenter = dataCenter.dataCenter()           
        #mid 1) local data selector
        layoutLocalDataSource = self.createDataSourceSelectorLayout()
        layoutLocalDataVisualizer = self.createDataVisualizerLayout()
        # bottom--------------------------------------------------------------------
        self.addLayout(layoutLocalDataSource)
        self.addLayout(layoutLocalDataVisualizer)
        #self.setStretch(0, 1)
        #self.setStretch(1, 4)
    def createDataSourceSelectorLayout(self):
        '''mid
        创建数据来源选择组合框组，横向排列
        '''
        layoutSymbolsSelector = QtGui.QHBoxLayout(self.parent)

        labelSourceType = QtGui.QLabel('source Type:')
        labelStorageType = QtGui.QLabel(self.tr("storage type:"))
        labelPeriodType = QtGui.QLabel(self.tr("period type:"))
        
        datasourceComboBox = QtGui.QComboBox()
        self.localDatasourceComboBox = datasourceComboBox
        dataProviders = self.dataCenter.getDataProviders()
        for dataProvider in dataProviders:
            datasourceComboBox.insertItem(0,dataProvider)

        storageComboBox = QtGui.QComboBox()
        self.localSymbolsStorageComboBox = storageComboBox
        dataStorages = self.dataCenter.getDataStorages()
        for dataStorage in dataStorages:
            storageComboBox.insertItem(0,dataStorage)       
        
        periodComboBox=QtGui.QComboBox()
        self.localSymbolsPeriodComboBox = periodComboBox
        dataPeriods = self.dataCenter.getDataPeriods('mt5')
        for dataPeriod in sorted(dataPeriods):
            periodComboBox.insertItem(0,dataPeriod)               
        
        
        self.overlayCheckBox = QtGui.QRadioButton('overlay')   # 创建单选框
        self.aloneCheckBox = QtGui.QRadioButton('stand-alone')
        self.aloneCheckBox.setChecked(True)      # 将Radio1选中
   
        
        datasourceComboBox.activated[str].connect(self.onDataSourceTypeComboBoxChanged)        
        storageComboBox.activated[str].connect(self.onLocalSymbolSelectorActivate)        
        periodComboBox.activated[str].connect(self.onLocalSymbolSelectorActivate)        
    
        layoutSymbolsSelector.addWidget(labelSourceType)
        layoutSymbolsSelector.addWidget(datasourceComboBox)
        
        layoutSymbolsSelector.addWidget(labelStorageType)
        layoutSymbolsSelector.addWidget(storageComboBox)      
        
        layoutSymbolsSelector.addWidget(labelPeriodType)
        layoutSymbolsSelector.addWidget(periodComboBox)        
        
        layoutSymbolsSelector.addWidget(self.aloneCheckBox)        
        layoutSymbolsSelector.addWidget(self.overlayCheckBox)        
        
        layoutSymbolsSelector.addWidget(QtGui.QLabel(' '))
        
        layoutSymbolsSelector.setStretch(8,1)
        
        return layoutSymbolsSelector
    def onDataSourceTypeComboBoxChanged(self):
        datasource = str(self.localDatasourceComboBox.currentText())
        dataPeriods = self.dataCenter.getDataPeriods(datasource)
        dataPeriodsSorted = sorted(dataPeriods)
        self.localSymbolsPeriodComboBox.clear()
        for dataPeriod in dataPeriodsSorted:
            self.localSymbolsPeriodComboBox.insertItem(0,dataPeriod)          
            
        self.updateLocalAvailableSymbolsTable() 
    def onLocalSymbolSelectorActivate(self,text):
        self.updateLocalAvailableSymbolsTable()    
    def updateLocalAvailableSymbolsTable(self):
        """mid
        dfLocalSymbols.index = 'code'
        dfLocalSymbols.columns = ['code','name','c_name',...]
        """
        datasource = str(self.localDatasourceComboBox.currentText())
        storageType = str(self.localSymbolsStorageComboBox.currentText())
        period = str(self.localSymbolsPeriodComboBox.currentText()) 
        
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
    def createDataControlButtonLayout(self):
        bottomLeft03 = QtGui.QHBoxLayout(self.parent)
    
        DeleteOneFromDBButton=QtGui.QPushButton(self.tr("DeleteOneFromDB"))
        DeleteAllFromDBButton=QtGui.QPushButton(self.tr("DeleteAllFromDB"))      
        ShowInTableButton=QtGui.QPushButton(self.tr("ShowInTable"))
        ShowInGraphButton=QtGui.QPushButton(self.tr("ShowInGraph"))           
    
        bottomLeft03.addWidget(DeleteOneFromDBButton)
        bottomLeft03.addWidget(DeleteAllFromDBButton)
        bottomLeft03.addWidget(ShowInTableButton)
        bottomLeft03.addWidget(ShowInGraphButton)
        
        self.connect(DeleteOneFromDBButton,QtCore.SIGNAL("clicked()"),self.slotDeleteOneFromDB)
        self.connect(DeleteAllFromDBButton,QtCore.SIGNAL("clicked()"),self.slotDeleteAllFromDB)
        self.connect(ShowInTableButton,QtCore.SIGNAL("clicked()"),self.slotShowInTable)
        self.connect(ShowInGraphButton,QtCore.SIGNAL("clicked()"),self.slotShowInCandleGraph)
        return bottomLeft03
    def getDataSourceParams(self):
        rowSelected = self.tableLocalAvailableSymbols.currentRow()
        if((rowSelected<0) and (self.tableLocalAvailableSymbols.rowCount()>0)):
            rowSelected = 0
        datasource = str(self.localDatasourceComboBox.currentText())
        storageType = str(self.localSymbolsStorageComboBox.currentText())
        period = str(self.localSymbolsPeriodComboBox.currentText())            
        
        alone = self.aloneCheckBox.isChecked()
        overlay = self.overlayCheckBox.isChecked()
        
        dataSource={}        
        dataSource['dataProvider'] = datasource
        dataSource['storageFormat']=storageType
        dataSource['dataPeriod']=period
        dataSource['dateStart']=None
        dataSource['dateEnd']=None  
        dataSource['alone'] = alone
        dataSource['overlay'] = overlay        
        
        if(rowSelected>=0):   #a row selected or table is not empty.
            symbolToShow = str(self.tableLocalAvailableSymbols.item(rowSelected,0).text())
            dataSource['symbol']=symbolToShow
        else:
            dataSource['symbol']=''
        return dataSource
    def onClicked(self):
        print ('******row : ' , self.tableLocalAvailableSymbols.currentRow(), ' ***********')
        
        rows = self.tableLocalAvailableSymbols.rowCount()

        #for rows_index in range(rows):
            ##print items[item_index].text()
            #print (self.tableLocalAvailableSymbols.item(rows_index,0).text())    
        params = self.getDataSourceParams()
        if(params is not None):
            dataForCandle = self.dataCenter.retriveCandleData(params = params)   
            if(params['alone'] is True):       # 判断单选框是否选中
                graphMode = 'alone'
            elif (params['overlay'] is True):
                graphMode = 'overlay'                
            self.candleWidget.setCandleData(dataForCandle = dataForCandle,graphMode = graphMode)   
    def createTableLayout(self):
        # 06)bottomLeft03
        localSymbolTable = QtGui.QVBoxLayout(self.parent)
        
        self.tableLocalAvailableSymbols = QtGui.QTableWidget()
        localSymbolTable.addWidget(self.tableLocalAvailableSymbols)  
        
        localSymbolTable.addLayout(self.createDataControlButtonLayout())
        self.tableLocalAvailableSymbols.itemClicked.connect(self.onClicked)
        self.updateLocalAvailableSymbolsTable()        
        return localSymbolTable
    def createDataVisualizerLayout(self):
        bottomLeft02 = QtGui.QHBoxLayout(self.parent)  
        bottomLeft02.addLayout(self.createTableLayout())        
    
        # 05)bottomLeft02---------------------        
        params = self.getDataSourceParams()
        if(params is not None):   
            dataForCandle = self.dataCenter.retriveCandleData(params = params)
        
            self.candleWidget = pgCandleWidgetCross(dataForCandle=dataForCandle)          
    
        
        bottomLeft02.addWidget(self.candleWidget)  
        
        bottomLeft02.setStretch(0,1)
        bottomLeft02.setStretch(1,3.5)
        return bottomLeft02    
    def slotDeleteOneFromDB(self):
        params = self.getDataSourceParams()
        if(params is not None):
            self.dataCenter.removeFromStorage(dataProvider = params['dataProvider'],storageType = params['storageFormat'],
                                              symbols = params['symbol'],period=params['dataPeriod']) 
            self.updateLocalAvailableSymbolsTable()
    def slotDeleteAllFromDB(self):
        '''
            dataSource={}        
            dataSource['dataProvider'] = datasource
            dataSource['storageFormat']=storageType
            dataSource['dataPeriod']=period
            dataSource['symbol']=symbolToShow
            dataSource['dateStart']='2015-03-19'
            dataSource['dateEnd']='2015-12-31'  
            dataSource['alone'] = alone
            dataSource['overlay'] = overlay        
        '''
        params = self.getDataSourceParams()
        if(params is not None):
            self.dataCenter.removeFromStorage(dataProvider = params['dataProvider'],storageType = params['storageFormat'],
                                              symbols = None,period=params['dataPeriod'])
        self.updateLocalAvailableSymbolsTable()   
    def slotShowInTable(self):
        """
        show currrent selected symbol in table
        """     
        params = self.getDataSourceParams()
        if(params is not None):
            data = self.dataCenter.retriveHistData(params = params)                           
            self.tableHistory=HistoryTableView(rawData=data)
            self.tableHistory.setWindowTitle("history")
            self.tableHistory.showMaximized()          
        else:   #none selected and empty table
            symbol = 'none to download.'
            QtGui.QMessageBox.information(self.parent,"Information",self.tr(symbol))             
      
    def slotShowInCandleGraph(self):
        params = self.getDataSourceParams()
        if(params is not None):
            dataForCandle = self.dataCenter.retriveCandleData(params = params)     
            self.__showCandle__(dataForCandle)
            #self.myWindowfff = MyDialog(dataForCandle=dataForCandle)  
            #self.myWindowfff.show()                        
        else:   #none selected and empty table
            symbol = 'none to download.'
            QtGui.QMessageBox.information(self.parent,"Information",self.tr(symbol)) 
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