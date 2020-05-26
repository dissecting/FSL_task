trigger ServiceAppointmentTrigger on ServiceAppointment (after insert, before insert) {

    if (Trigger.isInsert) {
        if (Trigger.isAfter) {
            ServiceAppointmentTriggerHandler.attachDocuments(Trigger.new);
        } else if (Trigger.isBefore) {
            ServiceAppointmentTriggerHandler.populateParameters(Trigger.new);
        }
    }
}