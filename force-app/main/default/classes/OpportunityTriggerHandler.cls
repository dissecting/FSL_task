public with sharing class OpportunityTriggerHandler {

    public static void prepareProductRequest(List<Opportunity> opportunityNewList,
                                            List<Opportunity> opportunityOldList,
                                            Map<Id, Opportunity> opportunityNewMap,
                                            Map<Id, Opportunity> opportunityOldMap) {

        List<Opportunity> oppClosedWonList = new List<Opportunity>();

        for (Opportunity opportunity : opportunityNewList) {
            String opportunityOldStage = opportunityOldMap.containsKey(opportunity.Id) ?
                opportunityOldMap.get(opportunity.Id).StageName : null;

            Boolean isOpportunityWon = (
                opportunityOldStage != opportunityNewMap.get(opportunity.Id).StageName &&
                opportunityNewMap.get(opportunity.Id).StageName == 'Closed Won'
            );

            if (isOpportunityWon) {
                oppClosedWonList.add(opportunity);
            }
        }

        if (!oppClosedWonList.isEmpty()) {
            Set<Id> opportunityIds = new Map<Id, Opportunity>(oppClosedWonList).keySet();
            List<OpportunityLineItem> oppLineItemList = [
                SELECT OpportunityId, Product2Id, Quantity
                FROM OpportunityLineItem
                WHERE OpportunityId IN :opportunityIds
            ];

            if (!oppLineItemList.isEmpty()) {
                ProductRequestGenerator.createProductRequest(oppLineItemList);
            }
        }
    }
}