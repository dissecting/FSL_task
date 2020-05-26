@isTest
private class ServiceAppointmentCancelTest {

    @testSetup
    private static void setupTestData() {
        WorkOrder workOrder = new WorkOrder(
            Status = 'New',
            Priority = 'Low'
        );

        insert workOrder;

        ServiceAppointment serviceAppointment = new ServiceAppointment(
            ParentRecordId = workOrder.Id,
            Status = 'None',
            EarliestStartTime = Datetime.now(),
            DueDate = Datetime.now().addMonths(1)
        );

        insert serviceAppointment;

        System.assertNotEquals(null, workOrder.Id, 'WorkOrder is not created');
        System.assertNotEquals(null, serviceAppointment.Id, 'ServiceAppointment is not created');
    }

    @isTest
    private static void testTransferServiceAppointment() {
        ServiceAppointmentCancel serviceAppointmentCancel = new ServiceAppointmentCancel();
        List<ServiceAppointment> serviceAppointmentList = [
            SELECT SchedStartTime, SchedEndTime, Status
            FROM ServiceAppointment
        ];

        Datetime startDate = Datetime.now().addDays(1);
        Datetime endDate = Datetime.now().addDays(1).addHours(2);

        startDate = startDate.addSeconds(-startDate.second());
        endDate = endDate.addSeconds(-endDate.second());

        for (ServiceAppointment serviceAppointment : serviceAppointmentList) {
            serviceAppointment.Status = 'Scheduled';
            serviceAppointment.SchedStartTime = startDate;
            serviceAppointment.SchedEndTime = endDate;
        }

        update serviceAppointmentList;

        Test.startTest();

        serviceAppointmentCancel.action(
            new List<Id>(new Map<Id, ServiceAppointment>(serviceAppointmentList).keySet()), null, null, null
        );

        Test.stopTest();

        List<ServiceAppointment> transferedServiceAppointmentList = [
            SELECT SchedStartTime, SchedEndTime, Status
            FROM ServiceAppointment
            WHERE Status = 'Scheduled'
                AND SchedStartTime = :startDate.addDays(1)
                AND SchedEndTime = :endDate.addDays(1)
        ];

        System.assertEquals(1, transferedServiceAppointmentList.size(), 'ServiceAppointment is not transferred');
    }
}