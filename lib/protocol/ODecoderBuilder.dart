part of orient_dart;


/**
 * This class aims to decode a list of bytes using the [_decoders] list
 * 
 * Do not include in the [ODecoder] list the status field nor the old session id field: as it is a common requirement for all requests, 
 * it will be automatically added by the [OResponseHandler]
 */
class ODecoderBuilder {
  
  final _logger = LoggerFactory.getLoggerFor(ODecoderBuilder);
  
  List<ODecoder> _errorFields = [ new OByteDecoder("status"), new OIntDecoder("old-session-id"), new OErrorDecoder("errors") ];
  
  bool _completed = false;
  bool _error = false;
  int _currentField = 0;
  List<ODecoder> _decoders;
  String _errorMsg;
  
  /**
   * Create the builder with a list of decoders and an error function called when an error occurs
   */
  ODecoderBuilder(this._decoders);
  
  /**
   * Is the decode process is finished: all fields have been decoded
   */
  bool get completed => _completed;
  
  /**
   * Returns the error message or null if there's no error
   */
  String get errorMessage => _errorMsg;
  
  /**
   * Insert a decoder
   */
  void insert(int index, ODecoder decoder) {
    if (_decoders == null) _decoders = new List();
    _decoders.insert(index, decoder);
  }
  
  /**
   * Returns the list of current [ODecoder]. Remember that this list may be different than the list you passed at construction time
   * because some [ODecoder] may be instance of [ODecoderTransformer]
   */
  List<ODecoder> getDecoders() => _decoders;
  
  /**
   * Decode the byte list. This methods returns unused bytes.
   * 
   * Also the [completed] attribut returns if the response has been fully decoded or not
   */
  List<int> decode(List<int> bytes) {
    List<int> remainingBytes = bytes;
    do {
      ODecoder fieldToDecode = _decoders[_currentField];
      if (fieldToDecode != null) {
        remainingBytes = fieldToDecode.decode(remainingBytes);
        // The current field has been decoded. Increment to decode the next field
        if (fieldToDecode.value != null) {
          
          // In case the field is also a transformer then apply it
          if (fieldToDecode is ODecoderTransformer) {
            List<ODecoder> newFields = (fieldToDecode as ODecoderTransformer).transform(_decoders.sublist(_currentField+1));
            _decoders = _decoders.sublist(0, _currentField+1);
            _decoders.addAll(newFields);
          }
          
          // If the current field is the first then verify if there's an error
          if (_currentField == 0 && fieldToDecode.value == 1) {
            // Replace it by error fields
            _decoders = _errorFields;
            _error = true;
          }
        }
        // The current field was not able to be decoded (not enough bytes) so returns the remaining bytes
        else {
          _logger.debug('Field ${fieldToDecode.name} is not fully decoded: missing bytes in buffer ${remainingBytes}');
          return remainingBytes;
        }
      }
      else {
        _logger.error('The field #${_currentField} does not exist !!!');
        return bytes;
      }
    }
    while (++_currentField < _decoders.length);
    _completed = true;
    // In case of error
    if (_error) {
      _errorMsg = "";
      for (String exception in _decoders.last.value) {
        _errorMsg += exception +", ";
      }
    }
    return remainingBytes;
  }
  
}