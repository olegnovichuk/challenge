trigger SuperheroMissionTrigger on Superhero_Mission__c (after insert) {
    SuperheroMissionTriggerHandler handler = new SuperheroMissionTriggerHandler();

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.onAfterInsert(Trigger.new);
        }
    }
}