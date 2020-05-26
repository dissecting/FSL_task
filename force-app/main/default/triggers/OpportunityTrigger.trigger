trigger OpportunityTrigger on Opportunity (after update) {

    if (Trigger.isAfter && Trigger.isUpdate) {
        OpportunityTriggerHandler.prepareProductRequest(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    }
}