public with sharing class OrderItemTriggerHandler {
    
    List<OrderItem> oldList { get; set; }
    List<OrderItem> newList { get; set; }
    Map<Id, OrderItem> oldMap { get; set; }
    Map<Id, OrderItem> newMap { get; set; }

    public OrderItemTriggerHandler(
        List<OrderItem> oldList,
        List<OrderItem> newList,
        Map<Id, OrderItem> oldMap,
        Map<Id, OrderItem> newMap
    ) {
        this.oldList = oldList;
        this.newList = newList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public void beforeInsert() {
        OrderItemHelper.checkParameters(this.newList);
    }
    public void beforeUpdate() {
        OrderItemHelper.checkParameters(this.newList);
    }
}
