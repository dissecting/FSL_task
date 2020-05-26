public with sharing class MainWarehouse {

    public static Id getWarehouseId() {

        return [
            SELECT Type__c, LocationType, IsInventoryLocation
            FROM Location
            WHERE Type__c = :Label.MainValue
                AND LocationType = 'Warehouse'
                AND IsInventoryLocation = true
            LIMIT 1
        ].Id;
    }
}