#! /usr/bin/env python
# -*- coding: utf-8 -*-
'''
mid 201512011843
此类用于通过PyMongo操作Mongodb

包含外部数据源操作时，建立新类，加入新数据源的操作方法。
如此，可针对每个外部数据源新建处理类，减少在此类中判断的复杂度。

1.填充数据到数据库
类实例被调用后，根据参数获得外部数据源（各种非本Mongodb的数据源），之后存入Mongodb

2.检索数据
检索得到的数据需要被打包成DataFrame格式返回给调用者。
'''
import pymongo
import datetime as dt
import tushare as ts
import pandas as pd

class Mongodb(object):  
    def __init__(self, host='192.168.0.212', port=27017):
        try:
            self.conn = pymongo.MongoClient(host, port)
        except  Error:
            print ('connect to %s:%s fail' %(host, port))
            exit(0)
    def __del__(self):
        self.conn.close()
    def testConnect(self):
        # mid 
        conn = self.conn
        for databaseName in conn.database_names():
            print('databaseName:',databaseName)    
            if(databaseName == 'local'):
                continue
            database = conn[databaseName]
            for collectionName in database.collection_names():
                print('----collectionName:',collectionName)
                collection = database[collectionName]
                for item in collection.find():
                    print('--------item:',item)        
    def use(self, dbname):
        self.db = self.conn[dbname]
        #self.db = self.dbname
    def setCollection(self, collection):
        if not self.db:
            print ('should use database first.')
            exit(0)
        else:
            self.coll = self.db[collection]
            #self.coll = self.db.collection
    def find(self, query = {}):
        # mid query是dict类型
        if type(query) is not dict:
            print ('the type of query isn\'t dict')
            exit(0)
        try:
            if not self.coll:
                print ('should setCollection first.')
            else:
                result = self.coll.find(query)
        except NameError:
            print ('some fields name are wrong in ',query)
            exit(0)
        return result
    def insert(self, data):      
        if (isinstance (data,list)):
            self.coll.insert_many(data)
        else:
            self.coll.insert_one(data)
    def removeItem(self,collection='D',data = None):
        self.setCollection(collection)
        if(data is not None):
            self.__remove(data=data)
        else:
            self.__remove()
    def __remove(self, data = None):
        self.coll.remove(data)
    def update(self,data, setdata):
        if type(data) is not dict or type(setdata) is not dict:
            print ('the type of update and data isn\'t dict')
            exit(0)
        All = True
        if(All):
            self.coll.update_many(data,{'$set':setdata})
        else:
            self.coll.update_one(data,{'$set':setdata})
    #----------------------------------------------------------------------
    def downloadAndStoreHistory(self,symbol,start,end,frequency):
        """"""
        # 2)download history data    
        quotesDf = ts.get_hist_data(symbol,start,end,frequency)
        if(quotesDf is not None):
            quotesDict = quotesDf.to_dict()
            quotesDict['symbol']=symbol
            self.insert(quotesDict)
            return len(quotesDf)
        else:
            return -1
    #----------------------------------------------------------------------
    def retrive(self,symbol='',period='D', timeFrom=None, timeTo=None):
        # 1) retrive data from database
        self.setCollection(period)
        data = self.find({'symbol':str(symbol)})
        print(str(symbol) + '----retrived ok')
        
        
        #cursor = tweets.find(fields=['id'])
        #tweet_fields = ['id']
        #result = pd.DataFrame(list(data))        
        
        
        # 2) store to DataFrame
        historyDf = pd.DataFrame()        
        
        # 3) 
        if(data.count()>0):
            historyDf = pd.DataFrame(data[0])  # mid only one field and it is a dict.
            
        historyDf.index.names = ['Date'] 
        historyDf.columns.names=['OHLC']
        historyDf.sort_index(inplace=True,ascending=True)
        
        if(isinstance(timeFrom,dt.datetime) and  isinstance(timeTo,dt.datetime)):
            strFrom = timeFrom.strftime("%Y-%m-%d %H:%M:%S")
            strTo = timeTo.strftime("%Y-%m-%d %H:%M:%S")
            ret = historyDf[strFrom:strTo]
        else:
            ret = historyDf
        return ret
    #----------------------------------------------------------------------
    def retriveSymbolsAll(self,period = 'D'):
        """"""
        self.setCollection(period)
        
        dfSymbols = pd.DataFrame(columns=['code','counts','dateStart','dateEnd'])
        symbols = self.find({})
        
        for item in symbols:
            if(len(item)<3):
                break
            symbol = item["symbol"]        
            high = item["high"]
            dateStart = min(high.keys())
            dateEnd = max(high.keys())
            counts = len(high.keys())
            
            dfSymbols.loc[symbol]=[symbol,counts,dateStart,dateEnd]
        return dfSymbols
    def retriveCodes(self):
        '''mid
        decode的作用是将其他编码的字符串转换成unicode编码，
        如str1.decode('gb2312')，表示将gb2312编码的字符串str1转换成unicode编码。

        encode的作用是将unicode编码转换成其他编码的字符串，
        如str2.encode('gb2312')，表示将unicode编码的字符串str2转换成gb2312编码。
        '''
        self.setCollection('codes')
        codes = self.find({})
        if(True):#mid better performance
            dfCodes = pd.DataFrame(list(codes), columns = ['symbol','code','name','c_name','digits'])  
            dfCodes.index = dfCodes['symbol']
        else:
            dfCodes = pd.DataFrame(columns=['code','name','c_name'])
            for item in codes:
                code = item['code']
                
                originName = item['name']
                originClass = item['c_name']
                
                #name = item['name'].encode('utf-8')
                #className = item['c_name'].encode('utf-8')
                
                dfCodes.loc[code] = [code,originName,originClass]
        return dfCodes
if __name__ == "__main__":
    # mid create a new connect to mongodb and test it.
    connect = Mongodb()
    #connect.testConnect()
    # mid 1)if find 'midtest',delete it.
    
    
    #mid 2)create 'midtest'
    databaseName = 'midtest'  
    connect.use(databaseName)
    #mid 3)create collection 'midClassmate'
    collectionName = 'midClassmate'
    connect.setCollection(collectionName)
    #mid 4)insert one item
    post = {"id": "1","author": "Mike"}
    new_posts = [{"id": "2","author": "Mike"},
                 {"id": "3","author": "Eliot"}]
    connect.insert(post)
    connect.insert(new_posts)    
    #mid 5)update one item
    data = {'id':'1'}
    setdata = {"author":"upsea"}
    connect.update(data, setdata)
    
    #a = connect.find_one({"author":"Mike"}) #根据条件查询posts中数据
    items = connect.find({"author":"Mike"}).sort('author')  #--默认为升序    
    for item in items:
        print('--------item:',item)     
    #mid 4)delete one item
    data = {'id':'1'}
    setdata = {"author":"upsea"}
    connect.removeItem(collection=collectionName,data = data)       
    #mid 5)delete all
    connect.removeItem(collection=collectionName)          
    