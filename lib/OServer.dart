part of orient_dart;

/**
 * The main class to request a OrientDB server. This class creates to OSession to request a server. 
 * By default it creates only one socket connection and uses it for all OSession. If you have a high traffic, you can create
 * more socket: use maxConnections to increase the maximum number of sockets used to request the server.
 */
class OServer {
  
  static final _logger = LoggerFactory.getLoggerFor(OServer);
  
  List<OConnection> _connections = new List();
  int _nextConnection = 0;
  
  int _numConnections = 0;
  
  // The next session id: sessionId MUST be null to create a server session!
  int _nextId = -120;
  bool _initialized = false;
  
  String _host;
  int _port;
  
  /**
   * 
   */
  Future<bool> initialize(String host, [int port = 2424, int maxConnections = 1]) {
    Completer completer = new Completer();
    _host = host;
    _port = port;
    List<Future> futures = new List();
    for (int i = 0; i < maxConnections; i++) {
      Future future = _createConnection();
      if (future != null) {
        futures.add(future);
      }
    }
    // Now wait for all connections to complete
    Future.wait(futures).then((List<Future> futures) {
      completer.complete(true);
    }, onError: (Object error) {
      completer.completeError("OrientServer was unable to complete the initialization phase");
    });
    return completer.future;
  }
  
  /*
   *  Create one connection to the remote server
   */
  Future<OConnection> _createConnection() {
    Completer completer = new Completer();
    new OConnection(_host, _port).connect().then((OConnection connection) {
      _connections.add(connection);
      completer.complete(connection);
    }, onError: (Object exception) {
      _logger.error("Unable to create a new connection ${exception}");
      completer.complete(null);
    });
    return completer.future;
  }
  
  /**
   * Get the next connexion
   */
  OConnection _getNextConnection() {
    if (_nextConnection >= _connections.length) {
      _nextConnection = 0;
    }
    return _connections[_nextConnection++];
  }
  
  /**
   * Return a new session
   */
  OSession getSession() {
    OSession session = new OSession(_getNextConnection(), _nextId--);
    if (_nextId < -2147483648) {
      _nextId = -1;
    }
    return session;
  }
  
}