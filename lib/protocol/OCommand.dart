part of orient_dart;

/**
 * Definition of a command
 */
abstract class OCommand {
  
  /// Current session which initialized this command
  OSession session;
  
  /**
   * Returns the [OEncoderBuilder] which will be send to the server.
   * The [OEncoderBuilder] MUST contains the operation type, the session id and the message content (based on the command type)
   */
  OEncoderBuilder getEncoderBuilder();
  
  /**
   * Returns the field list of the expected response. This field list must be created at class contruction time (this method is not a factory)
   * and will be used to create the reply when the [getReply] method will be called.
   */
  ODecoderBuilder getDecoderBuilder();
  
  /**
   * Returns the Reply according to the [fields] parameter. Implementation must not rely on fields returned by [getDecoderBuilder] but only
   * the the [fields] parameters as fields may have been transformed during the decode process
   */
  OReply getReply(List<ODecoder> fields);
}
