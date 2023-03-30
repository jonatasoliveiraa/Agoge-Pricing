trigger TaxTrigger on Tax__c(before insert, before update) {
    TaxTriggerHandler handler = new TaxTriggerHandler(
        Trigger.old,
        Trigger.new,
        Trigger.oldMap,
        Trigger.newMap
    );

    switch on Trigger.operationType {
        when BEFORE_INSERT {
            handler.beforeInsert();
        }
        when BEFORE_UPDATE {
            handler.beforeUpdate();
        }
    }
}
