part of orient_dart;

/**
 * This class aims to decode a response for a [OCommand]. An [OResponseHandler] does not decode bytes list itself: it delegates the process
 * to the [ODecoderBuilder] returned by the [OCommand]
 * 
 * When the response has been fully decoded it completeq the [Future] with the correct [OReply] or completes with an error
 * if an error as been received.
 */
class OResponseHandler<T> {
  
  final _logger = LoggerFactory.getLoggerFor(OResponseHandler);
  
  OCommand _command;
  Completer<T> _completer = new Completer();
  ODecoderBuilder _decoderBuilder;
  int _currentField = 0;
  bool _completed = false;
  
  /**
   * Creates the command completer
   */
  OResponseHandler(this._command) {
    _decoderBuilder = _command.getDecoderBuilder();
    // If there's no builder this command doesn't wait for a reply, so complete immediatly
    if (_decoderBuilder == null) {
      _completer.complete(null);
      _completed = true;
    }
    else {
      // Each response has a minimum of OK/KO field + session id field
      _decoderBuilder.insert(0, new OByteDecoder('status'));
      _decoderBuilder.insert(1, new OIntDecoder('old-session-id'));
    }
  }
  
  /**
   * Returns the future of the completer
   */
  Future<T> get future => _completer.future;
  
  /**
   * Decode the response and returns the remaining bytes
   */
  List<int> decodeResponse(List<int> bytes) {
    
    List<int> remainingBytes = _decoderBuilder.decode(bytes);
    
    if (!_decoderBuilder.completed) return bytes;
    
    // At this point everything have been received so we can retrieve the reply and complete the future
    _completed = true;
    
    // If there's an error then complete the future with the reply
    if (_decoderBuilder.errorMessage == null) {
      OReply reply = _command.getReply(_decoderBuilder.getDecoders());
      _completer.complete(reply);
    }
    // If there's an error then complete the future with an error
    else {
      _completer.completeError(_decoderBuilder.errorMessage);
    }
    return remainingBytes;
  }
  
  /**
   * Returns true if the command's response has been fully decoded and if the future has been completed
   */
  bool get completed => _completed;
 
}