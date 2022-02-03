object PacketClntDm: TPacketClntDm
  OldCreateOrder = False
  Height = 150
  Width = 215
  object cliSock: TWSocket
    LineEnd = #13#10
    Proto = 'tcp'
    LocalAddr = '0.0.0.0'
    LocalAddr6 = '::'
    LocalPort = '0'
    SocksLevel = '5'
    ExclusiveAddr = False
    ComponentOptions = []
    ListenBacklog = 15
    OnDataAvailable = cliSockDataAvailable
    OnSessionClosed = cliSockSessionClosed
    OnSessionConnected = cliSockSessionConnected
    SocketErrs = wsErrTech
    Left = 24
    Top = 16
  end
end
