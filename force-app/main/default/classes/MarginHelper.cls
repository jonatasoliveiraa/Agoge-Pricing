public with sharing class MarginHelper {
    public static void checkMargin(List<Margin__c> newListMargin) {
        for (Margin__c moreSpecificMarginValue : newListMargin) {
            Decimal value = 0;

            if (!String.isBlank(moreSpecificMarginValue.Product__c)) {
                value += 2000;
            }
            if (!String.isBlank(moreSpecificMarginValue.ProductHierarchy__c)) {
                value += 1000;
            }
            if (!String.isBlank(moreSpecificMarginValue.Account__c)) {
                value += 200;
            }
            if (!String.isBlank(moreSpecificMarginValue.AccountGroup__c)) {
                value += 100;
            }
            if (!String.isBlank(moreSpecificMarginValue.City__c)) {
                value += 30;
            }
            if (!String.isBlank(moreSpecificMarginValue.State__c)) {
                value += 20;
            }
            if (!String.isBlank(moreSpecificMarginValue.Country__c)) {
                value += 10;
            }

            moreSpecificMarginValue.Score__c = value;
        }

        Set<Id> marginIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        Set<Id> productHierarchyIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> accountGroupIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        Set<Id> countryIds = new Set<Id>();

        for (Margin__c newMargin : newListMargin) {
            marginIds.add(newMargin.Id);
            if (!String.isBlank(newMargin.Product__c)) {
                productIds.add(newMargin.Product__c);
            }
            if (!String.isBlank(newMargin.ProductHierarchy__c)) {
                productHierarchyIds.add(newMargin.ProductHierarchy__c);
            }
            if (
                !String.isBlank(newMargin.Product__c) &&
                !String.isBlank(newMargin.ProductHierarchy__c)
            ) {
                newMargin.addError(System.Label.MoreSpecificProducts);
            }
            if (!String.isBlank(newMargin.Account__c)) {
                accountIds.add(newMargin.Account__c);
            }
            if (!String.isBlank(newMargin.AccountGroup__c)) {
                accountGroupIds.add(newMargin.AccountGroup__c);
            }
            if (
                !String.isBlank(newMargin.Account__c) &&
                !String.isBlank(newMargin.AccountGroup__c)
            ) {
                newMargin.addError(System.Label.MoreSpecificCustomers);
            }
            if (!String.isBlank(newMargin.City__c)) {
                cityIds.add(newMargin.City__c);
            }
            if (!String.isBlank(newMargin.State__c)) {
                stateIds.add(newMargin.State__c);
            }
            if (!String.isBlank(newMargin.Country__c)) {
                countryIds.add(newMargin.Country__c);
            }
            if (
                (!String.isBlank(newMargin.City__c) &&
                !String.isBlank(newMargin.State__c)) ||
                (!String.isBlank(newMargin.City__c) &&
                !String.isBlank(newMargin.Country__c)) ||
                (!String.isBlank(newMargin.State__c) &&
                !String.isBlank(newMargin.Country__c))
            ) {
                newMargin.addError(System.Label.MoreSpecificLocation);
            }
        }

        List<Margin__c> marginList = [
            SELECT
                Id,
                Product__c,
                ProductHierarchy__c,
                Account__c,
                AccountGroup__c,
                City__c,
                State__c,
                Country__c
            FROM Margin__c
            WHERE
                Id NOT IN :marginIds
                AND Status__c = 'Aprovado'
                AND (Product__c IN :productIds
                OR ProductHierarchy__c IN :productHierarchyIds
                OR Account__c IN :accountIds
                OR AccountGroup__c IN :accountGroupIds
                OR City__c IN :cityIds
                OR State__c IN :stateIds
                OR Country__c IN :countryIds)
        ];

        Map<String, Margin__c> marginKey = new Map<String, Margin__c>();

        for (Margin__c marginIterationToKey : marginList) {
            marginKey.put(
                createMarginKey(marginIterationToKey),
                marginIterationToKey
            );
        }

        for (Margin__c newMarginKey : newListMargin) {
            if (marginKey.containsKey(createMarginKey(newMarginKey))) {
                newMarginKey.addError(
                    System.Label.UnauthorizedMargin +
                    ' ' +
                    marginKey.get(createMarginKey(newMarginKey))
                );
            }
        }
    }

    public static String createMarginKey(Margin__c margin) {
        return (!String.isBlank(margin.Product__c)
                ? String.valueOf(margin.Product__c)
                : String.valueOf(margin.ProductHierarchy__c)) +
                    (!String.isBlank(margin.Account__c)
                        ? String.valueOf(margin.Account__c)
                        : String.valueOf(margin.AccountGroup__c)) +
                            (!String.isBlank(margin.City__c)
                                ? String.valueOf(margin.City__c)
                                : (!String.isBlank(margin.State__c)
                                    ? String.valueOf(margin.State__c)
                                    : String.valueOf(margin.Country__c)));
    }
}
