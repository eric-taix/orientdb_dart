part of orient_dart;

/**
 * Configuration of a cluster
 */
class OCluster {
  String name;
  int id;
  String type;
  int dataSegmentId;
  
  OCluster(this.name, this.id, this.type, this.dataSegmentId);
  
}