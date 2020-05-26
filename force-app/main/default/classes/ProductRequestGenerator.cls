public with sharing class ProductRequestGenerator {

    public static void createProductRequest(List<SObject> sobjectList) {
        Id warehouseId = MainWarehouse.getWarehouseId();
        String objectType;
        List<ProductRequest> productRequestList = new List<ProductRequest>();
        Set<Id> workOrderIds = new Set<Id>();

        Map<String, OpportunityLineItem> oppLineItemsByNumberMap = new Map<String, OpportunityLineItem>();
        Map<String, ProductRequired> productRequiredsByNumberMap = new Map<String, ProductRequired>();
        Map<ProductRequired, Id> idsByProductRequiredMap = new Map<ProductRequired, Id>();

        if (sobjectList[0].Id.getSobjectType() == Schema.OpportunityLineItem.sObjectType) {
            objectType = 'OpportunityLineItem';
        } else if (sobjectList[0].Id.getSobjectType() == Schema.ProductRequired.sObjectType) {
            objectType = 'ProductRequired';
        }

        if (warehouseId != null) {
            for (SObject sobjItem : sobjectList) {
                ProductRequest productRequest = new ProductRequest(
                    DestinationLocationId = warehouseId
                );

                if (objectType == 'OpportunityLineItem') {
                    oppLineItemsByNumberMap.put(productRequest.ProductRequestNumber, (OpportunityLineItem) sobjItem);
                } else if (objectType == 'ProductRequired') {
                    ProductRequired productRequired = (ProductRequired) sobjItem;

                    productRequiredsByNumberMap.put(productRequest.ProductRequestNumber, productRequired);

                    if (productRequired.ParentRecordId.getSobjectType() == Schema.WorkOrder.sObjectType) {
                        workOrderIds.add(productRequired.ParentRecordId);
                        productRequest.WorkOrderId = productRequired.ParentRecordId;
                        idsByProductRequiredMap.put(productRequired, productRequired.ParentRecordId);
                    }
                }

                productRequestList.add(productRequest);
            }

            insert productRequestList;

            ProductRequestGenerator.createProductRequestLineItem(
                productRequestList,
                idsByProductRequiredMap,
                oppLineItemsByNumberMap,
                productRequiredsByNumberMap,
                workOrderIds,
                warehouseId,
                objectType
            );
        }
    }

    private static Map<ProductRequired, Decimal> getQuantityMap(Map<ProductRequired, Id> idsByProductRequiredMap,
                                                                Set<Id> workOrderIds) {

        Map<ProductRequired, Decimal> quantityByProductRequiredMap = new Map<ProductRequired, Decimal>();
        Map<Id, List<ProductConsumed>> productConsumedsByIdMap = new Map<Id, List<ProductConsumed>>();
        List<ProductConsumed> productConsumedList = [
            SELECT WorkOrderId, QuantityConsumed, Product2Id, ProductItem.QuantityOnHand
            FROM ProductConsumed
            WHERE WorkOrderId IN :workOrderIds
        ];

        for (ProductConsumed productConsumed : productConsumedList) {
            Id productConsumedKey = productConsumed.WorkOrderId;

            if (productConsumedsByIdMap.containsKey(productConsumedKey)) {
                List<ProductConsumed> newProductConsumedList = productConsumedsByIdMap.get(productConsumedKey);

                newProductConsumedList.add(productConsumed);
                productConsumedsByIdMap.put(productConsumedKey, newProductConsumedList);
            } else {
                productConsumedsByIdMap.put(productConsumedKey, new List<ProductConsumed>{ productConsumed });
            }
        }

        for (ProductRequired productRequired : idsByProductRequiredMap.keySet()) {
            Id productRequiredKey = idsByProductRequiredMap.get(productRequired);
            Decimal quantity = 0;
            Decimal quantityOnHand = 0;

            if (productConsumedsByIdMap.containsKey(productRequiredKey)) {
                for (ProductConsumed productConsumed : productConsumedsByIdMap.get(productRequiredKey)) {
                    if (productConsumed.Product2Id == productRequired.Product2Id) {
                        quantity += productConsumed.QuantityConsumed;
                        quantityOnHand = productConsumed.ProductItem.QuantityOnHand;
                    }
                }

                quantity += quantityOnHand != null ? quantityOnHand : 0;
                quantityByProductRequiredMap.put(productRequired, quantity);
            }
        }

        return quantityByProductRequiredMap;
    }

    private static void createProductRequestLineItem(List<ProductRequest> productRequestList,
                                                    Map<ProductRequired, Id> idsByProductRequiredMap,
                                                    Map<String, OpportunityLineItem> oppLineItemsByNumberMap,
                                                    Map<String, ProductRequired> productRequiredsByNumberMap,
                                                    Set<Id> workOrderIds,
                                                    Id warehouseId,
                                                    String objectType) {

        List<ProductRequestLineItem> productRequestLineItemList = new List<ProductRequestLineItem>();
        Map<ProductRequired, Decimal> quantityByProductRequiredMap = new Map<ProductRequired, Decimal>();

        if (objectType == 'ProductRequired') {
            quantityByProductRequiredMap = ProductRequestGenerator.getQuantityMap(idsByProductRequiredMap, workOrderIds);
        }

        for (ProductRequest productRequest : productRequestList) {
            Id productId;
            Decimal quantityRequested;

            if (objectType == 'OpportunityLineItem') {
                OpportunityLineItem oppLineItem = oppLineItemsByNumberMap.get(productRequest.ProductRequestNumber);

                productId = oppLineItem.Product2Id;
                quantityRequested = oppLineItem.Quantity;
            } else if (objectType == 'ProductRequired') {
                ProductRequired productRequiredKey = productRequiredsByNumberMap.get(
                    productRequest.ProductRequestNumber
                );

                productId = productRequiredKey.Product2Id;
                quantityRequested = quantityByProductRequiredMap.containsKey(productRequiredKey) ?
                    productRequiredKey.QuantityRequired - quantityByProductRequiredMap.get(productRequiredKey) :
                    productRequiredKey.QuantityRequired;
            }

            if (quantityRequested > 0) {
                productRequestLineItemList.add(new ProductRequestLineItem(
                    ParentId = productRequest.Id,
                    Product2Id = productId,
                    DestinationLocationId = warehouseId,
                    QuantityRequested = quantityRequested
                ));
            }
        }

        if (!productRequestLineItemList.isEmpty()) {
            insert productRequestLineItemList;
        }
    }
}