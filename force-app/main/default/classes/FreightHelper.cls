public with sharing class FreightHelper {
    
    public static void checkFreight(List<Freight__c> newListFreight) {

        for (Freight__c moreSpecificFreightValue : newListFreight) {
        Decimal value = 0;

        if(!String.isBlank(moreSpecificFreightValue.Product__c)){
            value += 2000;
        }
        if(!String.isBlank(moreSpecificFreightValue.ProductHierarchy__c)){
            value += 1000;
        }
        if(!String.isBlank(moreSpecificFreightValue.City__c)){
            value += 30;
        }
        if(!String.isBlank(moreSpecificFreightValue.State__c)){
            value += 20;
        }
        if(!String.isBlank(moreSpecificFreightValue.Country__c)){
            value += 10;
        }

        moreSpecificFreightValue.Score__c = value;
    }

        Set<Id> freightIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        Set<Id> productHierarchyIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        Set<Id> countryIds = new Set<Id>();

        for (Freight__c newFreight : newListFreight) {
            freightIds.add(newFreight.Id);
            if (!String.isBlank(newFreight.Product__c)) {
                productIds.add(newFreight.Product__c);
            }
            if (!String.isBlank(newFreight.ProductHierarchy__c)) {
                productIds.add(newFreight.ProductHierarchy__c);
            }
            if (!String.isBlank(newFreight.Product__c) && !String.isBlank(newFreight.ProductHierarchy__c)){
                newFreight.addError(System.Label.MoreSpecificProducts);
            }
            if (!String.isBlank(newFreight.City__c)) {
                productIds.add(newFreight.City__c);
            }
            if (!String.isBlank(newFreight.State__c)) {
                productIds.add(newFreight.State__c);
            }
            if (!String.isBlank(newFreight.Country__c)) {
                productIds.add(newFreight.Country__c);
            }
            if((!String.isBlank(newFreight.City__c) && !String.isBlank(newFreight.State__c)) ||
                (!String.isBlank(newFreight.City__c) && !String.isBlank(newFreight.Country__c)) ||
                (!String.isBlank(newFreight.State__c) && !String.isBlank(newFreight.Country__c))){
                newFreight.addError(System.Label.MoreSpecificLocation);
            }
        }

        List<Freight__c> FreightList = [
            SELECT
                Id,
                Product__c,
                ProductHierarchy__c,
                City__c,
                State__c,
                Country__c
            FROM Freight__c
            WHERE
                Id NOT IN :freightIds
                AND Status__c = 'Aprovado'
                AND (Product__c IN :productIds
                OR ProductHierarchy__c IN :productHierarchyIds
                OR City__c IN :cityIds
                OR State__c IN :stateIds
                OR Country__c IN :countryIds)
        ];

        Map<String, Freight__c> freightKey = new Map<String, Freight__c>();

        for (Freight__c freightIterationToKey : FreightList) {
            freightKey.put(
                buildFreightKey(freightIterationToKey), 
                freightIterationToKey
            );
        }

        for (Freight__c newFreightKey : newListFreight) {
            if (freightKey.containsKey(buildFreightKey(newFreightKey))) {
                newFreightKey.addError(
                    System.Label.UnauthorizedFreight + 
                    ' ' +
                    freightKey.get(buildFreightKey(newFreightKey))
                );
            }
        }
    }

    public static String buildFreightKey(Freight__c freight) {
        return (!String.isBlank(freight.Product__c)
                ? String.valueOf(freight.Product__c)
                : String.valueOf(freight.ProductHierarchy__c)) +
                    (!String.isBlank(freight.City__c)
                        ? String.valueOf(freight.City__c)
                        : (!String.isBlank(freight.State__c)
                            ? String.valueOf(freight.State__c)
                            : String.valueOf(freight.Country__c)));
    }
}
