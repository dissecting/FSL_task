public with sharing class ServiceAppointmentTriggerHandler {

    public static void populateParameters(List<ServiceAppointment> serviceAppointmentNewList) {
        Set<Id> workOrderIds = ServiceAppointmentTriggerHandler.populateAsset(
            new Map<Id, WorkOrder>(),
            serviceAppointmentNewList
        );

        Map<Id, WorkOrder> workOrderByIdMap = new Map<Id, WorkOrder>([
            SELECT AssetId
            FROM WorkOrder
            WHERE Id IN :workOrderIds
        ]);

        ServiceAppointmentTriggerHandler.populateAsset(workOrderByIdMap, serviceAppointmentNewList);
    }

    private static Set<Id> populateAsset(Map<Id, WorkOrder> workOrderMap, List<ServiceAppointment> serviceAppointments) {
        Set<Id> workOrderIds = new Set<Id>();

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            Boolean isCondition = (
                serviceAppointment.Asset__c == null &&
                serviceAppointment.ParentRecordId.getSobjectType() == Schema.WorkOrder.sObjectType
            );

            if (isCondition) {
                if (workOrderMap.containsKey(serviceAppointment.ParentRecordId)) {
                    serviceAppointment.Asset__c = workOrderMap.get(serviceAppointment.ParentRecordId).AssetId;
                } else {
                    workOrderIds.add(serviceAppointment.ParentRecordId);
                }
            }
        }

        return workOrderIds;
    }

    public static void attachDocuments(List<ServiceAppointment> serviceAppointmentNewList) {
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        List<ContentDocument> contentDocumentList = [
            SELECT Title
            FROM ContentDocument
            WHERE Title = :Label.FirstFileName
                OR Title = :Label.SecondFileName
            LIMIT 2
        ];

        for (ServiceAppointment serviceAppointment : serviceAppointmentNewList) {
            for (ContentDocument contentDocument : contentDocumentList) {
                contentDocumentLinkList.add(new ContentDocumentLink(
                    ContentDocumentId = contentDocument.Id,
                    LinkedEntityId = serviceAppointment.Id
                ));
            }
        }

        if (!contentDocumentLinkList.isEmpty()) {
            insert contentDocumentLinkList;
        }
    }
}