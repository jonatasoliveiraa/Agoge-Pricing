public with sharing class OrderItemHelper {
    public static void checkParameters(List<OrderItem> newOrderItemList) {
        Set<Id> productIdsSet = new Set<Id>();
        Set<Id> orderIdsSet = new Set<Id>();

        Set<Id> taxStateIds = new Set<Id>();
        Set<Id> taxDistributionCenterIds = new Set<Id>();

        Set<Id> freightProductHierarchyIds = new Set<Id>();
        Set<Id> freightCityIds = new Set<Id>();
        Set<Id> freightStateIds = new Set<Id>();
        Set<Id> freightCountryIds = new Set<Id>();

        Set<Id> marginProductHierarchyIds = new Set<Id>();
        Set<Id> marginAccountIds = new Set<Id>();
        Set<Id> marginAccountGroupIds = new Set<Id>();
        Set<Id> marginCityIds = new Set<Id>();
        Set<Id> marginStateIds = new Set<Id>();
        Set<Id> marginCountryIds = new Set<Id>();

        for (OrderItem orderItem : newOrderItemList) {
            productIdsSet.add(orderItem.Product2Id);
            orderIdsSet.add(orderItem.OrderId);
        }

        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT Id, ProductHierarchy__c
            FROM Product2
            WHERE Id IN :productIdsSet
        ]);

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT
                AccountId,
                Account.AccountGroup__c,
                AccountAddress__r.City__c,
                AccountAddress__r.City__r.State__c,
                AccountAddress__r.City__r.State__r.Country__c,
                DistributionCenter__c
            FROM Order
            WHERE Id IN :orderIdsSet
        ]);

        for (Product2 product : productMap.values()) {
            freightProductHierarchyIds.add(product.ProductHierarchy__c);
            marginProductHierarchyIds.add(product.ProductHierarchy__c);
        }

        for (Order order : orderMap.values()) {
            taxStateIds.add(order.AccountAddress__r.City__r.State__c);
            taxDistributionCenterIds.add(order.DistributionCenter__c);

            freightCityIds.add(order.AccountAddress__r.City__c);
            freightStateIds.add(order.AccountAddress__r.City__r.State__c);
            freightCountryIds.add(order.AccountAddress__r.City__r.State__r.Country__c);

            marginAccountIds.add(order.AccountId);
            marginAccountGroupIds.add(order.Account.AccountGroup__c);
            marginCityIds.add(order.AccountAddress__r.City__c);
            marginStateIds.add(order.AccountAddress__r.City__r.State__c);
            marginCountryIds.add(order.AccountAddress__r.City__r.State__r.Country__c);
        }

        List<Tax__c> taxList = [
            SELECT Id, Product__c, State__c, DistributionCenter__c, Value__c
            FROM Tax__c
            WHERE
                Status__c = 'Aprovado'
                AND Product__c IN :productIdsSet
                AND State__c IN :taxStateIds
                AND DistributionCenter__c IN :taxDistributionCenterIds
        ];

        List<Freight__c> freightList = [
            SELECT
                Id,
                City__c,
                State__c,
                Country__c,
                Product__c,
                ProductHierarchy__c,
                Value__c
            FROM Freight__c
            WHERE
                Status__c = 'Aprovado'
                AND (Product__c IN :productIdsSet OR Product__c = NULL)
                AND (ProductHierarchy__c IN :freightProductHierarchyIds OR ProductHierarchy__c = NULL)
                AND (City__c IN :freightCityIds OR City__c = NULL)
                AND (State__c IN :freightStateIds OR State__c = NULL)
                AND (Country__c IN :freightCountryIds OR Country__c = NULL)
            ORDER BY Score__c DESC
        ];

        List<Margin__c> marginList = [
            SELECT
                Id,
                City__c,
                State__c,
                Country__c,
                Product__c,
                ProductHierarchy__c,
                Account__c,
                AccountGroup__c,
                Value__c
            FROM Margin__c
            WHERE
                Status__c = 'Aprovado'
                AND (Product__c IN :productIdsSet OR Product__c = NULL)
                AND (ProductHierarchy__c IN :marginProductHierarchyIds OR ProductHierarchy__c = NULL)
                AND (Account__c IN :marginAccountIds OR Account__c = NULL)
                AND (AccountGroup__c IN :marginAccountGroupIds OR AccountGroup__c = NULL)
                AND (City__c IN :marginCityIds OR City__c = NULL)
                AND (State__c IN :marginStateIds OR State__c = NULL)
                AND (Country__c IN :marginCountryIds OR Country__c = NULL)
            ORDER BY Score__c DESC
        ];

        assignTaxesToItems(taxList, newOrderItemList, orderMap);
        Map<OrderItem, Freight__c> orderItemToFreight = assignFreightToItems(
            freightList,
            newOrderItemList,
            orderMap,
            productMap
        );
        Map<OrderItem, Margin__c> orderItemToMargin = assignMarginToItems(
            marginList,
            newOrderItemList,
            orderMap,
            productMap
        );
        calcDiscount(newOrderItemList);
    }

    public static void assignTaxesToItems(
        List<Tax__c> taxList,
        List<OrderItem> newOrderItemList,
        Map<Id, Order> orderMap
    ) {
        Map<String, Tax__c> buildTaxKeyToTaxList = new Map<String, Tax__c>();

        for (Tax__c taxForBuildKey : taxList) {
            buildTaxKeyToTaxList.put(
                String.valueOf(taxForBuildKey.Product__c) +
                String.valueOf(taxForBuildKey.State__c) +
                String.valueOf(taxForBuildKey.DistributionCenter__c),
                taxForBuildKey
            );
        }

        for (OrderItem orderItem : newOrderItemList) {
            Order parentOrder = orderMap.get(orderItem.OrderId);
            String orderItemTaxComposeKey =
                String.valueOf(orderItem.Product2Id) +
                String.valueOf(parentOrder.AccountAddress__r.City__r.State__c) +
                String.valueOf(parentOrder.DistributionCenter__c);

            if (buildTaxKeyToTaxList.containsKey(orderItemTaxComposeKey)) {
                Tax__c taxFound = buildTaxKeyToTaxList.get(
                    orderItemTaxComposeKey
                );
                orderItem.TaxPercentage__c = taxFound.Value__c;
            } else {
                orderItem.addError(System.Label.UnauthorizedSale);
            }
        }
    }

    public static Map<OrderItem, Freight__c> assignFreightToItems(
        List<Freight__c> freightList,
        List<OrderItem> newOrderItemList,
        Map<Id, Order> orderMap,
        Map<Id, Product2> productMap
    ) {
        Map<OrderItem, Freight__c> orderItemToFreight = new Map<OrderItem, Freight__c>();

        for (OrderItem orderItem : newOrderItemList) {
            Order parentOrder = orderMap.get(orderItem.OrderId);
            Product2 parentProduct = productMap.get(orderItem.Product2Id);

            orderItemToFreight.put(orderItem, null);

            for (Freight__c freight : freightList) {
                if (matchFreight(freight, orderItem, parentOrder, parentProduct)) {
                    orderItemToFreight.put(orderItem, freight);
                    break;
                }
            }
        }

        for (OrderItem orderItem : orderItemToFreight.keySet()) {
            Freight__c freightValue = orderItemToFreight.get(orderItem);

            if (freightValue != null) {
                orderItem.FreightValue__c = freightValue.Value__c;
            }
        }

        return orderItemToFreight;
    }

    public static Boolean matchFreight(
        Freight__c freight,
        OrderItem orderItem,
        Order parentOrder,
        Product2 parentProduct
    ) {
        return (String.isBlank(freight.Product__c) ||
            freight.Product__c == orderItem.Product2Id) &&
            (String.isBlank(freight.ProductHierarchy__c) ||
            freight.ProductHierarchy__c == parentProduct.ProductHierarchy__c) &&
            (String.isBlank(freight.City__c) ||
            freight.City__c == parentOrder.AccountAddress__r.City__c) &&
            (String.isBlank(freight.State__c) ||
            freight.State__c ==
            parentOrder.AccountAddress__r.City__r.State__c) &&
            (String.isBlank(freight.Country__c) ||
            freight.Country__c ==
            parentOrder.AccountAddress__r.City__r.State__r.Country__c);
    }

    public static Map<OrderItem, Margin__c> assignMarginToItems(
        List<Margin__c> marginList,
        List<OrderItem> newOrderItemList,
        Map<Id, Order> orderMap,
        Map<Id, Product2> productMap
    ) {
        Map<OrderItem, Margin__c> orderItemToMargin = new Map<OrderItem, Margin__c>();

        for (OrderItem orderItem : newOrderItemList) {
            Order parentOrder = orderMap.get(orderItem.OrderId);
            Product2 parentProduct = productMap.get(orderItem.Product2Id);

            orderItemToMargin.put(orderItem, null);

            for (Margin__c margin : marginList) {
                if (matchMargin(margin, orderItem, parentOrder, parentProduct)) {
                    orderItemToMargin.put(orderItem, margin);
                    break;
                }
            }
        }

        for (OrderItem orderItem : orderItemToMargin.keySet()) {
            Margin__c marginValue = orderItemToMargin.get(orderItem);

            if (marginValue != null) {
                orderItem.MarginPercentage__c = marginValue.Value__c;
            }
        }

        return orderItemToMargin;
    }

    public static Boolean matchMargin(
        Margin__c margin,
        OrderItem orderItem,
        Order parentOrder,
        Product2 parentProduct
    ) {
        return (String.isBlank(margin.Product__c) ||
            margin.Product__c == orderItem.Product2Id) &&
            (String.isBlank(margin.ProductHierarchy__c) ||
            margin.ProductHierarchy__c == parentProduct.ProductHierarchy__c) &&
            (String.isBlank(margin.Account__c) ||
            margin.Account__c == parentOrder.AccountId) &&
            (String.isBlank(margin.AccountGroup__c) ||
            margin.AccountGroup__c == parentOrder.Account.AccountGroup__c) &&
            (String.isBlank(margin.City__c) ||
            margin.City__c == parentOrder.AccountAddress__r.City__c) &&
            (String.isBlank(margin.State__c) ||
            margin.State__c ==
            parentOrder.AccountAddress__r.City__r.State__c) &&
            (String.isBlank(margin.Country__c) ||
            margin.Country__c ==
            parentOrder.AccountAddress__r.City__r.State__r.Country__c);
    }

    public static Boolean isUnauthorizedSale(OrderItem orderItem) {
        return (orderItem.FreightValue__c == null) ||
            (orderItem.TaxPercentage__c == null) ||
            (orderItem.MarginPercentage__c == null);
    }
    public static void calcDiscount(List<OrderItem> newOrderItemList) {
        for (OrderItem orderItem : newOrderItemList) {
            if (isUnauthorizedSale(orderItem)) {
                orderItem.addError(System.Label.UnauthorizedSale);
            } else {
                orderItem.FinalPrice__c =
                    (orderItem.ListPrice + orderItem.FreightValue__c) *
                    (1 + orderItem.TaxPercentage__c / 100) *
                    (1 + orderItem.MarginPercentage__c / 100);

                orderItem.PriceWithoutMargin__c =
                    (orderItem.ListPrice + orderItem.FreightValue__c) *
                    (1 + orderItem.TaxPercentage__c / 100);

                orderItem.Discount__c =
                    (orderItem.FinalPrice__c - orderItem.UnitPrice) /
                    orderItem.FinalPrice__c;
            }
        }
    }
}