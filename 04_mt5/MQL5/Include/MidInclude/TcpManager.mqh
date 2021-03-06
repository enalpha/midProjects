#include    <MidInclude\InterfaceToNetMTDll.mqh>
#include    <Trade\SymbolInfo.mqh>
/*mid
此处使用加载的socket_mql5_x64.dll中函数构建TcpManager
TcpManager负责通过此dll中创建的socket收发数据

socket收发的数据在socket眼里全是一致的char字节流，没有特殊格式和含义，
所以，在dll中不用定义数据结构
但是，mt5程序调用此dll后和其他socket程序在交流的过程中，对char字节流需要解析
解析的时候，就需要协议，这些协议定义具体char字节流的含义，协议在InterfaceToNetMTDLL.mqh中定义
其他socket程序也要有与InterfaceToNetMTDLL.mqh中定义类似的定义文件方能交流。
*/

//mid 以下定义用于与socket_mql5_x64.dll交流
#define  ERROR_SUCCESS                             0
#define  ERROR_INVALID_HANDLE                      6

#define	SOCKET_STATUS_CLIENT_CONNECTED				1
#define	SOCKET_STATUS_CLIENT_DISCONNECTED			2
#define	SOCKET_STATUS_SERVER_LISTENING		      3
#define	SOCKET_STATUS_SERVER_NOTLISTENING	      4
struct SOCKET_MT
  {
   uchar             status;
   ushort            sequence;
   uint              sock;
  };
  
//mid 以下导入socket_mql5_x64.dll中导出的函数
#import "socket_mql5_x64.dll"
uint SocketConnectToServer(SOCKET_MT &socketClient,const string host,const ushort port);
uint SocketListenToClient(SOCKET_MT &socketServer,const string host,const ushort port);
uint SocketAcceptClient(SOCKET_MT &socketServerListening,SOCKET_MT &socketAccepted);
void SocketClose(SOCKET_MT &socket);
string SocketErrorString(int error_code);
//mid 以下名称应与TcpManager中的名称区别，改日，需要在dll中和此处同步修改
uint SocketSend(SOCKET_MT &socket, RSP_HISTORY_HEADER &tick,            int nBytesToWrite,   int &pnBytesWriten,  int flag);
uint SocketSend(SOCKET_MT &socket, RSP_HISTORY        &outgoing[],      int nBytesToWrite,   int &pnBytesWriten,  int flag);
uint SocketSend(SOCKET_MT &socket, RSP_LOGIN          &outgoing,        int nBytesToWrite,   int &pnBytesWriten,  int flag);
uint SocketSend(SOCKET_MT &socket, RSP_LOGOUT         &outgoing,        int nBytesToWrite,   int &pnBytesWriten,  int flag);
uint SocketSend(SOCKET_MT &socket, RSP_CONNECT        &outgoing,        int nBytesToWrite,   int &pnBytesWriten,  int flag);
uint SocketSend(SOCKET_MT &socket, RSP_REPORT         &tick,            int nBytesToWrite,   int &pnBytesWriten,  int flag);
uint SocketSend(SOCKET_MT &socket, RSP_SUBSCRIBE      &tick,            int nBytesToWrite,   int &pnBytesWriten,  int flag);
uint SocketSend(SOCKET_MT &socket, RSP_UNSUBSCRIBE    &tick,            int nBytesToWrite,   int &pnBytesWriten,  int flag);
uint SocketSend(SOCKET_MT &socket, RSP_CODE_HEADER    &tick,            int nBytesToWrite,   int &pnBytesWriten,  int flag);
uint SocketSend(SOCKET_MT &socket, RSP_CODE           &tick[],          int nBytesToWrite,   int &pnBytesWriten,  int flag);

uint SocketRecv(SOCKET_MT &socket, REQ_HEADER               &reqHeader,       int nBytesToReceived,int &pnBytesReceived,int flag);
uint SocketRecv(SOCKET_MT &socket, REQ_HISTORY              &reqHistory,      int nBytesToReceived,int &pnBytesReceived,int flag);
uint SocketRecv(SOCKET_MT &socket, REQ_LOGIN                &reqHistory,      int nBytesToReceived,int &pnBytesReceived,int flag);
uint SocketRecv(SOCKET_MT &socket, REQ_LOGOUT               &reqHistory,      int nBytesToReceived,int &pnBytesReceived,int flag);
uint SocketRecv(SOCKET_MT &socket, REQ_CONNECT              &reqHistory,      int nBytesToReceived,int &pnBytesReceived,int flag);
uint SocketRecv(SOCKET_MT &socket, REQ_SUBSCRIBE_HEADER     &reqHistory,      int nBytesToReceived,int &pnBytesReceived,int flag);
uint SocketRecv(SOCKET_MT &socket, REQ_SUBSCRIBE            &reqHistory[],    int nBytesToReceived,int &pnBytesReceived,int flag);
uint SocketRecv(SOCKET_MT &socket, REQ_UNSUBSCRIBE_HEADER   &reqHistory,      int nBytesToReceived,int &pnBytesReceived,int flag);
uint SocketRecv(SOCKET_MT &socket, REQ_UNSUBSCRIBE          &reqHistory[],    int nBytesToReceived,int &pnBytesReceived,int flag);
#import

//mid CArraySubscribedSymbols用于处理已订阅symbols的字符串数组
#include <Arrays\ArrayString.mqh>
class CArraySubscribedSymbols : public CArrayString
  {
public:
                     CArraySubscribedSymbols(void);
                    ~CArraySubscribedSymbols(void);
public:
   bool              AddUniqueSymbol(string symbol);
   bool              DeleteAllSymbol(string symbol);
   
   bool              SynchronizeGlobalValues();
  }; 
CArraySubscribedSymbols::CArraySubscribedSymbols(void)
{
   Shutdown();
}
CArraySubscribedSymbols::~CArraySubscribedSymbols(void)
{
   Shutdown();
}  
bool  CArraySubscribedSymbols::SynchronizeGlobalValues()
{
   bool  bReturn =true;
   GlobalVariablesDeleteAll();
   for(int i=0;i<Total();i++)
   {
      if(GlobalVariableSet(At(i),0)==0)
      {  //mid 失敗
         bReturn = false;
         break;
      }
   }
   return bReturn;
}
bool  CArraySubscribedSymbols::AddUniqueSymbol(string symbol)
{
   Sort();
   int iPos = Search(symbol);//mid 需要先經過Sort()之後才能Search()，否則，直接返回-1
   if(iPos==-1)
   {
      Add(symbol);
   }
   return true;
}
bool  CArraySubscribedSymbols::DeleteAllSymbol(string symbol)
{  //mid 刪除所有指定字符串
   Sort();
   int iPos = Search(symbol); //mid 需要先經過Sort()之後才能Search()，否則，直接返回-1
   while(iPos!=-1)
   {
      Delete(iPos);
      iPos = Search(symbol);
   }
   return true;
}

/*------------------------------------------------------
mid 此类只提供方法，不提供变量
如果提供变量，则需要给调用此方法类的SocketClient和SocketServer分别提供Send和Receive方法，以区别调用的是Server还是Client的Socket。
-------------------------------------------------------*/
class CTcpManager
  {
public:
                     CTcpManager(void);
                    ~CTcpManager(void);
public:
   uint              SocketConnectToServer(SOCKET_MT &socket,const string host,const ushort port);
   uint              SocketListenToClient(SOCKET_MT &socket,const string host,const ushort port);
   uint              SocketAcceptClient(SOCKET_MT &socketServerListening,SOCKET_MT &socketAccepted);
   void              SocketClose(SOCKET_MT &socket);   
   string            SocketErrorString(const int error_code);
private:
   CArraySubscribedSymbols m_SubscribedSymbols;
private:
   uint              SocketSend(SOCKET_MT &socket, RSP_HISTORY_HEADER      &reqHeader,    int nBytesToSend,   int &pnBytesSent,    int flag);
   uint              SocketSend(SOCKET_MT &socket, RSP_HISTORY             &outgoing[],   int nBytesToSend,    int &pnBytesSent,    int flag);
   uint              SocketSend(SOCKET_MT &socket, RSP_LOGIN               &outgoing,     int nBytesToSend,    int &pnBytesSent,    int flag);
   uint              SocketSend(SOCKET_MT &socket, RSP_LOGOUT              &outgoing,     int nBytesToSend,    int &pnBytesSent,    int flag);
   uint              SocketSend(SOCKET_MT &socket, RSP_CONNECT             &outgoing,     int nBytesToSend,    int &pnBytesSent,    int flag);
   uint              SocketSend(SOCKET_MT &socket, RSP_REPORT              &outgoing,     int nBytesToSend,    int &pnBytesSent,    int flag);
   uint              SocketSend(SOCKET_MT &socket, RSP_SUBSCRIBE           &tick,         int nBytesToWrite,   int &pnBytesWriten,  int flag);
   uint              SocketSend(SOCKET_MT &socket, RSP_UNSUBSCRIBE         &tick,         int nBytesToWrite,   int &pnBytesWriten,  int flag);
   uint              SocketSend(SOCKET_MT &socket, RSP_CODE_HEADER         &tick,         int nBytesToWrite,   int &pnBytesWriten,  int flag);
   uint              SocketSend(SOCKET_MT &socket, RSP_CODE                &tick[],       int nBytesToWrite,   int &pnBytesWriten,  int flag);

   uint              SocketRecv(SOCKET_MT &socket, REQ_HISTORY             &reqHistory,   int nBytesToReceive, int &pnBytesReceived,  int flag);
   uint              SocketRecv(SOCKET_MT &socket, REQ_LOGIN               &reqLogin,     int nBytesToReceive, int &pnBytesReceived,  int flag);
   uint              SocketRecv(SOCKET_MT &socket, REQ_LOGOUT              &reqLogout,    int nBytesToReceive, int &pnBytesReceived,  int flag);
   uint              SocketRecv(SOCKET_MT &socket, REQ_CONNECT             &reqLogout,    int nBytesToReceive, int &pnBytesReceived,  int flag);
   uint              SocketRecv(SOCKET_MT &socket, REQ_SUBSCRIBE_HEADER    &reqHistory,   int nBytesToReceived,int &pnBytesReceived,int flag);
   uint              SocketRecv(SOCKET_MT &socket, REQ_SUBSCRIBE           &reqHistory[], int nBytesToReceived,int &pnBytesReceived,int flag);
   uint              SocketRecv(SOCKET_MT &socket, REQ_UNSUBSCRIBE_HEADER  &reqHistory,   int nBytesToReceived,int &pnBytesReceived,int flag);
   uint              SocketRecv(SOCKET_MT &socket, REQ_UNSUBSCRIBE         &reqHistory[], int nBytesToReceived,int &pnBytesReceived,int flag);

   
public:
   //mid    mt作为服务器使用方法
   uint              SocketRecv(SOCKET_MT &socket, REQ_HEADER   &reqHeader,    int nBytesToReceive, int &pnBytesReceived,  int flag);
   void              ParseAskTypeHistory(SOCKET_MT &socket,REQ_HEADER &AskHeader);
	void              ParseAskTypeLogin(SOCKET_MT &socket,REQ_HEADER &AskHeader);
   bool              ParseAskTypeLogout(SOCKET_MT &socket,REQ_HEADER &AskHeader);
   void              ParseAskTypeConnect(SOCKET_MT &socket,REQ_HEADER &AskHeader);
   void              ParseAskTypeSubscribe(SOCKET_MT &socket,REQ_HEADER &AskHeader);
   void              ParseAskTypeUnSubscribe(SOCKET_MT &socket,REQ_HEADER &AskHeader);
   void              ParseAskTypeCode(SOCKET_MT &socket,REQ_HEADER &AskHeader);

   int               GetHistoryDataAndSend(SOCKET_MT &socket,RSP_HISTORY_HEADER & RspHistoryHeader,RSP_HISTORY  & HistoryKDataArrayAll[], string strCode, ENUM_TIMEFRAMES enuTimeFrame);
   //mid    mt作为客户使用方法
   void              GetDepth(RSP_REPORT &OneReport,const string &symbol);
   void              SendReport(SOCKET_MT &socket,/*const*/ RSP_REPORT &rspReport,string strIP,ushort uPort);
  };
void CTcpManager::SendReport(SOCKET_MT &socket,/*const*/ RSP_REPORT &rspReport,string strIP,ushort uPort)
{
	/*
 	TimeCurrent(g_RspReport.m_time); //mid 此语句偶尔会生成全是0的数据
	*/
	MqlTick  lastTick;

  	if (!SymbolInfoTick(CharArrayToString(rspReport.m_szCode,0,WHOLE_ARRAY,CP_UTF8), lastTick))
   	{ //mid 获得最后一次报价数据，包括时间
   		return;
      }
   TimeToStruct(lastTick.time, rspReport.m_time);

	
	string str_msg = StringFormat("symbol: %s dt: %s bid: %s ask: %s", _Symbol, 
	                              TimeToString(StructToTime(rspReport.m_time),/*g_LastTick.time,*/TIME_DATE | TIME_SECONDS),
								         DoubleToString(rspReport.m_fBuyPrice[0], _Digits), DoubleToString(rspReport.m_fSellPrice[0], _Digits));
	
		int nBytesSent;
      uint  unSendStatus = ERROR_INVALID_HANDLE;
      Print("Begin to send RspReport Data...");
      unSendStatus =SocketSend(socket,rspReport,sizeof(RSP_REPORT),nBytesSent,0);
      
      if(unSendStatus==ERROR_SUCCESS)
      {  //mid 头发送成功
      	Print("rspReport data sent.");
   	}
   	else
   	{
      	Print("rspReport data sent error.**********");
   		Print(SocketErrorString(unSendStatus));
   		SocketConnectToServer(socket, strIP, uPort);
   	}
	
	//Print("sizeof RSP_REPORT:",sizeof(RSP_REPORT));
	//Print("sizeof g_RspReport:",sizeof(rspReport));
	Print("DateTime:" ,TimeToString(StructToTime(rspReport.m_time),TIME_DATE | TIME_SECONDS));
	//Print("Broker:",CharArrayToString(rspReport.m_szBrokerName));
	//Print("Account:",CharArrayToString(rspReport.m_szAccountName));
	//Print("Code:",CharArrayToString(rspReport.m_szCode));
	long lDigits =SymbolInfoInteger(CharArrayToString(rspReport.m_szCode,0,WHOLE_ARRAY,CP_UTF8),SYMBOL_DIGITS);
	Print(StringFormat("bid: %s ask: %s",DoubleToString(rspReport.m_fBuyPrice[0],lDigits ), DoubleToString(rspReport.m_fSellPrice[0],lDigits )));
}
void CTcpManager::GetDepth(RSP_REPORT &OneReport,const string &symbol)
{
	StringToCharArray("FXCM", OneReport.m_szBrokerName,0,WHOLE_ARRAY,CP_UTF8);
	StringToCharArray("13923887010", OneReport.m_szAccountName,0,WHOLE_ARRAY,CP_UTF8);
	StringToCharArray(symbol, OneReport.m_szCode,0,WHOLE_ARRAY,CP_UTF8);

	int   iTotal   =  GlobalVariablesTotal();
   bool  bNeeded  =  false;
   for(int i=0;i<iTotal;i++)
   {
      if(StringCompare(symbol,GlobalVariableName(i),false)==0)
      {
         bNeeded  =  true;
      }
   }
   if(!bNeeded)
   {
      return;
   }
   MqlBookInfo priceArray[];
   bool getBook=MarketBookGet(symbol,priceArray);
   if(getBook)
   {
      int size=ArraySize(priceArray);
      Print("MarketBookInfo get for ",symbol);
      
      /*           
      for(int i=0;i<size;i++)
      {
         if(priceArray[i].type==BOOK_TYPE_BUY)
         {
            Print(IntegerToString(i,2,'0')+":",DoubleToString(priceArray[i].price,SymbolInfoInteger(symbol,SYMBOL_DIGITS))
            //+"    Volume = "+priceArray[i].volume
            ,
            " type = ",StringFormat("%20s",EnumToString(priceArray[i].type)));
            break;         
         }         
      }      
      for(int i=size-1;i>0;i--)
      {
         if(priceArray[i].type==BOOK_TYPE_SELL)
         {
            Print(IntegerToString(i,2,'0')+":",DoubleToString(priceArray[i].price,SymbolInfoInteger(symbol,SYMBOL_DIGITS))
            //+"    Volume = "+priceArray[i].volume
            ,
            " type = ",StringFormat("%20s",EnumToString(priceArray[i].type)));         
            break;         
         }
      } 
      */
      /*
         priceArray[i]
         价格由0开始，随index增加而减少
         0:1.5
         1:1.4
         2:1.3
         所以，for(int i=0;i<size;i++)
               最先遇到的一个buy单是最高bid价格bid0
               for(int i=size;i>=0;i--)
               最先遇到的一个sell单是最低ask价格sell0
      */

      for(int i=0;i<size;i++)
      {  //mid 由高到低遍历价格，第一个BUY单为bid0
         if(priceArray[i].type==BOOK_TYPE_BUY)
         {  //mid 找到第一个BUY单
            for(int j=0;(j<ArraySize(OneReport.m_fBuyPrice)&&j>=0)&&(i<size&&i>=0);j++,i++)
            {
		         OneReport.m_fBuyPrice[j] = priceArray[i].price;
		         OneReport.m_fBuyVolume[j] = priceArray[i].volume;
            }
            break;   //mid 操，这个必须加入，否则会继续上层循环，导致赋值错误
         }
      }
      for(int i=size-1;i>=0;i--)
      {  //mid 有低到高遍历价格，第一个SELL单为ask0
         if(priceArray[i].type==BOOK_TYPE_SELL)
         {
            for(int j=0;(j<ArraySize(OneReport.m_fBuyPrice)&&j>=0)&&(i<size&&i>=0);j++,i--)
            {
		         OneReport.m_fSellPrice[j] = priceArray[i].price;
		         OneReport.m_fSellVolume[j] = priceArray[i].volume;
            }
            break;//mid 操，这个必须加入，否则会继续上层循环，导致赋值错误
         }
      }		
      //Print(IntegerToString(0,2,'0')+":",DoubleToString(OneReport.m_fSellPrice[0],SymbolInfoInteger(symbol,SYMBOL_DIGITS)));         
      //Print(IntegerToString(0,2,'0')+":",DoubleToString(OneReport.m_fBuyPrice[0],SymbolInfoInteger(symbol,SYMBOL_DIGITS)));
   }
   else
   {
      Print("Could not get contents of the symbol DOM ",Symbol());
		CSymbolInfo symbolInfo;
		symbolInfo.Name(symbol);
		//symbolInfo.Refresh();          //mid 获取符号相关数据（功能尚未清楚）
		symbolInfo.RefreshRates();       //mid 获取价格数据
		OneReport.m_fBuyPrice[0] = symbolInfo.Bid();
		OneReport.m_fSellPrice[0] = symbolInfo.Ask();
   } 
   
	//OneReport.m_fLast = rates[1].close;
	//OneReport.m_fOpen = rates[0].open;
	//OneReport.m_fHigh = rates[0].high;
	//OneReport.m_fLow = rates[0].low;
	//OneReport.m_fVolume = rates[0].tick_volume;
	OneReport.m_fNew =  OneReport.m_fBuyPrice[0];
}
int CTcpManager::GetHistoryDataAndSend(SOCKET_MT &socket,RSP_HISTORY_HEADER & rspHistoryHeader,RSP_HISTORY  & HistoryKDataArrayAll[], string strCode, ENUM_TIMEFRAMES enuTimeFrame)
{
	//int   iBytesLimitation  =  65535;                                             //mid xp系统定义的最大数据发送bytes数
	Print("Begin get history data on::", strCode, "--", EnumToString(enuTimeFrame));
	//mid 1)准备获取数据结构数组数据
	int   iSizeOfStruct = sizeof(RSP_HISTORY);                             //mid 价格数据结构体单元
	int   iCountToWriteAll = Bars(strCode, enuTimeFrame);                           //mid 剩余需要被传输的bars个数，用于填充数据结构
	Print(__FUNCTION__,"().Total bars on chart::", iCountToWriteAll);
	if (iCountToWriteAll > 10000)
	{//mid 在没有加入请求数据日期指定前，需要如此控制数量，否则M1，M5等数据量太大，阻塞处理。
		iCountToWriteAll = 10000;
	}
	MqlRates rates[];
	ArrayResize(rates, iCountToWriteAll);
	ArraySetAsSeries(rates, false);
	//mid 2)获得数据
	int copied = CopyRates(strCode, enuTimeFrame, 0, iCountToWriteAll, rates);
	//mid 3)将已获得数据转换为返回数据格式
	ArrayResize(HistoryKDataArrayAll, iCountToWriteAll);
	ArraySetAsSeries(rates, false);
	for (int i = 0; i < iCountToWriteAll; i++)
	{
		TimeToStruct(rates[i].time, HistoryKDataArrayAll[i].m_time);
		HistoryKDataArrayAll[i].m_fOpen = rates[i].open;
		HistoryKDataArrayAll[i].m_fHigh = rates[i].high;
		HistoryKDataArrayAll[i].m_fLow = rates[i].low;
		HistoryKDataArrayAll[i].m_fClose = rates[i].close;
		HistoryKDataArrayAll[i].m_fVolume = rates[i].tick_volume;
	}
	//return  iCountToWriteAll;
	//mid 3)发送数据
	int iAmountToSent=iCountToWriteAll;
	rspHistoryHeader.m_nCount=iAmountToSent; 
   //mid 3.1)发送数据头
   int nBytesSent;
   uint  unSendStatus = ERROR_INVALID_HANDLE;
   unSendStatus =SocketSend(socket,rspHistoryHeader,sizeof(RSP_HISTORY_HEADER),nBytesSent,0);
   if(unSendStatus==ERROR_SUCCESS)
   {  //mid 头发送成功
   	static int iCounterSent=0;
   	iCounterSent++;		Print("历史数据头已发送。");
   	Print("rspHistoryHeader sent.");
      //mid 3.2)发送数据
      Print("Total amout of bars to sent::",iAmountToSent);
      Print("Total amout of BYTES to sent::",iAmountToSent*sizeof(RSP_HISTORY));
      if(SocketSend(socket,HistoryKDataArrayAll,iAmountToSent*sizeof(RSP_HISTORY),nBytesSent,0)==ERROR_SUCCESS)
      {
         Print("History data sent.");
      }
      else
      {
         Alert("History data sent error.**********");
      }   
   }
	else
	{
   	Alert("rspHistoryHeader sent error.**********");
	}

   /*
   */

   return iAmountToSent;
}
CTcpManager::CTcpManager(void)
{

}
CTcpManager::~CTcpManager(void)
{
}
uint  CTcpManager::SocketSend(SOCKET_MT &socket, RSP_HISTORY_HEADER &reqHeader, int nBytesToSend, int &pnBytesSent, int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketSend(socket, reqHeader, nBytesToSend, pnBytesSent, flag));
   }
   else
   {
      return 0;
   }
}
uint  CTcpManager::SocketSend(SOCKET_MT &socket, RSP_LOGIN &reqHeader, int nBytesToSend, int &pnBytesSent, int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketSend(socket, reqHeader, nBytesToSend, pnBytesSent, flag));
   }
   else
   {
      return 0;
   }
}
uint  CTcpManager::SocketSend(SOCKET_MT &socket, RSP_CONNECT &reqHeader, int nBytesToSend, int &pnBytesSent, int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketSend(socket, reqHeader, nBytesToSend, pnBytesSent, flag));
   }
   else
   {
      return 0;
   }
}uint  CTcpManager::SocketSend(SOCKET_MT &socket, RSP_LOGOUT &reqHeader, int nBytesToSend, int &pnBytesSent, int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketSend(socket, reqHeader, nBytesToSend, pnBytesSent, flag));
   }
   else
   {
      return 0;
   }
}
uint  CTcpManager::SocketSend(SOCKET_MT &socket, RSP_REPORT  &outgoing, int nBytesToSend,    int &pnBytesSent,    int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketSend(socket, outgoing, nBytesToSend, pnBytesSent, flag));
   }
   else
   {
      return 0;
   }
}
uint  CTcpManager::SocketSend(SOCKET_MT &socket,  RSP_HISTORY  &outgoing[], int nBytesToSend, int &pnBytesSent, int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketSend(socket, outgoing, nBytesToSend, pnBytesSent, flag));
   }
   else
   {
      return 0;
   }
}
uint  CTcpManager::SocketSend(SOCKET_MT &socket,  RSP_CODE  &outgoing[], int nBytesToSend, int &pnBytesSent, int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketSend(socket, outgoing, nBytesToSend, pnBytesSent, flag));
   }
   else
   {
      return 0;
   }
}
uint  CTcpManager::SocketSend(SOCKET_MT &socket,  RSP_CODE_HEADER  &outgoing, int nBytesToSend, int &pnBytesSent, int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketSend(socket, outgoing, nBytesToSend, pnBytesSent, flag));
   }
   else
   {
      return 0;
   }
}
uint  CTcpManager::SocketSend(SOCKET_MT &socket,  RSP_UNSUBSCRIBE  &outgoing, int nBytesToSend, int &pnBytesSent, int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketSend(socket, outgoing, nBytesToSend, pnBytesSent, flag));
   }
   else
   {
      return 0;
   }
}

uint  CTcpManager::SocketRecv(SOCKET_MT &socket, REQ_UNSUBSCRIBE &reqHeader[], int nBytesToReceived, int &pnBytesReceived, int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketRecv(socket, reqHeader, nBytesToReceived, pnBytesReceived, flag));
   }
   else
   {
      return 0;
   }
}

uint  CTcpManager::SocketRecv(SOCKET_MT &socket, REQ_UNSUBSCRIBE_HEADER &reqHeader, int nBytesToReceived, int &pnBytesReceived, int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketRecv(socket, reqHeader, nBytesToReceived, pnBytesReceived, flag));
   }
   else
   {
      return 0;
   }
}
uint  CTcpManager::SocketSend(SOCKET_MT &socket,  RSP_SUBSCRIBE  &outgoing, int nBytesToSend, int &pnBytesSent, int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketSend(socket, outgoing, nBytesToSend, pnBytesSent, flag));
   }
   else
   {
      return 0;
   }
}

uint  CTcpManager::SocketRecv(SOCKET_MT &socket, REQ_SUBSCRIBE &reqHeader[], int nBytesToReceived, int &pnBytesReceived, int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketRecv(socket, reqHeader, nBytesToReceived, pnBytesReceived, flag));
   }
   else
   {
      return 0;
   }
}

uint  CTcpManager::SocketRecv(SOCKET_MT &socket, REQ_SUBSCRIBE_HEADER &reqHeader, int nBytesToReceived, int &pnBytesReceived, int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketRecv(socket, reqHeader, nBytesToReceived, pnBytesReceived, flag));
   }
   else
   {
      return 0;
   }
}
uint  CTcpManager::SocketRecv(SOCKET_MT &socket, REQ_HEADER &reqHeader, int nBytesToReceived, int &pnBytesReceived, int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketRecv(socket, reqHeader, nBytesToReceived, pnBytesReceived, flag));
   }
   else
   {
      return 0;
   }
}
uint  CTcpManager::SocketRecv(SOCKET_MT &socket, REQ_LOGIN   &reqLogin,     int nBytesToReceived, int &pnBytesReceived,  int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketRecv(socket, reqLogin, nBytesToReceived, pnBytesReceived, flag));
   }
   else
   {
      return 0;
   }
}
uint  CTcpManager::SocketRecv(SOCKET_MT &socket, REQ_CONNECT   &reqLogin,     int nBytesToReceived, int &pnBytesReceived,  int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketRecv(socket, reqLogin, nBytesToReceived, pnBytesReceived, flag));
   }
   else
   {
      return 0;
   }
}
uint  CTcpManager::SocketRecv(SOCKET_MT &socket, REQ_LOGOUT   &reqLogin,     int nBytesToReceived, int &pnBytesReceived,  int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketRecv(socket, reqLogin, nBytesToReceived, pnBytesReceived, flag));
   }
   else
   {
      return 0;
   }
}

uint  CTcpManager::SocketRecv(SOCKET_MT &socket, REQ_HISTORY &reqHistory, int nBytesToReceived, int &pnBytesReceived, int flag)
{
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketRecv(socket, reqHistory, nBytesToReceived, pnBytesReceived, flag));
   }
   else
   {
      return 0;
   }
}
//+------------------------------------------------------------------+
//|   SocketConnectToServer                                                     |
//+------------------------------------------------------------------+
uint CTcpManager::SocketConnectToServer(SOCKET_MT &socket,const string host,const ushort port)
  {
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketConnectToServer(socket, host, port));
   }
   else
   {
      return(-1);
   }
  }
/*--------------------------------------------------------------------
   SocketListenToClient
---------------------------------------------------------------------*/
uint CTcpManager::SocketListenToClient(SOCKET_MT &socket,const string host,const ushort port)
  {
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketListenToClient(socket, host, port));
   }
   else
   {
      return(-1);
   }
  }
/*--------------------------------------------------------------------
   SocketAcceptClient
---------------------------------------------------------------------*/
uint CTcpManager::SocketAcceptClient(SOCKET_MT &socketServerListening,SOCKET_MT &socketAccepted)
  {
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketAcceptClient(socketServerListening,socketAccepted));
   }
   else
   {
      return(-1);
   }
  }
//+------------------------------------------------------------------+
//|   SocketClose                                                    |
//+------------------------------------------------------------------+
void CTcpManager::SocketClose(SOCKET_MT &socket)
  {
   if(_IsX64)
   {
      socket_mql5_x64::SocketClose(socket);
   }
   else 
   {
      return;
   }
  }
//+------------------------------------------------------------------+
//|   SysErrorMessage                                                |
//+------------------------------------------------------------------+
string CTcpManager::SocketErrorString(const int error_code)
  {
   if(_IsX64)
   {
      return(socket_mql5_x64::SocketErrorString(error_code));
   }
   else
   {
      return(-1);
   }
  }  
void CTcpManager::ParseAskTypeLogin(SOCKET_MT &socket,REQ_HEADER &AskHeader)
{
	Print("Begin to ParseAskTypeLogin.");
	REQ_LOGIN reqLogin;
	int iSize = sizeof(REQ_LOGIN);
	
   int   nBytesReceived;
   uint  unReceiveStatus = ERROR_INVALID_HANDLE;
   unReceiveStatus =SocketRecv(socket,reqLogin,sizeof(REQ_LOGIN),nBytesReceived,0);
   if(unReceiveStatus==ERROR_SUCCESS)
   {
     	Print("LoginData received.");
     	Print("Broker:",CharArrayToString(reqLogin.broker,0,WHOLE_ARRAY,CP_UTF8),".Account:",CharArrayToString(reqLogin.account,0,WHOLE_ARRAY,CP_UTF8),".Password:",CharArrayToString(reqLogin.password,0,WHOLE_ARRAY,CP_UTF8));
     	RSP_LOGIN rspLogin;
   	//mid 此处应添加对用户账户和密码的验证
   	string strResult;
   	if(true)
   	{
   	   strResult="TRUE";
   	}
   	else
   	{
   	   strResult="FALSE";
   	}
   	StringToCharArray(strResult, rspLogin.result,0,WHOLE_ARRAY,CP_UTF8); //将string字符数组转化为char字符数组。因stkui使用char类型的字符组      RSP_HISTORY_HEADER   rspHistoryHeader;


	   int nBytesSent;
      uint  unSendStatus = ERROR_INVALID_HANDLE;
      Print("Begin to send RspLogin Data...");
      unSendStatus =SocketSend(socket,rspLogin,sizeof(RSP_LOGIN),nBytesSent,0);
      
      if(unSendStatus==ERROR_SUCCESS)
      {  //mid 头发送成功
      	Print("rspLogin data sent.");
   	}
   	else
   	{
      	Alert("Login data sent error.**********");
   	}
   }
}
void CTcpManager::ParseAskTypeSubscribe(SOCKET_MT &socket,REQ_HEADER &AskHeader)
{
	Print(__FUNCTION__,"Begin to ParseAskTypeSubscribe.");
	REQ_SUBSCRIBE_HEADER reqSubscribeHeader;
	int iSize = sizeof(REQ_SUBSCRIBE_HEADER);
	
   int   nBytesReceived;
   uint  unReceiveStatus = ERROR_INVALID_HANDLE;
   unReceiveStatus =SocketRecv(socket,reqSubscribeHeader,sizeof(REQ_SUBSCRIBE_HEADER),nBytesReceived,0);
   if(unReceiveStatus==ERROR_SUCCESS)
   {
     	Print(__FUNCTION__,"reqSubscribeHeader received.");
     	Print("Counts To Subscribe:",reqSubscribeHeader.counts);
     	
     	REQ_SUBSCRIBE  reqSubscribe[];
     	ArrayResize(reqSubscribe,reqSubscribeHeader.counts);
     	
      nBytesReceived=0;
      unReceiveStatus = ERROR_INVALID_HANDLE;
      unReceiveStatus =SocketRecv(socket,reqSubscribe,reqSubscribeHeader.counts*sizeof(REQ_SUBSCRIBE),nBytesReceived,0);
     	if(unReceiveStatus==ERROR_SUCCESS)
     	{
     	   bool bSubscribed = true;
     	   for(int i=0;i<reqSubscribeHeader.counts;i++)
     	   {  //mid 添加所有當次訂閱Symbols到訂閱總列表
     	      string strSymbol = CharArrayToString(reqSubscribe[i].symbol,0,WHOLE_ARRAY,CP_UTF8);
     	      Print(__FUNCTION__,StringFormat("No.%d symbols:%s received.",i,strSymbol));
     	      m_SubscribedSymbols.AddUniqueSymbol(strSymbol);
     	   }
     	   //mid 刪除所有全局變量
     	   
     	   if(!m_SubscribedSymbols.SynchronizeGlobalValues())
         {//mid 刪除所有全局變量，并將當前已訂閱列表同步
            bSubscribed=false;
         }
         else
         {
            long lNextChart = ChartNext(ChartID());
            if(lNextChart==-1)
            {  //mid -1 表示傳入Chart為最後一個Chart，沒有下一個，表示尋找失敗，此時新建一個
               lNextChart=ChartOpen(NULL,0);
            }
            if(lNextChart!=-1)
            {
               /*
               */
               if(!ChartApplyTemplate(lNextChart,"MidTemplates\\ExpertTcpClientMarketData.tpl"))
               {
                  int iErr= GetLastError();
                  bSubscribed=false;
               }               
            }
            else
            {
               int iErr= GetLastError();
               bSubscribed=false;               
            }
         }
     	   //mid 接收订阅数据，并处理之后，发送订阅处理结果回馈
        	RSP_SUBSCRIBE rspSubscribe;
      	//mid 此处应添加对用户账户和密码的验证
      	string strResult;
      	if(bSubscribed)
      	{
      	   strResult="TRUE";
      	}
      	else
      	{
      	   strResult="FALSE";
      	}
      	StringToCharArray(strResult, rspSubscribe.result,0,WHOLE_ARRAY,CP_UTF8); //将string字符数组转化为char字符数组。因stkui使用char类型的字符组      RSP_HISTORY_HEADER   rspHistoryHeader;
      
      
         int nBytesSent;
         uint  unSendStatus = ERROR_INVALID_HANDLE;
         Print(__FUNCTION__,"Begin to send rspSubscribe Data...");
         unSendStatus =SocketSend(socket,rspSubscribe,sizeof(RSP_SUBSCRIBE),nBytesSent,0);
         
         if(unSendStatus==ERROR_SUCCESS)
         {  //mid 头发送成功
         	Print(__FUNCTION__,"rspSubscribe data sent.");
      	}
      	else
      	{
         	Alert(__FUNCTION__,"rspSubscribe data sent error.**********");
      	}
     	}
   }
   
}
void CTcpManager::ParseAskTypeCode(SOCKET_MT &socket,REQ_HEADER &AskHeader)
{
	Print(__FUNCTION__,"Begin to ParseAskTypeSubscribe.");
   int iTotalSymbols = SymbolsTotal(false);	
	RSP_CODE_HEADER rspCodeHeader;
   //mid 生成返回头
   rspCodeHeader.m_nCount=iTotalSymbols;
 	StringToCharArray(AccountInfoString(ACCOUNT_COMPANY), rspCodeHeader.m_szBroker,0,WHOLE_ARRAY,CP_UTF8);
 	StringToCharArray(AccountInfoString(ACCOUNT_NAME), rspCodeHeader.m_szAccount,0,WHOLE_ARRAY,CP_UTF8);
    
   int nBytesSent;
   uint  unSendStatus = ERROR_INVALID_HANDLE;
   Print(__FUNCTION__,"Begin to send rspSubscribe Data...");
   unSendStatus =SocketSend(socket,rspCodeHeader,sizeof(RSP_CODE_HEADER),nBytesSent,0);
   if(unSendStatus==ERROR_SUCCESS)
   {  //mid 头发送成功
   	Print(__FUNCTION__,"rspSubscribe data sent.");
      RSP_CODE  rspCodes[];
      ArrayResize(rspCodes,rspCodeHeader.m_nCount);
   	
      for(int i=0; i<rspCodeHeader.m_nCount; i++)
      {
       	string strSymbol = SymbolName(i,false);
       	StringToCharArray(strSymbol, rspCodes[i].m_szCode,0,WHOLE_ARRAY,CP_UTF8);
       	StringToCharArray(strSymbol, rspCodes[i].m_szName,0,WHOLE_ARRAY,CP_UTF8);
       	rspCodes[i].m_iDigits=SymbolInfoInteger(strSymbol,SYMBOL_DIGITS);
	   }   
	   int nBytesSent;
      uint  unSendStatus = ERROR_INVALID_HANDLE;
      Print(__FUNCTION__,"Begin to send rspSubscribe Data...");
      unSendStatus =SocketSend(socket,rspCodes,sizeof(RSP_CODE)*rspCodeHeader.m_nCount,nBytesSent,0);   	

      if(unSendStatus==ERROR_SUCCESS)
      {  //mid 头发送成功
      	Print(__FUNCTION__,"rspSubscribe data sent.");
      }
   }
   else
   {
   	Alert(__FUNCTION__,"rspSubscribe data sent error.**********");
   }
}
void CTcpManager::ParseAskTypeUnSubscribe(SOCKET_MT &socket,REQ_HEADER &AskHeader)
{
	Print(__FUNCTION__,"Begin to ParseAskTypeSubscribe.");
	REQ_UNSUBSCRIBE_HEADER reqUnSubscribeHeader;
	int iSize = sizeof(REQ_UNSUBSCRIBE_HEADER);
	
   int   nBytesReceived;
   uint  unReceiveStatus = ERROR_INVALID_HANDLE;
   unReceiveStatus =SocketRecv(socket,reqUnSubscribeHeader,sizeof(REQ_UNSUBSCRIBE_HEADER),nBytesReceived,0);
   if(unReceiveStatus==ERROR_SUCCESS)
   {
     	Print(__FUNCTION__,"reqUnSubscribeHeader received.");
     	Print("Counts To UnSubscribe:",reqUnSubscribeHeader.counts);
     	
     	REQ_UNSUBSCRIBE  reqUnSubscribe[];
     	ArrayResize(reqUnSubscribe,reqUnSubscribeHeader.counts);
     	
      nBytesReceived=0;
      unReceiveStatus = ERROR_INVALID_HANDLE;
      unReceiveStatus =SocketRecv(socket,reqUnSubscribe,reqUnSubscribeHeader.counts*sizeof(REQ_UNSUBSCRIBE),nBytesReceived,0);
     	if(unReceiveStatus==ERROR_SUCCESS)
     	{
     	   bool bSubscribed = true;
     	   for(int i=0;i<reqUnSubscribeHeader.counts;i++)
     	   {  //mid 添加所有當次訂閱Symbols到訂閱總列表
     	      string strSymbol = CharArrayToString(reqUnSubscribe[i].symbol,0,WHOLE_ARRAY,CP_UTF8);
     	      Print(__FUNCTION__,StringFormat("No.%d symbols:%s received.",i,strSymbol));
     	      m_SubscribedSymbols.DeleteAllSymbol(strSymbol);
     	   }
     	   //mid 刪除所有全局變量
     	   
     	   if(!m_SubscribedSymbols.SynchronizeGlobalValues())
         {//mid 刪除所有全局變量，并將當前已訂閱列表同步
            bSubscribed=false;
         }
         //mid UI 中的邏輯是，先退訂，緊接著訂閱
         //mid 所以，為減少MT系統開銷，退訂操作不應應用到EA
         /*
         else
         {
            long lNextChart = ChartNext(ChartID());
            if(lNextChart==-1)
            {  //mid -1 表示傳入Chart為最後一個Chart，沒有下一個，表示尋找失敗，此時新建一個
               lNextChart=ChartOpen(NULL,0);
            }
            if(lNextChart!=-1)
            {
               if(!ChartApplyTemplate(lNextChart,"MidTemplates\\aa.tpl"))
               {
                  int iErr= GetLastError();
                  bSubscribed=false;
               }
            }
            else
            {
               int iErr= GetLastError();
               bSubscribed=false;               
            }
         }
               */
     	   //mid 接收订阅数据，并处理之后，发送订阅处理结果回馈
        	RSP_UNSUBSCRIBE rspUnSubscribe;
      	//mid 此处应添加对用户账户和密码的验证
      	string strResult;
      	if(bSubscribed)
      	{
      	   strResult="TRUE";
      	}
      	else
      	{
      	   strResult="FALSE";
      	}
      	StringToCharArray(strResult, rspUnSubscribe.result,0,WHOLE_ARRAY,CP_UTF8); //将string字符数组转化为char字符数组。因stkui使用char类型的字符组      RSP_HISTORY_HEADER   rspHistoryHeader;
      
      
         int nBytesSent;
         uint  unSendStatus = ERROR_INVALID_HANDLE;
         Print(__FUNCTION__,"Begin to send rspSubscribe Data...");
         unSendStatus =SocketSend(socket,rspUnSubscribe,sizeof(RSP_UNSUBSCRIBE),nBytesSent,0);
         
         if(unSendStatus==ERROR_SUCCESS)
         {  //mid 头发送成功
         	Print(__FUNCTION__,"rspSubscribe data sent.");
      	}
      	else
      	{
         	Alert(__FUNCTION__,"rspSubscribe data sent error.**********");
      	}
     	}
   }
}
void CTcpManager::ParseAskTypeConnect(SOCKET_MT &socket,REQ_HEADER &AskHeader)
{
	Print(__FUNCTION__,"Begin to ParseAskTypeConnect.");
	REQ_CONNECT reqConnect;
	int iSize = sizeof(REQ_CONNECT);
   int   nBytesReceived;
   uint  unReceiveStatus = ERROR_INVALID_HANDLE;
   unReceiveStatus =SocketRecv(socket,reqConnect,sizeof(REQ_CONNECT),nBytesReceived,0);
   if(unReceiveStatus==ERROR_SUCCESS)
   {
     	Print(__FUNCTION__,"reqConnectData received.");

     	string str7=CharArrayToString(reqConnect.connect,0,WHOLE_ARRAY,CP_UTF8);
     	
     	
     	
     	RSP_CONNECT rspConnect;
   	//mid 此处应添加对用户账户和密码的验证
   	string strResult;
   	if(true)
   	{
   	   strResult="TRUE";
   	}
   	else
   	{
   	   strResult="FALSE";
   	}
   	StringToCharArray(strResult, rspConnect.connect,0,WHOLE_ARRAY,CP_UTF8); //将string字符数组转化为char字符数组。因stkui使用char类型的字符组      RSP_HISTORY_HEADER   rspHistoryHeader;


	   int nBytesSent;
      uint  unSendStatus = ERROR_INVALID_HANDLE;
      Print(__FUNCTION__,"Begin to send reqConnectData Data...");
      unSendStatus =SocketSend(socket,rspConnect,sizeof(RSP_CONNECT),nBytesSent,0);
      
      if(unSendStatus==ERROR_SUCCESS)
      {  //mid 头发送成功
      	Print(__FUNCTION__,"reqConnectData data sent.");
   	}
   	else
   	{
      	Alert(__FUNCTION__,"reqConnectData data sent error.**********");
   	}
   }
}
bool CTcpManager::ParseAskTypeLogout(SOCKET_MT &socket,REQ_HEADER &AskHeader)
{
	Print("Begin to ParseAskTypeLogout.");
	bool bLogouted=false;
	REQ_LOGOUT reqLogout;
	int iSize = sizeof(REQ_LOGOUT);
	
   int   nBytesReceived;
   uint  unReceiveStatus = ERROR_INVALID_HANDLE;
   unReceiveStatus =SocketRecv(socket,reqLogout,sizeof(REQ_LOGOUT),nBytesReceived,0);
   if(unReceiveStatus==ERROR_SUCCESS)
   {
     	Print("LogoutData received.");
     	RSP_LOGOUT rspLogout;
   	//mid 此处应添加对用户账户和密码的验证
   	string strResult;
   	if(true)
   	{
   	   strResult="TRUE";
   	}
   	else
   	{
   	   strResult="FALSE";
   	}
   	StringToCharArray(strResult, rspLogout.result,0,WHOLE_ARRAY,CP_UTF8); //将string字符数组转化为char字符数组。因stkui使用char类型的字符组      RSP_HISTORY_HEADER   rspHistoryHeader;


	   int nBytesSent;
      uint  unSendStatus = ERROR_INVALID_HANDLE;
      Print("Begin to send RspLogout Data...");
      unSendStatus =SocketSend(socket,rspLogout,sizeof(RSP_LOGOUT),nBytesSent,0);
      
      if(unSendStatus==ERROR_SUCCESS)
      {  //mid 头发送成功
      	Print("rspLogout data sent.");
      	bLogouted=true;
   	}
   	else
   	{
      	Alert("Login data sent error.**********");
   	}
   }
   return bLogouted;
}
void CTcpManager::ParseAskTypeHistory(SOCKET_MT &socket,REQ_HEADER &AskHeader)
{
   Print("Begin to ParseAskTypeHistory.");
	REQ_HISTORY reqHistory;
	int iSize = sizeof(REQ_HISTORY);
	
   int   nBytesReceived;
   uint  unReceiveStatus = ERROR_INVALID_HANDLE;
   unReceiveStatus =SocketRecv(socket,reqHistory,sizeof(REQ_HISTORY),nBytesReceived,0);
   if(unReceiveStatus==ERROR_SUCCESS)
   {
      Print("请求Symbol:",CharArrayToString(reqHistory.symbol,0,WHOLE_ARRAY,CP_UTF8));
      Print ("请求Period:",EnumToString((EnumReqHistoryDataType)reqHistory.type));
      //mid 1）构造返回数据头
      RSP_HISTORY_HEADER   rspHistoryHeader;
      //mid 构造返回结构的Symbol,Period.简单根据请求数据赋值，用于请求方核对。
      ArrayCopy(rspHistoryHeader.m_szSymbol,reqHistory.symbol);
      rspHistoryHeader.m_type=reqHistory.type;            
      //StringToCharArray(Symbol(),rspHistoryHeader.m_szSymbol );   //将string字符数组转化为char字符数组。因stkui使用char类型的字符组              switch(reqHistory.type)
      //mid 2）构造返回数据
      RSP_HISTORY  HistoryKDataArrayAll[];

      switch(reqHistory.type)
      {
         case  HistoryPeriodM1:
         {
            int iAmountToSent=GetHistoryDataAndSend(socket,rspHistoryHeader,HistoryKDataArrayAll,CharArrayToString(reqHistory.symbol,0,WHOLE_ARRAY,CP_UTF8),PERIOD_M1);
            break;
         }
         case  HistoryPeriodM5:
         {
            int iAmountToSent=GetHistoryDataAndSend(socket,rspHistoryHeader,HistoryKDataArrayAll,CharArrayToString(reqHistory.symbol,0,WHOLE_ARRAY,CP_UTF8),PERIOD_M5);
            break;
         }         
         case  HistoryPeriodM15:
         {
            int iAmountToSent=GetHistoryDataAndSend(socket,rspHistoryHeader,HistoryKDataArrayAll,CharArrayToString(reqHistory.symbol,0,WHOLE_ARRAY,CP_UTF8),PERIOD_M15);
            break;
         }                  
         case  HistoryPeriodM30:
         {
            int iAmountToSent=GetHistoryDataAndSend(socket,rspHistoryHeader,HistoryKDataArrayAll,CharArrayToString(reqHistory.symbol,0,WHOLE_ARRAY,CP_UTF8),PERIOD_M30);
            break;
         }           
         case  HistoryPeriodH1:
         {
            int iAmountToSent=GetHistoryDataAndSend(socket,rspHistoryHeader,HistoryKDataArrayAll,CharArrayToString(reqHistory.symbol,0,WHOLE_ARRAY,CP_UTF8),PERIOD_H1);
            break;
         }           
         case  HistoryPeriodH4:
         {
            int iAmountToSent=GetHistoryDataAndSend(socket,rspHistoryHeader,HistoryKDataArrayAll,CharArrayToString(reqHistory.symbol,0,WHOLE_ARRAY,CP_UTF8),PERIOD_H4);
            break;
         }           
         case  HistoryPeriodD1:
         {
            int iAmountToSent=GetHistoryDataAndSend(socket,rspHistoryHeader,HistoryKDataArrayAll,CharArrayToString(reqHistory.symbol,0,WHOLE_ARRAY,CP_UTF8),PERIOD_D1);
            break;
         }           
         case  HistoryPeriodW1:
         {
            int iAmountToSent=GetHistoryDataAndSend(socket,rspHistoryHeader,HistoryKDataArrayAll,CharArrayToString(reqHistory.symbol,0,WHOLE_ARRAY,CP_UTF8),PERIOD_W1);
            break;
         }           
         case  HistoryPeriodMN:
         {
            int iAmountToSent=GetHistoryDataAndSend(socket,rspHistoryHeader,HistoryKDataArrayAll,CharArrayToString(reqHistory.symbol,0,WHOLE_ARRAY,CP_UTF8),PERIOD_MN1);
            break;
         }           
       default:
           break;
      }   
   
   }  
} 
