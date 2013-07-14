part of orient_dart;

/**
 * Connect to the server instance
 */
class OConnect extends ODriverInfo {

  String _username;
  String _password;
 
  // Response: (session-id:int)
  final ODecoderBuilder _decoderBuilder = new ODecoderBuilder([new OIntDecoder('session-id') ]);
  
  OConnect(this._username, this._password);

  OEncoderBuilder getEncoderBuilder() {
    OEncoderBuilder _request = new OEncoderBuilder();
    _request.addByte(2);
    _request.addInteger(session.id);
    _request.addString(_driverName);
    _request.addString(_driverVersion);
    _request.addShort(_protocolVersion);
    _request.addString(_clientId);
    _request.addString(_username);
    _request.addString(_password);
    return _request;
  }

  ODecoderBuilder getDecoderBuilder() => _decoderBuilder;
  
  OReply getReply(List<ODecoder> fields) {
    // Affect the (new) sessionId to the current session then next requests will use this new session id
    int newSessionId = fields[2].value;
    session.id = newSessionId;
    return new OConnectReply(newSessionId);
  }
  
}

/**
 * Reply of a [OConnect] command
 */
class OConnectReply implements OReply {
  
  int _sessionId;
  
  OConnectReply(this._sessionId);
  
  /// The (new) sessionId
  int get sessionId => _sessionId;
}