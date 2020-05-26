global class ServiceAppointmentCancel implements FSL.CustomGanttServiceAppointmentAction {

    global String action(List<Id> serviceAppointmentsIds,
                        Datetime ganttStartDate,
                        Datetime ganttEndDate,
                        Map<String, Object> additionalParameters) {

        List<String> saNames = new List<String>();
        List<ServiceAppointment> saList = [
            SELECT SchedStartTime, SchedEndTime, Status, AppointmentNumber, ParentRecordId
            FROM ServiceAppointment
            WHERE Id IN :serviceAppointmentsIds
        ];

        for (ServiceAppointment serviceAppointment : saList) {
            serviceAppointment.SchedStartTime = serviceAppointment.SchedStartTime.addDays(1);
            serviceAppointment.SchedEndTime = serviceAppointment.SchedEndTime.addDays(1);
            saNames.add(serviceAppointment.AppointmentNumber);
        }

        update saList;

        return String.format(Label.SA_TransferMsg, new List<String> { String.join(saNames, ', ') });
    }
}