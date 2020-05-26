@isTest
private class OpportunityTriggerHandlerTest {

    @testSetup
    private static void setupTestData() {
        Account account = new Account(
            Name = 'testAcc'
        );

        insert account;

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

        List<Opportunity> opportunityNewList = new List<Opportunity> {
            new Opportunity(
                AccountId = account.Id,
                Name = 'testOpp1',
                StageName = 'Prospecting',
                CloseDate = Date.today().addMonths(1),
                Pricebook2Id = pricebookId
            ),
            new Opportunity(
                AccountId = account.Id,
                Name = 'testOpp2',
                StageName = 'Prospecting',
                CloseDate = Date.today().addMonths(1),
                Pricebook2Id = pricebookId
            ),
            new Opportunity(
                AccountId = account.Id,
                Name = 'testOpp2',
                StageName = 'Prospecting',
                CloseDate = Date.today().addMonths(1),
                Pricebook2Id = pricebookId
            )
        };

        insert opportunityNewList;

        List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem> {
            new OpportunityLineItem(
                OpportunityId = opportunityNewList[0].Id,
                Quantity = 10,
                Product2Id = product.Id,
                TotalPrice = 10 * pbEntry.UnitPrice
            ),
            new OpportunityLineItem(
                OpportunityId = opportunityNewList[1].Id,
                Quantity = 20,
                Product2Id = product.Id,
                TotalPrice = 20 * pbEntry.UnitPrice
            ),
            new OpportunityLineItem(
                OpportunityId = opportunityNewList[2].Id,
                Quantity = 30,
                Product2Id = product.Id,
                TotalPrice = 30 * pbEntry.UnitPrice
            )
        };

        insert oppLineItemList;

        System.assertNotEquals(null, account.Id, 'Account is not created');
        System.assertNotEquals(null, warehouse.Id, 'Location is not created');
        System.assertNotEquals(null, product.Id, 'Product is not created');
        System.assertNotEquals(null, pbEntry.Id, 'PricebookEntry is not created');
        System.assertNotEquals(null, opportunityNewList[0].Id, 'First Opportunity is not created');
        System.assertNotEquals(null, opportunityNewList[1].Id, 'Second Opportunity is not created');
        System.assertNotEquals(null, opportunityNewList[2].Id, 'Third Opportunity is not created');
        System.assertNotEquals(null, oppLineItemList[0].Id, 'First OpportunityLineItem is not created');
        System.assertNotEquals(null, oppLineItemList[1].Id, 'Second OpportunityLineItem is not created');
        System.assertNotEquals(null, oppLineItemList[2].Id, 'Third OpportunityLineItem is not created');
    }

    @isTest
    private static void testUpdateOpportunity() {
        Id warehouseId = MainWarehouse.getWarehouseId();
        List<Opportunity> opportunityList = [
            SELECT StageName
            FROM Opportunity
        ];

        for (Opportunity opportunity : opportunityList) {
            opportunity.StageName = 'Closed Won';
        }

        Test.startTest();

        update opportunityList;

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

        System.assertEquals(3, productRequestList.size(), 'ProductRequests are not created');
        System.assertEquals(3, productRequestLineItemList.size(), 'ProductRequestLineItems are not created');
    }
}