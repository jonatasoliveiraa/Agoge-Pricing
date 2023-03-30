public with sharing class TaxTriggerHandler {
    List<Tax__c> oldList { get; set; }
    List<Tax__c> newList { get; set; }
    Map<Id, Tax__c> oldMap { get; set; }
    Map<Id, Tax__c> newMap { get; set; }

    public TaxTriggerHandler(
        List<Tax__c> oldList,
        List<Tax__c> newList,
        Map<Id, Tax__c> oldMap,
        Map<Id, Tax__c> newMap
    ) {
        this.oldList = oldList;
        this.newList = newList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }
    public void beforeInsert() {
        TaxHelper.checkTax(this.newList);
    }
    public void beforeUpdate() {
        TaxHelper.checkTax(this.newList);
    }
}
