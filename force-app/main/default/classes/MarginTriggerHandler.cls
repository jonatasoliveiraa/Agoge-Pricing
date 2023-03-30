public with sharing class MarginTriggerHandler {
    
    List<Margin__c> oldList { get; set; }
    List<Margin__c> newList { get; set; }
    Map<Id, Margin__c> oldMap { get; set; }
    Map<Id, Margin__c> newMap { get; set; }

    public MarginTriggerHandler(
        List<Margin__c> oldList,
        List<Margin__c> newList,
        Map<Id, Margin__c> oldMap,
        Map<Id, Margin__c> newMap
    ) {
        this.oldList = oldList;
        this.newList = newList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }
    public void beforeInsert() {
        MarginHelper.checkMargin(this.newList);
    }
    
    public void beforeUpdate() {
        MarginHelper.checkMargin(this.newList);
    }
    
}
