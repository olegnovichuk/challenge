public without sharing class MissionAssignmentTriggerHandler {

    public void onAfterUpdate(Map<Id, Mission_Assignment__c> newMissionAssignmentById, Map<Id, Mission_Assignment__c> oldMissionAssignmentById) {
        List<Mission_Assignment__c> availableMissionAssignments = new List<Mission_Assignment__c>();

        for (Id missionAssignmentId : newMissionAssignmentById.keySet()) {
            if (
                newMissionAssignmentById.get(missionAssignmentId).Status__c == Service.COMPLETED_STATUS
                && oldMissionAssignmentById.get(missionAssignmentId).Status__c != Service.COMPLETED_STATUS
            ) {
                availableMissionAssignments.add(newMissionAssignmentById.get(missionAssignmentId));
            }
        }

        if (!availableMissionAssignments.isEmpty()) {
            Database.executeBatch(new CompleteMissionBatch(availableMissionAssignments), 200);
        }
    }
}