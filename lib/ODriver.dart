library orient_dart;

import "dart:io";
import "dart:async";
import 'dart:typed_data';

import "package:log4dart/log4dart.dart";

part 'OConnection.dart';
part 'OServer.dart';
part 'OSession.dart';
part 'OResponseDispatcher.dart';
part 'OResponseHandler.dart';

part 'model/OCluster.dart';

part 'protocol/ODecoders.dart';
part 'protocol/OEncoderBuilder.dart';
part 'protocol/ODecoderBuilder.dart';
part 'protocol/OCommand.dart';
part 'protocol/OReply.dart';

part 'protocol/common/ODriverInfo.dart';
part 'protocol/db/OOpen.dart';
part 'protocol/server/OConnect.dart';

void main() {
  
  final _logger = LoggerFactory.getLogger("main");
  
  OServer server = new OServer();
  server.initialize("localhost", 2424, 4).then((bool initialized) {
  
    for(int i = 0; i < 40; i++) {
      OSession session = server.getSession();
      OCommand command = new OConnect('root', 'FCA2404B69E6E93FB3257AB48F9C6C2E2E73A1DC12194FD0FA785FF31AE21F5F');
      session.send(command).then((OConnectReply reply) {
        // Nothing very interesting to display, sorry ! ;-)
      }, onError: (e) {
        _logger.error(e);
      });
    }
    
    
    OSession dbSession = server.getSession();
    OOpen open = new OOpen("tinkerpop", "admin", "admin", "document");
    dbSession.send(open).then((OOpenReply reply) {
      _logger.info("Session id is now ${reply.sessionId}/${dbSession.id}");
      _logger.info("OrientDB version: ${reply.orientRelease}");
      _logger.info("Number of cluster: ${reply.numClusters}");
      for (OCluster cluster in reply.clusters) {
        _logger.info("> cluster id ${cluster.id} with name \"${cluster.name}\" of type ${cluster.type} is located on data segment ${cluster.dataSegmentId}");
      }
    }, onError: (Object error) {
      _logger.error(error);
    });
    
  }, onError: (Object error) {
    _logger.error("Error: ${error}");
  });
}
