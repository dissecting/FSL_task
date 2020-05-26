@isTest
private class ProductRequiredTriggerHandlerTest {

    @testSetup
    private static void setupTestData() {
        Schema.Location warehouse = new Schema.Location(
            Name = 'testWarehouse',
            LocationType = 'Warehouse',
            IsInventoryLocation = true,
            Type__c = Label.MainValue
        );

        insert warehouse;

        Product2 product = new Product2(
            Name = 'Test Product'
        );

        insert product;

        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = product.Id,
            UnitPrice = 10000,
            IsActive = true
        );

        insert pbEntry;

        List<WorkOrder> workOrderList = new List<WorkOrder> {
            new WorkOrder(
                Subject = 'testSubject1',
                Status = 'New',
                Priority = 'Low',
                Pricebook2Id = pricebookId
            ),
            new WorkOrder(
                Subject = 'testSubject2',
                Status = 'New',
                Priority = 'Low',
                Pricebook2Id = pricebookId
            )
        };

        insert workOrderList;

        List<ProductConsumed> productConsumedList = new List<ProductConsumed> {
            new ProductConsumed(
                PricebookEntryId = pbEntry.Id,
                QuantityConsumed = 20,
                WorkOrderId = workOrderList[0].Id
            ),
            new ProductConsumed(
                PricebookEntryId = pbEntry.Id,
                QuantityConsumed = 5,
                WorkOrderId = workOrderList[0].Id
            )
        };

        insert productConsumedList;

        System.assertNotEquals(null, warehouse.Id, 'Location is not created');
        System.assertNotEquals(null, product.Id, 'Product is not created');
        System.assertNotEquals(null, pbEntry.Id, 'PricebookEntry is not created');
        System.assertNotEquals(null, workOrderList[0].Id, 'First WorkOrder is not created');
        System.assertNotEquals(null, workOrderList[1].Id, 'Second WorkOrder is not created');
        System.assertNotEquals(null, productConsumedList[0].Id, 'First ProductConsumed is not created');
        System.assertNotEquals(null, productConsumedList[1].Id, 'Second ProductConsumed is not created');
    }

    @isTest
    private static void testInsertProductRequired() {
        Id warehouseId = MainWarehouse.getWarehouseId();
        WorkOrder workOrder = [
            SELECT Subject
            FROM WorkOrder
            WHERE Subject = 'testSubject1'
            LIMIT 1
        ];

        Product2 product = [
            SELECT Name
            FROM Product2
            WHERE Name = 'Test Product'
            LIMIT 1
        ];

        ProductRequired productRequired = new ProductRequired(
            ParentRecordId = workOrder.Id,
            Product2Id = product.Id,
            QuantityRequired = 30
        );

        Test.startTest();

        insert productRequired;

        Test.stopTest();

        List<ProductRequest> productRequestList = [
            SELECT DestinationLocationId
            FROM ProductRequest
            WHERE DestinationLocationId = :warehouseId
        ];

        List<ProductRequestLineItem> productRequestLineItemList = [
            SELECT DestinationLocationId
            FROM ProductRequestLineItem
            WHERE DestinationLocationId = :warehouseId
        ];

        System.assertEquals(1, productRequestList.size(), 'ProductRequest is not created');
        System.assertEquals(1, productRequestLineItemList.size(), 'ProductRequestLineItem is not created');
    }

    @isTest
    private static void testInsertProductRequiredWithOutProductConsumed() {
        Id warehouseId = MainWarehouse.getWarehouseId();
        WorkOrder workOrder = [
            SELECT Subject
            FROM WorkOrder
            WHERE Subject = 'testSubject2'
            LIMIT 1
        ];

        Product2 product = [
            SELECT Name
            FROM Product2
            WHERE Name = 'Test Product'
            LIMIT 1
        ];

        ProductRequired productRequired = new ProductRequired(
            ParentRecordId = workOrder.Id,
            Product2Id = product.Id,
            QuantityRequired = 30
        );

        Test.startTest();

        insert productRequired;

        Test.stopTest();

        List<ProductRequest> productRequestList = [
            SELECT DestinationLocationId
            FROM ProductRequest
            WHERE DestinationLocationId = :warehouseId
        ];

        System.assertEquals(1, productRequestList.size(), 'ProductRequest is not created');
    }
}