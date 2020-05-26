trigger ProductRequiredTrigger on ProductRequired (after update, after insert) {

    if (Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert)) {
        ProductRequiredTriggerHandler.invokeProductRequest(Trigger.new);
    }
}