part of orient_dart;

/**
 * This is the base class for session. An [OSession] has an unique id and can send command.
 */
class OSession {
  
  OConnection _connection;
  int _id;
  
  OSession(this._connection, this._id);
  
  int get id => _id;
  
  set id(int id) => _id = id;
  
  Future<OReply> send(OCommand command) {
    command.session = this;
    return _connection.send(command);
  }
  
  
}