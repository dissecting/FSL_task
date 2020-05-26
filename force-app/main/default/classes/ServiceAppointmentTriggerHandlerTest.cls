@isTest
private class ServiceAppointmentTriggerHandlerTest {

    @testSetup
    private static void setupTestData() {
        List<ContentVersion> contentVersionList = new List<ContentVersion> {
            new ContentVersion(
                Title = Label.FirstFileName,
                PathOnClient = Label.FirstFileName + '.txt',
                VersionData = Blob.valueOf('Test Content 1')
            ),
            new ContentVersion(
                Title = Label.SecondFileName,
                PathOnClient = Label.SecondFileName + '.txt',
                VersionData = Blob.valueOf('Test Content 2')
            )
        };

        insert contentVersionList;

        Account account = new Account(
            Name = 'testAccount'
        );

        insert account;

        Contact contact = new Contact(
            LastName = 'testContact',
            AccountId = account.Id
        );

        insert contact;

        Asset asset = new Asset(
            Name = 'testAsset',
            AccountId = account.Id,
            ContactId = contact.Id
        );

        insert asset;

        WorkOrder workOrder = new WorkOrder(
            Status = 'New',
            Priority = 'Low',
            AssetId = asset.Id
        );

        insert workOrder;

        System.assertNotEquals(null, contentVersionList[0].Id, 'First ContentVersion is not created');
        System.assertNotEquals(null, contentVersionList[1].Id, 'Second ContentVersion is not created');
        System.assertNotEquals(null, account.Id, 'Account is not created');
        System.assertNotEquals(null, contact.Id, 'Contact is not created');
        System.assertNotEquals(null, asset.Id, 'Asset is not created');
        System.assertNotEquals(null, workOrder.Id, 'WorkOrder is not created');
    }

    @isTest
    private static void testInsertServiceAppointment() {
        WorkOrder workOrder = [
            SELECT Id
            FROM WorkOrder
            LIMIT 1
        ];

        ServiceAppointment serviceAppointment = new ServiceAppointment(
            ParentRecordId = workOrder.Id,
            Status = 'None',
            EarliestStartTime = Datetime.now(),
            DueDate = Datetime.now().addMonths(1)
        );

        Test.startTest();

        insert serviceAppointment;

        Test.stopTest();

        List<ServiceAppointment> serviceAppointmentList = [
            SELECT ParentRecordId, Asset__c
            FROM ServiceAppointment
            WHERE ParentRecordId = :workOrder.Id
        ];

        List<ContentDocument> contentDocumentList = [
            SELECT Title
            FROM ContentDocument
            WHERE Title = :Label.FirstFileName
                OR Title = :Label.SecondFileName
            LIMIT 2
        ];

        Set<Id> contentDocumentIds = new Map<Id, ContentDocument>(contentDocumentList).keySet();
        Set<Id> serviceAppointmentIds = new Map<Id, ServiceAppointment>(serviceAppointmentList).keySet();

        List<ContentDocumentLink> contentDocumentLinkList = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :contentDocumentIds
                AND LinkedEntityId = :serviceAppointmentIds
        ];

        Asset actualAsset = [
            SELECT Name
            FROM Asset
            WHERE Name = 'testAsset'
            LIMIT 1
        ];

        System.assertEquals(2, contentDocumentLinkList.size(), 'Files are not attached');
        System.assertEquals(actualAsset.Id, serviceAppointmentList[0].Asset__c, 'Asset is not assigned');
    }
}