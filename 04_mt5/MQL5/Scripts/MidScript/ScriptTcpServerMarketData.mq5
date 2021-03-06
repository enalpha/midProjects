#include    <Trade\SymbolInfo.mqh>
#include    <MidInclude\TcpManager.mqh>

input string         InpHost = "192.168.0.212"; // Host
input ushort         InpPort = 5050;            // Port

//mid 分别为监听Socket和已接受连接Socket，此两值需要分开，而且由于只接受一个连接，所以Accepted只需一个即可
SOCKET_MT      g_SocketServerListening;   
SOCKET_MT      g_SocketAccepted;

CTcpManager    g_TcpManager;

int Init()
{
	/*
	1)创建Socket
	2)绑定
	3)侦听
	以上三步骤成功后返回TRUE
	*/
	if (g_TcpManager.SocketListenToClient(g_SocketServerListening, InpHost, InpPort) == ERROR_SUCCESS)
	{//mid 成功开始侦听
		return ERROR_SUCCESS;
	}
	else
	{
		return ERROR_INVALID_HANDLE;
	}
}
void Deinit()
{  
   Print("TcpServer Deinited.");
	g_TcpManager.SocketClose(g_SocketServerListening);
}
void OnStart()
{
	int iReturnValue = Init();
	switch (iReturnValue)
	{
		case ERROR_INVALID_HANDLE:
		{
			Print("Failed.");
			break;
		}
		case ERROR_SUCCESS:
		{
			Print("Init Successed.");


			bool bToAccept = true;
			uint  bAcceptStatus = ERROR_INVALID_HANDLE;
			while (bToAccept)
			{
				{
					//mid 阻塞等待连接
					int i = 0;
					//Print(__FUNCTION__,"Waiting for being connected.");
					bAcceptStatus = g_TcpManager.SocketAcceptClient(g_SocketServerListening,g_SocketAccepted);
				   Print(__FUNCTION__,"Waiting for being connected returned.");
				}
				switch (bAcceptStatus)
				{
					case  ERROR_INVALID_HANDLE:
					{//mid 接受连接失败
						Print(__FUNCTION__,"Accept client failed.");
						break;
					}
					case ERROR_SUCCESS:
					{//mid 接受连接成功
						Print(__FUNCTION__,"Accept client successed.");
                  int nBytesReceived;
                  uint  unReceiveStatus = ERROR_INVALID_HANDLE;
						REQ_HEADER   reqHeader;
                  unReceiveStatus =g_TcpManager.SocketRecv(g_SocketAccepted,reqHeader,sizeof(REQ_HEADER),nBytesReceived,0);
                  if(unReceiveStatus==ERROR_SUCCESS)
                  {
 							Print(__FUNCTION__,"AskType received.");
							Print(__FUNCTION__,"AskHeader's AskType::", EnumToString((EnumReqType)reqHeader.AskType));
							switch (reqHeader.AskType)
							{
								case  EnumReqType::ReqTypeHistory:
								{
							      g_TcpManager.ParseAskTypeHistory(g_SocketAccepted,reqHeader);
									break;
								}
								case EnumReqType::ReqTypeLogin:
								{
									g_TcpManager.ParseAskTypeLogin(g_SocketAccepted,reqHeader);
									break;
								}
								case EnumReqType::ReqTypeLogout:
								{  //mid 登出服务请求，此后TcpServer不在阻塞等待建立连接并关闭。如此设置是为了不让mt5服务器阻塞。
									if(g_TcpManager.ParseAskTypeLogout(g_SocketAccepted,reqHeader))
									{
									   bToAccept=false;									
									}
									break;
								}
								case EnumReqType::ReqTypeConnect:
								{
									g_TcpManager.ParseAskTypeConnect(g_SocketAccepted,reqHeader);
									break;
								}
								case EnumReqType::ReqTypeSubscribe:
								{
								   g_TcpManager.ParseAskTypeSubscribe(g_SocketAccepted,reqHeader);
								   break;
								}
								case EnumReqType::ReqTypeUnSubscribe:
								{
								   g_TcpManager.ParseAskTypeUnSubscribe(g_SocketAccepted,reqHeader);
								   break;
								}					
								case EnumReqType::ReqTypeCode:
								{
								   g_TcpManager.ParseAskTypeCode(g_SocketAccepted,reqHeader);
								   break;
								}			
								default:
									break;
							}
                  }
                  break;
					}
					default:
					{
						Print(__FUNCTION__,"Accept client failed.Other Reasons.");
						break;
					}
				}
			}
			break;
		}
	}
	Deinit();
}
