public with sharing class TaxHelper {
    public static void checkTax(List<Tax__c> newTaxList) {

        Set<Id> taxIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        Set<Id> distributionCenterIds = new Set<Id>();

        for (Tax__c newTax : newTaxList) {
            if (!String.isBlank(newTax.Product__c)) {
                productIds.add(newTax.Product__c);
            }
            if (!String.isBlank(newTax.State__c)) {
                stateIds.add(newTax.State__c);
            }
            if (!String.isBlank(newTax.DistributionCenter__c)) {
                distributionCenterIds.add(newTax.DistributionCenter__c);
            }
        }

        List<Tax__c> listTax = [
            SELECT Id, Product__c, State__c, DistributionCenter__c
            FROM Tax__c
            WHERE
                Id NOT IN :taxIds
                AND Status__c = 'Aprovado'
                AND (Product__c IN :productIds
                OR State__c IN :stateIds
                OR DistributionCenter__c IN :distributionCenterIds)
        ];

        Map<String, Tax__c> taxKey = new Map<String, Tax__c>();

        for (Tax__c taxIterationToKey : listTax) {
            taxKey.put(buildTaxKey(taxIterationToKey), taxIterationToKey);
        }

        for (Tax__c newTaxKey : newTaxList) {
            if (taxKey.containsKey(buildTaxKey(newTaxKey))) {
                newTaxKey.addError(
                    System.Label.UnauthorizedTax + ' ' +
                    
                    taxKey.get(buildTaxKey(newTaxKey))
                );
            }
        }
    }

    public static String buildTaxKey(Tax__c tax) {
        return String.valueOf(tax.Product__c) +
            String.valueOf(tax.State__c) +
            String.valueOf(tax.DistributionCenter__c);
    }
}
