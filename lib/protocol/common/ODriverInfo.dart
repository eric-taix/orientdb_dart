part of orient_dart;

/**
 * Connect to the server instance
 */
abstract class ODriverInfo extends OCommand {

  String _driverName = 'OrientDB-Dart';
  String _driverVersion = '1.0.alpha.0';
  int _protocolVersion = 15;
  String _clientId = '';
  
}