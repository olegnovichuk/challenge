trigger MissionAssignmentTrigger on Mission_Assignment__c (after update) {
    MissionAssignmentTriggerHandler handler = new MissionAssignmentTriggerHandler();

    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            handler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }
    }
}