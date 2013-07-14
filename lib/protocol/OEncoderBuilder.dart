part of orient_dart;

/**
 * A low level builder to encode values to a list of bytes which will be send over the socket.
 */
class OEncoderBuilder {
  
  List<int> _bytes = new List<int>();
  
  /**
   * Get the created buffer to send
   */
  List<int> get bytes => _bytes;
  
  /**
   * Add a boolean : 1 byte (true => 1, false => 0)
   */
  void addBoolean(bool boolean) {
    _bytes.add(boolean ? 1 : 0);
  }
  
  /**
   * Add a byte : 1 byte
   */
  void addByte(int byte) {
    assert(byte >= 0 && byte < 256);
    _bytes.add(byte);
  }
  
  /**
   * Add a short : 2 bytes
   */
  void addShort(int short) {
    assert(short >= -32768 && short <= 32767);
    
    if (short < 0)
      short = 0x10000 + short;
    
    int a = (short >> 8) & 0x00FF;
    int b = short & 0x00FF;
    
    _bytes.add(a);
    _bytes.add(b);
  }
  
  /**
   * Add an integer : 4 bytes
   */
  void addInteger(int integer) {
    assert(integer >= -2147483648 && integer <= 2147483647);
    
    if (integer < 0)
      integer = 0x100000000 + integer;
    
    int a = (integer >> 24) & 0x000000FF;
    int b = (integer >> 16) & 0x000000FF;
    int c = (integer >> 8) & 0x000000FF;
    int d = integer & 0x000000FF;
    
    _bytes.add(a);
    _bytes.add(b);
    _bytes.add(c);
    _bytes.add(d);
  }

  
  /**
   * Add a string : (length:int)(content)
   */
  void addString(String s) {
    addInteger(s.length);
    _bytes.addAll(s.codeUnits.toList());
  }
  
  /**
   * Add a list of string : (nb_string:integer)(length:int)(string_1)[(length:int)(string_n)]
   */
  void addStrings(List<String> stringList) {
    addInteger(stringList.length);
    stringList.forEach((stringEle) => addString(stringEle));
  }
 
}