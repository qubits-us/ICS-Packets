object ServerCommsDm: TServerCommsDm
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 112
  Width = 166
  object srvSock: TWSocketServer
    LineEnd = #13#10
    Port = '9000'
    Proto = 'tcp'
    LocalAddr = '0.0.0.0'
    LocalAddr6 = '::'
    LocalPort = '0'
    SocksLevel = '5'
    ExclusiveAddr = False
    ComponentOptions = []
    ListenBacklog = 15
    OnDataAvailable = srvSockDataAvailable
    OnDataSent = srvSockDataSent
    OnSessionConnected = srvSockSessionConnected
    OnBgException = srvSockBgException
    SocketErrs = wsErrTech
    OnClientDisconnect = srvSockClientDisconnect
    OnClientConnect = srvSockClientConnect
    OnClientCreate = srvSockClientCreate
    MultiListenSockets = <>
    Left = 64
    Top = 32
    Banner = ''
    BannerTooBusy = ''
  end
end
