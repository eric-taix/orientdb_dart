part of orient_dart;

/**
 * This class aims to dispatch response to appropriate [OResponseHandler] and to manage Completer for each command
 */
class ODispatcher {
  
  final Logger _logger = LoggerFactory.getLoggerFor(ODispatcher);
  
  // Contains the list of the current completers. The key is the sessionId
  Map<int, OResponseHandler<OReply>> _handlers = new Map();
  // Remaining bytes
  List<int> _remainingBytes = new List();
  // Current handler (may survive between multiple dispatch)
  int _currentSession = null;
  
  /**
   * Returns true if there's already a dispatch running for this session id.
   * 
   * Note: You should alway s wait for a response before sending a new one
   */
  bool exists(int sessionId) {
    return _handlers.containsKey(sessionId);
  }
  
  /**
   * Add a dispatch for a [command] running in a [session] and returns the [Future] which will be called when the [OReply] will be ready
   */
  Future<OReply> addDispatch(OCommand command) {
    OResponseHandler<OReply> commandCompleter = new OResponseHandler(command);
    // If the command wait for a response, add it to the handler list
    if (!commandCompleter.completed) {
      _handlers[command.session.id] = commandCompleter; 
    }
    return commandCompleter.future;
  }
  
  /**
   * Dispatch bytes to the matched handler
   */
  void dispatch(List<int> bytes) {
    _remainingBytes.addAll(bytes);
    bool completed = false;
    do {
      completed = _internalDispatch();
    }
    while (_remainingBytes.length > 0 && completed);
  }
  
  /*
   * Dispatch the received bytes
   * Returns true if a completer has been completed
   */
  bool _internalDispatch() {
    // No current handler: get it from the session id in the response
    if (_currentSession == null) {
      _currentSession = _getSessionId();
    }
    // Retrieve the handler
    if (exists(_currentSession)) {
      OResponseHandler handler = _handlers[_currentSession];
      _remainingBytes = handler.decodeResponse(_remainingBytes);
      if (handler.completed) {
        _handlers.remove(_currentSession);
        _currentSession = null;
        return true;
      }
      return false;
    }
    else {
      _logger.error("The session ${_currentSession} was not found: impossible to dispatch the response");
      // Throw the entire current buffer (hope it will help to synchronize again)
      _remainingBytes.clear();
      _currentSession = null;
      return true;
    }
  }
  
  /**
   * Get the session id from a new frame (when the current handler does not already exist)
   */
  int _getSessionId() {
    // The first byte is for OK / KO, so take the second one
    int index = 1;
    int result = (_remainingBytes[index++] & 0xFF) << 24;
    result += (_remainingBytes[index++] & 0xFF) << 16;
    result += (_remainingBytes[index++] & 0xFF) << 8;
    result += (_remainingBytes[index++] & 0xFF);
    if (result > 2147483647) {
      result -= (2147483648 * 2);
    }
    return result;
  }
}