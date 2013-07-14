part of orient_dart;

/**
 * Connect to the server instance
 */
class OOpen extends ODriverInfo {

  final int COMMAND = 3;
  final String DOCUMENT_TYPE = 'document';
  final String GRAPH_TYPE = 'graph';
  
  String _username;
  String _password;
  String _databaseName;
  String _databaseType;
 
  // (session-id:int)(num-of-clusters:short)[(cluster-name:string)(cluster-id:short)(cluster-type:string)(cluster-dataSegmentId:short)](cluster-config:bytes)(orientdb-release:string)
  final ODecoderBuilder _decoderBuilder = new ODecoderBuilder([new OIntDecoder('session-id') , new OLoopDecoder(new OShortDecoder('num-of-clusters'),(int n) {
    return [new OStringDecoder('cluster-name${n}'), new OShortDecoder('cluster-id${n}'), new OStringDecoder('cluster-type${n}'), new OShortDecoder('cluster-dataSegmentId${n}')];
  }), new OBytesDecoder('cluster-config'), new OStringDecoder('orientdb-release')]);
  
  OOpen(this._databaseName, this._username, this._password, this._databaseType);
  
  OEncoderBuilder getEncoderBuilder() {
    OEncoderBuilder _request = new OEncoderBuilder();
    _request.addByte(COMMAND);
    _request.addInteger(session.id);
    _request.addString(_driverName);
    _request.addString(_driverVersion);
    _request.addShort(_protocolVersion);
    _request.addString(_clientId);
    _request.addString(_databaseName);
    _request.addString(_databaseType);
    _request.addString(_username);
    _request.addString(_password);
    return _request;
  }

  ODecoderBuilder getDecoderBuilder() => _decoderBuilder;
  
  OReply getReply(List<ODecoder> fields) {
    // Affect the (new) sessionId to the current session then next requests will use this new session id
    int newSessionId = fields[2].value;
    session.id = newSessionId;
    return new OOpenReply(fields);
  }
  
}

/**
 * Reply of a [OConnect] command
 */
class OOpenReply implements OReply {
  
  int sessionId;
  int numClusters;
  List<OCluster> clusters = new List();
  List<int> clusterConfig;
  String orientRelease;
  
  OOpenReply(List<ODecoder> fields) {
    int idx = 2;
    sessionId = fields[idx++].value;
    numClusters = fields[idx++].value;
    for(int i=0; i<numClusters; i++) {
      OCluster cluster = new OCluster(fields[(idx++)+i].value,fields[(idx++)+i].value,fields[(idx++)+i].value,fields[(idx)+i].value);
      clusters.add(cluster);
    }
    clusterConfig = fields[(idx++)+numClusters].value;
    orientRelease = fields[idx+numClusters].value;
  }
  
}