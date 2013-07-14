part of orient_dart;


/**
 * A connection to an OrientDB server.
 * Each instance uses its own socket but can manage many OSession according to the OrientDBServer.initialize parameters
 */
class OConnection {
  
  static final _logger = LoggerFactory.getLoggerFor(OConnection);
  
  /// Defines the current protocol version. If the protocol version does not match with the server's protocol, it does not mean that it will fail!
  final int CURRENT_VERSION = 15;
  
  Socket _socket;
  bool _connected = false;
  String _host;
  int _port;
  // The completer for the connexion
  Completer _connectionCompleter;
  
  // The response dispatcher
  final ODispatcher dispatcher = new ODispatcher();
  
  // The version of the server's protocol
  int version;
  
  /**
   * Create a new connection.
   */
  OConnection(this._host, this._port);
  
  /**
   * Is the connection really connected
   */
  get connected => _connected;
  
  Socket get socket => _socket;
  
  /**
   * Connect to the server.
   * Returns a Future<bool> to indicate if the connection is successful or not. Errors/Exceptions are returned using the onError function of the Future (this Future never complete with false)
   */
  Future<OConnection> connect() {
    _connectionCompleter = new Completer(); 
    Socket.connect(_host, _port).then((Socket _sock) {
      _logger.debug("Socket is connected to port ${_sock.port}");
      _socket = _sock;
      _socket.listen(_onData, onError: (e) {
        _connectionCompleter.completeError(e);
      });
    }).catchError( (err) {
      _logger.error("Can't connect to ${_host}:${_port}: ${err}");
      _connectionCompleter.completeError(err);
    });
    return _connectionCompleter.future;
  }

  // Receive data from the socket
  void _onData(List<int> bytes) {
    if (!connected) {
      _connected = true;
      _connectionCompleter.complete(this);
      _decodeVersion(bytes);
    }
    else {
      dispatcher.dispatch(bytes);
    }
  }
  
  void _decodeVersion(List<int> bytes) {
    ByteData bd = new ByteData.view(new Int8List.fromList(bytes).buffer);
    version = bd.getInt16(0);
    if (version != CURRENT_VERSION) {
      _logger.warn("The current protocol version of this driver (${CURRENT_VERSION}) does not match the protocol version of the server (${version})");
    }
    else {
      _logger.debug("OrientDB server uses protocol version ${version}");
    }
  }
  
  /**
   * Send the bytes
   */
  Future<OReply> send(OCommand command) {
    if (!dispatcher.exists(command.session.id)) {
      // Get bytes and insert the session id
      OEncoderBuilder request = command.getEncoderBuilder();
      _logger.debug('Sending data length: ${request.bytes.length + 1} bytes with session id: ${command.session.id}');
      Future<OReply> replyFuture = dispatcher.addDispatch(command);
      _socket.add(request.bytes);
      return replyFuture;
    }
    else {
      return new Future.error("Can't send more than one request befire receiving a reponse");
    }
  }
}
