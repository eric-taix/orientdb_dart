part of orient_dart;



/**
 * Define a field decoder which aims to decode a field from a list of bytes.
 * 
 * The name of a field is required for debug purpose (and for mirroring in the future ?)
 * 
 * A [ODecoder] receives a list of bytes in the [decode] method. If the field can be fully decoded the [decode] method MUST
 * returns the remaining byte (ie the bytes which were not used to decode the field). If the field could not have been decoded
 * (ie: there's not enough bytes to decode the field) the [decode] method MUST return the original list of bytes.
 * 
 * The [value] getter MUST return null until the field has been fully decoded. If it returns null it means that it has not been fully decoded.
 * 
 */
abstract class ODecoder {

  final _logger = LoggerFactory.getLoggerFor(ODecoder);
  String _name;
  
  /**
   * Default constructor: the field name is required
   */
  ODecoder(this._name);
  
  String get name => _name;
  
  /**
   * Returns the decoded value or null if the value couldn't have been decoded (not enough bytes for example) 
   */
  Object get value;
  
  /**
   * Decode the value. Usually [ODecoder] uses only few bytes from the input. The remaining bytes are for others fields.
   * This method must returns bytes which were not used to decode the value or the original buffer is some bytes are missing to fully decode the value.
   * 
   * A common mistake is to forget to affect the internal value when the field has been fully decoded
   */
  List<int> decode(List<int> bytes);
  
  /**
   * Helper method to skip n bytes from a list of bytes and returns the new list
   */
  List<int> skip(List<int> bytes, int n) {
    return new List<int>.from(bytes.skip(n), growable: true);
  }
}

/**
 * An interface to define OField which may transform
 * 
 * The [transform] method is used by an [ODecoder] which can mutate or replace some (or all) remaining list of fields (an [ODecoder] can't mutate fields which have been already decoded)
 * when its [value] has been fully decoded. For example the [OStatusDecoder] can subsitute the remaining list of fields by an [OErrorDecoder] when its value is 1 (ERROR). Most of fields
 * are static which means they never transform remaining fields so the default implementation returns the input list of bytes. Override this implementation if you implement a dynamic field.
 */
abstract class ODecoderTransformer {
  
  /**
   * Tranform a field list
   * 
   * The input parameters are the remaining fields (an [ODecoderTransformer] can't transforme already decoded fields
   */
  List<ODecoder> transform(List<ODecoder> fields) {
    return fields;
  }
}


//------------ 'Special' fields implementations ------------

/**
 * A Status field (1 byte): O -> OK, 1 -> ERROR
 * 
 * This field is dynamic: it can replace the remaining field list with an [OErrorDecoder] according to its [value]
 */
class OStatusDecoder extends ODecoder implements ODecoderTransformer {
  
  int _value = null;
  
  OStatusDecoder(String name) : super(name);
  
  List<int> decode(List<int> bytes) {
    if (bytes.length < 1) return bytes;
    _value = bytes[0] & 0xFF;
    _logger.debug('Reading byte (1 byte): ${_name}=${_value}');
    return skip(bytes, 1);
  }

  Object get value => _value;
  
  List<ODecoder> transform(List<ODecoder> fields) {
    if (_value == 0) return fields;
    return [ new OErrorDecoder("errors") ];
  }
}


/**
 * A Loop field : this field iterates N times
 * 
 * This field is dynamic: it first read the loop size with the [_sizeField] and read [_fields] N times
 */
class OLoopDecoder extends ODecoder implements ODecoderTransformer {
  
  int _value = null;
  ODecoder _sizeField;
  var _onLoop;
  
  OLoopDecoder(this._sizeField, this._onLoop(int n)) : super('');
  
  List<int> decode(List<int> bytes) {
    bytes = _sizeField.decode(bytes);
    if (_sizeField.value == null) return bytes;
    
    _value = _sizeField.value;
    _logger.debug('Starting loop of size: ${_value}');
    return bytes;
  }

  Object get value => _value;
  
  List<ODecoder> transform(List<ODecoder> fields) {
    List<ODecoder> newFields = new List();
    for(int i=0; i<_value; i++) {
      newFields.addAll(_onLoop(i));
    }
    newFields.addAll(fields);
    return newFields;
  }
}

//------------ 'Native' fields implementations ------------

/**
 * A byte field (1 int)
 */
class OByteDecoder extends ODecoder {
  
  int _value = null;
  
  OByteDecoder(String name) : super(name);
  
  List<int> decode(List<int> bytes) {
    if (bytes.length < 1) return bytes;
    _value = bytes[0] & 0xFF;
    _logger.debug('Reading byte (1 byte): ${_name}=${_value}');
    return skip(bytes, 1);
  }

  Object get value => _value;
}

/**
 * A short field (2 ints)
 */
class OShortDecoder extends ODecoder {
  
  int _value = null;
  
  OShortDecoder(String name) : super(name);
  
  List<int> decode(List<int> bytes) {
    if (bytes.length < 2) return bytes;
    _value = (bytes[0] & 0xFF << 8) + bytes[1] & 0xFF;
    _logger.debug('Reading short (2 bytes): ${_name}=${_value}');
    return skip(bytes, 2);
  }

  Object get value => _value;
}

/**
 * An int field (4 ints)
 */
class OIntDecoder extends ODecoder {
  
  int _value = null;
  
  OIntDecoder(String name) : super(name);
  
  List<int> decode(List<int> bytes) {
    if (bytes.length < 4) return bytes;
    _value = (bytes[0] & 0xFF) << 24;
    _value += (bytes[1] & 0xFF) << 16;
    _value += (bytes[2] & 0xFF) << 8;
    _value += (bytes[3] & 0xFF);
    if (_value > 2147483647) {
      _value -= (2147483648 * 2);
    }
    _logger.debug('Reading int (4 bytes): ${_name}=${_value}');
    return skip(bytes, 4);
  }

  Object get value => _value;
}

/**
 * A String field (N bytes)
 */
class OStringDecoder extends ODecoder {
  
  String _value = null;
  
  OStringDecoder(String name) : super(name);
  
  List<int> decode(List<int> bytes) {
    if (bytes.length < 4) return bytes;
    int length = (bytes[0] & 0xFF) << 24;
    length += (bytes[1] & 0xFF) << 16;
    length += (bytes[2] & 0xFF) << 8;
    length += (bytes[3] & 0xFF);
    if (length > 2147483647) {
      length -= (2147483648 * 2);
    }
    
    // Special case: length = -1 -> null
    if (length == -1) {
      return skip(bytes, 4);
    }
    
    // If there's enough bytes to complete the string
    if (bytes.length < 4 + length) return bytes;
    
    Iterable<int> stringAsBytes = bytes.getRange(4, 4 + length);
    _value = new String.fromCharCodes(stringAsBytes);
    _logger.debug('Reading string (4+${length} = ${4+length} bytes): ${_name}=${_value}');
    return skip(bytes, 4 + length);
  }

  Object get value => _value;
}

/**
 * A bytes field (N bytes)
 */
class OBytesDecoder extends ODecoder {
  
  List<int> _value = null;
  
  OBytesDecoder(String name) : super(name);
  
  List<int> decode(List<int> bytes) {
    if (bytes.length < 4) return bytes;
    int length = (bytes[0] & 0xFF) << 24;
    length += (bytes[1] & 0xFF) << 16;
    length += (bytes[2] & 0xFF) << 8;
    length += (bytes[3] & 0xFF);
    if (length > 2147483647) {
      length -= (2147483648 * 2);
    }
    
    // Special case: length = -1 -> null
    if (length == -1) {
      _value = new List();
      _logger.debug('Reading bytes (4+0 = 4 bytes): ${_name}=null');
      return skip(bytes, 4);
    }
    
    // If there's enough bytes to complete the list
    if (bytes.length < 4 + length) return bytes;
    
    _value = new List.from(bytes.getRange(4, 4 + length), growable: true);
    _logger.debug('Reading bytes (4+${length} = ${4+length} bytes): ${_name}=${_value}');
    return skip(bytes, 4 + length);
  }
  
  Object get value => _value;
}

/**
 * An error field [(1)(exception-class:string)(exception-message:string)]*(0)
 */
class OErrorDecoder extends ODecoder {
  
  List<String> _value;
  
  OErrorDecoder(String name) : super(name);
  
  List<int> decode(List<int> bytes) {
    List<String> result = new List();
    List<int> originalBytes = bytes;
    int exNum = 1;
    while (true) {
      // If not enough bytes, revert list and returns original
      if (bytes.length < 1) {
        return originalBytes;
      }
      int flag = bytes[0] & 0xFF;
      bytes = skip(bytes, 1);
      // There's a new exception
      if (flag == 1) {
        // Get the exception class
        ODecoder exceptionField = new OStringDecoder("exception[${exNum}]");
        bytes = exceptionField.decode(bytes);
        // Not enough bytes to complete the String
        if (exceptionField.value == null) {
          return originalBytes;
        }
        // Get the exception message
        ODecoder msgField = new OStringDecoder("exceptionMsg[${exNum}]");
        bytes = msgField.decode(bytes);
        // Not enough bytes to complete the String
        if (msgField.value == null) {
          return originalBytes;
        }
        String errorMsg = exceptionField.value;
        errorMsg += ": " + msgField.value;
        result.add(errorMsg);
      }
      // No more exception
      else {
        _value = result;
        _logger.debug('Reading errors (N bytes): ${_name}=${_value}');
        return bytes;
      }
    }
    return skip(bytes, 1);
  }

  Object get value => _value;
}
