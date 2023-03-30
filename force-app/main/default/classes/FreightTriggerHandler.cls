public with sharing class FreightTriggerHandler {

    List<Freight__c> oldList {get; set;}
    List<Freight__c> newList {get; set;}
    Map<Id, Freight__c> oldMap {get; set;}
    Map<Id, Freight__c> newMap {get; set;}
    
    public FreightTriggerHandler(List<Freight__c> oldList, List<Freight__c> newList, Map<Id, Freight__c> oldMap, Map<Id, Freight__c> newMap) {
        this.oldList = oldList;
        this.newList = newList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }
    public void beforeInsert(){
        FreightHelper.checkFreight(this.newList);
    }
    public void beforeUpdate(){
        FreightHelper.checkFreight(this.newList);
    }
}
